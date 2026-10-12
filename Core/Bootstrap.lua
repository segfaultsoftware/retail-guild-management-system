local addonName, RGMS = ...

RGMS.name = addonName

function RGMS.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RGMS|r: " .. message)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, loadedAddonName)
    if loadedAddonName ~= addonName then
        return
    end

    local savedDataState = RGMS.SavedData.load(RGMSCharacterDB)
    RGMS.SavedDataState = savedDataState

    if savedDataState.enabled then
        RGMSCharacterDB = savedDataState.model
        RGMS.DB = savedDataState.model

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
                .. savedDataState.status
                .. ": "
                .. savedDataState.error
                .. ". The original data was preserved; accept the reset confirmation to recover."
        )
        RGMS.Reset:requestRecovery(savedDataState)
    end

    local initialized, initializeError = RGMS.UI.Initialize()
    if not initialized then
        RGMS.Print("Could not initialize the main window: " .. tostring(initializeError) .. ".")
    elseif type(RGMS.Roster) == "table"
        and type(RGMS.Roster.RefreshStatus) == "function" then
        RGMS.Roster.RefreshStatus()
    end

    self:UnregisterEvent("ADDON_LOADED")
end)
