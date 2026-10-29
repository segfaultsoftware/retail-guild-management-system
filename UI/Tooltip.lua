local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("Tooltip", function()
function hideTooltipIfOwned(owner)
    if GameTooltip:IsOwned(owner) then
        GameTooltip:Hide()
    end
end

showOwnedTooltip = function(owner, title, body, options)
    if type(UI.ShowTooltip) == "function" then
        UI.ShowTooltip(owner, title, body, options)
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if title and title ~= "" then
        GameTooltip:SetText(title)
    else
        GameTooltip:SetText(body or "", 1, 1, 1, true)
    end
    if title and title ~= "" and body and body ~= "" then
        GameTooltip:AddLine(body, 1, 1, 1, true)
    end
    GameTooltip:Show()
end

hideOwnedTooltip = function(owner)
    if type(UI.HideTooltip) == "function" then
        UI.HideTooltip(owner)
    end
    hideTooltipIfOwned(owner)
end


function createOwnedTooltip()
    local tooltip = CreateFrame("Frame", "RGMSTooltip", UIParent, "BackdropTemplate")
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:SetToplevel(true)
    tooltip:SetSize(280, 64)
    flatBackdrop(tooltip, PALETTE.shell, PALETTE.border)
    tooltip.title = tooltip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tooltip.title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, -8)
    tooltip.title:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -10, -8)
    tooltip.title:SetJustifyH("LEFT")
    setFont(tooltip.title, FONT_SEMIBOLD, 12)
    setTextColor(tooltip.title, PALETTE.text)
    tooltip.body = tooltip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tooltip.body:SetPoint("TOPLEFT", tooltip.title, "BOTTOMLEFT", 0, -5)
    tooltip.body:SetPoint("TOPRIGHT", tooltip.title, "BOTTOMRIGHT", 0, -5)
    tooltip.body:SetJustifyH("LEFT")
    tooltip.body:SetJustifyV("TOP")
    setFont(tooltip.body, FONT_REGULAR, 11)
    setTextColor(tooltip.body, PALETTE.secondary)
    tooltip:Hide()
    return tooltip
end


function UI.ShowTooltip(owner, title, body, options)
    if not UI.frame or not UI.frame.ownedTooltip then
        return false
    end
    local tooltip = UI.frame.ownedTooltip
    local hasTitle = type(title) == "string" and title ~= ""
    local compact = type(options) == "table" and options.compact == true
    local anchorAtCursor = type(options) == "table"
        and options.anchorAtCursor == true
    tooltip.owner = owner
    tooltip.title:SetText(tostring(title or ""))
    tooltip.title:SetShown(hasTitle)
    tooltip.body:SetText(tostring(body or ""))
    tooltip.body:ClearAllPoints()
    if hasTitle then
        tooltip.body:SetPoint("TOPLEFT", tooltip.title, "BOTTOMLEFT", 0, -5)
        tooltip.body:SetPoint("TOPRIGHT", tooltip.title, "BOTTOMRIGHT", 0, -5)
    else
        tooltip.body:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, -8)
        tooltip.body:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -10, -8)
    end
    if compact then
        tooltip:SetWidth(math.ceil(tooltip.title:GetStringWidth())
            + 20)
        tooltip:SetHeight(math.max(
            30,
            tooltip.title:GetStringHeight() + 16
        ))
    else
        tooltip:SetWidth(280)
        tooltip:SetHeight(math.max(
            44,
            tooltip.body:GetStringHeight() + (hasTitle and 34 or 16)
        ))
    end
    tooltip:ClearAllPoints()
    if anchorAtCursor and type(GetCursorPosition) == "function" then
        local cursorX, cursorY = GetCursorPosition()
        local scale = type(UIParent.GetEffectiveScale) == "function"
            and UIParent:GetEffectiveScale()
            or 1
        if type(scale) ~= "number" or scale <= 0 then
            scale = 1
        end
        tooltip:SetPoint(
            "TOPLEFT",
            UIParent,
            "BOTTOMLEFT",
            cursorX / scale,
            cursorY / scale
        )
    else
        tooltip:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", 8, 8)
    end
    tooltip:Show()
    return true
end

function UI.HideTooltip(owner)
    if not UI.frame or not UI.frame.ownedTooltip then
        return false
    end
    local tooltip = UI.frame.ownedTooltip
    if owner == nil or tooltip.owner == owner then
        tooltip.owner = nil
        tooltip:Hide()
    end
    return true
end


end, {
    "ShowTooltip",
    "HideTooltip",
})

