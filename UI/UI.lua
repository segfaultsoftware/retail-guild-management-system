local _, RGMS = ...

local UI = RGMS.UI or {}

local TAB_ORDER = { "roster", "mainsalts", "bank" }
local TAB_TITLES = {
    roster = "Roster",
    mainsalts = "Mains/Alts",
    bank = "Guild Bank",
}

local INITIAL_COPY = {
    roster = "No roster data yet",
    mainsalts = "No roster data yet",
    bank = "No bank scan yet",
}

local HEADER_HEIGHT = 56
local SIDEBAR_WIDTH = 136
local CONTENT_PADDING = 16
local CONTROL_GAP = 8
local RANK_TAB_WIDTH = 0
local RANK_TAB_HEIGHT = 24
local RANK_TAB_GAP = 3
local ROSTER_CONTENT_GAP = 24
local BANK_TAB_WIDTH = 0
local BANK_CONTENT_GAP = 18
local BANK_TAB_HEIGHT = 28
local BANK_TAB_GAP = 3
local BANK_ROW_HEIGHT = 24
local BANK_ICON_SIZE = 18
local BANK_HEADER_HEIGHT = 28
local BANK_TITLE_HEIGHT = 0
local ROSTER_TITLE_HEIGHT = 0
local ROSTER_GROUP_HEIGHT = 24
local ROSTER_ROW_HEIGHT = 24
local ROSTER_GROUP_GAP = 0
local MAINS_ALTS_ROW_HEIGHT = 24
local MAINS_ALTS_CHECKBOX_SIZE = 16
local MAINS_ALTS_CHECKBOX_LEFT = 8
local MAINS_ALTS_CONTROL_GAP = 4
local MAINS_ALTS_CHARACTER_LEFT = MAINS_ALTS_CHECKBOX_LEFT
    + MAINS_ALTS_CHECKBOX_SIZE + MAINS_ALTS_CONTROL_GAP
local MAINS_ALTS_ALT_INDENT = 64
local MAINS_ALTS_EXPAND_WIDTH = 16
local MAINS_ALTS_PROMOTE_WIDTH = 76
local MAINS_ALTS_REMOVE_WIDTH = 68
local MAINS_ALTS_NOTE_SIZE = 16
local MAINS_ALTS_NOTE_GAP = 4
local MAINS_ALTS_TAG_WIDTH = 24
local MAINS_ALTS_TAG_SIZE = 16
local MAINS_ALTS_SCROLL_DURATION = 0
local MAINS_ALTS_WHEEL_ROWS = 3
-- The legacy ScrollFrame is retained for exact pixel anchors and existing styling;
-- only enough complex row controls for the viewport are kept live and recycled.
local MAINS_ALTS_VIEWPORT_BUFFER_ROWS = 1
local MAINS_ALTS_SEARCH_WIDTH = 252
local MAINS_ALTS_SEARCH_HEIGHT = 32
local MAINS_ALTS_FILTER_WIDTH = 124
local TAG_POPOVER_WIDTH = 340
local TAG_PILL_HEIGHT = 20
local TAG_PILL_GAP = 6
local TAG_POPOVER_PADDING = 8
local CHARACTER_NOTE_LIMIT = 5500
local CHARACTER_NOTE_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\notebook-pen.png"
local CHARACTER_TAG_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\tag.png"
local MISSING_WARNING_SIZE = 16
local MISSING_WARNING_GAP = 4
local MISSING_WARNING_TEXTURE = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local CIRCLE_TEXTURE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local BORDER_TEXTURE = "Interface\\Tooltips\\UI-Tooltip-Border"
local LOGO_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\rgms-logo.png"
local CLOSE_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\x.png"
local CHEVRON_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\chevron-right.png"
local FONT_REGULAR = "Interface\\AddOns\\RGMS\\assets\\fonts\\Inter-Regular.ttf"
local FONT_SEMIBOLD = "Interface\\AddOns\\RGMS\\assets\\fonts\\Inter-SemiBold.ttf"
local PALETTE = type(RGMS.Portal) == "table" and RGMS.Portal.PALETTE or {
    shell = { 0.059, 0.067, 0.082, 1 }, surface = { 0.094, 0.106, 0.129, 1 },
    control = { 0.133, 0.149, 0.18, 1 }, border = { 0.204, 0.227, 0.275, 1 },
    pink = { 0.925, 0.282, 0.6, 1 }, pinkHover = { 0.957, 0.447, 0.714, 1 }, text = { 0.957, 0.957, 0.961, 1 },
    secondary = { 0.631, 0.631, 0.667, 1 }, disabled = { 0.443, 0.443, 0.478, 1 },
    error = { 0.973, 0.443, 0.443, 1 },
}

local function unpackColor(color)
    return color[1], color[2], color[3], color[4]
end

local function setFont(region, path, size)
    if region and type(region.SetFont) == "function" then
        region:SetFont(path, size, "")
    end
end

local MENU_FONT
if type(CreateFont) == "function" then
    MENU_FONT = CreateFont("RGMSMenuFont")
    setFont(MENU_FONT, FONT_SEMIBOLD, 12)
end

local function setTextColor(region, color)
    if region and type(region.SetTextColor) == "function" then
        region:SetTextColor(unpackColor(color))
    end
end

local function flatBackdrop(frame, color, borderColor)
    if type(frame.SetBackdrop) ~= "function" then
        return
    end
    frame:SetBackdrop({
        bgFile = WHITE_TEXTURE,
        edgeFile = BORDER_TEXTURE,
        tile = false,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(unpackColor(color))
    if type(frame.SetBackdropBorderColor) == "function" then
        frame:SetBackdropBorderColor(unpackColor(borderColor or PALETTE.border))
    end
end

local function setTextureColor(texture, color)
    if texture and type(texture.SetVertexColor) == "function" then
        texture:SetVertexColor(unpackColor(color))
    end
end

local function styleTagCapsule(control, background, borderColor)
    if not control then
        return
    end
    if type(control.SetBackdrop) == "function" then
        control:SetBackdrop(nil)
    end
    if not control.tagCapsule then
        local capsule = {}
        for _, layer in ipairs({ "border", "fill" }) do
            capsule[layer] = {
                left = control:CreateTexture(nil, "BACKGROUND"),
                center = control:CreateTexture(nil, "BACKGROUND"),
                right = control:CreateTexture(nil, "BACKGROUND"),
            }
            capsule[layer].left:SetTexture(
                CIRCLE_TEXTURE,
                "CLAMPTOBLACKADDITIVE",
                "CLAMPTOBLACKADDITIVE"
            )
            capsule[layer].center:SetTexture(WHITE_TEXTURE)
            capsule[layer].right:SetTexture(
                CIRCLE_TEXTURE,
                "CLAMPTOBLACKADDITIVE",
                "CLAMPTOBLACKADDITIVE"
            )
        end
        control.tagCapsule = capsule
    end

    local capsule = control.tagCapsule
    local height = math.max(2, control:GetHeight() or TAG_PILL_HEIGHT)
    local radius = height / 2
    local inset = 1
    local innerHeight = math.max(1, height - inset * 2)

    capsule.border.left:ClearAllPoints()
    capsule.border.left:SetSize(height, height)
    capsule.border.left:SetPoint("LEFT", control, "LEFT", 0, 0)
    capsule.border.center:ClearAllPoints()
    capsule.border.center:SetPoint("TOPLEFT", control, "TOPLEFT", radius, 0)
    capsule.border.center:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", -radius, 0)
    capsule.border.right:ClearAllPoints()
    capsule.border.right:SetSize(height, height)
    capsule.border.right:SetPoint("RIGHT", control, "RIGHT", 0, 0)

    capsule.fill.left:ClearAllPoints()
    capsule.fill.left:SetSize(innerHeight, innerHeight)
    capsule.fill.left:SetPoint("LEFT", control, "LEFT", inset, 0)
    capsule.fill.center:ClearAllPoints()
    capsule.fill.center:SetPoint("TOPLEFT", control, "TOPLEFT", radius, -inset)
    capsule.fill.center:SetPoint(
        "BOTTOMRIGHT",
        control,
        "BOTTOMRIGHT",
        -radius,
        inset
    )
    capsule.fill.right:ClearAllPoints()
    capsule.fill.right:SetSize(innerHeight, innerHeight)
    capsule.fill.right:SetPoint("RIGHT", control, "RIGHT", -inset, 0)

    for _, texture in pairs(capsule.border) do
        setTextureColor(texture, borderColor or PALETTE.border)
    end
    for _, texture in pairs(capsule.fill) do
        setTextureColor(texture, background or PALETTE.control)
    end
end

local function styleButton(button, kind, height)
    if not button then
        return
    end
    button:SetHeight(height or 32)
    local background = kind == "primary" and PALETTE.pink or PALETTE.control
    flatBackdrop(button, background, kind == "danger" and PALETTE.error or PALETTE.border)
    if type(button.GetFontString) == "function" then
        local label = button:GetFontString()
        setFont(label, FONT_SEMIBOLD, 12)
        setTextColor(label, kind == "danger" and PALETTE.error or PALETTE.text)
    end
    button:SetScript("OnEnter", function(self)
        if self:IsEnabled() and type(self.SetBackdropColor) == "function" then
            self:SetBackdropColor(unpackColor(kind == "primary" and PALETTE.pinkHover or PALETTE.border))
        end
    end)
    button:SetScript("OnLeave", function(self)
        if type(self.SetBackdropColor) == "function" then
            self:SetBackdropColor(unpackColor(background))
        end
    end)
    button:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() and type(self.SetBackdropColor) == "function" then
            local pressed = kind == "primary" and PALETTE.pinkHover or PALETTE.shell
            self:SetBackdropColor(unpackColor(pressed))
        end
    end)
    button:SetScript("OnMouseUp", function(self)
        if type(self.SetBackdropColor) == "function" then
            self:SetBackdropColor(unpackColor(background))
        end
    end)
end

local function styleScrollFrame(scrollFrame)
    local scrollBar = scrollFrame and (scrollFrame.ScrollBar or scrollFrame.scrollBar)
    if not scrollBar then
        return
    end
    if type(scrollBar.SetWidth) == "function" then
        scrollBar:SetWidth(8)
    end
    for _, button in ipairs({
        scrollBar.ScrollUpButton,
        scrollBar.ScrollDownButton,
        scrollBar.Back,
        scrollBar.Forward,
    }) do
        if button and type(button.Hide) == "function" then
            button:Hide()
        end
    end
    local thumb = scrollBar.ThumbTexture
        or (type(scrollBar.GetThumbTexture) == "function" and scrollBar:GetThumbTexture())
    if thumb then
        thumb:SetTexture(WHITE_TEXTURE)
        thumb:SetVertexColor(unpackColor(PALETTE.border))
    end
end

local showOwnedTooltip
local hideOwnedTooltip
local closeMainsAltsTagEditor
local closeMainsAltsTagFilter
local refreshMainsAltsTagEditor
local refreshMainsAltsTagFilter
local updateMainsAltsTagFilterAppearance

local function attachTruncationTooltip(parent, textRegion)
    local hitbox = CreateFrame("Button", nil, parent)
    hitbox:SetAllPoints(textRegion)
    hitbox:SetScript("OnEnter", function(button)
        if type(textRegion.IsTruncated) == "function" and textRegion:IsTruncated() then
            showOwnedTooltip(button, "Full value", textRegion:GetText())
        end
    end)
    hitbox:SetScript("OnLeave", function(button)
        hideOwnedTooltip(button)
    end)
    return hitbox
end

local function enableRowHover(line)
    line.frame:EnableMouse(true)
    line.frame:SetScript("OnEnter", function()
        line.background:SetVertexColor(unpackColor(PALETTE.control))
    end)
    line.frame:SetScript("OnLeave", function()
        line.background:SetVertexColor(unpackColor(line.baseColor or PALETTE.surface))
    end)
end

local function characterCount(value)
    if type(strlenutf8) == "function" then
        local counted, length = pcall(strlenutf8, value)
        if counted and type(length) == "number" then
            return length
        end
    end
    local withoutContinuationBytes = string.gsub(value, "[\128-\191]", "")
    return #withoutContinuationBytes
end

local function truncateCharacters(value, maximum)
    local parts = {}
    local count = 0
    for character in string.gmatch(value or "", "[^\128-\191][\128-\191]*") do
        count = count + 1
        if count > maximum then
            break
        end
        parts[#parts + 1] = character
    end
    return table.concat(parts)
end

local function normalizeTabId(tabId)
    if type(tabId) ~= "string" then
        return nil
    end

    tabId = string.lower(tabId)
    if TAB_TITLES[tabId] then
        return tabId
    end
    return nil
end

local function getScreenSize()
    return UIParent:GetWidth(), UIParent:GetHeight()
end

local function getFrameRectangle(frame)
    if frame == nil or type(frame.GetRect) ~= "function" then
        return nil, "the anchor frame does not expose its bounds"
    end

    local left, bottom, width, height = frame:GetRect()
    if type(left) ~= "number"
        or type(bottom) ~= "number"
        or type(width) ~= "number"
        or type(height) ~= "number" then
        return nil, "the anchor frame does not have resolved bounds"
    end

    local scale = 1
    if type(frame.GetEffectiveScale) == "function"
        and type(UIParent.GetEffectiveScale) == "function" then
        local frameScale = frame:GetEffectiveScale()
        local parentScale = UIParent:GetEffectiveScale()
        if type(frameScale) == "number"
            and type(parentScale) == "number"
            and parentScale > 0 then
            scale = frameScale / parentScale
        end
    end

    return {
        left = left * scale,
        bottom = bottom * scale,
        width = width * scale,
        height = height * scale,
    }
end

local function savePosition(position)
    if type(RGMS.DB) ~= "table" or type(RGMS.DB.ui) ~= "table" then
        return
    end

    RGMS.DB.ui.windowPosition = {
        point = position.point,
        relativePoint = position.relativePoint,
        x = position.x,
        y = position.y,
    }
end

local function applyClampedPosition(position, shouldSave)
    local frame = UI.frame
    if not frame then
        return nil, "the RGMS window has not been initialized"
    end

    local screenWidth, screenHeight = getScreenSize()
    local clamped, clampError = RGMS.UILayout.clampPosition(
        position,
        frame:GetWidth(),
        frame:GetHeight(),
        screenWidth,
        screenHeight
    )
    if not clamped then
        return nil, clampError
    end

    frame:ClearAllPoints()
    frame:SetPoint(
        clamped.point,
        UIParent,
        clamped.relativePoint,
        clamped.x,
        clamped.y
    )

    if shouldSave then
        savePosition(clamped)
    end
    return clamped
end

local function layoutRosterLines(view, availableWidth)
    if type(view.rosterLines) ~= "table" then
        return
    end

    local nameWidth = math.floor(availableWidth * 0.5)
    local lastOnlineWidth = math.floor(availableWidth * 0.3)
    local tenureWidth = availableWidth - nameWidth - lastOnlineWidth

    local lines = {}
    if view.rosterHeader then
        lines[#lines + 1] = view.rosterHeader
    end
    for _, line in ipairs(view.rosterLines) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(lines) do
        line.frame:SetWidth(availableWidth)
        line.primary:ClearAllPoints()
        line.secondary:ClearAllPoints()
        line.tertiary:ClearAllPoints()
        line.warningIndicator:ClearAllPoints()
        if line.memberRow then
            line.warningIndicator:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
            line.primary:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                MISSING_WARNING_SIZE + MISSING_WARNING_GAP,
                0
            )
        else
            line.primary:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
        end
        if line.columns then
            local warningSpace = line.memberRow
                and (MISSING_WARNING_SIZE + MISSING_WARNING_GAP)
                or 0
            line.primary:SetWidth(math.max(1, nameWidth - warningSpace))
            line.secondary:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                nameWidth,
                0
            )
            line.secondary:SetWidth(lastOnlineWidth)
            line.tertiary:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                nameWidth + lastOnlineWidth,
                0
            )
            line.tertiary:SetWidth(tenureWidth)
        else
            line.primary:SetWidth(availableWidth)
        end
    end
end

local function layoutBankLines(view, availableWidth)
    if type(view.bankRows) ~= "table" then
        return
    end

    local slotWidth = 56
    local countWidth = 64
    local stableWidth = 112
    local ageWidth = 56
    local itemWidth = math.max(
        120,
        availableWidth - slotWidth - countWidth - stableWidth - ageWidth
    )
    local usedWidth = itemWidth + slotWidth + countWidth + stableWidth + ageWidth
    if usedWidth > availableWidth then
        itemWidth = math.max(1, itemWidth - (usedWidth - availableWidth))
    end

    local function positionColumns(line)
        line.frame:SetWidth(availableWidth)
        for _, field in ipairs({ "item", "slot", "count", "stable", "age" }) do
            if line[field] and not (field == "slot" and line.slotCell) then
                line[field]:ClearAllPoints()
            end
        end
        if line.itemButton then
            line.itemButton:ClearAllPoints()
            line.itemButton:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
            line.itemButton:SetSize(itemWidth, BANK_ROW_HEIGHT)
            line.itemIcon:ClearAllPoints()
            line.itemIcon:SetPoint("LEFT", line.itemButton, "LEFT", 0, 0)
            line.item:ClearAllPoints()
            line.item:SetPoint(
                "LEFT",
                line.itemButton,
                "LEFT",
                BANK_ICON_SIZE + 8,
                0
            )
            line.item:SetWidth(math.max(1, itemWidth - BANK_ICON_SIZE - 10))
        else
            line.item:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
            line.item:SetWidth(itemWidth)
        end
        if line.slotCell then
            line.slotCell:ClearAllPoints()
            line.slotCell:SetPoint("LEFT", line.frame, "LEFT", itemWidth, 0)
            line.slotCell:SetSize(slotWidth, BANK_ROW_HEIGHT)
            line.slot:ClearAllPoints()
            line.slot:SetAllPoints(line.slotCell)
        else
            line.slot:SetPoint("LEFT", line.frame, "LEFT", itemWidth, 0)
            line.slot:SetWidth(slotWidth)
        end
        line.count:SetPoint(
            "LEFT",
            line.frame,
            "LEFT",
            itemWidth + slotWidth,
            0
        )
        line.count:SetWidth(countWidth)
        line.stable:SetPoint(
            "LEFT",
            line.frame,
            "LEFT",
            itemWidth + slotWidth + countWidth,
            0
        )
        line.stable:SetWidth(stableWidth)
        line.age:SetPoint(
            "LEFT",
            line.frame,
            "LEFT",
            itemWidth + slotWidth + countWidth + stableWidth,
            0
        )
        line.age:SetWidth(ageWidth)
    end

    if view.bankHeader then
        positionColumns(view.bankHeader)
    end
    for _, line in ipairs(view.bankRows) do
        positionColumns(line)
    end
end

local function layoutMainsAltsLines(view, availableWidth)
    if type(view.mainsAltsLinePool) ~= "table" then
        return
    end

    for _, line in ipairs(view.mainsAltsLinePool) do
        line.frame:SetWidth(availableWidth)
        line.checkbox:ClearAllPoints()
        line.name:ClearAllPoints()
        line.expandButton:ClearAllPoints()
        line.promoteButton:ClearAllPoints()
        line.removeButton:ClearAllPoints()
        line.noteButton:ClearAllPoints()
        line.tagButton:ClearAllPoints()
        if line.isAlt then
            line.name:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                MAINS_ALTS_CHARACTER_LEFT + MAINS_ALTS_EXPAND_WIDTH,
                0
            )
            local maximumNameWidth = math.max(
                1,
                availableWidth
                    - MAINS_ALTS_CHARACTER_LEFT - MAINS_ALTS_EXPAND_WIDTH
                    - MAINS_ALTS_TAG_WIDTH - 56 - 168 - 12
            )
            local nameWidth = type(line.name.GetStringWidth) == "function"
                and line.name:GetStringWidth() + 2
                or maximumNameWidth
            line.name:SetWidth(math.min(maximumNameWidth, nameWidth))
            line.tagButton:SetPoint("CENTER", line.frame, "RIGHT", -236, 0)
            line.noteButton:SetPoint("CENTER", line.frame, "RIGHT", -196, 0)
            line.removeButton:SetPoint("RIGHT", line.frame, "RIGHT", -4, 0)
            line.promoteButton:SetPoint(
                "RIGHT",
                line.removeButton,
                "LEFT",
                -4,
                0
            )
        else
            line.checkbox:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                MAINS_ALTS_CHECKBOX_LEFT,
                0
            )
            line.expandButton:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                MAINS_ALTS_CHARACTER_LEFT,
                0
            )
            line.name:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                MAINS_ALTS_CHARACTER_LEFT + MAINS_ALTS_EXPAND_WIDTH
                    + MAINS_ALTS_CONTROL_GAP,
                0
            )
            local maximumNameWidth = math.max(
                1,
                availableWidth
                    - MAINS_ALTS_CHARACTER_LEFT - MAINS_ALTS_EXPAND_WIDTH
                    - MAINS_ALTS_CONTROL_GAP
                    - MAINS_ALTS_TAG_WIDTH - 56 - 168 - 12
            )
            local nameWidth = type(line.name.GetStringWidth) == "function"
                and line.name:GetStringWidth() + 2
                or maximumNameWidth
            line.name:SetWidth(math.min(maximumNameWidth, nameWidth))
            line.tagButton:SetPoint("CENTER", line.frame, "RIGHT", -236, 0)
            line.noteButton:SetPoint("CENTER", line.frame, "RIGHT", -196, 0)
        end
    end
end

local function createMainsAltsHeader(view)
    local frame = CreateFrame("Frame", nil, view, "BackdropTemplate")
    flatBackdrop(frame, PALETTE.control, PALETTE.border)
    frame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    frame:SetPoint("TOPRIGHT", view, "TOPRIGHT", -8, 0)
    frame:SetHeight(28)
    local characterText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    local tagsText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    local noteText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    local actionsText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    characterText:SetPoint(
        "LEFT",
        frame,
        "LEFT",
        MAINS_ALTS_CHARACTER_LEFT,
        0
    )
    characterText:SetPoint("RIGHT", frame, "RIGHT", -252, 0)
    tagsText:SetPoint("RIGHT", frame, "RIGHT", -224, 0)
    tagsText:SetWidth(MAINS_ALTS_TAG_WIDTH)
    noteText:SetPoint("RIGHT", frame, "RIGHT", -168, 0)
    noteText:SetWidth(56)
    actionsText:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    actionsText:SetWidth(160)
    characterText:SetText("Character")
    tagsText:SetText("")
    noteText:SetText("Note")
    actionsText:SetText("Actions")
    for _, label in ipairs({ characterText, tagsText, noteText, actionsText }) do
        label:SetJustifyH("LEFT")
        setFont(label, FONT_SEMIBOLD, 12)
        setTextColor(label, PALETTE.text)
    end
    noteText:SetJustifyH("CENTER")
    tagsText:SetJustifyH("CENTER")
    frame.character = characterText
    frame.note = noteText
    frame.tags = tagsText
    view.mainsAltsHeader = frame
end

local function refreshScrollChild(view)
    local availableWidth = math.max(1, view.scrollFrame:GetWidth() - 8)
    view.scrollChild:SetWidth(availableWidth)
    view.text:SetWidth(availableWidth)
    layoutRosterLines(view, availableWidth)
    layoutBankLines(view, availableWidth)
    layoutMainsAltsLines(view, availableWidth)

    local viewportHeight = math.max(1, view.scrollFrame:GetHeight())
    local contentHeight = view.rosterTableHeight
        or view.bankTableHeight
        or view.mainsAltsTableHeight
        or (view.text:GetStringHeight() + 16)
    view.scrollChild:SetHeight(math.max(viewportHeight, contentHeight))
end

local function refreshBankTabScrollChild(view)
    if not view.bankTabScrollFrame then
        return
    end

    local viewportHeight = math.max(1, view.bankTabScrollFrame:GetHeight())
    local tabCount = type(view.bankReport) == "table"
        and type(view.bankReport.tabs) == "table"
        and #view.bankReport.tabs
        or 0
    local contentHeight = tabCount * (BANK_TAB_HEIGHT + BANK_TAB_GAP) + 4
    view.bankTabScrollChild:SetHeight(math.max(viewportHeight, contentHeight))
end

local function refreshRankScrollChild(view)
    if not view.rankScrollFrame then
        return
    end

    local viewportHeight = math.max(1, view.rankScrollFrame:GetHeight())
    local rankCount = type(view.rosterReport) == "table"
        and type(view.rosterReport.ranks) == "table"
        and #view.rosterReport.ranks
        or 0
    local contentHeight = rankCount * (RANK_TAB_HEIGHT + RANK_TAB_GAP) + 4
    view.rankScrollChild:SetHeight(math.max(viewportHeight, contentHeight))
end

local function hideTooltipIfOwned(owner)
    if GameTooltip:IsOwned(owner) then
        GameTooltip:Hide()
    end
end

showOwnedTooltip = function(owner, title, body)
    if type(UI.ShowTooltip) == "function" then
        UI.ShowTooltip(owner, title, body)
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    if body and body ~= "" then
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

local function hideRosterLines(view)
    for _, line in ipairs(view.rosterLines or {}) do
        hideOwnedTooltip(line.warningIndicator)
        line.frame:Hide()
    end
    if view.rosterHeader then
        view.rosterHeader.frame:Hide()
    end
    view.rosterTableHeight = nil
end

local function acquireRosterLine(view, index)
    local line = view.rosterLines[index]
    if line then
        return line
    end

    local frame = CreateFrame("Frame", nil, view.scrollChild)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetTexture(WHITE_TEXTURE)
    local divider = frame:CreateTexture(nil, "BORDER")
    divider:SetTexture(WHITE_TEXTURE)
    divider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    divider:SetVertexColor(unpackColor(PALETTE.border))
    local primary = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local secondary = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local tertiary = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local warningIndicator = CreateFrame("Button", nil, frame)
    warningIndicator:SetSize(MISSING_WARNING_SIZE, MISSING_WARNING_SIZE)
    local warningTexture = warningIndicator:CreateTexture(nil, "ARTWORK")
    warningTexture:SetAllPoints()
    warningTexture:SetTexture(MISSING_WARNING_TEXTURE)
    warningIndicator:Hide()
    primary:SetJustifyH("LEFT")
    secondary:SetJustifyH("LEFT")
    tertiary:SetJustifyH("RIGHT")
    primary:SetJustifyV("MIDDLE")
    secondary:SetJustifyV("MIDDLE")
    tertiary:SetJustifyV("MIDDLE")
    if type(primary.SetWordWrap) == "function" then
        primary:SetWordWrap(false)
        secondary:SetWordWrap(false)
        tertiary:SetWordWrap(false)
    end
    line = {
        frame = frame,
        background = background,
        primary = primary,
        secondary = secondary,
        tertiary = tertiary,
        warningIndicator = warningIndicator,
    }
    line.primaryHitbox = attachTruncationTooltip(frame, primary)
    line.secondaryHitbox = attachTruncationTooltip(frame, secondary)
    line.tertiaryHitbox = attachTruncationTooltip(frame, tertiary)
    enableRowHover(line)
    warningIndicator:SetScript("OnEnter", function()
        if line.missingLastSeenDate == nil then
            return
        end
        showOwnedTooltip(
            warningIndicator,
            "Missing roster member",
            "Not found in the current successful roster snapshot.\nLast appeared (Pacific): "
                .. line.missingLastSeenDate
        )
    end)
    warningIndicator:SetScript("OnLeave", function()
        hideOwnedTooltip(warningIndicator)
    end)
    view.rosterLines[index] = line
    return line
end

local function createRosterHeader(view)
    if view.rosterHeader then
        return view.rosterHeader
    end
    local frame = CreateFrame("Frame", nil, view, "BackdropTemplate")
    local header = {
        frame = frame,
        primary = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        secondary = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        tertiary = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        warningIndicator = CreateFrame("Frame", nil, frame),
        columns = true,
        memberRow = false,
    }
    header.warningIndicator:Hide()
    header.primary:SetText("Name-Realm")
    header.secondary:SetText("Last online")
    header.tertiary:SetText("Rank tenure")
    for _, field in ipairs({ "primary", "secondary", "tertiary" }) do
        header[field]:SetJustifyH(field == "tertiary" and "RIGHT" or "LEFT")
        header[field]:SetJustifyV("MIDDLE")
        setFont(header[field], FONT_SEMIBOLD, 12)
        setTextColor(header[field], PALETTE.text)
    end
    flatBackdrop(frame, PALETTE.control, PALETTE.border)
    frame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    frame:SetPoint("TOPRIGHT", view, "TOPRIGHT", -8, 0)
    frame:SetHeight(28)
    view.rosterHeader = header
    return header
end

local function renderRosterRank(view, rank)
    view.text:Hide()
    createRosterHeader(view).frame:Show()
    local lineIndex = 0
    local offset = 0

    local function addLine(
        height,
        primary,
        secondary,
        tertiary,
        columns,
        member
    )
        lineIndex = lineIndex + 1
        local line = acquireRosterLine(view, lineIndex)
        line.columns = columns == true
        line.memberRow = member ~= nil
        line.missingLastSeenDate = member
            and member.isMissing
            and member.missingLastSeenDate
            or nil
        if line.missingLastSeenDate == nil then
            hideOwnedTooltip(line.warningIndicator)
        end
        line.warningIndicator:SetShown(line.missingLastSeenDate ~= nil)
        line.frame:ClearAllPoints()
        line.frame:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
        line.frame:SetHeight(height)
        local rowColor = member and ((lineIndex % 2 == 0) and PALETTE.zebra or PALETTE.surface)
            or PALETTE.control
        line.baseColor = rowColor
        line.background:SetVertexColor(unpackColor(rowColor))
        line.primary:SetText(primary or "")
        line.secondary:SetText(secondary or "")
        line.tertiary:SetText(tertiary or "")
        if member then
            if type(line.primary.SetFontObject) == "function" then
                line.primary:SetFontObject("GameFontHighlight")
            end
            setFont(line.secondary, FONT_REGULAR, 12)
            setFont(line.tertiary, FONT_REGULAR, 12)
        else
            setFont(line.primary, FONT_SEMIBOLD, 12)
        end
        line.frame:Show()
        offset = offset + height
    end

    for groupIndex, group in ipairs(rank.groups) do
        addLine(ROSTER_GROUP_HEIGHT, group.title)
        if #group.members == 0 then
            addLine(
                ROSTER_ROW_HEIGHT,
                "|cff888888" .. group.emptyText .. "|r"
            )
        else
            for _, member in ipairs(group.members) do
                local dayLabel = member.tenureDays == 1 and "day" or "days"
                addLine(
                    ROSTER_ROW_HEIGHT,
                    member.displayName,
                    member.lastOnlineText,
                    string.format("%d %s", member.tenureDays, dayLabel),
                    true,
                    member
                )
            end
        end
        if groupIndex < #rank.groups then
            offset = offset + ROSTER_GROUP_GAP
        end
    end

    for index = lineIndex + 1, #view.rosterLines do
        hideOwnedTooltip(view.rosterLines[index].warningIndicator)
        view.rosterLines[index].frame:Hide()
    end
    view.rosterTableHeight = offset + 4
    view.scrollFrame:SetVerticalScroll(0)
    refreshScrollChild(view)
end

local function findRosterRank(view, rankIndex)
    if type(view.rosterReport) ~= "table" then
        return nil
    end
    for _, rank in ipairs(view.rosterReport.ranks or {}) do
        if rank.index == rankIndex then
            return rank
        end
    end
    return nil
end

local function mainsAltsControlsEnabled(view)
    return UI.dataEnabled ~= false
        and UI.globalScanLocked ~= true
        and view.mainsAltsAvailable ~= false
        and view.mainsAltsScanInProgress ~= true
end

local function hideMainsAltsLines(view)
    for _, line in ipairs(view.mainsAltsLinePool or {}) do
        line.frame:Hide()
    end
    view.mainsAltsLines = {}
    view.mainsAltsRows = {}
    view.mainsAltsViewportFirst = nil
    view.mainsAltsViewportLast = nil
    view.mainsAltsTableHeight = nil
end

local function updateMainsAltsControlState(view)
    local enabled = mainsAltsControlsEnabled(view)
    local selectionCount = 0
    local selectedGroupCount = 0
    for _, row in ipairs(
        type(view.mainsAltsSourceReport) == "table"
            and view.mainsAltsSourceReport.rows
            or {}
    ) do
        if view.mainsAltsSelections[row.identity] == true then
            selectionCount = selectionCount + 1
            if row.altCount > 0 then
                selectedGroupCount = selectedGroupCount + 1
            end
        end
    end
    if view.groupButton then
        view.groupButton:SetEnabled(
            enabled and selectionCount >= 2 and selectedGroupCount <= 1
        )
    end
    if view.mainsAltsSearchBox then
        view.mainsAltsSearchBox:SetEnabled(enabled)
        view.mainsAltsSearchClear:SetEnabled(
            enabled and view.mainsAltsSearchQuery ~= ""
        )
        if type(view.mainsAltsSearchBox.SetAlpha) == "function" then
            view.mainsAltsSearchBox:SetAlpha(enabled and 1 or 0.5)
        end
        if type(view.mainsAltsSearchClear.SetAlpha) == "function" then
            view.mainsAltsSearchClear:SetAlpha(enabled and 1 or 0.5)
        end
        if view.mainsAltsSearchClear.icon then
            view.mainsAltsSearchClear.icon:SetVertexColor(
                unpackColor(enabled and PALETTE.secondary or PALETTE.disabled)
            )
        end
        if type(view.mainsAltsSearchBox.SetBackdropBorderColor) == "function" then
            local border = enabled
                and (view.mainsAltsSearchFocused and PALETTE.pink
                    or view.mainsAltsSearchHovered and PALETTE.pinkHover
                    or PALETTE.border)
                or PALETTE.disabled
            view.mainsAltsSearchBox:SetBackdropBorderColor(unpackColor(border))
        end
    end
    if view.mainsAltsTagFilterButton then
        view.mainsAltsTagFilterButton:SetEnabled(enabled)
        if type(view.mainsAltsTagFilterButton.SetAlpha) == "function" then
            view.mainsAltsTagFilterButton:SetAlpha(enabled and 1 or 0.5)
        end
    end
    for _, line in ipairs(view.mainsAltsLinePool or {}) do
        if line.frame:IsShown() then
            line.checkbox:SetEnabled(enabled and not line.isAlt)
            line.expandButton:SetEnabled(enabled and line.hasAlts)
            line.promoteButton:SetEnabled(enabled and line.isAlt)
            line.removeButton:SetEnabled(enabled and line.isAlt)
            line.noteButton:SetEnabled(enabled)
            line.tagButton:SetEnabled(enabled)
            if type(line.tagButton.SetAlpha) == "function" then
                line.tagButton:SetAlpha(enabled and 1 or 0.5)
            end
        end
    end
    if UI.frame and UI.frame.notesEditor then
        local editor = UI.frame.notesEditor
        editor.saveButton:SetEnabled(enabled)
        editor.deleteButton:SetEnabled(enabled and editor.noteExists == true)
        editor.cancelButton:SetEnabled(enabled)
        editor.closeButton:SetEnabled(enabled)
        if type(editor.editBox.SetEnabled) == "function" then
            editor.editBox:SetEnabled(enabled)
        elseif enabled and type(editor.editBox.Enable) == "function" then
            editor.editBox:Enable()
        elseif not enabled and type(editor.editBox.Disable) == "function" then
            editor.editBox:Disable()
        end
    end
end

local function acquireMainsAltsLine(view, index)
    local line = view.mainsAltsLinePool[index]
    if line then
        return line
    end

    local frame = CreateFrame("Frame", nil, view.scrollChild)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetTexture(WHITE_TEXTURE)
    local divider = frame:CreateTexture(nil, "BORDER")
    divider:SetTexture(WHITE_TEXTURE)
    divider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    divider:SetVertexColor(unpackColor(PALETTE.border))
    local checkbox = CreateFrame(
        "CheckButton",
        nil,
        frame,
        "BackdropTemplate"
    )
    checkbox:SetSize(MAINS_ALTS_CHECKBOX_SIZE, MAINS_ALTS_CHECKBOX_SIZE)
    flatBackdrop(checkbox, PALETTE.control, PALETTE.border)
    if type(checkbox.SetCheckedTexture) == "function" then
        checkbox:SetCheckedTexture("Interface\\AddOns\\RGMS\\assets\\icons\\check.png")
    end
    if type(checkbox.SetHighlightTexture) == "function" then
        checkbox:SetHighlightTexture(WHITE_TEXTURE, "ADD")
    end
    local name = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    name:SetJustifyH("LEFT")
    name:SetJustifyV("MIDDLE")
    if type(name.SetWordWrap) == "function" then
        name:SetWordWrap(false)
    end
    local expandButton = CreateFrame("Button", nil, frame)
    expandButton:SetSize(MAINS_ALTS_EXPAND_WIDTH, 16)
    local expandIcon = expandButton:CreateTexture(nil, "ARTWORK")
    expandIcon:SetAllPoints(expandButton)
    expandIcon:SetTexture(CHEVRON_TEXTURE)
    expandButton.icon = expandIcon
    local promoteButton = CreateFrame(
        "Button",
        nil,
        frame,
        "UIPanelButtonTemplate"
    )
    promoteButton:SetSize(MAINS_ALTS_PROMOTE_WIDTH, 20)
    promoteButton:SetText("Make Main")
    styleButton(promoteButton, "secondary", 20)
    local removeButton = CreateFrame(
        "Button",
        nil,
        frame,
        "UIPanelButtonTemplate"
    )
    removeButton:SetSize(MAINS_ALTS_REMOVE_WIDTH, 20)
    removeButton:SetText("Remove")
    styleButton(removeButton, "danger", 20)
    local noteButton = CreateFrame("Button", nil, frame)
    noteButton:SetSize(MAINS_ALTS_NOTE_SIZE, MAINS_ALTS_NOTE_SIZE)
    local noteIcon = noteButton:CreateTexture(nil, "ARTWORK")
    noteIcon:SetAllPoints(noteButton)
    noteIcon:SetTexture(CHARACTER_NOTE_TEXTURE)
    noteButton.icon = noteIcon
    local tagButton = CreateFrame("Button", nil, frame)
    tagButton:SetSize(MAINS_ALTS_TAG_SIZE, MAINS_ALTS_TAG_SIZE)
    local tagIcon = tagButton:CreateTexture(nil, "ARTWORK")
    tagIcon:SetAllPoints(tagButton)
    tagIcon:SetTexture(CHARACTER_TAG_TEXTURE)
    tagButton.icon = tagIcon
    line = {
        frame = frame,
        background = background,
        checkbox = checkbox,
        name = name,
        expandButton = expandButton,
        promoteButton = promoteButton,
        removeButton = removeButton,
        noteButton = noteButton,
        tagButton = tagButton,
    }
    line.nameHitbox = attachTruncationTooltip(frame, name)
    enableRowHover(line)
    expandButton:SetScript("OnEnter", function(button)
        showOwnedTooltip(button, line.expandTooltip or "Expand", "Show or hide this main's alts.")
    end)
    expandButton:SetScript("OnLeave", function(button)
        hideOwnedTooltip(button)
    end)
    expandButton:SetScript("OnClick", function()
        if line.character then
            UI.ToggleMainsAltsGroup(line.character.identity)
        end
    end)
    checkbox:SetScript("OnClick", function(button)
        if not line.character then
            return
        end
        if not mainsAltsControlsEnabled(view) then
            button:SetChecked(
                view.mainsAltsSelections[line.character.identity] == true
            )
            return
        end
        view.mainsAltsSelections[line.character.identity] = button:GetChecked()
            == true
        updateMainsAltsControlState(view)
    end)
    promoteButton:SetScript("OnClick", function()
        if not line.character then
            return
        end
        local promoted, promoteError = RGMS.MainsAlts.PromoteAlt(
            line.character.identity
        )
        if not promoted and type(RGMS.Print) == "function" then
            RGMS.Print("Could not promote alt: " .. tostring(promoteError) .. ".")
        end
    end)
    removeButton:SetScript("OnClick", function()
        if not line.character then
            return
        end
        local removed, removeError = RGMS.MainsAlts.RemoveAlt(
            line.character.identity
        )
        if not removed and type(RGMS.Print) == "function" then
            RGMS.Print("Could not remove alt: " .. tostring(removeError) .. ".")
        end
    end)
    noteButton:SetScript("OnClick", function()
        if not line.character then
            return
        end
        local character = line.character
        local opened, openError = UI.OpenCharacterNote(
            character.identity,
            character.displayName,
            character.note,
            character.hasNote
        )
        if not opened and type(RGMS.Print) == "function" then
            RGMS.Print("Could not open character note: "
                .. tostring(openError) .. ".")
        end
    end)
    noteButton:SetScript("OnEnter", function(button)
        if not line.character then
            return
        end
        showOwnedTooltip(button,
            (line.hasNote and "Edit saved note for " or "Add note for ")
                .. line.character.displayName,
            "Open the character note editor."
        )
    end)
    noteButton:SetScript("OnLeave", function(button)
        hideOwnedTooltip(button)
    end)
    tagButton:SetScript("OnClick", function()
        if line.character then
            UI.OpenMainsAltsTagEditor(line.character.identity, tagButton)
        end
    end)
    tagButton:SetScript("OnEnter", function()
        if line.character and #(line.character.tags or {}) > 0 then
            UI.ShowMainsAltsTagPreview(line.character.tags, tagButton)
        end
    end)
    tagButton:SetScript("OnLeave", function()
        UI.HideMainsAltsTagPreview()
    end)
    view.mainsAltsLinePool[index] = line
    return line
end

local function bindMainsAltsLine(view, line, row, rowIndex)
    local character = row.character
    line.character = character
    line.isAlt = row.isAlt
    line.hasAlts = not line.isAlt and character.altCount > 0
    line.identity = character.identity
    line.offset = row.offset
    line.hasNote = character.hasNote == true
    line.tags = character.tags or {}
    line.frame:ClearAllPoints()
    line.frame:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -row.offset)
    line.frame:SetHeight(MAINS_ALTS_ROW_HEIGHT)
    line.noteButton.icon:SetVertexColor(
        line.hasNote and 1 or 0.55,
        line.hasNote and 0.82 or 0.55,
        line.hasNote and 0.2 or 0.55,
        line.hasNote and 1 or 0.65
    )
    line.noteButton:Show()
    line.tagButton.icon:SetVertexColor(
        #line.tags > 0 and 1 or 0.55,
        #line.tags > 0 and 0.82 or 0.55,
        #line.tags > 0 and 0.2 or 0.55,
        #line.tags > 0 and 1 or 0.65
    )
    line.tagButton:Show()
    if view.mainsAltsTagEditor
        and view.mainsAltsTagEditor:IsShown()
        and view.mainsAltsTagEditor.characterIdentity == character.identity then
        view.mainsAltsTagEditor:ClearAllPoints()
        view.mainsAltsTagEditor:SetPoint("TOPRIGHT", line.tagButton, "BOTTOMRIGHT", 0, -4)
        view.mainsAltsTagEditor.anchor = line.tagButton
    end

    if line.isAlt then
        line.checkbox:Hide()
        line.expandButton:Hide()
        line.name:SetText(character.displayName)
        line.promoteButton:Show()
        line.removeButton:Show()
    else
        line.promoteButton:Hide()
        line.removeButton:Hide()
        line.checkbox:SetChecked(
            view.mainsAltsSelections[character.identity] == true
        )
        line.checkbox:Show()
        if line.hasAlts then
            line.name:SetText(string.format(
                "%s (+%d)",
                character.displayName,
                character.altCount
            ))
            local expanded = view.expandedMainsAlts[character.identity] == true
            line.expandTooltip = expanded and "Collapse alts" or "Expand alts"
            line.expandButton:SetText("")
            if line.expandButton.icon
                and type(line.expandButton.icon.SetRotation) == "function" then
                line.expandButton.icon:SetRotation(expanded and math.pi / 2 or 0)
            end
            line.expandButton:Show()
        else
            line.name:SetText(character.displayName)
            line.expandButton:Hide()
        end
    end
    line.baseColor = (rowIndex % 2 == 0) and PALETTE.zebra or PALETTE.surface
    line.background:SetVertexColor(unpackColor(line.baseColor))
    line.frame:Show()
end

local function renderMainsAltsViewport(view, explicitOffset, force)
    local rows = view.mainsAltsRows or {}
    local rowCount = #rows
    if rowCount == 0 then
        for _, line in ipairs(view.mainsAltsLinePool or {}) do
            line.frame:Hide()
        end
        view.mainsAltsLines = {}
        view.mainsAltsViewportFirst = nil
        view.mainsAltsViewportLast = nil
        return
    end

    local offset = explicitOffset or view.scrollFrame:GetVerticalScroll()
    local viewportHeight = math.max(1, view.scrollFrame:GetHeight())
    local firstVisible = math.max(
        1,
        math.floor((offset - 4) / MAINS_ALTS_ROW_HEIGHT) + 1
    )
    local lastVisible = math.min(
        rowCount,
        math.ceil((offset + viewportHeight - 4) / MAINS_ALTS_ROW_HEIGHT)
    )
    local first = math.max(1, firstVisible - MAINS_ALTS_VIEWPORT_BUFFER_ROWS)
    local last = math.min(
        rowCount,
        lastVisible + MAINS_ALTS_VIEWPORT_BUFFER_ROWS
    )
    if not force
        and first == view.mainsAltsViewportFirst
        and last == view.mainsAltsViewportLast then
        return
    end

    view.mainsAltsViewportFirst = first
    view.mainsAltsViewportLast = last
    view.mainsAltsLines = {}
    local poolIndex = 0
    for rowIndex = first, last do
        poolIndex = poolIndex + 1
        local line = acquireMainsAltsLine(view, poolIndex)
        bindMainsAltsLine(view, line, rows[rowIndex], rowIndex)
        view.mainsAltsLines[rowIndex] = line
    end
    for index = poolIndex + 1, #view.mainsAltsLinePool do
        view.mainsAltsLinePool[index].frame:Hide()
    end
    layoutMainsAltsLines(view, math.max(1, view.scrollFrame:GetWidth() - 8))
    updateMainsAltsControlState(view)
end

local function mainsAltsMaximumScroll(view)
    local contentHeight = type(view.mainsAltsTableHeight) == "number"
        and view.mainsAltsTableHeight
        or view.scrollChild:GetHeight()
    return math.max(0, contentHeight - view.scrollFrame:GetHeight())
end

local function clampMainsAltsScroll(view, offset)
    return math.max(0, math.min(offset or 0, mainsAltsMaximumScroll(view)))
end

local function setMainsAltsScroll(view, offset)
    view.settingMainsAltsScroll = true
    local clampedOffset = clampMainsAltsScroll(view, offset)
    view.scrollFrame:SetVerticalScroll(clampedOffset)
    view.settingMainsAltsScroll = false
    renderMainsAltsViewport(view, clampedOffset)
end

local function cancelMainsAltsScrollAnimation(view)
    view.mainsAltsScrollAnimation = nil
end

local function cancelMainsAltsScrollWork(view)
    cancelMainsAltsScrollAnimation(view)
    view.pendingMainsAltsScrollTarget = nil
end

local function captureMainsAltsScrollAnchor(view)
    local offset = view.scrollFrame:GetVerticalScroll()
    for _, row in ipairs(view.mainsAltsRows or {}) do
        if row.offset + MAINS_ALTS_ROW_HEIGHT > offset then
            return {
                identity = row.identity,
                relativeOffset = row.offset - offset,
                numericOffset = offset,
            }
        end
    end
    return { numericOffset = offset }
end

local function findMainsAltsRow(view, identity, topLevelOnly)
    for _, row in ipairs(view.mainsAltsRows or {}) do
        if row.identity == identity
            and (not topLevelOnly or not row.isAlt) then
            return row
        end
    end
    return nil
end

local function restoreMainsAltsScrollAnchor(view, anchor)
    if not anchor then
        return
    end
    local line = anchor.identity
        and findMainsAltsRow(view, anchor.identity, false)
        or nil
    if line then
        setMainsAltsScroll(view, line.offset - anchor.relativeOffset)
    else
        setMainsAltsScroll(view, anchor.numericOffset)
    end
end

local function startMainsAltsScrollAnimation(view, line)
    cancelMainsAltsScrollAnimation(view)
    setMainsAltsScroll(view, line.offset)
end

local function updateMainsAltsScrollAnimation(view, elapsed)
    cancelMainsAltsScrollAnimation(view)
end

local function renderMainsAlts(view, resolvePendingTarget, preferredAnchor)
    cancelMainsAltsScrollAnimation(view)
    local anchor = preferredAnchor or captureMainsAltsScrollAnchor(view)
    hideMainsAltsLines(view)
    view.text:Hide()
    local lineIndex = 0
    local offset = 4

    local function addLine(character, isAlt)
        lineIndex = lineIndex + 1
        view.mainsAltsRows[lineIndex] = {
            character = character,
            identity = character.identity,
            isAlt = isAlt == true,
            offset = offset,
        }
        offset = offset + MAINS_ALTS_ROW_HEIGHT
    end

    for _, row in ipairs(view.mainsAltsReport.rows) do
        addLine(row, false)
        if view.expandedMainsAlts[row.identity] then
            for _, alt in ipairs(row.alts) do
                addLine(alt, true)
            end
        end
    end

    view.mainsAltsTableHeight = offset + 4
    if preferredAnchor and preferredAnchor.identity then
        local anchoredLine = findMainsAltsRow(
            view,
            preferredAnchor.identity,
            true
        )
        if anchoredLine then
            local anchoredOffset = math.max(
                0,
                anchoredLine.offset - preferredAnchor.relativeOffset
            )
            view.mainsAltsTableHeight = math.max(
                view.mainsAltsTableHeight,
                anchoredOffset + view.scrollFrame:GetHeight()
            )
        end
    end
    refreshScrollChild(view)

    if lineIndex == 0 then
        cancelMainsAltsScrollWork(view)
        setMainsAltsScroll(view, 0)
        return
    end

    if resolvePendingTarget and view.pendingMainsAltsScrollTarget then
        local targetIdentity = view.pendingMainsAltsScrollTarget
        view.pendingMainsAltsScrollTarget = nil
        local targetLine = findMainsAltsRow(view, targetIdentity, true)
        if targetLine
            and UI.selectedTab == "mainsalts"
            and UI.frame:IsShown()
            and view:IsShown()
            and view.mainsAltsAvailable ~= false then
            startMainsAltsScrollAnimation(view, targetLine)
            return
        end
    end
    restoreMainsAltsScrollAnchor(view, anchor)
end

local function updateMainsAltsSearchAppearance(view)
    local query = view.mainsAltsSearchQuery or ""
    view.mainsAltsSearchPlaceholder:SetShown(query == "")
    view.mainsAltsSearchClear:SetShown(query ~= "")

    if type(view.mainsAltsSearchBox.SetBackdropBorderColor) == "function" then
        local color = view.mainsAltsSearchFocused and PALETTE.pink
            or view.mainsAltsSearchHovered and PALETTE.pinkHover
            or PALETTE.border
        if not mainsAltsControlsEnabled(view) then
            color = PALETTE.disabled
        end
        view.mainsAltsSearchBox:SetBackdropBorderColor(unpackColor(color))
    end
    if updateMainsAltsTagFilterAppearance then
        updateMainsAltsTagFilterAppearance(view)
    end
end

local function applyMainsAltsSearch(view, resetScroll, resolvePendingTarget)
    local source = view.mainsAltsSourceReport
    if type(source) ~= "table" or type(source.rows) ~= "table" then
        return
    end
    local availableTags = {}
    for _, name in ipairs(source.tagCatalog or {}) do
        availableTags[name] = true
    end
    for name in pairs(view.mainsAltsTagFilters or {}) do
        if not availableTags[name] then
            view.mainsAltsTagFilters[name] = nil
        end
    end

    local filtered, matchingGroups, normalized = RGMS.MainsAltsSearch.filter(
        source,
        view.mainsAltsSearchQuery,
        view.mainsAltsTagFilters
    )
    if not filtered then
        filtered = source
        matchingGroups = {}
        normalized = ""
    end
    view.mainsAltsReport = filtered
    view.mainsAltsNormalizedSearch = normalized
    local hasTagFilters = type(view.mainsAltsTagFilters) == "table"
        and next(view.mainsAltsTagFilters) ~= nil
    if normalized ~= "" or hasTagFilters then
        view.expandedMainsAlts = matchingGroups
    elseif resetScroll then
        view.expandedMainsAlts = {}
    end

    renderMainsAlts(view, resolvePendingTarget == true)
    if resetScroll then
        cancelMainsAltsScrollWork(view)
        setMainsAltsScroll(view, 0)
    end
    updateMainsAltsSearchAppearance(view)
    if refreshMainsAltsTagFilter then
        refreshMainsAltsTagFilter(view)
    end
    if view.mainsAltsTagEditor and view.mainsAltsTagEditor:IsShown() then
        local identity = view.mainsAltsTagEditor.characterIdentity
        local visible = false
        for _, row in ipairs(filtered.rows or {}) do
            if row.identity == identity then
                visible = true
                break
            end
            for _, alt in ipairs(row.alts or {}) do
                if alt.identity == identity then
                    visible = true
                    break
                end
            end
            if visible then
                break
            end
        end
        if not visible and closeMainsAltsTagEditor then
            closeMainsAltsTagEditor(view)
        elseif refreshMainsAltsTagEditor then
            refreshMainsAltsTagEditor(view)
        end
    end
end

local function clearMainsAltsSearch(view, keepFocus)
    view.settingMainsAltsSearchText = true
    view.mainsAltsSearchBox:SetText("")
    view.settingMainsAltsSearchText = false
    view.mainsAltsSearchQuery = ""
    applyMainsAltsSearch(view, true, false)
    if keepFocus then
        view.mainsAltsSearchBox:SetFocus()
    else
        view.mainsAltsSearchBox:ClearFocus()
    end
end

local function clearMainsAltsFilters(view, keepSearchFocus)
    view.mainsAltsTagFilters = {}
    if view.mainsAltsTagPreview then
        view.mainsAltsTagPreview:Hide()
    end
    if closeMainsAltsTagEditor then
        closeMainsAltsTagEditor(view)
    end
    if closeMainsAltsTagFilter then
        closeMainsAltsTagFilter(view)
    end
    clearMainsAltsSearch(view, keepSearchFocus == true)
end

local function createMainsAltsSearch(view)
    local editBox = CreateFrame("EditBox", nil, view, "BackdropTemplate")
    editBox:SetSize(MAINS_ALTS_SEARCH_WIDTH, MAINS_ALTS_SEARCH_HEIGHT)
    editBox:SetPoint("TOPLEFT", view.groupButton, "TOPRIGHT", CONTROL_GAP, 0)
    editBox:SetAutoFocus(false)
    editBox:SetJustifyH("LEFT")
    if type(editBox.SetTextInsets) == "function" then
        editBox:SetTextInsets(10, 32, 0, 0)
    end
    setFont(editBox, FONT_REGULAR, 12)
    flatBackdrop(editBox, PALETTE.control, PALETTE.border)

    local placeholder = editBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placeholder:SetPoint("LEFT", editBox, "LEFT", 10, 0)
    placeholder:SetPoint("RIGHT", editBox, "RIGHT", -32, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetText("Search characters…")
    setFont(placeholder, FONT_REGULAR, 12)
    setTextColor(placeholder, PALETTE.secondary)

    local clearButton = CreateFrame("Button", nil, editBox)
    clearButton:SetSize(24, 24)
    clearButton:SetPoint("RIGHT", editBox, "RIGHT", -4, 0)
    clearButton.icon = clearButton:CreateTexture(nil, "ARTWORK")
    clearButton.icon:SetSize(16, 16)
    clearButton.icon:SetPoint("CENTER", clearButton, "CENTER", 0, 0)
    clearButton.icon:SetTexture(CLOSE_TEXTURE)
    clearButton.icon:SetVertexColor(unpackColor(PALETTE.secondary))
    clearButton:SetScript("OnClick", function()
        if mainsAltsControlsEnabled(view) then
            clearMainsAltsSearch(view, true)
        end
    end)
    clearButton:SetScript("OnEnter", function(button)
        button.icon:SetVertexColor(unpackColor(PALETTE.pinkHover))
        showOwnedTooltip(button, "Clear search", "Show every Mains/Alts character.")
    end)
    clearButton:SetScript("OnLeave", function(button)
        button.icon:SetVertexColor(unpackColor(
            mainsAltsControlsEnabled(view) and PALETTE.secondary or PALETTE.disabled
        ))
        hideOwnedTooltip(button)
    end)
    clearButton:SetScript("OnMouseDown", function(button)
        if button:IsEnabled() then
            button.icon:SetVertexColor(unpackColor(PALETTE.pink))
        end
    end)
    clearButton:SetScript("OnMouseUp", function(button)
        if button:IsEnabled() then
            button.icon:SetVertexColor(unpackColor(PALETTE.pinkHover))
        end
    end)

    view.mainsAltsSearchBox = editBox
    view.mainsAltsSearchPlaceholder = placeholder
    view.mainsAltsSearchClear = clearButton
    view.mainsAltsSearchQuery = ""
    view.mainsAltsNormalizedSearch = ""
    view.mainsAltsTagFilters = view.mainsAltsTagFilters or {}

    local filterButton = CreateFrame("Button", nil, view, "BackdropTemplate")
    filterButton:SetSize(MAINS_ALTS_FILTER_WIDTH, MAINS_ALTS_SEARCH_HEIGHT)
    filterButton:SetPoint("LEFT", editBox, "RIGHT", CONTROL_GAP, 0)
    styleTagCapsule(filterButton, PALETTE.control, PALETTE.border)
    filterButton.label = filterButton:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontHighlightSmall"
    )
    filterButton.label:SetAllPoints(filterButton)
    filterButton.label:SetJustifyH("CENTER")
    setFont(filterButton.label, FONT_SEMIBOLD, 11)
    setTextColor(filterButton.label, PALETTE.text)
    filterButton:SetScript("OnClick", function()
        if mainsAltsControlsEnabled(view) then
            UI.ToggleMainsAltsTagFilter()
        end
    end)
    view.mainsAltsTagFilterButton = filterButton

    editBox:SetScript("OnTextChanged", function(box)
        if view.settingMainsAltsSearchText then
            return
        end
        view.mainsAltsSearchQuery = box:GetText()
        applyMainsAltsSearch(view, true, false)
    end)
    editBox:SetScript("OnEscapePressed", function()
        clearMainsAltsSearch(view, false)
    end)
    editBox:SetScript("OnEnterPressed", function(box)
        box:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusGained", function()
        view.mainsAltsSearchFocused = true
        updateMainsAltsSearchAppearance(view)
    end)
    editBox:SetScript("OnEditFocusLost", function()
        view.mainsAltsSearchFocused = false
        updateMainsAltsSearchAppearance(view)
    end)
    editBox:SetScript("OnEnter", function()
        view.mainsAltsSearchHovered = true
        updateMainsAltsSearchAppearance(view)
    end)
    editBox:SetScript("OnLeave", function()
        view.mainsAltsSearchHovered = false
        updateMainsAltsSearchAppearance(view)
    end)
    updateMainsAltsSearchAppearance(view)
end

-- AceGUI supplies generic buttons and edit boxes but no wrapping tag-pill
-- selector anchored to virtualized rows; LibQTip is a tabular tooltip library.
-- These small portal-native frames avoid bundling either framework while
-- preserving RGMS styling, immediate persistence, and unrestricted wrapping.
local function setTagPillAppearance(button, selected)
    button.selected = selected == true
    local background = selected and PALETTE.pink or PALETTE.control
    styleTagCapsule(
        button,
        background,
        selected and PALETTE.pink or PALETTE.border
    )
    if button.label then
        setTextColor(button.label, PALETTE.text)
    end
end

local function acquireTagPill(container, index)
    container.pills = container.pills or {}
    local pill = container.pills[index]
    if pill then
        return pill
    end
    pill = CreateFrame("Button", nil, container, "BackdropTemplate")
    pill.label = pill:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    pill.label:SetAllPoints(pill)
    pill.label:SetJustifyH("CENTER")
    setFont(pill.label, FONT_SEMIBOLD, 11)
    pill:SetScript("OnClick", function(button)
        if container.onPillClick and button.tagName then
            container.onPillClick(button.tagName)
        end
    end)
    container.pills[index] = pill
    return pill
end

local function layoutTagPills(container, names, selected, onClick, startX, startY)
    container.onPillClick = onClick
    local maximumWidth = (container.contentWidth or TAG_POPOVER_WIDTH)
        - TAG_POPOVER_PADDING * 2
    local x = startX or TAG_POPOVER_PADDING
    local y = startY or -TAG_POPOVER_PADDING
    for index, name in ipairs(names or {}) do
        local pill = acquireTagPill(container, index)
        local width = math.min(maximumWidth, math.max(38, #name * 7 + 18))
        if x > TAG_POPOVER_PADDING and x + width > maximumWidth + TAG_POPOVER_PADDING then
            x = TAG_POPOVER_PADDING
            y = y - TAG_PILL_HEIGHT - TAG_PILL_GAP
        end
        pill:ClearAllPoints()
        pill:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)
        pill:SetSize(width, TAG_PILL_HEIGHT)
        pill.label:SetText(name)
        pill.tagName = name
        pill:SetEnabled(onClick ~= nil and mainsAltsControlsEnabled(container.view))
        setTagPillAppearance(pill, selected and selected[name] == true)
        pill:Show()
        x = x + width + TAG_PILL_GAP
    end
    for index = #(names or {}) + 1, #(container.pills or {}) do
        container.pills[index]:Hide()
    end
    return x, y
end

local function findMainsAltsCharacter(report, identity)
    for _, row in ipairs(type(report) == "table" and report.rows or {}) do
        if row.identity == identity then
            return row
        end
        for _, alt in ipairs(row.alts or {}) do
            if alt.identity == identity then
                return alt
            end
        end
    end
    return nil
end

local function updateTagDismissLayer(view)
    if not view.mainsAltsTagDismissLayer then
        return
    end
    local shown = (view.mainsAltsTagEditor and view.mainsAltsTagEditor:IsShown())
        or (view.mainsAltsTagFilter and view.mainsAltsTagFilter:IsShown())
    view.mainsAltsTagDismissLayer:SetShown(shown == true)
end

closeMainsAltsTagEditor = function(view)
    if view and view.mainsAltsTagEditor then
        view.mainsAltsTagEditor:Hide()
        view.mainsAltsTagEditor.characterIdentity = nil
        view.mainsAltsTagEditor.anchor = nil
        view.mainsAltsTagEditor.input:ClearFocus()
    end
    updateTagDismissLayer(view)
end

closeMainsAltsTagFilter = function(view)
    if view and view.mainsAltsTagFilter then
        view.mainsAltsTagFilter:Hide()
    end
    updateTagDismissLayer(view)
end

updateMainsAltsTagFilterAppearance = function(view)
    if not view.mainsAltsTagFilterButton then
        return
    end
    local count = 0
    for _, selected in pairs(view.mainsAltsTagFilters or {}) do
        if selected == true then
            count = count + 1
        end
    end
    view.mainsAltsTagFilterButton.label:SetText(
        count > 0 and ("Filter tags... (" .. count .. ")") or "Filter tags..."
    )
    styleTagCapsule(
        view.mainsAltsTagFilterButton,
        count > 0 and PALETTE.pink or PALETTE.control,
        count > 0 and PALETTE.pink or PALETTE.border
    )
end

refreshMainsAltsTagFilter = function(view)
    local popup = view and view.mainsAltsTagFilter
    if not popup then
        return
    end
    local catalog = type(view.mainsAltsSourceReport) == "table"
        and view.mainsAltsSourceReport.tagCatalog
        or {}
    local available = {}
    for _, name in ipairs(catalog or {}) do
        available[name] = true
    end
    for name in pairs(view.mainsAltsTagFilters or {}) do
        if not available[name] then
            view.mainsAltsTagFilters[name] = nil
        end
    end
    local _, y = layoutTagPills(
        popup,
        catalog,
        view.mainsAltsTagFilters,
        function(name)
            if view.mainsAltsTagFilters[name] then
                view.mainsAltsTagFilters[name] = nil
            else
                view.mainsAltsTagFilters[name] = true
            end
            applyMainsAltsSearch(view, true, false)
        end
    )
    popup:SetHeight(math.abs(y) + TAG_PILL_HEIGHT + TAG_POPOVER_PADDING)
    updateMainsAltsTagFilterAppearance(view)
end

refreshMainsAltsTagEditor = function(view)
    local editor = view and view.mainsAltsTagEditor
    if not editor or not editor.characterIdentity then
        return
    end
    local character = findMainsAltsCharacter(
        view.mainsAltsSourceReport,
        editor.characterIdentity
    )
    if not character then
        closeMainsAltsTagEditor(view)
        return
    end
    local selected = {}
    for _, name in ipairs(character.tags or {}) do
        selected[name] = true
    end
    local catalog = view.mainsAltsSourceReport.tagCatalog or {}
    local x, y = layoutTagPills(editor, catalog, selected, function(name)
        local changed, changeError = RGMS.MainsAlts.ToggleCharacterTag(
            editor.characterIdentity,
            name
        )
        if not changed and type(RGMS.Print) == "function" then
            RGMS.Print("Could not change character tag: " .. tostring(changeError) .. ".")
        end
    end)
    local inputWidth = 104
    local maximumX = TAG_POPOVER_WIDTH - TAG_POPOVER_PADDING
    if x > TAG_POPOVER_PADDING and x + inputWidth > maximumX then
        x = TAG_POPOVER_PADDING
        y = y - TAG_PILL_HEIGHT - TAG_PILL_GAP
    end
    editor.input:ClearAllPoints()
    editor.input:SetPoint("TOPLEFT", editor, "TOPLEFT", x, y)
    editor.input:SetSize(math.max(72, maximumX - x), TAG_PILL_HEIGHT)
    styleTagCapsule(editor.input, PALETTE.control, PALETTE.border)
    editor:SetHeight(math.abs(y) + TAG_PILL_HEIGHT + TAG_POPOVER_PADDING)
end

local function createMainsAltsTagPopovers(view)
    local dismiss = CreateFrame("Button", nil, UIParent)
    dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameStrata("DIALOG")
    dismiss:SetScript("OnClick", function()
        closeMainsAltsTagEditor(view)
        closeMainsAltsTagFilter(view)
    end)
    dismiss:Hide()
    view.mainsAltsTagDismissLayer = dismiss

    local filter = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    filter:SetWidth(TAG_POPOVER_WIDTH)
    filter.contentWidth = TAG_POPOVER_WIDTH
    filter.view = view
    filter:SetFrameStrata("FULLSCREEN_DIALOG")
    flatBackdrop(filter, PALETTE.surface, PALETTE.border)
    filter:SetPoint(
        "TOPRIGHT",
        view.mainsAltsTagFilterButton,
        "BOTTOMRIGHT",
        0,
        -4
    )
    filter:Hide()
    view.mainsAltsTagFilter = filter

    local editor = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    editor:SetWidth(TAG_POPOVER_WIDTH)
    editor.contentWidth = TAG_POPOVER_WIDTH
    editor.view = view
    editor:SetFrameStrata("FULLSCREEN_DIALOG")
    flatBackdrop(editor, PALETTE.surface, PALETTE.border)
    editor.input = CreateFrame("EditBox", nil, editor, "BackdropTemplate")
    editor.input:SetAutoFocus(false)
    editor.input:SetJustifyH("LEFT")
    editor.input:SetTextInsets(6, 6, 0, 0)
    setFont(editor.input, FONT_REGULAR, 11)
    editor.input:SetScript("OnTextChanged", function(box)
        if editor.settingInputText then
            return
        end
        local value = box:GetText()
        if characterCount(value) > 32 then
            editor.settingInputText = true
            box:SetText(truncateCharacters(value, 32))
            editor.settingInputText = false
        end
    end)
    editor.input:SetScript("OnEnterPressed", function(box)
        local changed, changeError = RGMS.MainsAlts.CreateOrAssignTag(
            editor.characterIdentity,
            box:GetText()
        )
        if not changed then
            if type(RGMS.Print) == "function" then
                RGMS.Print("Could not assign character tag: "
                    .. tostring(changeError) .. ".")
            end
            return
        end
        box:SetText("")
        box:SetFocus()
    end)
    editor.input:SetScript("OnEscapePressed", function()
        closeMainsAltsTagEditor(view)
    end)
    if type(editor.EnableKeyboard) == "function" then
        editor:EnableKeyboard(true)
        editor:SetScript("OnKeyDown", function(frame, key)
            if key == "ESCAPE" then
                closeMainsAltsTagEditor(view)
                if type(frame.SetPropagateKeyboardInput) == "function" then
                    frame:SetPropagateKeyboardInput(false)
                end
            elseif type(frame.SetPropagateKeyboardInput) == "function" then
                frame:SetPropagateKeyboardInput(true)
            end
        end)
    end
    editor:Hide()
    view.mainsAltsTagEditor = editor

    local preview = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    preview:SetWidth(TAG_POPOVER_WIDTH)
    preview.contentWidth = TAG_POPOVER_WIDTH
    preview.view = view
    preview:SetFrameStrata("TOOLTIP")
    flatBackdrop(preview, PALETTE.shell, PALETTE.border)
    preview:Hide()
    view.mainsAltsTagPreview = preview
end

function UI.OpenMainsAltsTagEditor(identity, anchor)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    local view = UI.frame.views.mainsalts
    if not mainsAltsControlsEnabled(view) then
        return nil, "character tag controls are disabled"
    end
    if not findMainsAltsCharacter(view.mainsAltsSourceReport, identity) then
        return nil, "roster character is unavailable"
    end
    UI.HideMainsAltsTagPreview()
    closeMainsAltsTagFilter(view)
    local editor = view.mainsAltsTagEditor
    editor.characterIdentity = identity
    editor.anchor = anchor
    editor:ClearAllPoints()
    editor:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
    refreshMainsAltsTagEditor(view)
    editor:Show()
    updateTagDismissLayer(view)
    editor.input:SetFocus()
    return true
end

function UI.ToggleMainsAltsTagFilter()
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    local view = UI.frame.views.mainsalts
    if not mainsAltsControlsEnabled(view) then
        return nil, "tag filter controls are disabled"
    end
    closeMainsAltsTagEditor(view)
    if view.mainsAltsTagFilter:IsShown() then
        closeMainsAltsTagFilter(view)
    else
        refreshMainsAltsTagFilter(view)
        view.mainsAltsTagFilter:Show()
        updateTagDismissLayer(view)
    end
    return true
end

function UI.ShowMainsAltsTagPreview(names, anchor)
    if not UI.frame or type(names) ~= "table" or #names == 0 then
        return false
    end
    local view = UI.frame.views.mainsalts
    if view.mainsAltsTagEditor and view.mainsAltsTagEditor:IsShown() then
        return false
    end
    local preview = view.mainsAltsTagPreview
    local selected = {}
    for _, name in ipairs(names) do
        selected[name] = true
    end
    local _, y = layoutTagPills(preview, names, selected, nil)
    preview:SetHeight(math.abs(y) + TAG_PILL_HEIGHT + TAG_POPOVER_PADDING)
    preview:ClearAllPoints()
    preview:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
    preview:Show()
    return true
end

function UI.HideMainsAltsTagPreview()
    if UI.frame and UI.frame.views.mainsalts.mainsAltsTagPreview then
        UI.frame.views.mainsalts.mainsAltsTagPreview:Hide()
    end
end

local function hideBankLines(view)
    if view.bankHeader then
        view.bankHeader.frame:Hide()
    end
    for _, line in ipairs(view.bankRows or {}) do
        hideTooltipIfOwned(line.itemButton)
        line.frame:Hide()
    end
    if view.bankTitle then
        view.bankTitle:Hide()
    end
    if view.bankMessage then
        view.bankMessage:Hide()
    end
    view.bankTableHeight = nil
end

local function configureBankText(text)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    if type(text.SetWordWrap) == "function" then
        text:SetWordWrap(false)
    end
end

local function createBankHeader(view)
    local frame = CreateFrame("Frame", nil, view)
    local header = {
        frame = frame,
        item = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        slot = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        count = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        stable = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        age = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
    }
    for _, field in ipairs({ "item", "slot", "count", "stable", "age" }) do
        configureBankText(header[field])
        setFont(header[field], FONT_SEMIBOLD, 12)
        setTextColor(header[field], PALETTE.text)
    end
    header.item:SetText("Item")
    header.slot:SetText("Slot")
    header.count:SetText("Count")
    header.slot:SetJustifyH("CENTER")
    header.count:SetJustifyH("CENTER")
    header.stable:SetText("Stable since")
    header.age:SetText("Age")
    flatBackdrop(frame, PALETTE.control, PALETTE.border)
    view.bankHeader = header
    return header
end

local function acquireBankLine(view, index)
    local line = view.bankRows[index]
    if line then
        return line
    end

    local frame = CreateFrame("Frame", nil, view.scrollChild)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetTexture(WHITE_TEXTURE)
    local divider = frame:CreateTexture(nil, "BORDER")
    divider:SetTexture(WHITE_TEXTURE)
    divider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    divider:SetVertexColor(unpackColor(PALETTE.border))
    local itemButton = CreateFrame("Button", nil, frame)
    local itemIcon = itemButton:CreateTexture(nil, "ARTWORK")
    itemIcon:SetSize(BANK_ICON_SIZE, BANK_ICON_SIZE)
    local item = itemButton:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local slotCell = CreateFrame("Frame", nil, frame)
    local slot = slotCell:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    slot:SetAllPoints(slotCell)
    local count = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local stable = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local age = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    line = {
        frame = frame,
        background = background,
        itemButton = itemButton,
        itemIcon = itemIcon,
        item = item,
        slotCell = slotCell,
        slot = slot,
        count = count,
        stable = stable,
        age = age,
    }
    line.countHitbox = attachTruncationTooltip(frame, count)
    line.stableHitbox = attachTruncationTooltip(frame, stable)
    line.ageHitbox = attachTruncationTooltip(frame, age)
    enableRowHover(line)
    for _, field in ipairs({ "item", "slot", "count", "stable", "age" }) do
        configureBankText(line[field])
    end
    setFont(slot, FONT_REGULAR, 12)
    setFont(count, FONT_REGULAR, 12)
    setFont(stable, FONT_REGULAR, 12)
    setFont(age, FONT_REGULAR, 12)
    setTextColor(slot, PALETTE.text)
    slot:SetJustifyH("CENTER")
    count:SetJustifyH("CENTER")
    age:SetJustifyH("RIGHT")
    itemButton:SetScript("OnEnter", function()
        if line.itemLink == nil then
            return
        end
        GameTooltip:SetOwner(itemButton, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(line.itemLink)
        GameTooltip:Show()
    end)
    itemButton:SetScript("OnLeave", function()
        hideTooltipIfOwned(itemButton)
    end)
    itemButton:SetScript("OnClick", function()
        if line.itemLink ~= nil and type(HandleModifiedItemClick) == "function" then
            HandleModifiedItemClick(line.itemLink)
        end
    end)
    view.bankRows[index] = line
    return line
end

local function renderBankTab(view, tab)
    view.text:Hide()
    hideBankLines(view)
    view.bankMessage:Show()

    local offset = 0
    if not tab.isViewable then
        view.bankMessage:SetText("|cffff5555No access|r")
        view.bankMessage:ClearAllPoints()
        view.bankMessage:SetPoint("CENTER", view, "CENTER", 0, 0)
        offset = offset + BANK_ROW_HEIGHT
    elseif #tab.rows == 0 then
        view.bankMessage:SetText("|cff888888No occupied slots|r")
        view.bankMessage:ClearAllPoints()
        view.bankMessage:SetPoint("CENTER", view, "CENTER", 0, 0)
        offset = offset + BANK_ROW_HEIGHT
    else
        view.bankMessage:Hide()
        local header = view.bankHeader or createBankHeader(view)
        header.frame:ClearAllPoints()
        header.frame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
        header.frame:SetPoint("TOPRIGHT", view, "TOPRIGHT", -8, 0)
        header.frame:SetHeight(BANK_HEADER_HEIGHT)
        header.frame:Show()

        for index, row in ipairs(tab.rows) do
            local line = acquireBankLine(view, index)
            line.itemLink = row.itemLink
            line.frame:ClearAllPoints()
            line.frame:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
            line.frame:SetHeight(BANK_ROW_HEIGHT)
            line.itemIcon:SetTexture(row.icon)
            line.item:SetText(row.itemName)
            line.slot:SetText(tostring(row.slotIndex))
            line.count:SetText(tostring(row.quantity))
            line.stable:SetText(row.stableSinceDate)
            local ageLabel = row.ageDays == 1 and "1 day" or (row.ageDays .. " days")
            if row.isStale then
                ageLabel = "|cffff5555" .. ageLabel .. "|r"
            end
            line.age:SetText(ageLabel)
            line.baseColor = (index % 2 == 0) and PALETTE.zebra or PALETTE.surface
            line.background:SetVertexColor(unpackColor(line.baseColor))
            line.frame:Show()
            offset = offset + BANK_ROW_HEIGHT
        end
    end

    for index = #tab.rows + 1, #view.bankRows do
        hideTooltipIfOwned(view.bankRows[index].itemButton)
        view.bankRows[index].frame:Hide()
    end
    view.bankTableHeight = offset + 4
    view.scrollFrame:SetVerticalScroll(0)
    refreshScrollChild(view)
end

local function findBankTab(view, tabIndex)
    if type(view.bankReport) ~= "table" then
        return nil
    end
    for _, tab in ipairs(view.bankReport.tabs or {}) do
        if tab.index == tabIndex then
            return tab
        end
    end
    return nil
end

local function updateDropdownLabel(dropdown, option, emptyLabel)
    if not dropdown then
        return
    end
    dropdown.selectedOption = option
    dropdown.label:ClearAllPoints()
    dropdown.label:SetPoint("LEFT", dropdown, "LEFT", option and option.icon and 34 or 12, 0)
    dropdown.label:SetPoint("RIGHT", dropdown, "RIGHT", -28, 0)
    dropdown.label:SetText(option and option.name or emptyLabel)
    dropdown:SetEnabled(option ~= nil and UI.globalScanLocked ~= true)
    if dropdown.icon then
        dropdown.icon:SetShown(option ~= nil and option.icon ~= nil)
        if option and option.icon then
            dropdown.icon:SetTexture(option.icon)
        end
    end
end

local function createDropdown(parent, width, emptyLabel, selected, options)
    local frameType = type(MenuUtil) == "table" and "DropdownButton" or "Button"
    local dropdown = CreateFrame(frameType, nil, parent, "BackdropTemplate")
    dropdown:SetSize(width, 32)
    flatBackdrop(dropdown, PALETTE.control, PALETTE.border)
    dropdown.label = dropdown:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    dropdown.label:SetPoint("LEFT", dropdown, "LEFT", 12, 0)
    dropdown.label:SetPoint("RIGHT", dropdown, "RIGHT", -28, 0)
    dropdown.label:SetJustifyH("LEFT")
    setFont(dropdown.label, FONT_SEMIBOLD, 12)
    setTextColor(dropdown.label, PALETTE.text)
    dropdown.icon = dropdown:CreateTexture(nil, "ARTWORK")
    dropdown.icon:SetSize(18, 18)
    dropdown.icon:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
    dropdown.arrow = dropdown:CreateTexture(nil, "ARTWORK")
    dropdown.arrow:SetSize(16, 16)
    dropdown.arrow:SetPoint("RIGHT", dropdown, "RIGHT", -8, 0)
    dropdown.arrow:SetTexture("Interface\\AddOns\\RGMS\\assets\\icons\\chevron-down.png")
    dropdown.emptyLabel = emptyLabel
    dropdown.options = options
    dropdown.selectOption = selected
    dropdown:SetScript("OnClick", function()
        if type(dropdown.OpenMenu) == "function" then
            dropdown:OpenMenu()
        end
    end)
    if type(dropdown.SetupMenu) == "function" then
        dropdown:SetupMenu(function(_, rootDescription)
            rootDescription:SetScrollMode(240)
            rootDescription:SetMinimumWidth(200)
            for _, option in ipairs(dropdown.options() or {}) do
                local menuOption = option
                local description = rootDescription:CreateRadio(
                    menuOption.name,
                    function(value)
                        return dropdown.selectedOption
                            and dropdown.selectedOption.index == value
                    end,
                    function(value)
                        dropdown.selectOption(value)
                    end,
                    menuOption.index
                )
                description:AddInitializer(function(button)
                    button:SetHeight(32)
                    if button.fontString and MENU_FONT
                        and type(button.fontString.SetFontObject) == "function" then
                        button.fontString:SetFontObject(MENU_FONT)
                    end
                    if menuOption.icon and type(button.AttachTexture) == "function" then
                        local icon = button:AttachTexture()
                        icon:SetSize(18, 18)
                        icon:SetPoint("RIGHT", button, "RIGHT", -8, 0)
                        icon:SetTexture(menuOption.icon)
                    end
                end)
            end
        end)
    end
    updateDropdownLabel(dropdown, nil, emptyLabel)
    return dropdown
end

local function createView(parent, tabId)
    local view = CreateFrame("Frame", nil, parent)
    view:SetPoint("TOPLEFT", SIDEBAR_WIDTH + CONTENT_PADDING, -HEADER_HEIGHT - CONTENT_PADDING)
    view:SetPoint("BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)

    view.status = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local statusY = tabId == "bank" and -8 or -20
    view.status:SetPoint("TOPLEFT", parent, "TOPLEFT", tabId == "mainsalts" and 576 or 280, statusY)
    view.status:SetPoint("TOPRIGHT", parent, "TOPRIGHT", tabId == "mainsalts" and -56 or -148, statusY)
    if tabId == "bank" then
        view.status:SetHeight(40)
        view.status:SetJustifyV("MIDDLE")
    end
    view.status:SetJustifyH("RIGHT")
    view.status:SetText(INITIAL_COPY[tabId])
    setFont(view.status, FONT_REGULAR, 11)
    setTextColor(view.status, PALETTE.secondary)
    view.spinner = CreateFrame("Frame", nil, view)
    view.spinner:SetSize(88, 16)
    view.spinner:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        tabId == "mainsalts" and 576 or 272,
        -20
    )
    view.spinner.icon = view.spinner:CreateTexture(nil, "ARTWORK")
    view.spinner.icon:SetSize(16, 16)
    view.spinner.icon:SetPoint("LEFT", view.spinner, "LEFT", 0, 0)
    view.spinner.icon:SetTexture("Interface\\AddOns\\RGMS\\assets\\icons\\loader-circle.png")
    view.spinner.icon:SetVertexColor(unpackColor(PALETTE.pink))
    view.spinner.label = view.spinner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.spinner.label:SetPoint("LEFT", view.spinner.icon, "RIGHT", 6, 0)
    view.spinner.label:SetPoint("RIGHT", view.spinner, "RIGHT", 0, 0)
    view.spinner.label:SetJustifyH("LEFT")
    view.spinner.label:SetText("Scanning...")
    setFont(view.spinner.label, FONT_REGULAR, 11)
    setTextColor(view.spinner.label, PALETTE.secondary)
    view.spinner.rotation = 0
    view.spinner:SetScript("OnUpdate", function(spinner, elapsed)
        spinner.rotation = (spinner.rotation + elapsed * 5) % (math.pi * 2)
        if type(spinner.icon.SetRotation) == "function" then
            spinner.icon:SetRotation(spinner.rotation)
        end
    end)
    view.spinner:Hide()
    view.statusHitbox = CreateFrame("Button", nil, view)
    view.statusHitbox:SetAllPoints(view.status)
    view.statusHitbox:SetScript("OnEnter", function(button)
        if type(view.status.IsTruncated) == "function" and view.status:IsTruncated() then
            showOwnedTooltip(button, "Status", view.status:GetText())
        end
    end)
    view.statusHitbox:SetScript("OnLeave", function(button)
        hideOwnedTooltip(button)
    end)

    if tabId == "roster" or tabId == "bank" then
        view.refreshButton = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
        view.refreshButton:SetSize(84, 32)
        view.refreshButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -56, -12)
        view.refreshButton:SetText("Refresh")
        styleButton(view.refreshButton, "primary", 32)
        if tabId == "roster" then
            view.rosterAvailable = true
            view.rosterScanInProgress = false
            view.refreshButton:SetScript("OnClick", function()
                RGMS.Roster.RequestManualScan()
            end)
        else
            view.refreshButton:SetScript("OnClick", function()
                RGMS.Bank.RequestManualScan()
            end)
            view.bankOpen = false
            view.bankScanInProgress = false
            view.refreshButton:SetEnabled(false)
        end
    end

    if tabId == "roster" then
        view.rankScrollFrame = CreateFrame(
            "ScrollFrame",
            nil,
            view,
            "UIPanelScrollFrameTemplate"
        )
        view.rankScrollFrame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
        view.rankScrollFrame:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
        view.rankScrollFrame:SetWidth(1)
        view.rankScrollFrame:Hide()

        view.rankScrollChild = CreateFrame("Frame", nil, view.rankScrollFrame)
        view.rankScrollChild:SetSize(RANK_TAB_WIDTH - 22, 1)
        view.rankScrollFrame:SetScrollChild(view.rankScrollChild)
        view.rankButtons = {}
        view.rosterLines = {}
        view.rankDropdown = createDropdown(view, 200, "No ranks", function(index)
            UI.SelectRosterRank(index)
        end, function()
            return view.rosterReport and view.rosterReport.ranks or {}
        end)
        view.rankDropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 64, -12)
        view.rankScrollFrame:SetScript("OnSizeChanged", function()
            refreshRankScrollChild(view)
        end)
    elseif tabId == "mainsalts" then
        view.mainsAltsAvailable = true
        view.mainsAltsScanInProgress = false
        view.mainsAltsLines = {}
        view.mainsAltsLinePool = {}
        view.mainsAltsRows = {}
        view.mainsAltsSelections = {}
        view.expandedMainsAlts = {}
        view.groupButton = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
        view.groupButton:SetSize(112, 32)
        view.groupButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 64, -12)
        view.groupButton:SetText("Group Toons")
        styleButton(view.groupButton, "primary", 32)
        view.groupButton:SetEnabled(false)
        view.groupButton:SetScript("OnClick", function()
            if not mainsAltsControlsEnabled(view) then
                return
            end
            local selectedIdentities = {}
            for _, row in ipairs(
                view.mainsAltsSourceReport and view.mainsAltsSourceReport.rows or {}
            ) do
                if view.mainsAltsSelections[row.identity] == true then
                    selectedIdentities[#selectedIdentities + 1] = row.identity
                end
            end
            local grouped, groupError = RGMS.MainsAlts.GroupSelected(selectedIdentities)
            if not grouped and type(RGMS.Print) == "function" then
                RGMS.Print("Could not group characters: " .. tostring(groupError) .. ".")
            end
        end)
        createMainsAltsSearch(view)
        createMainsAltsHeader(view)
    elseif tabId == "bank" then
        view.bankTabScrollFrame = CreateFrame(
            "ScrollFrame",
            nil,
            view,
            "UIPanelScrollFrameTemplate"
        )
        view.bankTabScrollFrame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
        view.bankTabScrollFrame:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
        view.bankTabScrollFrame:SetWidth(1)
        view.bankTabScrollFrame:Hide()

        view.bankTabScrollChild = CreateFrame("Frame", nil, view.bankTabScrollFrame)
        view.bankTabScrollChild:SetSize(BANK_TAB_WIDTH - 22, 1)
        view.bankTabScrollFrame:SetScrollChild(view.bankTabScrollChild)
        view.bankTabButtons = {}
        view.bankRows = {}
        view.bankDropdown = createDropdown(view, 200, "No bank tabs", function(index)
            UI.SelectBankTab(index)
        end, function()
            return view.bankReport and view.bankReport.tabs or {}
        end)
        view.bankDropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 64, -12)
        view.bankTabScrollFrame:SetScript("OnSizeChanged", function()
            refreshBankTabScrollChild(view)
        end)
    end

    view.scrollFrame = CreateFrame("ScrollFrame", nil, view, "UIPanelScrollFrameTemplate")
    styleScrollFrame(view.scrollFrame)
    view.scrollFrame:SetPoint("TOPLEFT", 0, -28)
    view.scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)

    view.scrollChild = CreateFrame("Frame", nil, view.scrollFrame)
    view.scrollChild:SetSize(1, 1)
    view.scrollFrame:SetScrollChild(view.scrollChild)

    view.text = view.scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    view.text:SetPoint("CENTER", view, "CENTER", 0, 0)
    view.text:SetJustifyH("CENTER")
    view.text:SetJustifyV("MIDDLE")
    view.text:SetText(INITIAL_COPY[tabId])

    if tabId == "bank" then
        view.bankTitle = view.scrollChild:CreateFontString(
            nil,
            "ARTWORK",
            "GameFontNormal"
        )
        configureBankText(view.bankTitle)
        view.bankTitle:Hide()
        view.bankMessage = view.scrollChild:CreateFontString(
            nil,
            "ARTWORK",
            "GameFontHighlight"
        )
        configureBankText(view.bankMessage)
        view.bankMessage:Hide()
    end

    view.scrollFrame:SetScript("OnSizeChanged", function()
        refreshScrollChild(view)
        if tabId == "mainsalts" then
            renderMainsAltsViewport(view, nil, true)
        end
    end)
    if tabId == "mainsalts" then
        view:SetScript("OnHide", function()
            cancelMainsAltsScrollWork(view)
        end)
        view.scrollFrame:EnableMouseWheel(true)
        view.scrollFrame:SetScript("OnMouseWheel", function(_, delta)
            cancelMainsAltsScrollAnimation(view)
            setMainsAltsScroll(
                view,
                view.scrollFrame:GetVerticalScroll()
                    - delta * MAINS_ALTS_ROW_HEIGHT * MAINS_ALTS_WHEEL_ROWS
            )
        end)
        view.scrollFrame:SetScript("OnVerticalScroll", function(_, offset)
            if view.settingMainsAltsScroll then
                return
            end
            cancelMainsAltsScrollAnimation(view)
            if view.scrollFrame:GetVerticalScroll() ~= offset then
                setMainsAltsScroll(view, offset)
            else
                renderMainsAltsViewport(view, offset)
            end
        end)
        view.scrollFrame:SetScript("OnUpdate", function(_, elapsed)
            updateMainsAltsScrollAnimation(view, elapsed)
        end)
        createMainsAltsTagPopovers(view)
    end

    return view
end

local function createNotesEditor()
    local editor = CreateFrame(
        "Frame",
        "RGMSNotesEditor",
        UIParent,
        "BackdropTemplate"
    )
    editor:SetSize(440, 330)
    editor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    editor:SetFrameStrata("DIALOG")
    editor:SetToplevel(true)
    editor:EnableMouse(true)
    editor:SetClampedToScreen(true)
    editor:SetBackdrop({
        bgFile = WHITE_TEXTURE,
        edgeFile = BORDER_TEXTURE,
        tile = false,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    editor:SetBackdropColor(unpackColor(PALETTE.surface))
    if type(editor.SetBackdropBorderColor) == "function" then
        editor:SetBackdropBorderColor(unpackColor(PALETTE.border))
    end

    editor.title = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    editor.title:SetPoint("TOPLEFT", editor, "TOPLEFT", 18, -17)
    editor.title:SetPoint("TOPRIGHT", editor, "TOPRIGHT", -46, -17)
    editor.title:SetJustifyH("LEFT")
    editor.title:SetText("Character Note")
    setFont(editor.title, FONT_SEMIBOLD, 13)
    setTextColor(editor.title, PALETTE.text)

    editor.character = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    editor.character:SetPoint("TOPLEFT", editor, "TOPLEFT", 20, -50)
    editor.character:SetPoint("TOPRIGHT", editor, "TOPRIGHT", -20, -50)
    editor.character:SetJustifyH("LEFT")

    editor.closeButton = CreateFrame("Button", nil, editor)
    editor.closeButton:SetSize(32, 32)
    editor.closeButton:SetPoint("TOPRIGHT", editor, "TOPRIGHT", -8, -8)
    editor.closeButton.icon = editor.closeButton:CreateTexture(nil, "ARTWORK")
    editor.closeButton.icon:SetAllPoints(editor.closeButton)
    editor.closeButton.icon:SetTexture(CLOSE_TEXTURE)
    editor.closeButton:SetScript("OnClick", function()
        UI.CloseCharacterNoteEditor()
    end)
    editor.closeButton:SetScript("OnEnter", function(button)
        showOwnedTooltip(button, "Close", "Close the note editor and discard unsaved changes.")
    end)
    editor.closeButton:SetScript("OnLeave", function(button)
        hideOwnedTooltip(button)
    end)

    editor.scrollFrame = CreateFrame(
        "ScrollFrame",
        nil,
        editor,
        "UIPanelScrollFrameTemplate"
    )
    editor.scrollFrame:SetPoint("TOPLEFT", editor, "TOPLEFT", 20, -78)
    editor.scrollFrame:SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -38, 58)

    editor.editBox = CreateFrame(
        "EditBox",
        nil,
        editor.scrollFrame,
        "InputBoxTemplate"
    )
    editor.editBox:SetMultiLine(true)
    editor.editBox:SetAutoFocus(false)
    editor.editBox:SetFontObject("ChatFontNormal")
    editor.editBox:SetWidth(370)
    editor.editBox:SetHeight(185)
    editor.editBox:SetMaxLetters(CHARACTER_NOTE_LIMIT)
    editor.scrollFrame:SetScrollChild(editor.editBox)

    editor.characterCount = editor:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    editor.characterCount:SetPoint(
        "BOTTOMRIGHT",
        editor,
        "BOTTOMRIGHT",
        -20,
        39
    )
    editor.characterCount:SetText("0 / " .. CHARACTER_NOTE_LIMIT)
    editor.editBox:SetScript("OnTextChanged", function(editBox)
        editor.characterCount:SetText(
            characterCount(editBox:GetText()) .. " / " .. CHARACTER_NOTE_LIMIT
        )
        if type(editBox.GetStringHeight) == "function" then
            editBox:SetHeight(math.max(185, editBox:GetStringHeight() + 20))
        end
        if type(editor.scrollFrame.UpdateScrollChildRect) == "function" then
            editor.scrollFrame:UpdateScrollChildRect()
        end
    end)
    editor.editBox:SetScript("OnEscapePressed", function()
        UI.CloseCharacterNoteEditor()
    end)

    editor.deleteButton = CreateFrame(
        "Button",
        nil,
        editor,
        "UIPanelButtonTemplate"
    )
    editor.deleteButton:SetSize(76, 22)
    editor.deleteButton:SetPoint("BOTTOMLEFT", editor, "BOTTOMLEFT", 20, 18)
    editor.deleteButton:SetText("Delete")
    styleButton(editor.deleteButton, "danger", 32)
    editor.deleteButton:SetScript("OnClick", function()
        local deleted, deleteError = RGMS.MainsAlts.DeleteCharacterNote(
            editor.characterIdentity
        )
        if deleted then
            UI.CloseCharacterNoteEditor()
        elseif type(RGMS.Print) == "function" then
            RGMS.Print("Could not delete character note: "
                .. tostring(deleteError) .. ".")
        end
    end)

    editor.cancelButton = CreateFrame(
        "Button",
        nil,
        editor,
        "UIPanelButtonTemplate"
    )
    editor.cancelButton:SetSize(76, 22)
    editor.cancelButton:SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -104, 18)
    editor.cancelButton:SetText("Cancel")
    styleButton(editor.cancelButton, "secondary", 32)
    editor.cancelButton:SetScript("OnClick", function()
        UI.CloseCharacterNoteEditor()
    end)

    editor.saveButton = CreateFrame(
        "Button",
        nil,
        editor,
        "UIPanelButtonTemplate"
    )
    editor.saveButton:SetSize(76, 22)
    editor.saveButton:SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -20, 18)
    editor.saveButton:SetText("Save")
    styleButton(editor.saveButton, "primary", 32)
    editor.saveButton:SetScript("OnClick", function()
        local saved, saveError = RGMS.MainsAlts.SaveCharacterNote(
            editor.characterIdentity,
            editor.editBox:GetText()
        )
        if saved then
            UI.CloseCharacterNoteEditor()
        elseif type(RGMS.Print) == "function" then
            RGMS.Print("Could not save character note: "
                .. tostring(saveError) .. ".")
        end
    end)

    editor:SetScript("OnShow", function()
        editor.editBox:SetFocus()
    end)
    editor:SetScript("OnHide", function()
        editor.editBox:ClearFocus()
        editor.characterIdentity = nil
        editor.displayName = nil
        editor.noteExists = false
    end)
    editor:Hide()
    return editor
end

local function createOwnedTooltip()
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

local function createWindow()
    local frame = CreateFrame("Frame", "RGMSMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(RGMS.UILayout.WINDOW_WIDTH, RGMS.UILayout.WINDOW_HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetResizable(false)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetClampRectInsets(0, 0, 0, 0)
    frame:SetBackdrop({
        bgFile = WHITE_TEXTURE,
        edgeFile = BORDER_TEXTURE,
        tile = false,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(unpackColor(PALETTE.surface))
    if type(frame.SetBackdropBorderColor) == "function" then
        frame:SetBackdropBorderColor(unpackColor(PALETTE.border))
    end
    local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow:SetTexture(WHITE_TEXTURE)
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -6, 6)
    shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 6, -6)
    shadow:SetVertexColor(0, 0, 0, 0.45)
    frame.shadow = shadow
    frame:Hide()

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    header:SetHeight(HEADER_HEIGHT)
    flatBackdrop(header, PALETTE.shell, PALETTE.border)
    frame.header = header

    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -HEADER_HEIGHT)
    sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    flatBackdrop(sidebar, PALETTE.surface, PALETTE.border)
    frame.sidebar = sidebar

    local logo = header:CreateTexture(nil, "OVERLAY")
    logo:SetSize(40, 40)
    logo:SetPoint("TOPLEFT", header, "TOPLEFT", 8, -8)
    logo:SetTexture(LOGO_TEXTURE)
    frame.logo = logo

    local closeButton = CreateFrame("Button", nil, frame)
    closeButton:SetSize(32, 32)
    closeButton:SetPoint("TOPRIGHT", -16, -12)
    closeButton.icon = closeButton:CreateTexture(nil, "ARTWORK")
    closeButton.icon:SetAllPoints(closeButton)
    closeButton.icon:SetTexture(CLOSE_TEXTURE)
    closeButton:SetScript("OnClick", function()
        UI.Hide()
    end)
    closeButton:SetScript("OnEnter", function(button)
        showOwnedTooltip(button, "Close", "Hide RGMS without canceling an active scan.")
    end)
    closeButton:SetScript("OnLeave", function(button)
        hideOwnedTooltip(button)
    end)
    frame.closeButton = closeButton

    local dragHandle = CreateFrame("Button", nil, frame)
    dragHandle:SetPoint("TOPLEFT", 280, -12)
    dragHandle:SetPoint("TOPRIGHT", -240, -12)
    dragHandle:SetHeight(32)
    dragHandle:RegisterForDrag("LeftButton")
    local function stopDragging()
        frame:StopMovingOrSizing()
        local left = frame:GetLeft()
        local bottom = frame:GetBottom()
        if left and bottom then
            applyClampedPosition({
                point = "BOTTOMLEFT",
                relativePoint = "BOTTOMLEFT",
                x = left,
                y = bottom,
            }, true)
        end
    end
    dragHandle:SetScript("OnDragStart", function()
        if UI.globalScanLocked == true then
            return
        end
        if type(RGMS.PortalState) == "table"
            and not RGMS.PortalState:canDrag("header", false) then
            return
        end
        frame:StartMoving()
    end)
    dragHandle:SetScript("OnDragStop", stopDragging)
    frame.dragHandle = dragHandle

    local sidebarDragHandle = CreateFrame("Button", nil, sidebar)
    sidebarDragHandle:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, -136)
    sidebarDragHandle:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -8, 8)
    sidebarDragHandle:RegisterForDrag("LeftButton")
    sidebarDragHandle:SetScript("OnDragStart", function()
        if UI.globalScanLocked == true then
            return
        end
        if type(RGMS.PortalState) == "table"
            and not RGMS.PortalState:canDrag("sidebar", false) then
            return
        end
        frame:StartMoving()
    end)
    sidebarDragHandle:SetScript("OnDragStop", stopDragging)
    frame.sidebarDragHandle = sidebarDragHandle

    frame.tabs = {}
    frame.views = {}
    for index, tabId in ipairs(TAB_ORDER) do
        local tab = CreateFrame("Button", "RGMSMainFrameTab" .. index, sidebar, "BackdropTemplate")
        tab:SetID(index)
        tab:SetSize(120, 40)
        tab:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, -8 - (index - 1) * 40)
        flatBackdrop(tab, { 0, 0, 0, 0 }, { 0, 0, 0, 0 })
        tab.indicator = tab:CreateTexture(nil, "ARTWORK")
        tab.indicator:SetTexture(WHITE_TEXTURE)
        tab.indicator:SetVertexColor(unpackColor(PALETTE.pink))
        tab.indicator:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, -4)
        tab.indicator:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 4)
        tab.indicator:SetWidth(3)
        tab.indicator:Hide()
        tab.label = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        tab.label:SetPoint("LEFT", tab, "LEFT", 14, 0)
        tab.label:SetPoint("RIGHT", tab, "RIGHT", -8, 0)
        tab.label:SetJustifyH("LEFT")
        tab.label:SetText(TAB_TITLES[tabId])
        setFont(tab.label, FONT_SEMIBOLD, 13)
        setTextColor(tab.label, PALETTE.secondary)
        tab:SetScript("OnClick", function()
            UI.SelectPrimaryTab(tabId)
        end)
        tab:SetScript("OnEnter", function(button)
            if UI.selectedTab ~= tabId and type(button.SetBackdropColor) == "function" then
                button:SetBackdropColor(unpackColor(PALETTE.control))
            end
        end)
        tab:SetScript("OnLeave", function(button)
            if UI.selectedTab ~= tabId and type(button.SetBackdropColor) == "function" then
                button:SetBackdropColor(0, 0, 0, 0)
            end
        end)
        frame.tabs[index] = tab
        frame.views[tabId] = createView(frame, tabId)
    end

    frame.numTabs = #TAB_ORDER

    frame.globalDimmer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.globalDimmer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -HEADER_HEIGHT)
    frame.globalDimmer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.globalDimmer:SetBackdrop({ bgFile = WHITE_TEXTURE })
    frame.globalDimmer:SetBackdropColor(0, 0, 0, 0.5)
    frame.globalDimmer:EnableMouse(true)
    frame.globalDimmer:Hide()

    frame.modalDimmer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.modalDimmer:SetAllPoints(frame)
    frame.modalDimmer:SetBackdrop({ bgFile = WHITE_TEXTURE })
    frame.modalDimmer:SetBackdropColor(0, 0, 0, 0.5)
    frame.modalDimmer:EnableMouse(true)
    frame.modalDimmer:Hide()
    frame.notesEditor = createNotesEditor()
    frame.ownedTooltip = createOwnedTooltip()

    frame:SetScript("OnShow", function()
        UI.ClampToScreen()
    end)
    frame:SetScript("OnHide", function()
        local mainsAltsView = frame.views.mainsalts
        cancelMainsAltsScrollWork(mainsAltsView)
        if type(UI.CollapseMainsAltsGroups) == "function" then
            UI.CollapseMainsAltsGroups()
        end
        setMainsAltsScroll(mainsAltsView, 0)
        frame.views.roster.scrollFrame:SetVerticalScroll(0)
        frame.views.bank.scrollFrame:SetVerticalScroll(0)
        UI.SelectPrimaryTab("roster")
        if type(RGMS.PortalState) == "table" then
            RGMS.PortalState:closeWindow()
        end
        if frame.notesEditor:IsShown() then
            UI.CloseCharacterNoteEditor()
        end
    end)

    return frame
end

function UI.Initialize()
    if UI.frame then
        return true
    end

    UI.frame = createWindow()
    UI.selectedTab = "roster"

    local savedPosition
    if type(RGMS.DB) == "table" and type(RGMS.DB.ui) == "table" then
        savedPosition = RGMS.DB.ui.windowPosition
    end

    local position = savedPosition or RGMS.UILayout.defaultPosition()
    local applied, positionError = applyClampedPosition(position, savedPosition ~= nil)
    if not applied then
        applied, positionError = applyClampedPosition(
            RGMS.UILayout.defaultPosition(),
            false
        )
    end
    if not applied then
        return nil, positionError
    end

    UI.SelectPrimaryTab("roster")
    for _, tabId in ipairs(TAB_ORDER) do
        refreshScrollChild(UI.frame.views[tabId])
        refreshRankScrollChild(UI.frame.views[tabId])
        refreshBankTabScrollChild(UI.frame.views[tabId])
    end

    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "RGMSMainFrame")
        table.insert(UISpecialFrames, "RGMSNotesEditor")
    end

    UI.eventFrame = CreateFrame("Frame")
    UI.eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    UI.eventFrame:RegisterEvent("UI_SCALE_CHANGED")
    UI.eventFrame:SetScript("OnEvent", function()
        UI.ClampToScreen()
    end)

    return true
end

function UI.ClampToScreen()
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local left = UI.frame:GetLeft()
    local bottom = UI.frame:GetBottom()
    if not left or not bottom then
        return nil, "the RGMS window does not have a resolved position"
    end

    return applyClampedPosition({
        point = "BOTTOMLEFT",
        relativePoint = "BOTTOMLEFT",
        x = left,
        y = bottom,
    }, type(RGMS.DB) == "table"
        and type(RGMS.DB.ui) == "table"
        and RGMS.DB.ui.windowPosition ~= nil)
end

function UI.HasSavedPosition()
    return type(RGMS.DB) == "table"
        and type(RGMS.DB.ui) == "table"
        and RGMS.DB.ui.windowPosition ~= nil
end

function UI.AlignToRightOf(frame)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if UI.HasSavedPosition() then
        return false, "the saved RGMS window position takes precedence"
    end

    local rectangle, rectangleError = getFrameRectangle(frame)
    if not rectangle then
        return nil, rectangleError
    end

    local position, positionError = RGMS.UILayout.positionToRightOfRectangle(
        rectangle,
        UI.frame:GetHeight()
    )
    if not position then
        return nil, positionError
    end

    return applyClampedPosition(position, false)
end

function UI.SelectPrimaryTab(tabId)
    tabId = normalizeTabId(tabId)
    if not tabId then
        return nil, "primary tab must be roster, mainsalts, or bank"
    end
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if UI.globalScanLocked == true and UI.frame:IsShown() then
        return nil, "scan-locked"
    end

    if UI.selectedTab and UI.frame.views[UI.selectedTab]
        and type(RGMS.PortalState) == "table" then
        RGMS.PortalState.scroll[UI.selectedTab] = UI.frame.views[UI.selectedTab].scrollFrame:GetVerticalScroll()
    end
    if type(RGMS.PortalState) == "table" then
        RGMS.PortalState.selectedView = tabId
    end

    if UI.selectedTab == "mainsalts" and tabId ~= "mainsalts" then
        local mainsAltsView = UI.frame.views.mainsalts
        clearMainsAltsFilters(mainsAltsView, false)
        cancelMainsAltsScrollWork(mainsAltsView)
    end
    for _, currentTabId in ipairs(TAB_ORDER) do
        local selected = currentTabId == tabId
        UI.frame.views[currentTabId]:SetShown(selected)
    end
    local selectedIndex
    for index, currentTabId in ipairs(TAB_ORDER) do
        if currentTabId == tabId then
            selectedIndex = index
        end
        local selected = currentTabId == tabId
        local tab = UI.frame.tabs[index]
        tab.indicator:SetShown(selected)
        if type(tab.SetBackdropColor) == "function" then
            tab:SetBackdropColor(unpackColor(selected and PALETTE.control or { 0, 0, 0, 0 }))
        end
        if type(tab.GetFontString) == "function" then
            setTextColor(tab:GetFontString(), selected and PALETTE.text or PALETTE.secondary)
        end
        setTextColor(tab.label, selected and PALETTE.text or PALETTE.secondary)
    end
    UI.frame.selectedTab = selectedIndex
    UI.selectedTab = tabId
    local selectedView = UI.frame.views[tabId]
    local savedScroll = type(RGMS.PortalState) == "table"
        and RGMS.PortalState.scroll[tabId]
        or selectedView.scrollFrame:GetVerticalScroll()
    if tabId == "mainsalts" then
        setMainsAltsScroll(selectedView, savedScroll or 0)
    else
        selectedView.scrollFrame:SetVerticalScroll(savedScroll or 0)
    end
    return true
end

function UI.SetViewContent(tabId, content)
    tabId = normalizeTabId(tabId)
    if not tabId then
        return nil, "primary tab must be roster, mainsalts, or bank"
    end
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views[tabId]
    if tabId == "roster" then
        hideRosterLines(view)
        for _, button in ipairs(view.rankButtons or {}) do
            button:Hide()
        end
        refreshRankScrollChild(view)
        view.text:Show()
    elseif tabId == "mainsalts" then
        cancelMainsAltsScrollWork(view)
        closeMainsAltsTagEditor(view)
        closeMainsAltsTagFilter(view)
        hideMainsAltsLines(view)
        view.text:Show()
    elseif tabId == "bank" then
        hideBankLines(view)
        for _, button in ipairs(view.bankTabButtons or {}) do
            button:Hide()
        end
        refreshBankTabScrollChild(view)
        view.text:Show()
    end
    view.text:SetText(tostring(content or ""))
    view.scrollFrame:SetVerticalScroll(0)
    refreshScrollChild(view)
    return true
end

function UI.SetViewStatus(tabId, status)
    tabId = normalizeTabId(tabId)
    if not tabId then
        return nil, "primary tab must be roster, mainsalts, or bank"
    end
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    UI.frame.views[tabId].status:SetText(tostring(status or ""))
    return true
end

function UI.SelectRosterRank(rankIndex)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.roster
    local rank = findRosterRank(view, rankIndex)
    if not rank then
        return nil, "roster rank is unavailable"
    end

    for buttonIndex, buttonRank in ipairs(view.rosterReport.ranks) do
        local button = view.rankButtons[buttonIndex]
        button:SetEnabled(buttonRank.index ~= rankIndex)
    end
    view.selectedRankIndex = rankIndex
    if type(RGMS.DB) == "table" and type(RGMS.DB.ui) == "table" then
        RGMS.DB.ui.selectedRosterRankIndex = rankIndex
    end
    updateDropdownLabel(view.rankDropdown, rank, "No ranks")
    if type(RGMS.PortalState) == "table" then
        RGMS.PortalState:selectionChanged("roster")
    end
    renderRosterRank(view, rank)
    return true
end

function UI.SetRosterReport(report)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(report) ~= "table" or type(report.ranks) ~= "table" then
        return nil, "roster report must contain ranks"
    end

    local view = UI.frame.views.roster
    local previousRankIndex = type(RGMS.DB) == "table"
        and type(RGMS.DB.ui) == "table"
        and RGMS.DB.ui.selectedRosterRankIndex
        or view.selectedRankIndex
    view.rosterReport = report

    for index, rank in ipairs(report.ranks) do
        local button = view.rankButtons[index]
        if not button then
            button = CreateFrame(
                "Button",
                nil,
                view.rankScrollChild,
                "UIPanelButtonTemplate"
            )
            button:SetHeight(RANK_TAB_HEIGHT)
            view.rankButtons[index] = button
        end

        button:ClearAllPoints()
        button:SetWidth(RANK_TAB_WIDTH - 22)
        if index == 1 then
            button:SetPoint("TOPLEFT", view.rankScrollChild, "TOPLEFT", 0, -2)
        else
            button:SetPoint(
                "TOPLEFT",
                view.rankButtons[index - 1],
                "BOTTOMLEFT",
                0,
                -RANK_TAB_GAP
            )
        end
        button:SetText(rank.name)
        local rankIndex = rank.index
        button:SetScript("OnClick", function()
            UI.SelectRosterRank(rankIndex)
        end)
        button:Show()
    end
    for index = #report.ranks + 1, #view.rankButtons do
        view.rankButtons[index]:Hide()
    end

    view.rankScrollFrame:SetVerticalScroll(0)
    refreshRankScrollChild(view)

    local selectedRank = type(RGMS.Portal) == "table"
        and RGMS.Portal.resolveSelection(report.ranks, previousRankIndex, false)
        or findRosterRank(view, previousRankIndex)
        or report.ranks[1]
    if selectedRank then
        return UI.SelectRosterRank(selectedRank.index)
    end

    view.selectedRankIndex = nil
    if type(RGMS.DB) == "table" and type(RGMS.DB.ui) == "table" then
        RGMS.DB.ui.selectedRosterRankIndex = nil
    end
    updateDropdownLabel(view.rankDropdown, nil, "No ranks")
    hideRosterLines(view)
    view.text:Show()
    view.text:SetText("No roster data yet")
    view.scrollFrame:SetVerticalScroll(0)
    refreshScrollChild(view)
    return true
end

function UI.OpenCharacterNote(identity, displayName, note, hasNote)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(identity) ~= "string" or identity == ""
        or type(displayName) ~= "string" or displayName == "" then
        return nil, "character note requires an identity and display name"
    end
    local view = UI.frame.views.mainsalts
    if not mainsAltsControlsEnabled(view) then
        return nil, "character note controls are disabled"
    end
    if type(RGMS.PortalState) == "table" then
        local admitted = RGMS.PortalState:openNote(note)
        if not admitted then
            return nil, "character note controls are disabled"
        end
    end

    local editor = UI.frame.notesEditor
    editor.characterIdentity = identity
    editor.displayName = displayName
    editor.noteExists = hasNote == true
    editor.character:SetText("Editing note for " .. displayName)
    editor.editBox:SetText(type(note) == "string" and note or "")
    editor.editBox:SetCursorPosition(0)
    editor.saveButton:SetEnabled(true)
    editor.deleteButton:SetEnabled(editor.noteExists)
    if type(editor.editBox.SetEnabled) == "function" then
        editor.editBox:SetEnabled(true)
    elseif type(editor.editBox.Enable) == "function" then
        editor.editBox:Enable()
    end
    editor:Show()
    UI.frame.modalDimmer:Show()
    editor.editBox:SetFocus()
    return true
end

function UI.CloseCharacterNoteEditor()
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    UI.frame.notesEditor:Hide()
    UI.frame.modalDimmer:Hide()
    if type(RGMS.PortalState) == "table" then
        RGMS.PortalState:closeNote()
    end
    return true
end

function UI.SetMainsAltsReport(report)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(report) ~= "table" or type(report.rows) ~= "table" then
        return nil, "Mains/Alts report must contain rows"
    end

    local view = UI.frame.views.mainsalts
    view.mainsAltsSourceReport = report
    local availableSelections = {}
    local availableMains = {}
    local availableCharacters = {}
    for _, row in ipairs(report.rows) do
        availableMains[row.identity] = true
        availableCharacters[row.identity] = true
        if view.mainsAltsSelections[row.identity] == true then
            availableSelections[row.identity] = true
        end
        for _, alt in ipairs(row.alts or {}) do
            availableCharacters[alt.identity] = true
        end
    end
    view.mainsAltsSelections = availableSelections
    local availableExpanded = {}
    for identity in pairs(view.expandedMainsAlts) do
        if availableMains[identity] then
            availableExpanded[identity] = true
        end
    end
    view.expandedMainsAlts = availableExpanded
    local editor = UI.frame.notesEditor
    if editor:IsShown()
        and not availableCharacters[editor.characterIdentity] then
        editor:Hide()
    end
    applyMainsAltsSearch(view, false, true)
    return true
end

function UI.CompleteRosterScan()
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    local view = UI.frame.views.mainsalts
    view.mainsAltsSelections = {}
    if type(view.mainsAltsReport) == "table" then
        renderMainsAlts(view)
    end
    return true
end

function UI.CompleteMainsAltsGrouping(mainIdentity)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(mainIdentity) ~= "string" or mainIdentity == "" then
        return nil, "the grouped main identity is required"
    end

    local view = UI.frame.views.mainsalts
    cancelMainsAltsScrollAnimation(view)
    view.pendingMainsAltsScrollTarget = mainIdentity
    view.mainsAltsSelections = {}
    view.expandedMainsAlts = { [mainIdentity] = true }
    if type(view.mainsAltsReport) == "table" then
        renderMainsAlts(view)
    end
    return true
end

function UI.CompleteMainsAltsChange(mainIdentity, expandGroup)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if mainIdentity ~= nil
        and (type(mainIdentity) ~= "string" or mainIdentity == "") then
        return nil, "the affected main identity must be a string"
    end

    local view = UI.frame.views.mainsalts
    cancelMainsAltsScrollAnimation(view)
    view.pendingMainsAltsScrollTarget = mainIdentity
    view.mainsAltsSelections = {}
    view.expandedMainsAlts = mainIdentity and expandGroup ~= false
        and { [mainIdentity] = true }
        or {}
    if type(view.mainsAltsReport) == "table" then
        renderMainsAlts(view)
    end
    return true
end

function UI.ToggleMainsAltsGroup(identity)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.mainsalts
    if not mainsAltsControlsEnabled(view) then
        return nil, "Mains/Alts controls are disabled"
    end
    local row
    for _, candidate in ipairs(
        type(view.mainsAltsReport) == "table" and view.mainsAltsReport.rows or {}
    ) do
        if candidate.identity == identity and candidate.altCount > 0 then
            row = candidate
            break
        end
    end
    if not row then
        return nil, "Mains/Alts group is unavailable"
    end

    local line = findMainsAltsRow(view, identity, true)
    local scrollOffset = view.scrollFrame:GetVerticalScroll()
    local toggleAnchor = line and {
        identity = identity,
        relativeOffset = line.offset - scrollOffset,
        numericOffset = scrollOffset,
    } or nil
    view.expandedMainsAlts[identity] = not view.expandedMainsAlts[identity]
    renderMainsAlts(view, false, toggleAnchor)
    return true
end

function UI.CollapseMainsAltsGroups()
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.mainsalts
    view.expandedMainsAlts = {}
    if type(view.mainsAltsReport) == "table" then
        renderMainsAlts(view)
    end
    return true
end

function UI.SelectBankTab(tabIndex)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.bank
    local tab = findBankTab(view, tabIndex)
    if not tab then
        return nil, "bank tab is unavailable"
    end

    for buttonIndex, buttonTab in ipairs(view.bankReport.tabs) do
        local button = view.bankTabButtons[buttonIndex]
        button:SetEnabled(buttonTab.index ~= tabIndex)
    end
    view.selectedBankTabIndex = tabIndex
    if type(RGMS.DB) == "table" and type(RGMS.DB.ui) == "table" then
        RGMS.DB.ui.selectedBankTabIndex = tabIndex
    end
    updateDropdownLabel(view.bankDropdown, tab, "No bank tabs")
    if type(RGMS.PortalState) == "table" then
        RGMS.PortalState:selectionChanged("bank")
    end
    renderBankTab(view, tab)
    if view.bankOpen == true and view.bankScanInProgress ~= true
        and type(view.bankReport.scannedAtText) == "string" then
        UI.SetViewStatus(
            "bank",
            type(RGMS.Portal) == "table"
                and RGMS.Portal.bankTimestamp(
                    view.bankReport.scannedAtText,
                    tab.lastAccessibleText
                )
                or ("Last successful scan: " .. view.bankReport.scannedAtText)
        )
    end
    return true
end

function UI.SetBankReport(report)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(report) ~= "table" or type(report.tabs) ~= "table" then
        return nil, "bank report must contain tabs"
    end

    local view = UI.frame.views.bank
    local previousTabIndex = type(RGMS.DB) == "table"
        and type(RGMS.DB.ui) == "table"
        and RGMS.DB.ui.selectedBankTabIndex
        or view.selectedBankTabIndex
    view.bankReport = report

    for index, tab in ipairs(report.tabs) do
        local button = view.bankTabButtons[index]
        if not button then
            button = CreateFrame(
                "Button",
                nil,
                view.bankTabScrollChild,
                "UIPanelButtonTemplate"
            )
            button:SetHeight(BANK_TAB_HEIGHT)
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetSize(BANK_ICON_SIZE, BANK_ICON_SIZE)
            button.icon:SetPoint("LEFT", button, "LEFT", 6, 0)
            view.bankTabButtons[index] = button
        end

        button:ClearAllPoints()
        button:SetWidth(BANK_TAB_WIDTH - 22)
        if index == 1 then
            button:SetPoint("TOPLEFT", view.bankTabScrollChild, "TOPLEFT", 0, -2)
        else
            button:SetPoint(
                "TOPLEFT",
                view.bankTabButtons[index - 1],
                "BOTTOMLEFT",
                0,
                -BANK_TAB_GAP
            )
        end
        button:SetText("   " .. tab.name)
        button.icon:SetTexture(tab.icon)
        local tabIndex = tab.index
        button:SetScript("OnClick", function()
            UI.SelectBankTab(tabIndex)
        end)
        button:Show()
    end
    for index = #report.tabs + 1, #view.bankTabButtons do
        view.bankTabButtons[index]:Hide()
    end

    view.bankTabScrollFrame:SetVerticalScroll(0)
    refreshBankTabScrollChild(view)

    local selectedTab = type(RGMS.Portal) == "table"
        and RGMS.Portal.resolveSelection(report.tabs, previousTabIndex, true)
        or findBankTab(view, previousTabIndex)
    if not selectedTab then
        for _, candidate in ipairs(report.tabs) do
            if selectedTab == nil or candidate.index < selectedTab.index then
                selectedTab = candidate
            end
        end
    end
    if selectedTab then
        return UI.SelectBankTab(selectedTab.index)
    end

    view.selectedBankTabIndex = nil
    if type(RGMS.DB) == "table" and type(RGMS.DB.ui) == "table" then
        RGMS.DB.ui.selectedBankTabIndex = nil
    end
    updateDropdownLabel(view.bankDropdown, nil, "No bank tabs")
    hideBankLines(view)
    view.text:Show()
    view.text:SetText("No bank tabs purchased")
    view.scrollFrame:SetVerticalScroll(0)
    refreshScrollChild(view)
    return true
end

local updateBankRefreshButton
local updateRosterRefreshButton

function UI.SetGlobalScanLock(locked)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    UI.globalScanLocked = locked == true
    UI.frame.globalDimmer:SetShown(UI.globalScanLocked)
    if UI.globalScanLocked and UI.frame.notesEditor:IsShown() then
        UI.CloseCharacterNoteEditor()
    end
    if UI.globalScanLocked then
        local mainsAltsView = UI.frame.views.mainsalts
        UI.HideMainsAltsTagPreview()
        closeMainsAltsTagEditor(mainsAltsView)
        closeMainsAltsTagFilter(mainsAltsView)
    end
    for _, tab in ipairs(UI.frame.tabs) do
        tab:SetEnabled(not UI.globalScanLocked)
    end
    for _, tabId in ipairs(TAB_ORDER) do
        local view = UI.frame.views[tabId]
        view.spinner:SetShown(UI.globalScanLocked)
        if type(view.scrollFrame.EnableMouse) == "function" then
            view.scrollFrame:EnableMouse(not UI.globalScanLocked)
        end
        if type(view.scrollFrame.EnableMouseWheel) == "function" then
            view.scrollFrame:EnableMouseWheel(not UI.globalScanLocked)
        end
        if view.rankDropdown then
            view.rankDropdown:SetEnabled(
                not UI.globalScanLocked and view.rankDropdown.selectedOption ~= nil
            )
            if type(view.rankDropdown.SetAlpha) == "function" then
                view.rankDropdown:SetAlpha(UI.globalScanLocked and 0.5 or 1)
            end
        end
        if view.bankDropdown then
            view.bankDropdown:SetEnabled(
                not UI.globalScanLocked and view.bankDropdown.selectedOption ~= nil
            )
            if type(view.bankDropdown.SetAlpha) == "function" then
                view.bankDropdown:SetAlpha(UI.globalScanLocked and 0.5 or 1)
            end
        end
        if view.refreshButton and type(view.refreshButton.SetAlpha) == "function" then
            view.refreshButton:SetAlpha(UI.globalScanLocked and 0.5 or 1)
        end
        if view.groupButton and type(view.groupButton.SetAlpha) == "function" then
            view.groupButton:SetAlpha(UI.globalScanLocked and 0.5 or 1)
        end
    end
    updateRosterRefreshButton(UI.frame.views.roster)
    updateBankRefreshButton(UI.frame.views.bank)
    updateMainsAltsControlState(UI.frame.views.mainsalts)
    return true
end

function UI.SetRosterScanInProgress(inProgress)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.roster
    view.rosterScanInProgress = inProgress == true
    view.refreshButton:SetEnabled(
        UI.dataEnabled ~= false
            and view.rosterAvailable ~= false
            and not view.rosterScanInProgress
    )
    local mainsAltsView = UI.frame.views.mainsalts
    mainsAltsView.mainsAltsScanInProgress = inProgress == true
    if inProgress == true then
        cancelMainsAltsScrollWork(mainsAltsView)
    end
    updateMainsAltsControlState(mainsAltsView)
    UI.SetGlobalScanLock(
        view.rosterScanInProgress
            or UI.frame.views.bank.bankScanInProgress == true
    )
    return true
end

updateBankRefreshButton = function(view)
    view.refreshButton:SetEnabled(
        UI.dataEnabled ~= false
            and UI.globalScanLocked ~= true
            and view.bankOpen == true
            and view.bankScanInProgress ~= true
    )
end

updateRosterRefreshButton = function(view)
    view.refreshButton:SetEnabled(
        UI.dataEnabled ~= false
            and UI.globalScanLocked ~= true
            and view.rosterAvailable ~= false
            and view.rosterScanInProgress ~= true
    )
end

function UI.SetRosterAvailable(isAvailable)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.roster
    view.rosterAvailable = isAvailable == true
    updateRosterRefreshButton(view)
    return true
end

function UI.SetMainsAltsAvailable(isAvailable)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.mainsalts
    view.mainsAltsAvailable = isAvailable == true
    if not view.mainsAltsAvailable then
        cancelMainsAltsScrollWork(view)
        closeMainsAltsTagEditor(view)
        closeMainsAltsTagFilter(view)
    end
    updateMainsAltsControlState(view)
    return true
end

function UI.SetGuildBankOpen(isOpen)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.bank
    view.bankOpen = isOpen == true
    updateBankRefreshButton(view)
    return true
end

function UI.SetBankScanInProgress(inProgress)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.bank
    view.bankScanInProgress = inProgress == true
    updateBankRefreshButton(view)
    UI.SetGlobalScanLock(
        view.bankScanInProgress
            or UI.frame.views.roster.rosterScanInProgress == true
    )
    return true
end

function UI.SetDataState(enabled, state)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    UI.dataEnabled = enabled == true
    updateRosterRefreshButton(UI.frame.views.roster)
    updateBankRefreshButton(UI.frame.views.bank)
    updateMainsAltsControlState(UI.frame.views.mainsalts)

    if UI.dataEnabled then
        return true
    end

    local stateLabel = tostring(state or "unavailable")
    local message = "Saved data is "
        .. stateLabel
        .. ". Reports and scans are unavailable until /rgms reset is accepted."
    for _, tabId in ipairs(TAB_ORDER) do
        UI.SetViewContent(tabId, message)
        UI.SetViewStatus(tabId, "Reports and scans unavailable")
    end
    return true
end

function UI.GetContentHost(tabId)
    tabId = normalizeTabId(tabId)
    if not tabId or not UI.frame then
        return nil
    end
    return UI.frame.views[tabId].scrollChild
end

function UI.ShowTooltip(owner, title, body)
    if not UI.frame or not UI.frame.ownedTooltip then
        return false
    end
    local tooltip = UI.frame.ownedTooltip
    tooltip.owner = owner
    tooltip.title:SetText(tostring(title or ""))
    tooltip.body:SetText(tostring(body or ""))
    tooltip:SetHeight(math.max(44, tooltip.body:GetStringHeight() + 34))
    tooltip:ClearAllPoints()
    tooltip:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", 8, 8)
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

function UI.Show(tabId)
    if not UI.frame then
        local initialized, initializeError = UI.Initialize()
        if not initialized then
            return nil, initializeError
        end
    end
    local wasShown = UI.frame:IsShown()
    if not wasShown then
        if type(RGMS.PortalState) == "table" then
            RGMS.PortalState:openWindow()
        end
        local selected, selectError = UI.SelectPrimaryTab("roster")
        if not selected then
            return nil, selectError
        end
    end

    UI.frame:Show()
    return true
end

function UI.Hide()
    if UI.frame then
        UI.frame:Hide()
    elseif type(RGMS.PortalState) == "table" then
        RGMS.PortalState:closeWindow()
    end
    return true
end

function UI.Toggle(tabId)
    if UI.frame and UI.frame:IsShown() then
        return UI.Hide()
    end
    return UI.Show(tabId)
end

function UI.IsShown()
    return UI.frame ~= nil and UI.frame:IsShown()
end

RGMS.UI = UI

return UI
