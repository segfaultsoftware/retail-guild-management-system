-- Transient live guild-note cache and verified best-effort save coordinator.
-- This module owns no WoW frames or globals; the Retail adapter supplies them.
-- Existing guild-note addons expose thin, single-write API wrappers rather than
-- a licensed reusable coordinator for RGMS's cache, conflicts, verification,
-- rollback, and interruption rules, so this RGMS-specific state machine stays
-- small and dependency-injected instead of vendoring an incompatible addon.

local _, RGMS = ...

local Notes = {}

Notes.PRIVATE_NOTE_LIMIT = 5500
Notes.GUILD_NOTE_LIMIT = 31
Notes.LOAD_TIMEOUT_SECONDS = 15
Notes.RETRY_INTERVAL_SECONDS = 1
Notes.MAX_VERIFY_REQUESTS = 3

local function characterCount(value)
    return #(string.gsub(value or "", "[\128-\191]", ""))
end

local function trim(value)
    return string.match(value or "", "^%s*(.-)%s*$") or ""
end

local function hasText(value)
    return type(value) == "string" and string.find(value, "%S") ~= nil
end

local function copyMember(member)
    if type(member) ~= "table" then
        return nil
    end
    return {
        identity = member.identity,
        displayName = member.displayName,
        guid = member.guid,
        index = member.index,
        publicNote = type(member.publicNote) == "string" and member.publicNote or "",
        officerNote = type(member.officerNote) == "string" and member.officerNote or "",
        isSelf = member.isSelf == true,
    }
end

local function call(callback, ...)
    if type(callback) == "function" then
        callback(...)
    end
end

function Notes.create(dependencies)
    dependencies = dependencies or {}
    local controller = {
        dependencies = dependencies,
        cache = {},
        cacheLoaded = false,
        permissions = {
            viewOfficer = false,
            editOfficer = false,
            editPublic = false,
        },
        revision = 0,
        sourceRevision = nil,
        loading = false,
        timedOut = false,
        loadElapsed = 0,
        loadRetryElapsed = 0,
        loadRequests = 0,
        loadNeedsRetry = false,
        editor = nil,
        transaction = nil,
    }

    local function notifyCache(identity)
        call(dependencies.onCacheChanged, identity)
    end

    local function notifyEditor()
        call(dependencies.onEditorChanged, controller:GetEditorModel())
    end

    local function requestRoster()
        local requested, requestError = pcall(function()
            dependencies.api:requestRoster()
        end)
        if not requested then
            return nil, tostring(requestError)
        end
        return true
    end

    local function memberEditable(member, permissions)
        return permissions.editPublic == true or member.isSelf == true
    end

    local function applyEditorMember(editor, member, permissions, preservePrivateDraft)
        local previousPrivate = editor.drafts.privateNote
        editor.member = copyMember(member)
        editor.permissions = {
            viewOfficer = permissions.viewOfficer == true,
            editOfficer = permissions.editOfficer == true,
            editPublic = permissions.editPublic == true,
        }
        local guildNotesReadOnly = dependencies.guildNotesReadOnly == true
        editor.publicEditable = not guildNotesReadOnly
            and member ~= nil and memberEditable(member, permissions)
            or false
        editor.officerVisible = member ~= nil and permissions.viewOfficer == true
        editor.officerEditable = not guildNotesReadOnly
            and editor.officerVisible
            and permissions.editOfficer == true
        editor.baseline.publicNote = member and member.publicNote or ""
        editor.baseline.officerNote = member and member.officerNote or ""
        editor.drafts.publicNote = editor.baseline.publicNote
        editor.drafts.officerNote = editor.baseline.officerNote
        if preservePrivateDraft then
            editor.drafts.privateNote = previousPrivate
        else
            editor.drafts.privateNote = editor.baseline.privateNote
        end
        editor.confirmed = copyMember(member)
    end

    local function editorDirty(editor)
        if not editor then
            return false
        end
        return editor.drafts.privateNote ~= editor.baseline.privateNote
            or editor.drafts.publicNote ~= editor.baseline.publicNote
            or (editor.officerVisible
                and editor.drafts.officerNote ~= editor.baseline.officerNote)
    end

    local function editorMemberChanged(editor, member, permissions)
        if editor.member == nil or member == nil then
            return editor.member ~= member
        end
        return editor.member.guid ~= member.guid
            or editor.member.publicNote ~= member.publicNote
            or ((editor.officerVisible or permissions.viewOfficer == true)
                and editor.member.officerNote ~= member.officerNote)
    end

    local function snapshotIsStale(snapshot)
        return type(snapshot.revision) == "number"
            and type(controller.sourceRevision) == "number"
            and snapshot.revision <= controller.sourceRevision
    end

    local function acceptSnapshot(snapshot, updateEditor)
        if snapshotIsStale(snapshot) then
            return false, "stale"
        end
        if type(snapshot.revision) == "number" then
            controller.sourceRevision = snapshot.revision
        end

        controller.revision = controller.revision + 1
        controller.permissions = {
            viewOfficer = snapshot.permissions
                and snapshot.permissions.viewOfficer == true,
            editOfficer = snapshot.permissions
                and snapshot.permissions.editOfficer == true,
            editPublic = snapshot.permissions
                and snapshot.permissions.editPublic == true,
        }
        controller.cache = {}
        for identity, member in pairs(snapshot.members or {}) do
            local copied = copyMember(member)
            copied.revision = controller.revision
            controller.cache[identity] = copied
        end
        controller.cacheLoaded = true
        controller.loading = false
        controller.timedOut = false
        controller.loadElapsed = 0
        controller.loadRetryElapsed = 0
        controller.loadNeedsRetry = false

        -- A completed request also changes the meaning of unchanged entries:
        -- row indicators may now include live notes again after loading.
        notifyCache(nil)

        local editor = controller.editor
        if updateEditor and editor then
            local member = controller.cache[editor.identity]
            if editor.loadedRevision == nil then
                applyEditorMember(editor, member, controller.permissions, true)
                editor.loadedRevision = controller.revision
                editor.status = member and "ready" or "private-only"
                editor.error = nil
            elseif editor.status == "loading" or editor.status == "load-failed" then
                applyEditorMember(editor, member, controller.permissions, true)
                editor.loadedRevision = controller.revision
                editor.status = member and "ready" or "private-only"
                editor.error = nil
            elseif editorMemberChanged(editor, member, controller.permissions)
                or editor.permissions.viewOfficer ~= controller.permissions.viewOfficer
                or editor.permissions.editOfficer ~= controller.permissions.editOfficer
                or editor.permissions.editPublic ~= controller.permissions.editPublic then
                if editorDirty(editor) then
                    editor.status = "conflict"
                    editor.error = "Guild notes changed while this draft was open. Reopen the character to continue."
                    editor.confirmed = copyMember(member)
                else
                    applyEditorMember(editor, member, controller.permissions, false)
                    editor.loadedRevision = controller.revision
                    editor.status = member and "ready" or "private-only"
                    editor.error = nil
                end
            end
            notifyEditor()
        end
        return true
    end

    local function captureSnapshot()
        local captured, snapshot, state, message = pcall(function()
            return dependencies.api:captureRoster()
        end)
        if not captured then
            return nil, "api-failure", tostring(snapshot)
        end
        if type(snapshot) ~= "table" then
            return nil, state or "incomplete", message
        end
        if type(snapshot.members) ~= "table" then
            return nil, "incomplete", "guild member notes are incomplete"
        end
        return snapshot
    end

    local finishFailure
    local submitRollback
    local beginRollback
    local submitNextWrite

    local function completeSuccess(transaction, member)
        local commitCalled, committed, commitError = pcall(
            dependencies.commitPrivate,
            transaction.identity,
            transaction.privateNote
        )
        if not commitCalled or not committed then
            return beginRollback(
                transaction,
                "Private Note could not be saved: "
                    .. tostring(commitCalled and commitError or committed)
            )
        end
        controller.transaction = nil
        local editor = controller.editor
        if editor then
            editor.status = "saved"
            editor.confirmed = copyMember(member)
        end
        notifyCache(transaction.identity)
        notifyEditor()
        call(dependencies.onSaveComplete, transaction.identity)
        return true
    end

    local function requestVerification(transaction)
        transaction.elapsed = 0
        transaction.requests = transaction.requests + 1
        local requested, requestError = requestRoster()
        if not requested then
            if transaction.stage == "rollback" then
                transaction.rollbackErrors[#transaction.rollbackErrors + 1] =
                    transaction.current.kind
                transaction.rollbackIndex = transaction.rollbackIndex - 1
                return submitRollback(transaction)
            end
            return beginRollback(transaction,
                "Guild-note verification could not be requested: " .. requestError)
        end
        return true
    end

    submitNextWrite = function(transaction)
        transaction.changeIndex = transaction.changeIndex + 1
        local change = transaction.changes[transaction.changeIndex]
        if not change then
            return completeSuccess(transaction, transaction.latestMember)
        end
        transaction.current = change
        transaction.requests = 0
        transaction.stage = "verify"
        transaction.touched[#transaction.touched + 1] = change
        local written, writeResult, writeError = pcall(function()
            return dependencies.api:writeNote(
                transaction.latestMember,
                change.kind,
                change.value
            )
        end)
        if not written or writeResult == false or writeResult == nil then
            return beginRollback(transaction,
                "Could not submit the " .. change.kind .. " guild note: "
                    .. tostring(writeError or writeResult))
        end
        return requestVerification(transaction)
    end

    finishFailure = function(transaction)
        controller.transaction = nil
        local editor = controller.editor
        if editor then
            editor.status = "failed"
            editor.error = transaction.error
            local separator = string.match(editor.error or "", "[%.!?]$")
                and " " or ". "
            if #transaction.rollbackErrors > 0 then
                editor.error = editor.error
                    .. separator .. "Rollback could not be verified for: "
                    .. table.concat(transaction.rollbackErrors, ", ") .. "."
            elseif #transaction.touched > 0 then
                editor.error = editor.error
                    .. separator .. "Changed guild notes were restored."
            end
            editor.confirmed = copyMember(transaction.latestMember)
        end
        notifyCache(transaction.identity)
        notifyEditor()
        call(dependencies.onSaveFailed, transaction.error)
        return nil, transaction.error
    end

    submitRollback = function(transaction)
        local change = transaction.touched[transaction.rollbackIndex]
        if not change then
            return finishFailure(transaction)
        end
        transaction.current = change
        transaction.stage = "rollback"
        transaction.requests = 0
        transaction.elapsed = 0
        local restored, restoreResult, restoreError = pcall(function()
            return dependencies.api:writeNote(
                transaction.latestMember,
                change.kind,
                change.baseline
            )
        end)
        if not restored or restoreResult == false or restoreResult == nil then
            transaction.rollbackErrors[#transaction.rollbackErrors + 1] = change.kind
            transaction.rollbackIndex = transaction.rollbackIndex - 1
            return submitRollback(transaction)
        end
        return requestVerification(transaction)
    end

    beginRollback = function(transaction, message)
        transaction.error = message
        transaction.rollbackErrors = transaction.rollbackErrors or {}
        transaction.rollbackIndex = #transaction.touched
        if transaction.rollbackIndex == 0 then
            return finishFailure(transaction)
        end
        return submitRollback(transaction)
    end

    function controller:GetEditorModel()
        local editor = self.editor
        if not editor then
            return nil
        end
        return {
            identity = editor.identity,
            displayName = editor.displayName,
            status = editor.status,
            error = editor.error,
            drafts = {
                privateNote = editor.drafts.privateNote,
                publicNote = editor.drafts.publicNote,
                officerNote = editor.drafts.officerNote,
            },
            confirmed = copyMember(editor.confirmed),
            publicVisible = editor.member ~= nil or editor.status == "loading"
                or editor.status == "load-failed",
            publicEditable = editor.publicEditable == true,
            officerVisible = editor.officerVisible == true,
            officerEditable = editor.officerEditable == true,
            loading = editor.status == "loading",
            loadFailed = editor.status == "load-failed",
            saving = self.transaction ~= nil,
            conflicted = editor.status == "conflict",
            saveEnabled = self.transaction == nil
                and (editor.status == "ready" or editor.status == "private-only"),
        }
    end

    function controller:RequestLoad()
        if self.loading then
            return true, "coalesced"
        end
        if self.transaction then
            return nil, "save-in-progress"
        end
        self.loading = true
        self.timedOut = false
        self.loadElapsed = 0
        self.loadRetryElapsed = 0
        self.loadRequests = 1
        self.loadNeedsRetry = false
        notifyCache(nil)
        if self.editor then
            self.editor.status = "loading"
            self.editor.error = nil
            self.editor.publicEditable = false
            self.editor.officerEditable = false
        end
        notifyEditor()
        local requested, requestError = requestRoster()
        if not requested then
            self.loading = false
            self.timedOut = true
            if self.editor then
                self.editor.status = "load-failed"
                self.editor.error = "Unable to load guild notes"
            end
            notifyEditor()
            return nil, requestError
        end
        return true
    end

    function controller:EnsureLoaded()
        if self.cacheLoaded then
            return true, "cached"
        end
        return self:RequestLoad()
    end

    function controller:Open(identity, displayName, privateNote)
        if self.transaction then
            return nil, "a note save is in progress"
        end
        if type(identity) ~= "string" or identity == ""
            or type(displayName) ~= "string" or displayName == "" then
            return nil, "character note requires an identity and display name"
        end
        local savedPrivate = type(privateNote) == "string" and privateNote or ""
        local member = self.cache[identity]
        local status
        if self.loading or not self.cacheLoaded then
            status = "loading"
        elseif member then
            status = "ready"
        else
            status = "private-only"
        end
        self.editor = {
            identity = identity,
            displayName = displayName,
            status = status,
            error = nil,
            loadedRevision = self.cacheLoaded and self.revision or nil,
            baseline = {
                privateNote = savedPrivate,
                publicNote = member and member.publicNote or "",
                officerNote = member and member.officerNote or "",
            },
            drafts = {
                privateNote = savedPrivate,
                publicNote = member and member.publicNote or "",
                officerNote = member and member.officerNote or "",
            },
            permissions = {},
        }
        applyEditorMember(self.editor, member, self.permissions, true)
        self.editor.status = status
        self.editor.loadedRevision = self.cacheLoaded and self.revision or nil
        if status == "loading" and not self.loading then
            self:RequestLoad()
        elseif self.timedOut then
            self:RequestLoad()
        end
        notifyEditor()
        return self:GetEditorModel()
    end

    function controller:SetDraft(kind, value)
        local editor = self.editor
        if not editor or self.transaction then
            return nil, "character note is unavailable"
        end
        if kind ~= "privateNote" and kind ~= "publicNote" and kind ~= "officerNote" then
            return nil, "unknown note field"
        end
        if kind == "publicNote" and not editor.publicEditable then
            return nil, "Public Note is read-only"
        end
        if kind == "officerNote" and not editor.officerEditable then
            return nil, "Officer Note is read-only"
        end
        editor.drafts[kind] = type(value) == "string" and value or ""
        return true
    end

    function controller:HasActiveNote(identity, privateNote)
        if hasText(privateNote) then
            return true
        end
        if not self.cacheLoaded then
            return false
        end
        local member = self.cache[identity]
        if not member then
            return false
        end
        return hasText(member.publicNote)
            or (self.permissions.viewOfficer and hasText(member.officerNote))
    end

    function controller:Save()
        local editor = self.editor
        if not editor then
            return nil, "character note is unavailable"
        end
        if self.transaction then
            return nil, "a note save is already in progress"
        end
        if editor.status ~= "ready" and editor.status ~= "private-only" then
            return nil, editor.error or "guild notes are not ready to save"
        end
        if type(dependencies.isScanInProgress) == "function"
            and dependencies.isScanInProgress() then
            return nil, "character notes are disabled during a roster scan"
        end
        if characterCount(editor.drafts.privateNote) > Notes.PRIVATE_NOTE_LIMIT then
            return nil, "Private Note must not exceed 5500 characters"
        end
        if characterCount(editor.drafts.publicNote) > Notes.GUILD_NOTE_LIMIT
            or characterCount(editor.drafts.officerNote) > Notes.GUILD_NOTE_LIMIT then
            return nil, "Guild notes must not exceed 31 characters"
        end

        local snapshot, captureState, captureError = captureSnapshot()
        if not snapshot then
            return nil, captureError or captureState or "guild notes are unavailable"
        end
        local current = snapshot.members[editor.identity]
        local permissions = snapshot.permissions or {}
        if editor.member == nil then
            if current ~= nil then
                return nil, "Guild membership changed; reopen the character to continue"
            end
        elseif current == nil
            or current.guid ~= editor.member.guid
            or current.publicNote ~= editor.baseline.publicNote
            or current.officerNote ~= editor.baseline.officerNote then
            editor.status = "conflict"
            editor.error = "Guild notes changed before Save. Reopen the character to continue."
            editor.confirmed = copyMember(current)
            notifyEditor()
            return nil, editor.error
        end

        local publicChanged = editor.drafts.publicNote ~= editor.baseline.publicNote
        local officerChanged = editor.drafts.officerNote ~= editor.baseline.officerNote
        if editor.officerVisible and permissions.viewOfficer ~= true then
            return nil, "Officer Note is no longer visible"
        end
        if publicChanged and (not current
            or not memberEditable(current, permissions)) then
            return nil, "Public Note is no longer editable"
        end
        if officerChanged and (not current
            or permissions.viewOfficer ~= true
            or permissions.editOfficer ~= true) then
            return nil, "Officer Note is no longer editable"
        end

        local privateValue = trim(editor.drafts.privateNote)
        local transaction = {
            identity = editor.identity,
            privateNote = privateValue ~= "" and privateValue or nil,
            latestMember = copyMember(current),
            changes = {},
            changeIndex = 0,
            touched = {},
            rollbackErrors = {},
        }
        if publicChanged then
            transaction.changes[#transaction.changes + 1] = {
                kind = "public",
                value = editor.drafts.publicNote,
                baseline = editor.baseline.publicNote,
            }
        end
        if officerChanged then
            transaction.changes[#transaction.changes + 1] = {
                kind = "officer",
                value = editor.drafts.officerNote,
                baseline = editor.baseline.officerNote,
            }
        end

        self.transaction = transaction
        editor.status = "saving"
        notifyEditor()
        if #transaction.changes == 0 then
            return completeSuccess(transaction, current)
        end
        return submitNextWrite(transaction)
    end

    function controller:OnRosterUpdated()
        local snapshot, state, message = captureSnapshot()
        if not snapshot then
            if state == "incomplete" then
                if self.loading then
                    self.loadNeedsRetry = true
                end
                return false, "incomplete"
            end
            if self.loading then
                self.loadNeedsRetry = true
            end
            return nil, message or state
        end

        local transaction = self.transaction
        if not transaction then
            return acceptSnapshot(snapshot, true)
        end
        if snapshotIsStale(snapshot) then
            return false, "stale"
        end
        acceptSnapshot(snapshot, false)
        local member = self.cache[transaction.identity]
        transaction.latestMember = copyMember(member)
        local change = transaction.current
        local actual = member and member[change.kind .. "Note"] or nil
        local expected = transaction.stage == "rollback"
            and change.baseline
            or change.value
        if actual ~= expected then
            return false, "awaiting-verification"
        end

        if transaction.stage == "verify" then
            return submitNextWrite(transaction)
        end
        transaction.rollbackIndex = transaction.rollbackIndex - 1
        return submitRollback(transaction)
    end

    function controller:Update(elapsed)
        elapsed = tonumber(elapsed) or 0
        if self.loading then
            self.loadElapsed = self.loadElapsed + elapsed
            self.loadRetryElapsed = self.loadRetryElapsed + elapsed
            if self.loadElapsed >= Notes.LOAD_TIMEOUT_SECONDS then
                self.loading = false
                self.timedOut = true
                self.loadNeedsRetry = false
                if self.editor then
                    self.editor.status = "load-failed"
                    self.editor.error = "Unable to load guild notes"
                end
                notifyCache(nil)
                notifyEditor()
            elseif self.loadNeedsRetry
                and self.loadRetryElapsed >= Notes.RETRY_INTERVAL_SECONDS
                and self.loadRequests < Notes.MAX_VERIFY_REQUESTS then
                self.loadRetryElapsed = 0
                self.loadRequests = self.loadRequests + 1
                self.loadNeedsRetry = false
                requestRoster()
            end
        end

        local transaction = self.transaction
        if not transaction then
            return false
        end
        transaction.elapsed = transaction.elapsed + elapsed
        if transaction.elapsed < Notes.RETRY_INTERVAL_SECONDS then
            return false
        end
        transaction.elapsed = 0
        -- Guild roster refresh events can be throttled or omitted after a
        -- note write. Poll the live roster before requesting another refresh
        -- so an updated API cache can still verify the transaction.
        local verified = self:OnRosterUpdated()
        if verified or self.transaction ~= transaction then
            return verified == true
        end
        if transaction.requests < Notes.MAX_VERIFY_REQUESTS then
            transaction.requests = transaction.requests + 1
            local requested = requestRoster()
            if requested then
                return false
            end
        end
        if transaction.stage == "rollback" then
            transaction.rollbackErrors[#transaction.rollbackErrors + 1] = transaction.current.kind
            transaction.rollbackIndex = transaction.rollbackIndex - 1
            return submitRollback(transaction)
        end
        return beginRollback(transaction,
            "The " .. transaction.current.kind .. " guild note could not be verified")
    end

    function controller:Close()
        local interrupted = self.transaction ~= nil
        self.transaction = nil
        self.editor = nil
        call(dependencies.onEditorChanged, nil)
        return true, interrupted
    end

    return controller
end

if type(RGMS) == "table" then
    RGMS.MainsAltsNotes = Notes
end

return Notes
