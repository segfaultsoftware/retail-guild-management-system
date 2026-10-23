local notes = require("MainsAlts.Notes")
local test = require("Tests.lib.runner")

local function cloneMember(member)
    return {
        identity = member.identity,
        displayName = member.displayName,
        guid = member.guid,
        index = member.index,
        publicNote = member.publicNote,
        officerNote = member.officerNote,
        isSelf = member.isSelf,
    }
end

local function newHarness(options)
    options = options or {}
    local server = options.members or {
        ["main-area52"] = {
            identity = "main-area52",
            displayName = "Main-Area52",
            guid = "Player-1",
            index = 1,
            publicNote = "public",
            officerNote = "officer",
            isSelf = options.isSelf == true,
        },
    }
    local permissions = options.permissions or {
        viewOfficer = true,
        editOfficer = true,
        editPublic = true,
    }
    local calls = {
        requests = 0,
        writes = {},
        commits = {},
        editor = {},
        cache = {},
        completed = 0,
        failures = {},
    }
    local incomplete = options.incomplete == true
    local scanning = false
    local writeResults = options.writeResults or {}
    local sourceRevision = 0
    local controller = notes.create({
        api = {
            requestRoster = function()
                calls.requests = calls.requests + 1
            end,
            captureRoster = function()
                if incomplete then
                    return nil, "incomplete", "partial"
                end
                local members = {}
                for identity, member in pairs(server) do
                    members[identity] = cloneMember(member)
                end
                return {
                    revision = sourceRevision,
                    members = members,
                    permissions = permissions,
                }
            end,
            writeNote = function(_, member, kind, value)
                calls.writes[#calls.writes + 1] = {
                    member = member.identity,
                    kind = kind,
                    value = value,
                }
                local result = table.remove(writeResults, 1)
                if result == false then
                    return nil, "rejected"
                end
                return true
            end,
        },
        isScanInProgress = function()
            return scanning
        end,
        commitPrivate = function(identity, value)
            calls.commits[#calls.commits + 1] = {
                identity = identity,
                value = value,
            }
            if options.commitError then
                return nil, options.commitError
            end
            return true
        end,
        onCacheChanged = function(identity)
            calls.cache[#calls.cache + 1] = identity
        end,
        onEditorChanged = function(model)
            calls.editor[#calls.editor + 1] = model
        end,
        onSaveComplete = function()
            calls.completed = calls.completed + 1
        end,
        onSaveFailed = function(message)
            calls.failures[#calls.failures + 1] = message
        end,
    })
    local function updateServer(kind, value)
        server["main-area52"][kind .. "Note"] = value
        sourceRevision = sourceRevision + 1
    end
    return controller, calls, {
        server = server,
        permissions = permissions,
        setIncomplete = function(value) incomplete = value == true end,
        setScanning = function(value) scanning = value == true end,
        updateServer = updateServer,
        bumpRevision = function() sourceRevision = sourceRevision + 1 end,
        setRevision = function(value) sourceRevision = value end,
    }
end

local function load(controller)
    test.assert_true(controller:RequestLoad())
    return controller:OnRosterUpdated()
end

return {
    test.case("live notes load once per pending request and obey visibility permissions", function()
        local controller, calls, state = newHarness({
            members = {
                ["main-area52"] = {
                    identity = "main-area52",
                    displayName = "Main-Area52",
                    guid = "Player-1",
                    index = 1,
                    publicNote = "   ",
                    officerNote = "hidden officer note",
                    isSelf = true,
                },
            },
            permissions = {
                viewOfficer = false,
                editOfficer = false,
                editPublic = false,
            },
            isSelf = true,
        })

        test.assert_true(controller:RequestLoad())
        local coalesced, reason = controller:RequestLoad()
        test.assert_true(coalesced)
        test.assert_equal(reason, "coalesced")
        test.assert_equal(calls.requests, 1)
        state.bumpRevision()
        test.assert_true(controller:OnRosterUpdated())

        local model = controller:Open("main-area52", "Main-Area52", "private")
        test.assert_true(model.publicEditable)
        test.assert_false(model.officerVisible)
        test.assert_false(model.officerEditable)
        test.assert_false(controller:HasActiveNote("main-area52", ""))
    end),

    test.case("Retail mode exposes guild notes as read-only", function()
        local controller, _, state = newHarness()
        controller.dependencies.guildNotesReadOnly = true
        state.bumpRevision()
        load(controller)

        local model = controller:Open("main-area52", "Main-Area52", "private")
        test.assert_true(model.publicVisible)
        test.assert_true(model.officerVisible)
        test.assert_false(model.publicEditable)
        test.assert_false(model.officerEditable)
        local changed, message = controller:SetDraft("publicNote", "blocked")
        test.assert_nil(changed)
        test.assert_matches(message, "read%-only")
    end),

    test.case("loading and timeout use private-only icons and keep Save unavailable", function()
        local controller, calls, state = newHarness({ incomplete = true })
        test.assert_true(controller:RequestLoad())
        local model = controller:Open("main-area52", "Main-Area52", " private ")
        test.assert_true(model.loading)
        test.assert_false(model.saveEnabled)
        test.assert_true(controller:HasActiveNote("main-area52", " private "))
        test.assert_false(controller:HasActiveNote("main-area52", ""))

        controller:OnRosterUpdated()
        controller:Update(1)
        test.assert_equal(calls.requests, 2)
        controller:Update(14)
        model = controller:GetEditorModel()
        test.assert_true(model.loadFailed)
        test.assert_false(model.saveEnabled)
        test.assert_equal(model.error, "Unable to load guild notes")

        state.setIncomplete(false)
        state.server["main-area52"] = nil
        test.assert_true(controller:Close())
        model = controller:Open("missing-area52", "Missing-Area52", "kept")
        test.assert_true(model.loading)
    end),

    test.case("background refreshes retain confirmed guild-note indicators", function()
        local controller, calls, state = newHarness()
        state.bumpRevision()
        load(controller)
        test.assert_true(controller:HasActiveNote("main-area52", ""))

        test.assert_true(controller:RequestLoad())
        test.assert_true(controller.loading)
        test.assert_true(controller:HasActiveNote("main-area52", ""))

        local ensured, reason = controller:EnsureLoaded()
        test.assert_true(ensured)
        test.assert_equal(reason, "cached")
        test.assert_equal(calls.requests, 2)

        controller:Update(15)
        test.assert_true(controller.timedOut)
        test.assert_true(controller:HasActiveNote("main-area52", ""))
    end),

    test.case("loaded characters absent from the live roster save Private Note only", function()
        local controller, calls, state = newHarness({ members = {} })
        state.bumpRevision()
        load(controller)
        local model = controller:Open("missing-area52", "Missing-Area52", "old")
        test.assert_equal(model.status, "private-only")
        test.assert_false(model.publicVisible)
        test.assert_true(model.saveEnabled)
        test.assert_true(controller:SetDraft("privateNote", "  replacement  "))
        test.assert_true(controller:Save())
        test.assert_equal(calls.writes, {})
        test.assert_equal(calls.commits[1], {
            identity = "missing-area52",
            value = "replacement",
        })
    end),

    test.case("external events refresh clean editors and conflict dirty drafts", function()
        local controller, _, state = newHarness()
        state.bumpRevision()
        load(controller)
        controller:Open("main-area52", "Main-Area52", "private")

        state.updateServer("public", "new live")
        controller:OnRosterUpdated()
        test.assert_equal(controller:GetEditorModel().drafts.publicNote, "new live")

        controller:SetDraft("privateNote", "draft")
        state.updateServer("public", "newer live")
        controller:OnRosterUpdated()
        local model = controller:GetEditorModel()
        test.assert_true(model.conflicted)
        test.assert_equal(model.drafts.privateNote, "draft")
        test.assert_false(model.saveEnabled)
    end),

    test.case("stale snapshot revisions cannot overwrite newer live notes", function()
        local controller, _, state = newHarness()
        state.setRevision(10)
        load(controller)
        controller:Open("main-area52", "Main-Area52", "private")
        state.server["main-area52"].publicNote = "newest"
        state.setRevision(11)
        controller:OnRosterUpdated()
        test.assert_equal(controller:GetEditorModel().drafts.publicNote, "newest")

        state.server["main-area52"].publicNote = "stale"
        state.setRevision(10)
        local accepted, reason = controller:OnRosterUpdated()

        test.assert_false(accepted)
        test.assert_equal(reason, "stale")
        test.assert_equal(controller:GetEditorModel().drafts.publicNote, "newest")
    end),

    test.case("preflight rejects changed live notes without writing", function()
        local controller, calls, state = newHarness()
        state.bumpRevision()
        load(controller)
        controller:Open("main-area52", "Main-Area52", "private")
        controller:SetDraft("publicNote", "mine")
        state.updateServer("public", "someone else's")

        local saved, message = controller:Save()

        test.assert_nil(saved)
        test.assert_matches(message, "changed before Save")
        test.assert_equal(calls.writes, {})
        test.assert_equal(calls.commits, {})
    end),

    test.case("verified guild writes commit Private Note last and complete", function()
        local controller, calls, state = newHarness()
        state.bumpRevision()
        load(controller)
        controller:Open("main-area52", "Main-Area52", "old private")
        controller:SetDraft("privateNote", "  new private  ")
        controller:SetDraft("publicNote", "new public ")

        test.assert_true(controller:Save())
        test.assert_equal(calls.commits, {})
        test.assert_equal(calls.writes[1].value, "new public ")
        state.updateServer("public", "new public ")
        test.assert_true(controller:OnRosterUpdated())

        test.assert_equal(calls.commits[1], {
            identity = "main-area52",
            value = "new private",
        })
        test.assert_equal(calls.completed, 1)
        test.assert_nil(controller.transaction)
    end),

    test.case("verification polls live notes when no roster event arrives", function()
        local controller, calls, state = newHarness()
        state.bumpRevision()
        load(controller)
        controller:Open("main-area52", "Main-Area52", "private")
        controller:SetDraft("publicNote", "new public")

        test.assert_true(controller:Save())
        state.updateServer("public", "new public")
        test.assert_true(controller:Update(1))

        test.assert_equal(calls.completed, 1)
        test.assert_nil(controller.transaction)
    end),

    test.case("rollback polls an unchanged baseline without a roster event", function()
        local controller, calls, state = newHarness()
        state.bumpRevision()
        load(controller)
        controller:Open("main-area52", "Main-Area52", "private")
        controller:SetDraft("publicNote", "unapplied")

        test.assert_true(controller:Save())
        controller:Update(1)
        controller:Update(1)
        controller:Update(1)
        state.bumpRevision()
        controller:Update(1)

        local model = controller:GetEditorModel()
        test.assert_equal(model.status, "failed")
        test.assert_matches(model.error, "restored")
        test.assert_false(string.find(
            model.error,
            "Rollback could not be verified",
            1,
            true
        ) ~= nil)
        test.assert_equal(calls.commits, {})
    end),

    test.case("failed verification rolls a submitted note back and retains drafts", function()
        local controller, calls, state = newHarness()
        state.bumpRevision()
        load(controller)
        controller:Open("main-area52", "Main-Area52", "private")
        controller:SetDraft("publicNote", "unverified")
        test.assert_true(controller:Save())

        controller:Update(1)
        controller:Update(1)
        controller:Update(1)
        test.assert_equal(calls.writes[2], {
            member = "main-area52",
            kind = "public",
            value = "public",
        })
        state.bumpRevision()
        controller:OnRosterUpdated()

        local model = controller:GetEditorModel()
        test.assert_equal(model.status, "failed")
        test.assert_equal(model.drafts.publicNote, "unverified")
        test.assert_matches(model.error, "restored")
        test.assert_equal(calls.commits, {})
    end),

    test.case("Private Note commit failure rolls verified guild writes back", function()
        local controller, calls, state = newHarness({ commitError = "storage failed" })
        state.bumpRevision()
        load(controller)
        controller:Open("main-area52", "Main-Area52", "private")
        controller:SetDraft("privateNote", "new private")
        controller:SetDraft("publicNote", "new public")
        test.assert_true(controller:Save())
        state.updateServer("public", "new public")
        controller:OnRosterUpdated()
        test.assert_equal(calls.writes[2].value, "public")

        state.updateServer("public", "public")
        controller:OnRosterUpdated()

        local model = controller:GetEditorModel()
        test.assert_equal(model.status, "failed")
        test.assert_matches(model.error, "Private Note could not be saved")
        test.assert_matches(model.error, "restored")
    end),

    test.case("rollback failures are reported after a mid-transaction write failure", function()
        local controller, calls, state = newHarness({
            writeResults = { true, false, false, false },
        })
        state.bumpRevision()
        load(controller)
        controller:Open("main-area52", "Main-Area52", "private")
        controller:SetDraft("publicNote", "new public")
        controller:SetDraft("officerNote", "new officer")
        test.assert_true(controller:Save())
        state.updateServer("public", "new public")
        controller:OnRosterUpdated()

        local model = controller:GetEditorModel()
        test.assert_equal(model.status, "failed")
        test.assert_matches(model.error, "Rollback could not be verified")
        test.assert_equal(calls.commits, {})
    end),

    test.case("closing abandons verification and scan locking rejects Save", function()
        local controller, calls, state = newHarness()
        state.bumpRevision()
        load(controller)
        controller:Open("main-area52", "Main-Area52", "private")
        controller:SetDraft("publicNote", "new")
        test.assert_true(controller:Save())
        local closed, interrupted = controller:Close()
        test.assert_true(closed)
        test.assert_true(interrupted)
        state.updateServer("public", "new")
        controller:OnRosterUpdated()
        controller:Update(10)
        test.assert_equal(calls.commits, {})
        test.assert_equal(calls.failures, {})

        controller:Open("main-area52", "Main-Area52", "private")
        state.setScanning(true)
        local saved, message = controller:Save()
        test.assert_nil(saved)
        test.assert_matches(message, "roster scan")
    end),
}
