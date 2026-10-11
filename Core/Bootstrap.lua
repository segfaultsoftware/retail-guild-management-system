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
            "Saved data is "
                .. savedDataState.status
                .. "; scans and reports are disabled. "
                .. savedDataState.error
                .. ". The original data was preserved."
        )
    end

    self:UnregisterEvent("ADDON_LOADED")
end)
