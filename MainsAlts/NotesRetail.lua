-- Retail WoW adapter for the pure live guild-note coordinator.

local _, RGMS = ...

local Retail = {}
local CharacterIdentity = type(RGMS) == "table"
    and RGMS.CharacterIdentity
    or require("Core.CharacterIdentity")
local ClientFlavor = type(RGMS) == "table"
    and RGMS.ClientFlavor
    or require("Core.ClientFlavor")
local Names = type(RGMS) == "table"
    and RGMS.RosterNames
    or require("Roster.Names")

local REGION_NAMES = {
    [1] = "US",
    [2] = "KR",
    [3] = "EU",
    [4] = "TW",
    [5] = "CN",
}

local function currentIdentityContext()
    local activeGuild = type(RGMS) == "table"
        and RGMS.ActiveGuildIdentity
        or nil
    if type(activeGuild) == "table"
        and type(activeGuild.flavor) == "string"
        and activeGuild.flavor ~= ""
        and type(activeGuild.region) == "string"
        and activeGuild.region ~= "" then
        return activeGuild.flavor, activeGuild.region
    end

    local flavor = type(ClientFlavor) == "table"
        and type(ClientFlavor.getFlavor) == "function"
        and ClientFlavor.getFlavor()
        or nil
    local regionId = type(GetCurrentRegion) == "function"
        and GetCurrentRegion()
        or nil
    return flavor, REGION_NAMES[regionId]
end

local function identityForRosterName(value, guid)
    if type(value) ~= "string" or value == "" then
        return nil, nil
    end
    if type(CharacterIdentity) ~= "table"
        or type(CharacterIdentity.create) ~= "function" then
        return nil, nil
    end

    local flavor, region = currentIdentityContext()
    local input = {
        flavor = flavor,
        region = region,
        name = value,
    }
    if type(guid) == "string" and guid ~= "" then
        input.guid = guid
    end
    if flavor == ClientFlavor.RETAIL then
        local defaultRealm = type(GetNormalizedRealmName) == "function"
            and GetNormalizedRealmName()
            or (type(GetRealmName) == "function" and GetRealmName() or "")
        input.name, input.realm = Names.splitDisplayName(value, defaultRealm)
    end

    local identity = CharacterIdentity.create(input)
    if not identity then
        return nil, nil
    end
    return identity.key, identity.displayName
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

    local flavor, region = currentIdentityContext()
    local input = {
        flavor = flavor,
        region = region,
        name = name,
    }
    if flavor == ClientFlavor.RETAIL then
        input.realm = realm or (type(GetNormalizedRealmName) == "function"
            and GetNormalizedRealmName() or "")
    end
    local identity = type(CharacterIdentity) == "table"
        and type(CharacterIdentity.create) == "function"
        and CharacterIdentity.create(input)
        or nil
    return identity and identity.key or nil
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
            local identity, displayName = identityForRosterName(
                info.name,
                info.guid
            )
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
