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

    if type(RGMSCharacterDB) ~= "table" then
        RGMSCharacterDB = {}
    end

    RGMSCharacterDB.loadCount = (tonumber(RGMSCharacterDB.loadCount) or 0) + 1

    local loadedAt, timestampError = RGMS.DateTime.formatPacificTimestamp()
    if not loadedAt then
        error("RGMS could not record its load time: " .. timestampError)
    end
    RGMSCharacterDB.lastLoadedAt = loadedAt

    RGMS.Print("[development] loaded. Type /rgms help for available commands.")
    self:UnregisterEvent("ADDON_LOADED")
end)
