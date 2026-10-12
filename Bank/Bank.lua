local _, RGMS = ...

-- Guild bank collection and reporting will live in this module.
RGMS.Bank = RGMS.Bank or {}

function RGMS.Bank.CanScan()
    return RGMS.Reset:canScan("the guild bank")
end

function RGMS.Bank.CanReport()
    return RGMS.Reset:canReport("the bank report")
end

local function alignWithGuildBank()
    if GuildBankFrame == nil
        or type(GuildBankFrame.IsShown) ~= "function"
        or not GuildBankFrame:IsShown() then
        return
    end

    RGMS.UI.AlignToRightOf(GuildBankFrame)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, interactionType)
    if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        if interactionType ~= Enum.PlayerInteractionType.GuildBanker then
            return
        end

        local shown = RGMS.UI.Show("bank")
        if shown then
            alignWithGuildBank()
        end
        return
    end

    if RGMS.UI.IsShown() then
        alignWithGuildBank()
    end
end)

RGMS.Bank.EventFrame = eventFrame
