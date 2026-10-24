local _, RGMS = ...

local UI = RGMS.UI or {}
local createFrame = CreateFrame
local windowDragRoot
local startWindowDrag
local stopWindowDrag
local setEditBoxEnabled

local function isInsideMainWindow(parent)
    local current = parent
    while current do
        if current == windowDragRoot then
            return true
        end
        if type(current.GetParent) ~= "function" then
            return false
        end
        current = current:GetParent()
    end
    return false
end

local function enableWindowDragging(surface)
    if not surface or type(surface.RegisterForDrag) ~= "function"
        or type(surface.HookScript) ~= "function" then
        return
    end
    surface:RegisterForDrag("LeftButton")
    surface:HookScript("OnDragStart", startWindowDrag)
    surface:HookScript("OnDragStop", stopWindowDrag)
end

local function CreateFrame(frameType, name, parent, template)
    local frame = createFrame(frameType, name, parent, template)
    if frameType ~= "EditBox"
        and windowDragRoot and isInsideMainWindow(parent) then
        enableWindowDragging(frame)
    end
    return frame
end

local TAB_ORDER = { "roster", "bank", "tags" }
local ALL_VIEW_IDS = { "roster", "mainsalts", "bank", "tags" }
local TAB_TITLES = {
    roster = "Roster",
    bank = "Guild Bank",
    tags = "Tags",
}

local INITIAL_COPY = {
    roster = "No roster data yet",
    mainsalts = "No roster data yet",
    bank = "No bank scan yet",
    tags = "No tags yet",
}

local HEADER_HEIGHT = 56
UI.GUILD_BADGE = {
    size = 63,
    x = -20,
    y = 20,
    innerSize = 55,
    emblemWidth = 65,
    emblemHeight = 65,
    controlX = 63,
    sidebarTop = 8,
}
local SIDEBAR_WIDTH = 136
local CONTENT_PADDING = 16
local GLOBAL_DIMMER_ALPHA = 0.8
local GLOBAL_DIMMER_FRAME_LEVEL_OFFSET = 100
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
local DROPDOWN_RADIO_SIZE = 16
local DROPDOWN_RADIO_INNER_SIZE = 12
local DROPDOWN_RADIO_DOT_SIZE = 8
local DROPDOWN_RADIO_LEFT = 10
local DROPDOWN_RADIO_LABEL_GAP = 8
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
local MAINS_ALTS_RANK_ICON_SIZE = 16
local MAINS_ALTS_RANK_ICON_GAP = 4
local MAINS_ALTS_SCROLL_DURATION = 0
local MAINS_ALTS_WHEEL_ROWS = 3
-- The legacy ScrollFrame is retained for exact pixel anchors and existing styling;
-- only enough complex row controls for the viewport are kept live and recycled.
local MAINS_ALTS_VIEWPORT_BUFFER_ROWS = 1
local MAINS_ALTS_SEARCH_WIDTH = 253
local MAINS_ALTS_SEARCH_HEIGHT = 32
local MAINS_ALTS_FILTER_WIDTH = 124
local MAINS_ALTS_FILTER_HEIGHT = 28
local BY_RANK_CHECKBOX_SIZE = 18
local BY_RANK_CONTROL_WIDTH = 88
-- Keep tag management on RGMS's established fixed-header ScrollFrame pattern.
-- External table libraries add their own styling and selection model, while
-- the native modern ScrollBox wrappers do not improve this small three-column
-- view enough to justify a new bundled dependency.
local TAG_MANAGEMENT_ROW_HEIGHT = 24
local TAG_MANAGEMENT_NAME_WIDTH = 180
local TAG_MANAGEMENT_DELETE_WIDTH = 36
local TAG_POPOVER_WIDTH = 340
local TAG_PILL_HEIGHT = 20
local TAG_PILL_GAP = 6
local TAG_POPOVER_PADDING = 8
local CHARACTER_NOTE_LIMIT = 5500
local GUILD_NOTE_LIMIT = 31
local CHARACTER_NOTE_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\notebook-pen.png"
local CHARACTER_TAG_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\tag.png"
local GUILD_MASTER_TEXTURE = "Interface\\GroupFrame\\UI-Group-LeaderIcon"
local OFFICER_TEXTURE = "Interface\\GroupFrame\\UI-Group-AssistantIcon"
local MISSING_WARNING_SIZE = 16
local MISSING_WARNING_GAP = 4
local MISSING_WARNING_TEXTURE = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local CIRCLE_TEXTURE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local BORDER_TEXTURE = "Interface\\Tooltips\\UI-Tooltip-Border"
local LOGO_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\rgms-logo.png"
local CLOSE_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\x.png"
local CHEVRON_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\chevron-right.png"
local REFRESH_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\refresh-cw.png"
local LOADER_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\loader-circle.png"
local CHECK_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\check.png"
local TAG_DELETE_ATLAS = "common-icon-delete"
local TAG_DELETE_DIALOG_KEY = "RGMS_CONFIRM_TAG_DELETE"
local FONT_REGULAR = "Interface\\AddOns\\RGMS\\assets\\fonts\\Inter-Regular.ttf"
local FONT_SEMIBOLD = "Interface\\AddOns\\RGMS\\assets\\fonts\\Inter-SemiBold.ttf"
local PALETTE = type(RGMS.Portal) == "table" and RGMS.Portal.PALETTE or {
    shell = { 0.059, 0.067, 0.082, 1 }, surface = { 0.094, 0.106, 0.129, 1 },
    control = { 0.133, 0.149, 0.18, 1 }, border = { 0.204, 0.227, 0.275, 1 },
    zebra = { 0.114, 0.125, 0.153, 1 }, filterMatch = { 0.231, 0.137, 0.192, 1 },
    pink = { 0.925, 0.282, 0.6, 1 }, pinkHover = { 0.957, 0.447, 0.714, 1 }, text = { 0.957, 0.957, 0.961, 1 },
    secondary = { 0.631, 0.631, 0.667, 1 }, disabled = { 0.443, 0.443, 0.478, 1 },
    warning = { 0.984, 0.749, 0.141, 1 }, error = { 0.973, 0.443, 0.443, 1 },
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

local function setCharacterNameColor(region, classFileName)
    local color = type(RAID_CLASS_COLORS) == "table"
        and RAID_CLASS_COLORS[classFileName]
        or nil
    if type(color) == "table"
        and type(color.r) == "number"
        and type(color.g) == "number"
        and type(color.b) == "number" then
        region:SetTextColor(color.r, color.g, color.b, 1)
        return
    end
    setTextColor(region, PALETTE.text)
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

function UI.RefreshGuildBadge(frame)
    if not frame or not frame.guildEmblem or not frame.guildBackground then
        return false
    end

    frame.guildEmblem:SetSize(
        UI.GUILD_BADGE.emblemWidth,
        UI.GUILD_BADGE.emblemHeight
    )
    if type(SetLargeGuildTabardTextures) == "function" then
        SetLargeGuildTabardTextures(
            "player",
            frame.guildEmblem,
            frame.guildBackground,
            nil
        )
        return true
    end

    frame.guildBackground:SetVertexColor(unpackColor(PALETTE.surface))
    frame.guildEmblem:SetTexture(LOGO_TEXTURE)
    frame.guildEmblem:SetTexCoord(0, 1, 0, 1)
    frame.guildEmblem:SetVertexColor(1, 1, 1, 1)
    return false
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
            local sublevel = layer == "border" and -2 or -1
            capsule[layer] = {
                left = control:CreateTexture(nil, "BACKGROUND", nil, sublevel),
                center = control:CreateTexture(nil, "BACKGROUND", nil, sublevel),
                right = control:CreateTexture(nil, "BACKGROUND", nil, sublevel),
            }
            capsule[layer].left:SetTexture(
                CIRCLE_TEXTURE,
                "CLAMP",
                "CLAMP"
            )
            capsule[layer].left:SetTexCoord(0, 0.5, 0, 1)
            capsule[layer].center:SetTexture(WHITE_TEXTURE)
            capsule[layer].right:SetTexture(
                CIRCLE_TEXTURE,
                "CLAMP",
                "CLAMP"
            )
            capsule[layer].right:SetTexCoord(0.5, 1, 0, 1)
        end
        control.tagCapsule = capsule
    end

    local capsule = control.tagCapsule
    local height = math.max(2, control:GetHeight() or TAG_PILL_HEIGHT)
    local radius = height / 2
    local inset = 1
    local innerHeight = math.max(1, height - inset * 2)
    local innerRadius = innerHeight / 2

    capsule.border.left:ClearAllPoints()
    capsule.border.left:SetSize(radius, height)
    capsule.border.left:SetPoint("LEFT", control, "LEFT", 0, 0)
    capsule.border.center:ClearAllPoints()
    capsule.border.center:SetPoint("TOPLEFT", control, "TOPLEFT", radius, 0)
    capsule.border.center:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", -radius, 0)
    capsule.border.right:ClearAllPoints()
    capsule.border.right:SetSize(radius, height)
    capsule.border.right:SetPoint("RIGHT", control, "RIGHT", 0, 0)

    capsule.fill.left:ClearAllPoints()
    capsule.fill.left:SetSize(innerRadius, innerHeight)
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
    capsule.fill.right:SetSize(innerRadius, innerHeight)
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

local function setRefreshButtonEnabled(button, enabled)
    enabled = enabled == true
    button:SetEnabled(enabled)
    setTextureColor(button.icon, enabled and PALETTE.text or PALETTE.disabled)
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

local function setScrollBarShown(scrollFrame, shown)
    local scrollBar = scrollFrame and (scrollFrame.ScrollBar or scrollFrame.scrollBar)
    if scrollBar and type(scrollBar.SetShown) == "function" then
        scrollBar:SetShown(shown == true)
    end
end

local showOwnedTooltip
local hideOwnedTooltip
local closeMainsAltsTagEditor
local closeMainsAltsTagFilter
local refreshMainsAltsTagEditor
local refreshMainsAltsTagFilter
local updateMainsAltsTagFilterAppearance
local updateRosterModeControls

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
    if TAB_TITLES[tabId] or tabId == "mainsalts" then
        return tabId
    end
    return nil
end

local function activeRosterMode()
    if type(RGMS.PortalState) == "table"
        and RGMS.PortalState.rosterMode == "ByTenure" then
        return "ByTenure"
    end
    if UI.rosterMode == "ByTenure" then
        return "ByTenure"
    end
    return "ByName"
end

local function rosterModeView(mode)
    if not UI.frame then
        return nil
    end
    return mode == "ByTenure"
        and UI.frame.views.roster
        or UI.frame.views.mainsalts
end

local function setRosterModeScroll(mode, offset)
    offset = math.max(0, tonumber(offset) or 0)
    if type(RGMS.PortalState) == "table" then
        RGMS.PortalState:setScroll("roster", offset, mode)
    else
        UI.rosterScroll = UI.rosterScroll or { ByName = 0, ByTenure = 0 }
        UI.rosterScroll[mode] = offset
    end
end

local function getRosterModeScroll(mode)
    if type(RGMS.PortalState) == "table" then
        return RGMS.PortalState.scroll.roster[mode] or 0
    end
    return UI.rosterScroll and UI.rosterScroll[mode] or 0
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
        line.rankIcon:ClearAllPoints()
        line.expandButton:ClearAllPoints()
        line.promoteButton:ClearAllPoints()
        line.removeButton:ClearAllPoints()
        line.noteButton:ClearAllPoints()
        line.tagButton:ClearAllPoints()
        local rankIconWidth = line.leadershipRole
            and MAINS_ALTS_RANK_ICON_SIZE + MAINS_ALTS_RANK_ICON_GAP
            or 0
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
                    - rankIconWidth
                    - MAINS_ALTS_TAG_WIDTH - 56 - 168 - 12
            )
            local nameWidth = type(line.name.GetStringWidth) == "function"
                and line.name:GetStringWidth() + 2
                or maximumNameWidth
            line.name:SetWidth(math.min(maximumNameWidth, nameWidth))
            line.rankIcon:SetPoint(
                "LEFT",
                line.name,
                "RIGHT",
                MAINS_ALTS_RANK_ICON_GAP,
                0
            )
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
                    - rankIconWidth
                    - MAINS_ALTS_TAG_WIDTH - 56 - 168 - 12
            )
            local nameWidth = type(line.name.GetStringWidth) == "function"
                and line.name:GetStringWidth() + 2
                or maximumNameWidth
            line.name:SetWidth(math.min(maximumNameWidth, nameWidth))
            line.rankIcon:SetPoint(
                "LEFT",
                line.name,
                "RIGHT",
                MAINS_ALTS_RANK_ICON_GAP,
                0
            )
            line.tagButton:SetPoint("CENTER", line.frame, "RIGHT", -236, 0)
            line.noteButton:SetPoint("CENTER", line.frame, "RIGHT", -196, 0)
        end
    end
end

local function layoutTagManagementLines(view, availableWidth)
    if type(view.tagRows) ~= "table" then
        return
    end

    local previewWidth = math.max(
        1,
        availableWidth - TAG_MANAGEMENT_NAME_WIDTH - TAG_MANAGEMENT_DELETE_WIDTH
    )
    local lines = {}
    if view.tagHeader then
        lines[#lines + 1] = view.tagHeader
    end
    for _, line in ipairs(view.tagRows) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(lines) do
        line.frame:SetWidth(availableWidth)
        line.name:ClearAllPoints()
        line.preview:ClearAllPoints()
        line.name:SetPoint("LEFT", line.frame, "LEFT", 8, 0)
        line.name:SetWidth(math.max(1, TAG_MANAGEMENT_NAME_WIDTH - 8))
        line.preview:SetPoint(
            "LEFT",
            line.frame,
            "LEFT",
            TAG_MANAGEMENT_NAME_WIDTH,
            0
        )
        line.preview:SetWidth(previewWidth)
        if line.delete then
            line.delete:ClearAllPoints()
            line.delete:SetPoint("RIGHT", line.frame, "RIGHT", -8, 0)
            line.delete:SetWidth(math.max(1, TAG_MANAGEMENT_DELETE_WIDTH - 8))
        end
        if line.deleteButton then
            line.deleteButton:ClearAllPoints()
            line.deleteButton:SetPoint("RIGHT", line.frame, "RIGHT", -8, 0)
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
    noteText:SetText("")
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
    layoutTagManagementLines(view, availableWidth)

    local viewportHeight = math.max(1, view.scrollFrame:GetHeight())
    local contentHeight = view.rosterTableHeight
        or view.bankTableHeight
        or view.mainsAltsTableHeight
        or view.tagTableHeight
        or (view.text:GetStringHeight() + 16)
    setScrollBarShown(view.scrollFrame, contentHeight > viewportHeight)
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

local function renderRosterRank(view, rank, forceTextRefresh)
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
        if forceTextRefresh then
            line.primary:SetText("")
            line.secondary:SetText("")
            line.tertiary:SetText("")
        end
        line.primary:SetText(primary or "")
        line.secondary:SetText(secondary or "")
        line.tertiary:SetText(tertiary or "")
        setCharacterNameColor(
            line.primary,
            member and member.classFileName or nil
        )
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
        local model = editor.model
        local saving = model and model.saving == true
        editor.saveButton:SetEnabled(enabled and model and model.saveEnabled == true)
        editor.cancelButton:SetEnabled(enabled and not saving)
        editor.closeButton:SetEnabled(true)
        for key, field in pairs(editor.fields or {}) do
            local fieldEnabled = enabled and not saving
            if key == "publicNote" then
                fieldEnabled = fieldEnabled and model
                    and model.publicEditable == true and not model.loading
            elseif key == "officerNote" then
                fieldEnabled = fieldEnabled and model
                    and model.officerEditable == true and not model.loading
            end
            setEditBoxEnabled(field.editBox, fieldEnabled == true)
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
    local name = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    name:SetJustifyH("LEFT")
    name:SetJustifyV("MIDDLE")
    if type(name.SetWordWrap) == "function" then
        name:SetWordWrap(false)
    end
    local rankIcon = frame:CreateTexture(nil, "ARTWORK")
    rankIcon:SetSize(MAINS_ALTS_RANK_ICON_SIZE, MAINS_ALTS_RANK_ICON_SIZE)
    rankIcon:Hide()
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
        rankIcon = rankIcon,
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
            local editor = view.mainsAltsTagEditor
            if editor
                and editor:IsShown()
                and editor.characterIdentity == line.character.identity then
                closeMainsAltsTagEditor(view)
            else
                UI.OpenMainsAltsTagEditor(line.character.identity, tagButton)
            end
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
    line.isFilterMatch = (view.mainsAltsMatchingCharacters or {})[
        character.identity
    ] == true
    line.hasNote = character.hasNote == true
    line.tags = character.tags or {}
    line.leadershipRole = character.leadershipRole
    setCharacterNameColor(line.name, character.classFileName)
    if line.leadershipRole == "guild-master" then
        line.rankIcon:SetTexture(GUILD_MASTER_TEXTURE)
        line.rankIcon:Show()
    elseif line.leadershipRole == "officer" then
        line.rankIcon:SetTexture(OFFICER_TEXTURE)
        line.rankIcon:Show()
    else
        line.rankIcon:Hide()
    end
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
    line.baseColor = line.isFilterMatch and PALETTE.filterMatch
        or (rowIndex % 2 == 0) and PALETTE.zebra
        or PALETTE.surface
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
            and UI.selectedTab == "roster"
            and activeRosterMode() == "ByName"
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

    local filtered, matchingGroups, normalized, matchingCharacters =
        RGMS.MainsAltsSearch.filter(
            source,
            view.mainsAltsSearchQuery,
            view.mainsAltsTagFilters
        )
    if not filtered then
        filtered = source
        matchingGroups = {}
        normalized = ""
        matchingCharacters = {}
    end
    view.mainsAltsReport = filtered
    view.mainsAltsNormalizedSearch = normalized
    view.mainsAltsMatchingCharacters = matchingCharacters or {}
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
    editBox:SetPoint(
        "TOPLEFT",
        view:GetParent(),
        "TOPLEFT",
        UI.GUILD_BADGE.controlX,
        -12
    )
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
    placeholder:SetText("Search...")
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
        showOwnedTooltip(button, "Clear search", "Show every Roster character.")
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
    filterButton:SetSize(MAINS_ALTS_FILTER_WIDTH, MAINS_ALTS_FILTER_HEIGHT)
    filterButton:SetPoint("LEFT", editBox, "RIGHT", CONTROL_GAP, 1)
    styleTagCapsule(filterButton, PALETTE.control, PALETTE.border)
    filterButton.label = filterButton:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    filterButton.label:SetPoint("CENTER", filterButton, "CENTER", 0, -1)
    filterButton.label:SetJustifyH("CENTER")
    setFont(filterButton.label, FONT_SEMIBOLD, 12)
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
    pill.label = pill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
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
        pill.label:SetText("")
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
    local shown = view.mainsAltsTagFilter and view.mainsAltsTagFilter:IsShown()
    view.mainsAltsTagDismissLayer:SetShown(shown == true)
end

closeMainsAltsTagEditor = function(view)
    if view and view.mainsAltsTagEditor then
        view.mainsAltsTagEditor:Hide()
        view.mainsAltsTagEditor.characterIdentity = nil
        view.mainsAltsTagEditor.anchor = nil
        view.mainsAltsTagEditor.input:SetText("")
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
    local label = count > 0
        and ("Tags... (" .. count .. ")")
        or "Tags..."
    view.mainsAltsTagFilterButton.label:SetText("")
    view.mainsAltsTagFilterButton.label:SetText(label)
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

    local mouseListener = CreateFrame("Frame")
    mouseListener:RegisterEvent("GLOBAL_MOUSE_DOWN")
    mouseListener:SetScript("OnEvent", function(_, event)
        if event == "GLOBAL_MOUSE_DOWN"
            and editor:IsShown()
            and not editor:IsMouseOver()
            and (not editor.anchor or not editor.anchor:IsMouseOver()) then
            closeMainsAltsTagEditor(view)
        end
    end)
    view.mainsAltsTagMouseListener = mouseListener

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

local function updateDropdownLabel(dropdown, option, emptyLabel, forceTextRefresh)
    if not dropdown then
        return
    end
    dropdown.selectedOption = option
    dropdown.label:ClearAllPoints()
    dropdown.label:SetPoint("LEFT", dropdown, "LEFT", option and option.icon and 34 or 12, 0)
    dropdown.label:SetPoint("RIGHT", dropdown, "RIGHT", -28, 0)
    local label = option and (option.label or option.name) or emptyLabel
    if forceTextRefresh then
        dropdown.label:SetText("")
    end
    dropdown.label:SetText(label)
    dropdown:SetEnabled(option ~= nil and UI.globalScanLocked ~= true)
    if dropdown.icon then
        dropdown.icon:SetShown(option ~= nil and option.icon ~= nil)
        if option and option.icon then
            dropdown.icon:SetTexture(option.icon)
        end
    end
end

local function styleDropdownRadio(button)
    local ring = button.leftTexture1
    if ring then
        ring:ClearAllPoints()
        ring:SetPoint("LEFT", button, "LEFT", DROPDOWN_RADIO_LEFT, 0)
        ring:SetSize(DROPDOWN_RADIO_SIZE, DROPDOWN_RADIO_SIZE)
        ring:SetTexture(CIRCLE_TEXTURE)
        ring:SetDrawLayer("ARTWORK", 0)
        ring:SetVertexColor(unpackColor(PALETTE.border))

        local interior = button:AttachTexture()
        interior:SetPoint("CENTER", ring, "CENTER", 0, 0)
        interior:SetSize(DROPDOWN_RADIO_INNER_SIZE, DROPDOWN_RADIO_INNER_SIZE)
        interior:SetTexture(CIRCLE_TEXTURE)
        interior:SetDrawLayer("ARTWORK", 1)
        interior:SetVertexColor(unpackColor(PALETTE.shell))
        button.rgmsRadioInterior = interior
    end

    local dot = button.leftTexture2
    if dot and ring then
        dot:ClearAllPoints()
        dot:SetPoint("CENTER", ring, "CENTER", 0, 0)
        dot:SetSize(DROPDOWN_RADIO_DOT_SIZE, DROPDOWN_RADIO_DOT_SIZE)
        dot:SetTexture(CIRCLE_TEXTURE)
        dot:SetDrawLayer("ARTWORK", 2)
        dot:SetVertexColor(unpackColor(PALETTE.pink))
    end

    if button.fontString and ring then
        button.fontString:ClearAllPoints()
        button.fontString:SetPoint(
            "LEFT",
            ring,
            "RIGHT",
            DROPDOWN_RADIO_LABEL_GAP,
            0
        )
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
                    menuOption.label or menuOption.name,
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
                    styleDropdownRadio(button)
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

local function configureTagManagementText(text)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    if type(text.SetWordWrap) == "function" then
        text:SetWordWrap(false)
    end
    if type(text.SetMaxLines) == "function" then
        text:SetMaxLines(1)
    end
end

local function createTagManagementHeader(view)
    local frame = CreateFrame("Frame", nil, view, "BackdropTemplate")
    flatBackdrop(frame, PALETTE.control, PALETTE.border)
    frame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    frame:SetPoint("TOPRIGHT", view, "TOPRIGHT", -8, 0)
    frame:SetHeight(28)
    local header = {
        frame = frame,
        name = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        preview = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        delete = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
    }
    header.name:SetText("Tag")
    header.preview:SetText("")
    header.delete:SetText("")
    for _, label in ipairs({ header.name, header.preview, header.delete }) do
        configureTagManagementText(label)
        setFont(label, FONT_SEMIBOLD, 12)
        setTextColor(label, PALETTE.text)
    end
    view.tagHeader = header
    return header
end

local function updateTagDeleteButton(line)
    local enabled = line.row ~= nil
        and line.row.immutable ~= true
        and UI.globalScanLocked ~= true
        and UI.dataEnabled ~= false
    line.deleteEnabled = enabled
    line.deleteButton:SetEnabled(enabled)
    if type(line.deleteButton.SetAlpha) == "function" then
        line.deleteButton:SetAlpha(line.deleteEnabled and 1 or 0.45)
    end
    setTextureColor(
        line.deleteIcon,
        line.deleteEnabled and PALETTE.text or PALETTE.disabled
    )
end

local function hideTagManagementRows(view)
    for _, line in ipairs(view.tagRows or {}) do
        hideOwnedTooltip(line.deleteButton)
        line.frame:Hide()
    end
    view.tagTableHeight = nil
end

local function acquireTagManagementRow(view, index)
    local line = view.tagRows[index]
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
    local name = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local preview = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local deleteButton = CreateFrame("Button", nil, frame)
    deleteButton:SetSize(20, 20)
    local deleteIcon = deleteButton:CreateTexture(nil, "ARTWORK")
    deleteIcon:SetAllPoints(deleteButton)
    if type(deleteIcon.SetAtlas) == "function" then
        deleteIcon:SetAtlas(TAG_DELETE_ATLAS)
    end
    line = {
        frame = frame,
        background = background,
        name = name,
        preview = preview,
        deleteButton = deleteButton,
        deleteIcon = deleteIcon,
    }
    configureTagManagementText(name)
    configureTagManagementText(preview)
    setFont(name, FONT_REGULAR, 12)
    setFont(preview, FONT_REGULAR, 12)
    setTextColor(name, PALETTE.text)
    setTextColor(preview, PALETTE.secondary)
    enableRowHover(line)
    deleteButton:SetScript("OnEnter", function(button)
        if line.deleteEnabled then
            line.background:SetVertexColor(unpackColor(PALETTE.control))
            setTextureColor(line.deleteIcon, PALETTE.pinkHover)
        end
    end)
    deleteButton:SetScript("OnLeave", function(button)
        line.background:SetVertexColor(unpackColor(line.baseColor or PALETTE.surface))
        updateTagDeleteButton(line)
    end)
    deleteButton:SetScript("OnClick", function()
        if line.row and line.deleteEnabled then
            UI.RequestTagDeletion(line.row)
        end
    end)
    view.tagRows[index] = line
    return line
end

local function renderTagManagement(view, report)
    view.text:Hide()
    hideTagManagementRows(view)
    local header = view.tagHeader or createTagManagementHeader(view)
    header.frame:Show()

    local offset = 0
    for index, row in ipairs(report.rows) do
        local line = acquireTagManagementRow(view, index)
        line.row = row
        line.frame:ClearAllPoints()
        line.frame:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
        line.frame:SetHeight(TAG_MANAGEMENT_ROW_HEIGHT)
        line.name:SetText(row.name)
        line.preview:SetText(row.characterPreview)
        line.baseColor = (index % 2 == 0) and PALETTE.zebra or PALETTE.surface
        line.background:SetVertexColor(unpackColor(line.baseColor))
        updateTagDeleteButton(line)
        line.frame:Show()
        offset = offset + TAG_MANAGEMENT_ROW_HEIGHT
    end
    for index = #report.rows + 1, #view.tagRows do
        local line = view.tagRows[index]
        hideOwnedTooltip(line.deleteButton)
        line.row = nil
        line.frame:Hide()
    end
    view.tagTableHeight = offset + 4
    refreshScrollChild(view)
end

local function refreshVisibleReport(view, tabId)
    if tabId == "roster" then
        if activeRosterMode() == "ByTenure" then
            local rank = findRosterRank(view, view.selectedRankIndex)
            if rank then
                updateDropdownLabel(view.rankDropdown, rank, "No ranks", true)
                renderRosterRank(view, rank, true)
            end
        else
            local byNameView = UI.frame.views.mainsalts
            if type(byNameView.mainsAltsReport) == "table" then
                renderMainsAlts(byNameView)
            end
        end
    elseif tabId == "bank" then
        local tab = findBankTab(view, view.selectedBankTabIndex)
        if tab then
            updateDropdownLabel(view.bankDropdown, tab, "No bank tabs", true)
            renderBankTab(view, tab)
        end
    elseif tabId == "tags"
        and type(RGMS.MainsAlts) == "table"
        and type(RGMS.MainsAlts.RefreshTags) == "function" then
        RGMS.MainsAlts.RefreshTags()
    end
end

local function createByRankControl(view, checked, relativeTo, point, relativePoint, x, y)
    local control = CreateFrame("CheckButton", nil, view, "BackdropTemplate")
    control:SetSize(BY_RANK_CONTROL_WIDTH, 32)
    control:SetPoint(point, relativeTo, relativePoint, x, y)

    control.box = CreateFrame("Frame", nil, control, "BackdropTemplate")
    control.box:SetSize(BY_RANK_CHECKBOX_SIZE, BY_RANK_CHECKBOX_SIZE)
    control.box:SetPoint("LEFT", control, "LEFT", 0, 0)
    flatBackdrop(control.box, PALETTE.control, PALETTE.border)
    control.check = control.box:CreateTexture(nil, "ARTWORK")
    control.check:SetAllPoints(control.box)
    control.check:SetTexture(CHECK_TEXTURE)
    control.check:SetShown(checked == true)

    control.label = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    control.label:SetPoint("LEFT", control.box, "RIGHT", 6, 0)
    control.label:SetJustifyH("LEFT")
    control.label:SetText("By rank")
    setFont(control.label, FONT_SEMIBOLD, 12)
    setTextColor(control.label, PALETTE.text)
    control:SetChecked(checked == true)
    control:SetScript("OnClick", function(button)
        local selected, reason = UI.SelectRosterMode(
            button:GetChecked() and "ByTenure" or "ByName"
        )
        if not selected then
            button:SetChecked(activeRosterMode() == "ByTenure")
            button.check:SetShown(button:GetChecked())
            if reason and reason ~= "modal-open" and type(RGMS.Print) == "function" then
                RGMS.Print("Could not change the Roster presentation: " .. tostring(reason) .. ".")
            end
        end
    end)
    view.byRankCheckbox = control
    return control
end

local function createView(parent, tabId)
    local view = CreateFrame("Frame", nil, parent)
    view:SetPoint("TOPLEFT", SIDEBAR_WIDTH + CONTENT_PADDING, -HEADER_HEIGHT - CONTENT_PADDING)
    view:SetPoint("BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)

    view.status = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local statusY = tabId == "bank" and -8 or -20
    view.status:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        (tabId == "mainsalts" or tabId == "roster") and 680 or 280,
        statusY
    )
    view.status:SetPoint(
        "TOPRIGHT",
        parent,
        "TOPRIGHT",
        (tabId == "mainsalts" or tabId == "roster" or tabId == "bank" or tabId == "tags") and -96 or -148,
        statusY
    )
    if tabId == "bank" then
        view.status:SetHeight(40)
        view.status:SetJustifyV("MIDDLE")
    end
    view.status:SetJustifyH("RIGHT")
    view.status:SetText(INITIAL_COPY[tabId])
    setFont(view.status, FONT_REGULAR, 11)
    setTextColor(view.status, PALETTE.secondary)
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

    if tabId == "roster" or tabId == "mainsalts" or tabId == "bank" then
        view.refreshButton = CreateFrame("Button", nil, view)
        view.refreshButton:SetSize(32, 32)
        view.refreshButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -56, -12)
        view.refreshButton.icon = view.refreshButton:CreateTexture(nil, "ARTWORK")
        view.refreshButton.icon:SetSize(18, 18)
        view.refreshButton.icon:SetPoint("CENTER", view.refreshButton, "CENTER", 0, 0)
        view.refreshButton.icon:SetTexture(REFRESH_TEXTURE)
        setRefreshButtonEnabled(view.refreshButton, tabId ~= "bank")
        view.refreshButton:SetScript("OnEnter", function(button)
            if button:IsEnabled() then
                setTextureColor(button.icon, PALETTE.pinkHover)
            end
            local body = (tabId == "roster" or tabId == "mainsalts")
                and "Refresh the guild roster."
                or "Refresh the guild bank."
            showOwnedTooltip(button, "Refresh", body)
        end)
        view.refreshButton:SetScript("OnLeave", function(button)
            setTextureColor(
                button.icon,
                button:IsEnabled() and PALETTE.text or PALETTE.disabled
            )
            hideOwnedTooltip(button)
        end)
        view.refreshButton:SetScript("OnMouseDown", function(button)
            if button:IsEnabled() then
                setTextureColor(button.icon, PALETTE.pink)
            end
        end)
        view.refreshButton:SetScript("OnMouseUp", function(button)
            if button:IsEnabled() then
                setTextureColor(button.icon, PALETTE.pinkHover)
            end
        end)
        if tabId == "roster" or tabId == "mainsalts" then
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
        view.rankDropdown:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            UI.GUILD_BADGE.controlX,
            -12
        )
        createByRankControl(
            view,
            true,
            view.status,
            "RIGHT",
            "LEFT",
            -CONTROL_GAP,
            0
        )
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
        view.groupButton:SetPoint(
            "LEFT",
            view.mainsAltsTagFilterButton,
            "RIGHT",
            CONTROL_GAP,
            0
        )
        createByRankControl(
            view,
            false,
            view.status,
            "RIGHT",
            "LEFT",
            -CONTROL_GAP,
            0
        )
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
        view.bankDropdown:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            UI.GUILD_BADGE.controlX,
            -12
        )
        view.bankTabScrollFrame:SetScript("OnSizeChanged", function()
            refreshBankTabScrollChild(view)
        end)
    elseif tabId == "tags" then
        view.tagRows = {}
        createTagManagementHeader(view)
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

setEditBoxEnabled = function(editBox, enabled)
    if type(editBox.SetEnabled) == "function" then
        editBox:SetEnabled(enabled)
    elseif enabled and type(editBox.Enable) == "function" then
        editBox:Enable()
    elseif not enabled and type(editBox.Disable) == "function" then
        editBox:Disable()
    end
end

local function createNoteField(editor, key, labelText, y, height, limit, readOnly)
    local field = CreateFrame("Frame", nil, editor)
    field:SetPoint("TOPLEFT", editor, "TOPLEFT", 20, y)
    field:SetPoint("TOPRIGHT", editor, "TOPRIGHT", -20, y)
    field:SetHeight(height)
    field.key = key
    field.limit = limit

    field.label = field:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    field.label:SetPoint("TOPLEFT", field, "TOPLEFT", 0, 0)
    field.label:SetText(labelText)
    setFont(field.label, FONT_SEMIBOLD, 11)
    setTextColor(field.label, PALETTE.text)

    if readOnly then
        field.helpButton = CreateFrame("Button", nil, field)
        field.helpButton:SetSize(14, 14)
        field.helpButton:SetPoint("LEFT", field.label, "RIGHT", 5, 0)
        field.helpButton.background = field.helpButton:CreateFontString(
            nil,
            "ARTWORK",
            "GameFontNormal"
        )
        field.helpButton.background:SetPoint("CENTER", field.helpButton, "CENTER", 0, 0)
        field.helpButton.background:SetText("○")
        setFont(field.helpButton.background, FONT_SEMIBOLD, 16)
        setTextColor(field.helpButton.background, PALETTE.secondary)
        field.helpButton.glyph = field.helpButton:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
        field.helpButton.glyph:SetPoint("CENTER", field.helpButton, "CENTER", 0, 0)
        field.helpButton.glyph:SetText("?")
        setFont(field.helpButton.glyph, FONT_SEMIBOLD, 10)
        setTextColor(field.helpButton.glyph, PALETTE.secondary)
        field.helpButton:SetScript("OnEnter", function(button)
            showOwnedTooltip(
                button,
                nil,
                "This note is read-only in RGMS. To change it, use the default Guild Roster interface."
            )
        end)
        field.helpButton:SetScript("OnLeave", function(button)
            hideOwnedTooltip(button)
        end)
    end

    field.textArea = CreateFrame("Frame", nil, field, "BackdropTemplate")
    field.textArea:SetPoint("TOPLEFT", field, "TOPLEFT", 0, -19)
    field.textArea:SetPoint("BOTTOMRIGHT", field, "BOTTOMRIGHT", 0, 0)
    flatBackdrop(field.textArea, PALETTE.control, PALETTE.border)

    local scrollTemplate
    if not readOnly then
        scrollTemplate = "UIPanelScrollFrameTemplate"
    end
    field.scrollFrame = CreateFrame(
        "ScrollFrame",
        nil,
        field,
        scrollTemplate
    )
    field.scrollFrame:SetPoint("TOPLEFT", field.textArea, "TOPLEFT", 0, 0)
    field.scrollFrame:SetPoint(
        "BOTTOMRIGHT",
        field.textArea,
        "BOTTOMRIGHT",
        readOnly and 0 or -18,
        0
    )

    field.editBox = CreateFrame("EditBox", nil, field.scrollFrame)
    field.editBox:SetMultiLine(true)
    field.editBox:SetAutoFocus(false)
    field.editBox:SetFontObject("ChatFontNormal")
    field.editBox:SetJustifyH("LEFT")
    field.editBox:SetJustifyV("TOP")
    field.editBox:SetTextInsets(8, 8, 8, 8)
    field.editBox:SetWidth(370)
    field.editBox:SetHeight(math.max(44, height - 24))
    field.editBox:SetMaxLetters(limit)
    field.scrollFrame:SetScrollChild(field.editBox)

    field.characterCount = field:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    field.characterCount:SetPoint("BOTTOMRIGHT", field.textArea, "BOTTOMRIGHT", -7, 4)
    field.characterCount:SetText("0 / " .. limit)
    setTextColor(field.characterCount, PALETTE.secondary)
    field.characterCount:SetShown(readOnly ~= true)

    if readOnly then
        field.readOnlyOverlay = CreateFrame(
            "Frame",
            nil,
            field.textArea,
            "BackdropTemplate"
        )
        field.readOnlyOverlay:SetAllPoints(field.textArea)
        field.readOnlyOverlay:SetFrameLevel(field.scrollFrame:GetFrameLevel() + 2)
        field.readOnlyOverlay:SetBackdrop({ bgFile = WHITE_TEXTURE })
        field.readOnlyOverlay:SetBackdropColor(0.32, 0.34, 0.38, 0.05)
        if type(field.readOnlyOverlay.SetClipsChildren) == "function" then
            field.readOnlyOverlay:SetClipsChildren(true)
        end
        field.readOnlyOverlay:EnableMouse(true)
        field.readOnlyOverlay.stripes = {}
        for index = 1, 24 do
            local stripe = field.readOnlyOverlay:CreateTexture(nil, "OVERLAY")
            stripe:SetTexture(WHITE_TEXTURE)
            stripe:SetVertexColor(0.58, 0.6, 0.64, 0.1)
            stripe:SetSize(180, 5)
            stripe:SetPoint(
                "CENTER",
                field.readOnlyOverlay,
                "CENTER",
                -276 + ((index - 1) * 24),
                0
            )
            stripe:SetRotation(math.pi / 4)
            field.readOnlyOverlay.stripes[index] = stripe
        end
    end

    local function focusEditBox()
        if field.editBox:IsEnabled() then
            field.editBox:SetFocus()
        end
    end
    for _, surface in ipairs({ field.textArea, field.scrollFrame, field.editBox }) do
        surface:EnableMouse(true)
        surface:SetScript("OnMouseDown", focusEditBox)
    end
    field.editBox:SetScript("OnTextChanged", function(editBox)
        field.characterCount:SetText(
            characterCount(editBox:GetText()) .. " / " .. limit
        )
        if type(editBox.GetStringHeight) == "function" then
            editBox:SetHeight(math.max(height - 24, editBox:GetStringHeight() + 20))
        end
        if type(field.scrollFrame.UpdateScrollChildRect) == "function" then
            field.scrollFrame:UpdateScrollChildRect()
        end
        if not editor.settingState
            and type(RGMS.MainsAlts) == "table"
            and type(RGMS.MainsAlts.SetCharacterNoteDraft) == "function" then
            RGMS.MainsAlts.SetCharacterNoteDraft(key, editBox:GetText())
        end
    end)
    field.editBox:SetScript("OnEscapePressed", function()
        UI.CloseCharacterNoteEditor()
    end)
    return field
end

local function createNotesEditor(owner)
    local editor = CreateFrame(
        "Frame",
        "RGMSNotesEditor",
        UIParent,
        "BackdropTemplate"
    )
    editor:SetSize(440, 570)
    editor:SetPoint("TOPLEFT", owner, "TOPRIGHT", 20, 0)
    editor:SetFrameStrata("DIALOG")
    editor:SetToplevel(true)
    editor:EnableMouse(true)
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
    local shadow = editor:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow:SetTexture(WHITE_TEXTURE)
    shadow:SetPoint("TOPLEFT", editor, "TOPLEFT", -6, 6)
    shadow:SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", 6, -6)
    shadow:SetVertexColor(0, 0, 0, 0.45)
    editor.shadow = shadow

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

    editor.fields = {
        officerNote = createNoteField(
            editor,
            "officerNote",
            "Officer Note",
            -78,
            112,
            GUILD_NOTE_LIMIT,
            true
        ),
        publicNote = createNoteField(
            editor,
            "publicNote",
            "Public Note",
            -198,
            112,
            GUILD_NOTE_LIMIT,
            true
        ),
        privateNote = createNoteField(
            editor,
            "privateNote",
            "Private Note",
            -318,
            140,
            CHARACTER_NOTE_LIMIT,
            false
        ),
    }
    -- Retain the established private-field aliases for callers and layout tests.
    editor.textArea = editor.fields.privateNote.textArea
    editor.scrollFrame = editor.fields.privateNote.scrollFrame
    editor.editBox = editor.fields.privateNote.editBox
    editor.characterCount = editor.fields.privateNote.characterCount

    editor.status = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    editor.status:SetPoint("BOTTOMLEFT", editor, "BOTTOMLEFT", 20, 48)
    editor.status:SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -20, 48)
    editor.status:SetJustifyH("LEFT")
    setTextColor(editor.status, PALETTE.error)

    editor.guildOverlay = CreateFrame("Frame", nil, editor, "BackdropTemplate")
    editor.guildOverlay:SetPoint("TOPLEFT", editor.fields.officerNote, "TOPLEFT", 0, 0)
    editor.guildOverlay:SetPoint(
        "BOTTOMRIGHT",
        editor.fields.publicNote,
        "BOTTOMRIGHT",
        0,
        0
    )
    editor.guildOverlay:SetBackdrop({ bgFile = WHITE_TEXTURE })
    editor.guildOverlay:SetBackdropColor(0, 0, 0, 0.58)
    editor.guildOverlay:SetFrameLevel(editor:GetFrameLevel() + 10)
    editor.guildOverlay:EnableMouse(true)
    editor.guildOverlay.icon = editor.guildOverlay:CreateTexture(nil, "OVERLAY")
    editor.guildOverlay.icon:SetSize(22, 22)
    editor.guildOverlay.icon:SetPoint("CENTER", editor.guildOverlay, "CENTER", 0, 10)
    editor.guildOverlay.icon:SetTexture(LOADER_TEXTURE)
    editor.guildOverlay.message = editor.guildOverlay:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    editor.guildOverlay.message:SetPoint("TOP", editor.guildOverlay.icon, "BOTTOM", 0, -8)
    editor.guildOverlay:SetScript("OnUpdate", function(overlay, elapsed)
        if overlay.spinning then
            overlay.rotation = ((overlay.rotation or 0) + elapsed * 5)
                % (math.pi * 2)
            if type(overlay.icon.SetRotation) == "function" then
                overlay.icon:SetRotation(overlay.rotation)
            end
        end
    end)
    editor.guildOverlay:Hide()

    editor.operationOverlay = CreateFrame("Frame", nil, editor, "BackdropTemplate")
    editor.operationOverlay:SetAllPoints(editor)
    editor.operationOverlay:SetBackdrop({ bgFile = WHITE_TEXTURE })
    editor.operationOverlay:SetBackdropColor(0, 0, 0, 0.66)
    editor.operationOverlay:EnableMouse(true)
    editor.operationOverlay.icon = editor.operationOverlay:CreateTexture(nil, "OVERLAY")
    editor.operationOverlay.icon:SetSize(24, 24)
    editor.operationOverlay.icon:SetPoint("CENTER", editor.operationOverlay, "CENTER", 0, 8)
    editor.operationOverlay.icon:SetTexture(LOADER_TEXTURE)
    editor.operationOverlay.message = editor.operationOverlay:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    editor.operationOverlay.message:SetPoint("TOP", editor.operationOverlay.icon, "BOTTOM", 0, -8)
    editor.operationOverlay.message:SetText("Saving and verifying notes…")
    editor.operationOverlay:SetScript("OnUpdate", function(overlay, elapsed)
        overlay.rotation = ((overlay.rotation or 0) + elapsed * 5) % (math.pi * 2)
        if type(overlay.icon.SetRotation) == "function" then
            overlay.icon:SetRotation(overlay.rotation)
        end
    end)
    editor.operationOverlay:Hide()

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
        local saved, saveError = RGMS.MainsAlts.SaveCharacterNotes()
        if not saved and type(RGMS.Print) == "function" then
            RGMS.Print("Could not save character notes: "
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
        editor.model = nil
    end)
    enableWindowDragging(editor)
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

local function newsSetText(set)
    local lines = {}
    local function addMembers(members, formatter)
        for _, member in ipairs(members) do
            lines[#lines + 1] = formatter(member)
        end
    end
    addMembers(set.joiningMembers, function(member)
        return member .. " joined the guild."
    end)
    addMembers(set.leavingMembers, function(member)
        return member .. " left the guild."
    end)
    addMembers(set.rankChanges, function(change)
        return change.name .. "'s rank changed to " .. change.rankName .. "."
    end)
    return table.concat(lines, "\n"), #lines
end

local function acquireNewsBlock(newsWindow, index)
    local block = newsWindow.blocks[index]
    if block then
        return block
    end
    block = CreateFrame("Frame", nil, newsWindow.content)
    block.panel = CreateFrame("Frame", nil, block, "BackdropTemplate")
    block.panel:SetPoint("TOPLEFT", block, "TOPLEFT", 0, 0)
    block.panel:SetPoint("TOPRIGHT", block, "TOPRIGHT", 0, 0)
    flatBackdrop(block.panel, PALETTE.control, PALETTE.border)
    block.check = CreateFrame("Button", nil, block.panel, "BackdropTemplate")
    block.check:SetSize(24, 24)
    block.check:SetPoint("TOPRIGHT", block.panel, "TOPRIGHT", -10, -10)
    block.check:SetBackdrop(nil)
    block.check.circleFill = block.check:CreateTexture(
        nil,
        "BACKGROUND",
        nil,
        -1
    )
    block.check.circleFill:SetAllPoints(block.check)
    block.check.circleFill:SetTexture(CIRCLE_TEXTURE)
    setTextureColor(block.check.circleFill, PALETTE.control)
    block.check.icon = block.check:CreateTexture(nil, "ARTWORK")
    block.check.icon:SetSize(16, 16)
    block.check.icon:SetPoint("CENTER", block.check, "CENTER", 0, 0)
    block.check.icon:SetTexture(CHECK_TEXTURE)
    if type(block.check.icon.SetDesaturated) == "function" then
        block.check.icon:SetDesaturated(true)
    end
    block.check.icon:SetVertexColor(1, 0.82, 0.2, 1)

    block.text = block.panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    block.text:SetPoint("TOPLEFT", block.panel, "TOPLEFT", 12, -10)
    block.text:SetPoint("TOPRIGHT", block.panel, "TOPRIGHT", -48, -10)
    block.text:SetJustifyH("LEFT")
    block.text:SetJustifyV("TOP")
    setFont(block.text, FONT_REGULAR, 12)
    setTextColor(block.text, PALETTE.text)
    newsWindow.blocks[index] = block
    return block
end

local function renderNewsSets(newsWindow, newsSets)
    newsSets = type(newsSets) == "table" and newsSets or {}
    newsWindow.newsSets = newsSets
    local y = 0
    for index, set in ipairs(newsSets) do
        local block = acquireNewsBlock(newsWindow, index)
        local text, lineCount = newsSetText(set)
        local height = math.max(44, lineCount * 15 + 20)
        block:ClearAllPoints()
        block:SetPoint("TOPLEFT", newsWindow.content, "TOPLEFT", 0, -y)
        block:SetPoint("TOPRIGHT", newsWindow.content, "TOPRIGHT", 0, -y)
        block:SetHeight(height)
        block.panel:SetHeight(height)
        block.text:SetText(text)
        block.setId = set.id
        block.check:SetScript("OnClick", function()
            if UI.globalScanLocked then
                return
            end
            local acknowledged, acknowledgeError = RGMS.Roster.AcknowledgeNewsSet(
                block.setId
            )
            if not acknowledged and type(RGMS.Print) == "function" then
                RGMS.Print("Could not acknowledge roster news: "
                    .. tostring(acknowledgeError) .. ".")
            end
        end)
        block:Show()
        y = y + height + 10
    end
    for index = #newsSets + 1, #newsWindow.blocks do
        newsWindow.blocks[index]:Hide()
    end
    local contentHeight = math.max(1, y > 0 and y - 10 or 1)
    newsWindow.content:SetHeight(contentHeight)
    setScrollBarShown(newsWindow.scrollFrame, contentHeight > 332)
    if contentHeight <= 332 then
        newsWindow.scrollFrame:SetVerticalScroll(0)
    end
end

local function createNewsWindow(owner)
    local newsWindow = CreateFrame(
        "Frame",
        "RGMSNewsWindow",
        UIParent,
        "BackdropTemplate"
    )
    newsWindow:SetSize(400, 400)
    newsWindow:SetPoint("TOPLEFT", owner, "TOPRIGHT", 20, 0)
    newsWindow:SetFrameStrata("DIALOG")
    newsWindow:SetToplevel(true)
    newsWindow:EnableMouse(true)
    flatBackdrop(newsWindow, PALETTE.surface, PALETTE.border)
    local shadow = newsWindow:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow:SetTexture(WHITE_TEXTURE)
    shadow:SetPoint("TOPLEFT", newsWindow, "TOPLEFT", -6, 6)
    shadow:SetPoint("BOTTOMRIGHT", newsWindow, "BOTTOMRIGHT", 6, -6)
    shadow:SetVertexColor(0, 0, 0, 0.45)
    newsWindow.shadow = shadow

    newsWindow.title = newsWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    newsWindow.title:SetPoint("TOPLEFT", newsWindow, "TOPLEFT", 18, -17)
    newsWindow.title:SetText("News")
    setFont(newsWindow.title, FONT_SEMIBOLD, 13)
    setTextColor(newsWindow.title, PALETTE.text)

    newsWindow.closeButton = CreateFrame("Button", nil, newsWindow)
    newsWindow.closeButton:SetSize(32, 32)
    newsWindow.closeButton:SetPoint("TOPRIGHT", newsWindow, "TOPRIGHT", -8, -8)
    newsWindow.closeButton.icon = newsWindow.closeButton:CreateTexture(nil, "ARTWORK")
    newsWindow.closeButton.icon:SetAllPoints(newsWindow.closeButton)
    newsWindow.closeButton.icon:SetTexture(CLOSE_TEXTURE)
    newsWindow.closeButton:SetScript("OnClick", function()
        UI.CloseNews()
    end)

    newsWindow.scrollFrame = CreateFrame(
        "ScrollFrame",
        nil,
        newsWindow,
        "UIPanelScrollFrameTemplate"
    )
    newsWindow.scrollFrame:SetSize(394, 332)
    newsWindow.scrollFrame:SetPoint("TOPLEFT", newsWindow, "TOPLEFT", 3, -52)
    styleScrollFrame(newsWindow.scrollFrame)
    newsWindow.content = CreateFrame("Frame", nil, newsWindow.scrollFrame)
    newsWindow.content:SetSize(394, 1)
    newsWindow.scrollFrame:SetScrollChild(newsWindow.content)
    newsWindow.blocks = {}

    newsWindow.dimmer = CreateFrame("Frame", nil, newsWindow, "BackdropTemplate")
    newsWindow.dimmer:SetAllPoints(newsWindow)
    newsWindow.dimmer:SetFrameLevel(newsWindow:GetFrameLevel() + 100)
    newsWindow.dimmer:SetBackdrop({ bgFile = WHITE_TEXTURE })
    newsWindow.dimmer:SetBackdropColor(0, 0, 0, GLOBAL_DIMMER_ALPHA)
    newsWindow.dimmer:EnableMouse(true)
    newsWindow.dimmer.label = newsWindow.dimmer:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
    )
    newsWindow.dimmer.label:SetPoint("CENTER", newsWindow.dimmer, "CENTER", 0, 0)
    newsWindow.dimmer.label:SetText("Scanning...")
    setFont(newsWindow.dimmer.label, FONT_SEMIBOLD, 16)
    setTextColor(newsWindow.dimmer.label, PALETTE.text)
    newsWindow.dimmer:Hide()
    newsWindow:Hide()
    return newsWindow
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
    startWindowDrag = function()
        if UI.globalScanLocked == true then
            return
        end
        if type(RGMS.PortalState) == "table"
            and not RGMS.PortalState:canDrag() then
            return
        end
        UI.windowDragActive = true
        frame:StartMoving()
    end
    stopWindowDrag = function()
        if UI.windowDragActive ~= true then
            return
        end
        UI.windowDragActive = false
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
    windowDragRoot = frame
    enableWindowDragging(frame)
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

    frame.logoButton = CreateFrame("Button", nil, frame)
    frame.logoButton:SetSize(UI.GUILD_BADGE.size, UI.GUILD_BADGE.size)
    frame.logoButton:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        UI.GUILD_BADGE.x,
        UI.GUILD_BADGE.y
    )
    frame.logoButton:SetFrameLevel(header:GetFrameLevel() + 1)
    frame.logoRing = frame.logoButton:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.logoRing:SetAllPoints(frame.logoButton)
    frame.logoRing:SetTexture(CIRCLE_TEXTURE)
    setTextureColor(frame.logoRing, PALETTE.shell)
    frame.guildBackground = frame.logoButton:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.guildBackground:SetSize(UI.GUILD_BADGE.innerSize, UI.GUILD_BADGE.innerSize)
    frame.guildBackground:SetPoint("CENTER", frame.logoButton, "CENTER", 0, 0)
    frame.guildBackground:SetTexture(CIRCLE_TEXTURE)
    frame.guildEmblem = frame.logoButton:CreateTexture(nil, "OVERLAY", nil, 1)
    frame.guildEmblem:SetPoint("CENTER", frame.logoButton, "CENTER", 0, 0)
    frame.logo = frame.guildEmblem
    UI.RefreshGuildBadge(frame)
    frame.logoButton:SetScript("OnClick", function()
        UI.OpenNews()
    end)

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

    frame.tabs = {}
    frame.views = {}
    for index, tabId in ipairs(TAB_ORDER) do
        local tab = CreateFrame("Button", "RGMSMainFrameTab" .. index, sidebar, "BackdropTemplate")
        tab:SetID(index)
        tab:SetSize(120, 40)
        tab:SetPoint(
            "TOPLEFT",
            sidebar,
            "TOPLEFT",
            8,
            -UI.GUILD_BADGE.sidebarTop - (index - 1) * 40
        )
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
        if tabId == "roster" then
            frame.views.mainsalts = createView(frame, "mainsalts")
            frame.views.roster.byNameView = frame.views.mainsalts
            frame.views.roster.byTenureView = frame.views.roster
        end
    end

    frame.numTabs = #TAB_ORDER

    frame.globalDimmer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.globalDimmer:SetFrameLevel(
        frame:GetFrameLevel() + GLOBAL_DIMMER_FRAME_LEVEL_OFFSET
    )
    frame.globalDimmer:SetAllPoints(frame)
    frame.globalDimmer:SetBackdrop({ bgFile = WHITE_TEXTURE })
    frame.globalDimmer:SetBackdropColor(0, 0, 0, GLOBAL_DIMMER_ALPHA)
    frame.globalDimmer:EnableMouse(true)

    local scanNotice = CreateFrame("Frame", nil, frame.globalDimmer, "BackdropTemplate")
    scanNotice:SetFrameLevel(frame.globalDimmer:GetFrameLevel() + 1)
    scanNotice:SetSize(184, 56)
    scanNotice:SetPoint("CENTER", frame.globalDimmer, "CENTER", 0, 0)
    flatBackdrop(scanNotice, PALETTE.shell, PALETTE.pink)
    scanNotice.icon = scanNotice:CreateTexture(nil, "ARTWORK")
    scanNotice.icon:SetSize(24, 24)
    scanNotice.icon:SetPoint("LEFT", scanNotice, "LEFT", 20, 0)
    scanNotice.icon:SetTexture(LOADER_TEXTURE)
    scanNotice.icon:SetVertexColor(unpackColor(PALETTE.pink))
    scanNotice.label = scanNotice:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    scanNotice.label:SetPoint("LEFT", scanNotice.icon, "RIGHT", 10, 0)
    scanNotice.label:SetPoint("RIGHT", scanNotice, "RIGHT", -20, 0)
    scanNotice.label:SetJustifyH("LEFT")
    scanNotice.label:SetText("Scanning...")
    setFont(scanNotice.label, FONT_SEMIBOLD, 16)
    setTextColor(scanNotice.label, PALETTE.text)
    scanNotice.rotation = 0
    scanNotice:SetScript("OnUpdate", function(notice, elapsed)
        notice.rotation = (notice.rotation + elapsed * 5) % (math.pi * 2)
        if type(notice.icon.SetRotation) == "function" then
            notice.icon:SetRotation(notice.rotation)
        end
    end)
    frame.globalDimmer.notice = scanNotice
    frame.closeButtonBaseFrameLevel = frame.closeButton:GetFrameLevel()
    frame.globalDimmer:Hide()

    frame.modalDimmer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.modalDimmer:SetAllPoints(frame)
    frame.modalDimmer:SetBackdrop({ bgFile = WHITE_TEXTURE })
    frame.modalDimmer:SetBackdropColor(0, 0, 0, 0.5)
    frame.modalDimmer:EnableMouse(true)
    frame.modalDimmer:Hide()
    frame.notesEditor = createNotesEditor(frame)
    frame.newsWindow = createNewsWindow(frame)
    frame.ownedTooltip = createOwnedTooltip()

    frame:SetScript("OnShow", function()
        UI.ClampToScreen()
        refreshVisibleReport(frame.views[UI.selectedTab], UI.selectedTab)
    end)
    frame:SetScript("OnHide", function()
        local mainsAltsView = frame.views.mainsalts
        cancelMainsAltsScrollWork(mainsAltsView)
        clearMainsAltsFilters(mainsAltsView, false)
        mainsAltsView.mainsAltsSelections = {}
        if type(UI.CollapseMainsAltsGroups) == "function" then
            UI.CollapseMainsAltsGroups()
        end
        setMainsAltsScroll(mainsAltsView, 0)
        frame.views.roster.scrollFrame:SetVerticalScroll(0)
        frame.views.bank.scrollFrame:SetVerticalScroll(0)
        frame.views.tags.scrollFrame:SetVerticalScroll(0)
        if type(RGMS.PortalState) == "table" then
            RGMS.PortalState.rosterMode = "ByName"
        end
        UI.rosterMode = "ByName"
        UI.rosterScroll = { ByName = 0, ByTenure = 0 }
        UI.SelectPrimaryTab("roster")
        if type(RGMS.PortalState) == "table" then
            RGMS.PortalState:closeWindow()
        end
        if frame.notesEditor:IsShown() then
            UI.CloseCharacterNoteEditor()
        end
        if frame.newsWindow:IsShown() then
            UI.CloseNews()
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
    UI.rosterMode = "ByName"
    UI.rosterScroll = { ByName = 0, ByTenure = 0 }

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
    refreshScrollChild(UI.frame.views.mainsalts)

    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "RGMSMainFrame")
        table.insert(UISpecialFrames, "RGMSNotesEditor")
    end

    UI.eventFrame = CreateFrame("Frame")
    UI.eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    UI.eventFrame:RegisterEvent("UI_SCALE_CHANGED")
    UI.eventFrame:RegisterEvent("INITIAL_CLUBS_LOADED")
    UI.eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
    UI.eventFrame:SetScript("OnEvent", function(_, event)
        if event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
            UI.ClampToScreen()
        else
            UI.RefreshGuildBadge(UI.frame)
        end
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
    local previousTabId = UI.selectedTab
    if type(tabId) == "string" and string.lower(tabId) == "mainsalts" then
        tabId = "roster"
        if UI.frame then
            UI.SelectRosterMode("ByName")
        end
    end
    tabId = normalizeTabId(tabId)
    if not tabId then
        return nil, "primary tab must be roster, bank, or tags"
    end
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if UI.globalScanLocked == true and UI.frame:IsShown() then
        return nil, "scan-locked"
    end

    if UI.selectedTab and UI.frame.views[UI.selectedTab] then
        if UI.selectedTab == "roster" then
            setRosterModeScroll(
                activeRosterMode(),
                rosterModeView(activeRosterMode()).scrollFrame:GetVerticalScroll()
            )
        elseif type(RGMS.PortalState) == "table" then
            RGMS.PortalState.scroll[UI.selectedTab] = UI.frame.views[UI.selectedTab].scrollFrame:GetVerticalScroll()
        end
    end
    if type(RGMS.PortalState) == "table" then
        RGMS.PortalState.selectedView = tabId
    end

    for _, currentTabId in ipairs(TAB_ORDER) do
        local selected = currentTabId == tabId
        if currentTabId ~= "roster" then
            UI.frame.views[currentTabId]:SetShown(selected)
        end
    end
    local rosterSelected = tabId == "roster"
    local mode = activeRosterMode()
    UI.frame.views.roster:SetShown(rosterSelected and mode == "ByTenure")
    UI.frame.views.mainsalts:SetShown(rosterSelected and mode == "ByName")
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
    if tabId == "roster" and mode == "ByName" and previousTabId ~= "roster"
        and type(RGMS.MainsAlts) == "table"
        and type(RGMS.MainsAlts.RequestGuildNotes) == "function" then
        RGMS.MainsAlts.RequestGuildNotes()
    end
    local selectedView = tabId == "roster" and rosterModeView(mode)
        or UI.frame.views[tabId]
    if UI.frame:IsShown() then
        refreshVisibleReport(selectedView, tabId)
    end
    local savedScroll = tabId == "roster"
        and getRosterModeScroll(mode)
        or (type(RGMS.PortalState) == "table"
            and RGMS.PortalState.scroll[tabId]
            or selectedView.scrollFrame:GetVerticalScroll())
    if tabId == "roster" and mode == "ByName" then
        setMainsAltsScroll(selectedView, savedScroll or 0)
    else
        selectedView.scrollFrame:SetVerticalScroll(savedScroll or 0)
    end
    return true
end

function UI.SelectRosterMode(mode)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if mode ~= "ByName" and mode ~= "ByTenure" then
        return nil, "roster mode must be ByName or ByTenure"
    end
    if UI.frame.notesEditor:IsShown() then
        return nil, "modal-open"
    end
    if UI.globalScanLocked == true and UI.frame:IsShown() then
        return nil, "scan-locked"
    end

    local previousMode = activeRosterMode()
    local previousView = rosterModeView(previousMode)
    setRosterModeScroll(previousMode, previousView.scrollFrame:GetVerticalScroll())
    if type(RGMS.PortalState) == "table" then
        local selected, reason = RGMS.PortalState:selectRosterMode(mode)
        if not selected then
            return nil, reason
        end
    end
    UI.rosterMode = mode

    local byNameView = UI.frame.views.mainsalts
    if mode == "ByTenure" then
        UI.HideMainsAltsTagPreview()
        closeMainsAltsTagEditor(byNameView)
        closeMainsAltsTagFilter(byNameView)
        cancelMainsAltsScrollWork(byNameView)
    elseif type(RGMS.MainsAlts) == "table"
        and type(RGMS.MainsAlts.RequestGuildNotes) == "function" then
        RGMS.MainsAlts.RequestGuildNotes()
    end

    local rosterSelected = UI.selectedTab == "roster"
    UI.frame.views.roster:SetShown(rosterSelected and mode == "ByTenure")
    byNameView:SetShown(rosterSelected and mode == "ByName")
    local selectedView = rosterModeView(mode)
    local savedScroll = getRosterModeScroll(mode)
    if mode == "ByName" then
        setMainsAltsScroll(selectedView, savedScroll)
    else
        refreshVisibleReport(selectedView, "roster")
        selectedView.scrollFrame:SetVerticalScroll(savedScroll)
    end
    updateRosterModeControls()
    return true
end

function UI.SetViewContent(tabId, content)
    tabId = normalizeTabId(tabId)
    if not tabId then
        return nil, "primary tab must be roster, bank, or tags"
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
        local byNameView = UI.frame.views.mainsalts
        cancelMainsAltsScrollWork(byNameView)
        closeMainsAltsTagEditor(byNameView)
        closeMainsAltsTagFilter(byNameView)
        hideMainsAltsLines(byNameView)
        byNameView.text:Show()
        byNameView.text:SetText(tostring(content or ""))
        byNameView.scrollFrame:SetVerticalScroll(0)
        refreshScrollChild(byNameView)
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
    elseif tabId == "tags" then
        hideTagManagementRows(view)
        if view.tagHeader then
            view.tagHeader.frame:Hide()
        end
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
        return nil, "primary tab must be roster, mainsalts, bank, or tags"
    end
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local value = tostring(status or "")
    UI.frame.views[tabId].status:SetText(value)
    if tabId == "roster" then
        UI.frame.views.mainsalts.status:SetText(value)
    elseif tabId == "mainsalts" then
        UI.frame.views.roster.status:SetText(value)
    end
    return true
end

function UI.SetTagsReport(report)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(report) ~= "table" or type(report.rows) ~= "table" then
        return nil, "tag report must contain rows"
    end

    local view = UI.frame.views.tags
    view.tagReport = report
    renderTagManagement(view, report)
    return true
end

local function ensureTagDeleteDialog()
    if type(StaticPopupDialogs) ~= "table" then
        return false
    end
    if StaticPopupDialogs[TAG_DELETE_DIALOG_KEY] == nil then
        StaticPopupDialogs[TAG_DELETE_DIALOG_KEY] = {
            text = "%s",
            button1 = ACCEPT,
            button2 = CANCEL,
            OnAccept = function(_, request)
                local deleted, deleteError
                if type(RGMS.MainsAlts) == "table"
                    and type(RGMS.MainsAlts.DeleteTag) == "function" then
                    deleted, deleteError = RGMS.MainsAlts.DeleteTag(request.name)
                else
                    deleteError = "character tag deletion is unavailable"
                end
                if not deleted and type(RGMS.Print) == "function" then
                    RGMS.Print(
                        "Could not delete tag '" .. tostring(request.name)
                            .. "': " .. tostring(deleteError) .. "."
                    )
                end
            end,
            OnCancel = function() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    return true
end

function UI.RequestTagDeletion(row)
    if type(row) ~= "table" or type(row.name) ~= "string" or row.name == "" then
        return nil, "tag deletion requires a tag row"
    end
    if row.immutable then
        return nil, "the me tag is immutable"
    end
    if UI.globalScanLocked == true then
        return nil, "scan-locked"
    end
    if not ensureTagDeleteDialog() or type(StaticPopup_Show) ~= "function" then
        return nil, "tag deletion confirmation is unavailable"
    end

    local count = tonumber(row.characterCount) or 0
    local message = "Delete tag '" .. row.name .. "'? This will remove it from "
        .. tostring(count) .. (count == 1 and " character" or " characters")
        .. " and cannot be undone."
    local request = { name = row.name }
    local popup = StaticPopup_Show(
        TAG_DELETE_DIALOG_KEY,
        message,
        nil,
        request
    )
    if not popup and type(RGMS.Print) == "function" then
        RGMS.Print(
            "Could not open the deletion confirmation for tag '"
                .. row.name .. "'. No data was changed."
        )
        return nil, "tag deletion confirmation could not be opened"
    end
    return popup
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

    if type(RGMS.MainsAlts) ~= "table"
        or type(RGMS.MainsAlts.OpenCharacterNotes) ~= "function" then
        return nil, "live guild notes are unavailable"
    end
    local model, modelError = RGMS.MainsAlts.OpenCharacterNotes(
        identity,
        displayName,
        note
    )
    if not model then
        if type(RGMS.PortalState) == "table" then
            RGMS.PortalState:closeNote()
        end
        return nil, modelError
    end
    local editor = UI.frame.notesEditor
    UI.CloseNews()
    editor.characterIdentity = identity
    editor.displayName = displayName
    editor.character:SetText("Editing notes for " .. displayName)
    UI.SetCharacterNoteState(model)
    editor:Show()
    UI.frame.modalDimmer:Show()
    editor.editBox:SetFocus()
    return true
end

function UI.CloseCharacterNoteEditor(skipController)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if not skipController
        and type(RGMS.MainsAlts) == "table"
        and type(RGMS.MainsAlts.CloseCharacterNotes) == "function" then
        RGMS.MainsAlts.CloseCharacterNotes()
    end
    UI.frame.notesEditor:Hide()
    UI.frame.modalDimmer:Hide()
    if type(RGMS.PortalState) == "table" then
        RGMS.PortalState:closeNote()
    end
    return true
end

function UI.SetCharacterNoteState(model)
    if not UI.frame or type(model) ~= "table" then
        return nil, "character note state is unavailable"
    end
    local editor = UI.frame.notesEditor
    editor.model = model
    editor.characterIdentity = model.identity
    editor.displayName = model.displayName
    editor.character:SetText("Editing notes for " .. model.displayName)
    editor.settingState = true
    for key, field in pairs(editor.fields) do
        local value = type(model.drafts) == "table" and model.drafts[key] or ""
        if field.editBox:GetText() ~= value then
            field.editBox:SetText(value)
            field.editBox:SetCursorPosition(0)
        end
    end
    editor.settingState = false

    local fieldY = -78
    local function positionField(field)
        field:ClearAllPoints()
        field:SetPoint("TOPLEFT", editor, "TOPLEFT", 20, fieldY)
        field:SetPoint("TOPRIGHT", editor, "TOPRIGHT", -20, fieldY)
        fieldY = fieldY - field:GetHeight() - 8
    end
    editor.fields.officerNote:SetShown(model.officerVisible == true)
    if model.officerVisible then
        positionField(editor.fields.officerNote)
    end
    editor.fields.publicNote:SetShown(model.publicVisible == true)
    if model.publicVisible then
        positionField(editor.fields.publicNote)
    end
    editor.fields.privateNote:Show()
    positionField(editor.fields.privateNote)
    editor:SetHeight(330
        + (model.publicVisible and 120 or 0)
        + (model.officerVisible and 120 or 0))

    editor.guildOverlay:ClearAllPoints()
    editor.guildOverlay:SetPoint(
        "TOPLEFT",
        model.officerVisible and editor.fields.officerNote
            or editor.fields.publicNote,
        "TOPLEFT",
        0,
        0
    )
    editor.guildOverlay:SetPoint(
        "BOTTOMRIGHT",
        editor.fields.publicNote,
        "BOTTOMRIGHT",
        0,
        0
    )

    setEditBoxEnabled(editor.fields.privateNote.editBox, not model.saving)
    setEditBoxEnabled(editor.fields.publicNote.editBox,
        model.publicEditable == true and not model.loading and not model.saving)
    setEditBoxEnabled(editor.fields.officerNote.editBox,
        model.officerEditable == true and not model.loading and not model.saving)
    editor.saveButton:SetEnabled(model.saveEnabled == true)
    editor.cancelButton:SetEnabled(not model.saving)
    editor.closeButton:SetEnabled(true)

    local status = model.error or ""
    if model.status == "failed" and model.confirmed then
        status = status
            .. " Latest confirmed Public: “" .. tostring(model.confirmed.publicNote or "")
            .. "”."
        if model.officerVisible then
            status = status
                .. " Officer: “" .. tostring(model.confirmed.officerNote or "") .. "”."
        end
    end
    editor.status:SetText(status)

    editor.guildOverlay:SetShown(model.loading or model.loadFailed)
    editor.guildOverlay.spinning = model.loading == true
    editor.guildOverlay.icon:SetShown(model.loading == true)
    editor.guildOverlay.message:SetText(
        model.loadFailed and "Unable to load guild notes" or "Loading guild notes…"
    )
    editor.operationOverlay:SetShown(model.saving == true)
    if model.saving then
        editor.operationOverlay:SetFrameLevel(editor:GetFrameLevel() + 20)
        editor.closeButton:SetFrameLevel(editor:GetFrameLevel() + 22)
    end
    return true
end

function UI.SetMainsAltsReport(report)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(report) ~= "table" or type(report.rows) ~= "table" then
        return nil, "ByName report must contain rows"
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
        UI.CloseCharacterNoteEditor()
    end
    applyMainsAltsSearch(view, false, true)
    return true
end

function UI.CompleteRosterScan(newsCreated)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    local view = UI.frame.views.mainsalts
    view.mainsAltsSelections = {}
    if type(view.mainsAltsReport) == "table" then
        renderMainsAlts(view)
    end
    UI.SetNewsSets(type(RGMS.DB) == "table" and RGMS.DB.newsSets or {})
    if newsCreated == true and UI.frame:IsShown() then
        UI.OpenNews()
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
        return nil, "Roster controls are disabled"
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
        return nil, "Roster group is unavailable"
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
                and RGMS.Portal.bankTimestamp(view.bankReport.scannedAtText)
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

updateRosterModeControls = function()
    if not UI.frame then
        return
    end
    local byTenure = UI.frame.views.roster
    local byName = UI.frame.views.mainsalts
    local enabled = UI.dataEnabled ~= false
        and UI.globalScanLocked ~= true
        and byTenure.rosterAvailable ~= false
        and byName.mainsAltsAvailable ~= false
        and byTenure.rosterScanInProgress ~= true
        and byName.mainsAltsScanInProgress ~= true
    local checked = activeRosterMode() == "ByTenure"
    for _, view in ipairs({ byName, byTenure }) do
        local checkbox = view.byRankCheckbox
        checkbox:SetEnabled(enabled)
        checkbox:SetChecked(checked)
        checkbox.check:SetShown(checked)
        if type(checkbox.SetAlpha) == "function" then
            checkbox:SetAlpha(enabled and 1 or 0.5)
        end
    end
end

function UI.SetGlobalScanLock(locked)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    UI.globalScanLocked = locked == true
    UI.frame.globalDimmer:SetShown(UI.globalScanLocked)
    UI.frame.newsWindow.dimmer:SetShown(UI.globalScanLocked)
    UI.frame.closeButton:SetFrameLevel(
        UI.globalScanLocked
            and UI.frame.globalDimmer:GetFrameLevel() + 2
            or UI.frame.closeButtonBaseFrameLevel
    )
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
    for _, tabId in ipairs(ALL_VIEW_IDS) do
        local view = UI.frame.views[tabId]
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
        for _, line in ipairs(view.tagRows or {}) do
            updateTagDeleteButton(line)
        end
    end
    updateRosterRefreshButton(UI.frame.views.roster)
    updateRosterRefreshButton(UI.frame.views.mainsalts)
    updateBankRefreshButton(UI.frame.views.bank)
    updateMainsAltsControlState(UI.frame.views.mainsalts)
    updateRosterModeControls()
    return true
end

function UI.SetRosterScanInProgress(inProgress)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.roster
    view.rosterScanInProgress = inProgress == true
    setRefreshButtonEnabled(
        view.refreshButton,
        UI.dataEnabled ~= false
            and view.rosterAvailable ~= false
            and not view.rosterScanInProgress
    )
    local mainsAltsView = UI.frame.views.mainsalts
    mainsAltsView.rosterScanInProgress = inProgress == true
    mainsAltsView.mainsAltsScanInProgress = inProgress == true
    if inProgress == true then
        cancelMainsAltsScrollWork(mainsAltsView)
    end
    updateMainsAltsControlState(mainsAltsView)
    UI.SetGlobalScanLock(
        view.rosterScanInProgress
            or UI.frame.views.bank.bankScanInProgress == true
    )
    updateRosterRefreshButton(mainsAltsView)
    updateRosterModeControls()
    return true
end

updateBankRefreshButton = function(view)
    setRefreshButtonEnabled(
        view.refreshButton,
        UI.dataEnabled ~= false
            and UI.globalScanLocked ~= true
            and view.bankOpen == true
            and view.bankScanInProgress ~= true
    )
end

updateRosterRefreshButton = function(view)
    setRefreshButtonEnabled(
        view.refreshButton,
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
    local byNameView = UI.frame.views.mainsalts
    byNameView.rosterAvailable = isAvailable == true
    updateRosterRefreshButton(byNameView)
    updateRosterModeControls()
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
    updateRosterModeControls()
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
    updateRosterRefreshButton(UI.frame.views.mainsalts)
    updateBankRefreshButton(UI.frame.views.bank)
    updateMainsAltsControlState(UI.frame.views.mainsalts)
    updateRosterModeControls()
    for _, line in ipairs(UI.frame.views.tags.tagRows or {}) do
        updateTagDeleteButton(line)
    end

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
    local hasTitle = type(title) == "string" and title ~= ""
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
    tooltip:SetHeight(math.max(
        44,
        tooltip.body:GetStringHeight() + (hasTitle and 34 or 16)
    ))
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
    UI.SetNewsSets(type(RGMS.DB) == "table" and RGMS.DB.newsSets or {})
    if not wasShown and type(RGMS.DB) == "table"
        and type(RGMS.DB.newsSets) == "table"
        and #RGMS.DB.newsSets > 0 then
        UI.OpenNews()
    end
    if not wasShown and type(RGMS.MainsAlts) == "table"
        and type(RGMS.MainsAlts.RequestGuildNotes) == "function" then
        RGMS.MainsAlts.RequestGuildNotes()
    end
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

function UI.SetNewsSets(newsSets)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    renderNewsSets(UI.frame.newsWindow, newsSets)
    return true
end

function UI.OpenNews()
    if not UI.frame then
        local initialized, initializeError = UI.Initialize()
        if not initialized then
            return nil, initializeError
        end
    end
    if UI.frame.notesEditor:IsShown() then
        UI.CloseCharacterNoteEditor()
    end
    UI.SetNewsSets(type(RGMS.DB) == "table" and RGMS.DB.newsSets or {})
    UI.frame.newsWindow:ClearAllPoints()
    UI.frame.newsWindow:SetPoint("TOPLEFT", UI.frame, "TOPRIGHT", 20, 0)
    UI.frame.newsWindow:Show()
    return true
end

function UI.CloseNews()
    if not UI.frame then
        return true
    end
    UI.frame.newsWindow:Hide()
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
