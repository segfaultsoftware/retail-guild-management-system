local addonName, RGMS = ...

RGMS.name = addonName
RGMS.DebugEnabled = false

function RGMS.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RGMS|r: " .. message)
end

function RGMS.Debug(message)
    if not RGMS.DebugEnabled then
        return false
    end

    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff33ff99RGMS|r [debug]: " .. tostring(message)
    )
    return true
end

function RGMS.ToggleDebug()
    RGMS.DebugEnabled = not RGMS.DebugEnabled
    return RGMS.DebugEnabled
end

local REGION_NAMES = {
    [1] = "US",
    [2] = "KR",
    [3] = "EU",
    [4] = "TW",
    [5] = "CN",
}

function RGMS.ResolveCurrentGuildIdentity()
    if type(IsInGuild) ~= "function" or IsInGuild() ~= true
        or type(GetGuildInfo) ~= "function" then
        return nil
    end
    local guildName, _, _, guildRealm = GetGuildInfo("player")
    local normalizedRealm = guildRealm
        or (type(GetNormalizedRealmName) == "function" and GetNormalizedRealmName())
    local displayRealm = guildRealm
        or (type(GetRealmName) == "function" and GetRealmName())
    if type(guildName) ~= "string" or guildName == ""
        or type(normalizedRealm) ~= "string" or normalizedRealm == ""
        or type(displayRealm) ~= "string" or displayRealm == "" then
        return nil
    end
    local clubId = type(C_Club) == "table"
        and type(C_Club.GetGuildClubId) == "function"
        and C_Club.GetGuildClubId()
        or nil
    local regionId = type(GetCurrentRegion) == "function" and GetCurrentRegion() or nil
    return {
        id = tostring(clubId or guildName),
        name = guildName,
        realm = {
            name = RGMS.Realm.normalize(displayRealm),
            slug = RGMS.Realm.normalize(normalizedRealm),
        },
        region = REGION_NAMES[regionId] or "Unknown",
    }
end

function RGMS.ActivateCurrentGuild()
    if type(RGMS.AccountDataState) ~= "table"
        or not RGMS.AccountDataState.enabled
        or type(RGMS.SavedDataState) ~= "table"
        or not RGMS.SavedDataState.enabled then
        RGMS.DB = nil
        return nil
    end
    local identity = RGMS.ResolveCurrentGuildIdentity()
    RGMS.ActiveGuildIdentity = identity
    RGMS.DB = RGMS.AccountData.view(
        RGMS.AccountDataState.model,
        identity,
        RGMS.SavedDataState.model.ui
    )
    return identity
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, loadedAddonName)
    if loadedAddonName ~= addonName then
        return
    end

    local savedDataState = RGMS.SavedData.load(RGMSCharacterDB)
    local accountDataState = RGMS.AccountData.load(RGMSAccountDB)
    savedDataState.scope = "character"
    accountDataState.scope = "account"
    RGMS.SavedDataState = savedDataState
    RGMS.AccountDataState = accountDataState

    -- Each valid store can be normalized independently. Recovery for one
    -- store must not lose the usable model from the other store.
    if savedDataState.enabled then
        RGMSCharacterDB = savedDataState.model
    end
    if accountDataState.enabled then
        RGMSAccountDB = accountDataState.model
    end
    local disabledState = not savedDataState.enabled
        and savedDataState
        or (not accountDataState.enabled and accountDataState or nil)

    if savedDataState.enabled and accountDataState.enabled then
        RGMS.ActivateCurrentGuild()

        if savedDataState.migratedFrom ~= nil then
            RGMS.Print(
                "Saved data migrated from "
                    .. tostring(savedDataState.migratedFrom)
                    .. " to schema version "
                    .. RGMS.SavedData.CURRENT_SCHEMA_VERSION
                    .. "."
            )
        end
        RGMS.Print("[development] loaded. Type /rgms help for available commands.")
    else
        RGMS.DB = nil
        RGMS.Print(
            "RGMS cannot scan or report because saved data is "
                .. disabledState.status
                .. ": "
                .. disabledState.error
                .. ". The original data was preserved; accept the reset confirmation to recover."
        )
        RGMS.Reset:requestRecovery(disabledState)
    end

    local initialized, initializeError = RGMS.UI.Initialize()
    if not initialized then
        RGMS.Print("Could not initialize the main window: " .. tostring(initializeError) .. ".")
    elseif not savedDataState.enabled or not accountDataState.enabled then
        if type(RGMS.UI.SetDataState) == "function" then
            RGMS.UI.SetDataState(false, disabledState.status)
        end
    else
        if type(RGMS.UI.SetDataState) == "function" then
            RGMS.UI.SetDataState(true)
        end
        if type(RGMS.Roster) == "table"
            and type(RGMS.Roster.RefreshStatus) == "function" then
            RGMS.Roster.RefreshStatus()
        end
        if type(RGMS.Bank) == "table"
            and type(RGMS.Bank.RefreshStatus) == "function" then
            RGMS.Bank.RefreshStatus()
        end
    end

    self:UnregisterEvent("ADDON_LOADED")
end)
