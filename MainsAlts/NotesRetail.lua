-- Retail WoW adapter for the pure live guild-note coordinator.

local _, RGMS = ...

local Retail = {}

local function identityForRosterName(value)
    if type(value) ~= "string" or value == "" then
        return nil, nil
    end
    local defaultRealm = type(GetNormalizedRealmName) == "function"
        and GetNormalizedRealmName()
        or (type(GetRealmName) == "function" and GetRealmName() or "")
    if type(RGMS.RosterNames) == "table"
        and type(RGMS.RosterNames.splitDisplayName) == "function"
        and type(RGMS.RosterNames.identity) == "function" then
        local name, realm, displayName = RGMS.RosterNames.splitDisplayName(
            value,
            defaultRealm
        )
        return RGMS.RosterNames.identity(name, realm), displayName
    end
    local name, realm = string.match(value, "^([^%-]+)%-(.+)$")
    name = name or value
    realm = realm or defaultRealm
    return string.lower(name .. "-" .. realm), name .. "-" .. realm
end

local function booleanApi(namespaceName, globalName)
    local namespace = type(C_GuildInfo) == "table" and C_GuildInfo or nil
    local callback = namespace and namespace[namespaceName] or _G[globalName]
    if type(callback) ~= "function" then
        return false
    end
    local called, value = pcall(callback)
    return called and value == true
end

local function readRosterInfo(index)
    if type(C_GuildInfo) == "table"
        and type(C_GuildInfo.GetGuildRosterInfo) == "function" then
        local called, info = pcall(C_GuildInfo.GetGuildRosterInfo, index)
        if called and type(info) == "table" then
            return {
                name = info.name,
                publicNote = info.note or info.publicNote or "",
                officerNote = info.officerNote or "",
                guid = info.guid or info.GUID or info.playerGUID
                    or info.memberGUID or info.guildMemberGUID,
            }
        end
    end
    if type(GetGuildRosterInfo) ~= "function" then
        return nil
    end
    local name, _, _, _, _, _, publicNote, officerNote,
        _, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(index)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    return {
        name = name,
        publicNote = publicNote or "",
        officerNote = officerNote or "",
        guid = guid,
    }
end

local function playerIdentity()
    local name, realm
    if type(UnitFullName) == "function" then
        name, realm = UnitFullName("player")
    elseif type(UnitName) == "function" then
        name, realm = UnitName("player")
    end
    if type(name) ~= "string" or name == "" then
        return nil
    end
    realm = realm or (type(GetNormalizedRealmName) == "function"
        and GetNormalizedRealmName() or "")
    if type(RGMS.RosterNames) == "table"
        and type(RGMS.RosterNames.identity) == "function" then
        return RGMS.RosterNames.identity(name, realm)
    end
    return string.lower(name .. "-" .. realm)
end

function Retail.createApi()
    local api = {}

    function api:requestRoster()
        if type(C_GuildInfo) == "table"
            and type(C_GuildInfo.GuildRoster) == "function" then
            C_GuildInfo.GuildRoster()
        elseif type(GuildRoster) == "function" then
            GuildRoster()
        else
            error("the guild roster API is unavailable")
        end
    end

    function api:captureRoster()
        if type(IsInGuild) == "function" and IsInGuild() ~= true then
            return { members = {}, permissions = {} }
        end
        if type(GetNumGuildMembers) ~= "function" then
            return nil, "incomplete", "the guild member count is unavailable"
        end
        local total = GetNumGuildMembers()
        if type(total) ~= "number" then
            return nil, "incomplete", "the guild member count is incomplete"
        end
        local selfIdentity = playerIdentity()
        local members = {}
        local count = 0
        for index = 1, total do
            local info = readRosterInfo(index)
            if not info then
                return nil, "incomplete", "one or more guild notes are incomplete"
            end
            local identity, displayName = identityForRosterName(info.name)
            if not identity or members[identity] then
                return nil, "incomplete", "guild member identities are incomplete"
            end
            members[identity] = {
                identity = identity,
                displayName = displayName,
                guid = info.guid,
                index = index,
                publicNote = info.publicNote,
                officerNote = info.officerNote,
                isSelf = identity == selfIdentity,
            }
            count = count + 1
        end
        if count ~= total then
            return nil, "incomplete", "the guild note roster is partial"
        end
        return {
            members = members,
            permissions = {
                viewOfficer = booleanApi("CanViewOfficerNote", "CanViewOfficerNote"),
                editOfficer = booleanApi("CanEditOfficerNote", "CanEditOfficerNote"),
                editPublic = booleanApi("CanEditPublicNote", "CanEditPublicNote"),
            },
        }
    end

    function api:writeNote(member, kind, value)
        if type(member) ~= "table" then
            return nil, "the guild member is unavailable"
        end
        local callback = kind == "officer"
            and GuildRosterSetOfficerNote
            or GuildRosterSetPublicNote
        if type(callback) == "function" and type(member.index) == "number" then
            callback(member.index, value)
            return true
        end
        if type(C_GuildInfo) == "table"
            and type(C_GuildInfo.SetNote) == "function" then
            return nil, "the protected " .. kind
                .. " guild-note API cannot be called by addons"
        end
        return nil, "the " .. kind .. " guild-note API is unavailable"
    end

    return api
end

RGMS.MainsAltsNotesRetail = Retail

if type(RGMS.MainsAltsNotes) == "table"
    and type(RGMS.MainsAltsNotes.create) == "function"
    and type(C_GuildInfo) == "table" then
    local controller = RGMS.MainsAltsNotes.create({
        api = Retail.createApi(),
        guildNotesReadOnly = true,
        isScanInProgress = function()
            return type(RGMS.Roster) == "table"
                and type(RGMS.Roster.IsScanInProgress) == "function"
                and RGMS.Roster.IsScanInProgress()
        end,
        commitPrivate = function(identity, value)
            return RGMS.MainsAlts.SaveCharacterNote(identity, value or "")
        end,
        onCacheChanged = function()
            if type(RGMS.MainsAlts) == "table"
                and type(RGMS.MainsAlts.RefreshStatus) == "function" then
                RGMS.MainsAlts.RefreshStatus()
            end
        end,
        onEditorChanged = function(model)
            if type(RGMS.UI) == "table"
                and type(RGMS.UI.SetCharacterNoteState) == "function" then
                RGMS.UI.SetCharacterNoteState(model)
            end
        end,
        onSaveComplete = function()
            if type(RGMS.UI) == "table"
                and type(RGMS.UI.CloseCharacterNoteEditor) == "function" then
                RGMS.UI.CloseCharacterNoteEditor()
            end
        end,
        onSaveFailed = function(message)
            if type(RGMS.Print) == "function" then
                RGMS.Print("Could not save character notes: "
                    .. tostring(message) .. ".")
            end
        end,
    })
    RGMS.LiveGuildNotes = controller

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    eventFrame:RegisterEvent("CLUB_MEMBERS_UPDATED")
    eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" or event == "PLAYER_GUILD_UPDATE" then
            controller:RequestLoad()
        else
            controller:OnRosterUpdated()
        end
    end)
    eventFrame:SetScript("OnUpdate", function(_, elapsed)
        controller:Update(elapsed)
    end)
    Retail.EventFrame = eventFrame
end

return Retail
