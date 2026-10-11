local addonName, RGMS = ...

-- Expose one namespace for future modules while keeping implementation details local.
_G.RGMS = RGMS

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RGMS|r: " .. message)
end

SLASH_RGMS1 = "/rgms"
SlashCmdList.RGMS = function()
    local loadCount = RGMSCharacterDB and RGMSCharacterDB.loadCount or 0
    Print(("loaded successfully for this character (load count: %d)."):format(loadCount))
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, loadedAddonName)
    if loadedAddonName ~= addonName then
        return
    end

    if type(RGMSCharacterDB) ~= "table" then
        RGMSCharacterDB = {}
    end

    RGMSCharacterDB.loadCount = (tonumber(RGMSCharacterDB.loadCount) or 0) + 1
    RGMSCharacterDB.lastLoadedAt = date("%Y-%m-%d %H:%M:%S")

    Print("loaded. Type /rgms to verify the development setup.")
    eventFrame:UnregisterEvent("ADDON_LOADED")
end)
