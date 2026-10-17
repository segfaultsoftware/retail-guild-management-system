local _, RGMS = ...

local UI = RGMS.UI or {}

local TAB_ORDER = { "roster", "mainsalts", "bank" }
local TAB_TITLES = {
    roster = "Roster",
    mainsalts = "Mains/Alts",
    bank = "Bank",
}

local INITIAL_COPY = {
    roster = "No roster data yet",
    mainsalts = "No roster data yet",
    bank = "No bank scan yet",
}

local RANK_TAB_WIDTH = 242
local RANK_TAB_HEIGHT = 24
local RANK_TAB_GAP = 3
local ROSTER_CONTENT_GAP = 24
local BANK_TAB_WIDTH = 200
local BANK_CONTENT_GAP = 18
local BANK_TAB_HEIGHT = 28
local BANK_TAB_GAP = 3
local BANK_ROW_HEIGHT = 22
local BANK_ICON_SIZE = 18
local BANK_HEADER_HEIGHT = 22
local BANK_TITLE_HEIGHT = 24
local ROSTER_TITLE_HEIGHT = 26
local ROSTER_GROUP_HEIGHT = 22
local ROSTER_ROW_HEIGHT = 20
local ROSTER_GROUP_GAP = 8
local MAINS_ALTS_ROW_HEIGHT = 24
local MAINS_ALTS_CHECKBOX_SIZE = 22
local MAINS_ALTS_ALT_INDENT = 48
local MAINS_ALTS_EXPAND_WIDTH = 28
local MISSING_WARNING_SIZE = 16
local MISSING_WARNING_GAP = 4
local MISSING_WARNING_TEXTURE = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"

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

    for _, line in ipairs(view.rosterLines) do
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

    local tabWidth = 92
    local slotWidth = 38
    local countWidth = 48
    local stableWidth = 88
    local ageWidth = 60
    local itemWidth = math.max(
        120,
        availableWidth - tabWidth - slotWidth - countWidth - stableWidth - ageWidth
    )
    local usedWidth = itemWidth + tabWidth + slotWidth + countWidth + stableWidth + ageWidth
    if usedWidth > availableWidth then
        itemWidth = math.max(1, itemWidth - (usedWidth - availableWidth))
    end

    local function positionColumns(line)
        line.frame:SetWidth(availableWidth)
        for _, field in ipairs({ "item", "tab", "slot", "count", "stable", "age" }) do
            if line[field] then
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
                BANK_ICON_SIZE + 4,
                0
            )
            line.item:SetWidth(math.max(1, itemWidth - BANK_ICON_SIZE - 6))
        else
            line.item:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
            line.item:SetWidth(itemWidth)
        end
        line.tab:SetPoint("LEFT", line.frame, "LEFT", itemWidth, 0)
        line.tab:SetWidth(tabWidth)
        line.slot:SetPoint("LEFT", line.frame, "LEFT", itemWidth + tabWidth, 0)
        line.slot:SetWidth(slotWidth)
        line.count:SetPoint(
            "LEFT",
            line.frame,
            "LEFT",
            itemWidth + tabWidth + slotWidth,
            0
        )
        line.count:SetWidth(countWidth)
        line.stable:SetPoint(
            "LEFT",
            line.frame,
            "LEFT",
            itemWidth + tabWidth + slotWidth + countWidth,
            0
        )
        line.stable:SetWidth(stableWidth)
        line.age:SetPoint(
            "LEFT",
            line.frame,
            "LEFT",
            itemWidth + tabWidth + slotWidth + countWidth + stableWidth,
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
    if type(view.mainsAltsLines) ~= "table" then
        return
    end

    for _, line in ipairs(view.mainsAltsLines) do
        line.frame:SetWidth(availableWidth)
        line.checkbox:ClearAllPoints()
        line.name:ClearAllPoints()
        line.expandButton:ClearAllPoints()
        if line.isAlt then
            line.name:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                MAINS_ALTS_ALT_INDENT,
                0
            )
            line.name:SetWidth(math.max(1, availableWidth - MAINS_ALTS_ALT_INDENT))
        else
            line.checkbox:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
            line.name:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                MAINS_ALTS_CHECKBOX_SIZE + 4,
                0
            )
            line.name:SetWidth(math.max(
                1,
                availableWidth
                    - MAINS_ALTS_CHECKBOX_SIZE
                    - MAINS_ALTS_EXPAND_WIDTH
                    - 12
            ))
            line.expandButton:SetPoint("RIGHT", line.frame, "RIGHT", -2, 0)
        end
    end
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

local function hideRosterLines(view)
    for _, line in ipairs(view.rosterLines or {}) do
        hideTooltipIfOwned(line.warningIndicator)
        line.frame:Hide()
    end
    view.rosterTableHeight = nil
end

local function acquireRosterLine(view, index)
    local line = view.rosterLines[index]
    if line then
        return line
    end

    local frame = CreateFrame("Frame", nil, view.scrollChild)
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
    tertiary:SetJustifyH("LEFT")
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
        primary = primary,
        secondary = secondary,
        tertiary = tertiary,
        warningIndicator = warningIndicator,
    }
    warningIndicator:SetScript("OnEnter", function()
        if line.missingLastSeenDate == nil then
            return
        end
        GameTooltip:SetOwner(warningIndicator, "ANCHOR_RIGHT")
        GameTooltip:SetText("Missing roster member", 1, 0.82, 0)
        GameTooltip:AddLine(
            "Not found in the current successful roster snapshot.",
            1,
            1,
            1,
            true
        )
        GameTooltip:AddLine(
            "Last appeared (Pacific): " .. line.missingLastSeenDate,
            1,
            1,
            1,
            true
        )
        GameTooltip:Show()
    end)
    warningIndicator:SetScript("OnLeave", function()
        hideTooltipIfOwned(warningIndicator)
    end)
    view.rosterLines[index] = line
    return line
end

local function renderRosterRank(view, rank)
    view.text:Hide()
    local lineIndex = 0
    local offset = 4

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
            hideTooltipIfOwned(line.warningIndicator)
        end
        line.warningIndicator:SetShown(line.missingLastSeenDate ~= nil)
        line.frame:ClearAllPoints()
        line.frame:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
        line.frame:SetHeight(height)
        line.primary:SetText(primary or "")
        line.secondary:SetText(secondary or "")
        line.tertiary:SetText(tertiary or "")
        line.frame:Show()
        offset = offset + height
    end

    addLine(ROSTER_TITLE_HEIGHT, "|cffffd100" .. rank.name .. "|r")
    for groupIndex, group in ipairs(rank.groups) do
        addLine(ROSTER_GROUP_HEIGHT, "|cffffd100" .. group.title .. "|r")
        if #group.members == 0 then
            addLine(
                ROSTER_ROW_HEIGHT,
                "|cff888888" .. group.emptyText .. "|r"
            )
        else
            addLine(
                ROSTER_ROW_HEIGHT,
                "|cffaaaaaaName-Realm|r",
                "|cffaaaaaaLast online|r",
                "|cffaaaaaaRank tenure|r",
                true
            )
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
        hideTooltipIfOwned(view.rosterLines[index].warningIndicator)
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
        and view.mainsAltsAvailable ~= false
        and view.mainsAltsScanInProgress ~= true
end

local function hideMainsAltsLines(view)
    for _, line in ipairs(view.mainsAltsLines or {}) do
        line.frame:Hide()
    end
    view.mainsAltsTableHeight = nil
end

local function updateMainsAltsControlState(view)
    local enabled = mainsAltsControlsEnabled(view)
    local selectionCount = 0
    local selectedGroupCount = 0
    for _, row in ipairs(
        type(view.mainsAltsReport) == "table" and view.mainsAltsReport.rows or {}
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
    for _, line in ipairs(view.mainsAltsLines or {}) do
        if line.frame:IsShown() then
            line.checkbox:SetEnabled(enabled and not line.isAlt)
            line.expandButton:SetEnabled(enabled and line.hasAlts)
        end
    end
end

local function acquireMainsAltsLine(view, index)
    local line = view.mainsAltsLines[index]
    if line then
        return line
    end

    local frame = CreateFrame("Frame", nil, view.scrollChild)
    local checkbox = CreateFrame(
        "CheckButton",
        nil,
        frame,
        "UICheckButtonTemplate"
    )
    checkbox:SetSize(MAINS_ALTS_CHECKBOX_SIZE, MAINS_ALTS_CHECKBOX_SIZE)
    local name = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    name:SetJustifyH("LEFT")
    name:SetJustifyV("MIDDLE")
    if type(name.SetWordWrap) == "function" then
        name:SetWordWrap(false)
    end
    local expandButton = CreateFrame(
        "Button",
        nil,
        frame,
        "UIPanelButtonTemplate"
    )
    expandButton:SetSize(MAINS_ALTS_EXPAND_WIDTH, 20)
    line = {
        frame = frame,
        checkbox = checkbox,
        name = name,
        expandButton = expandButton,
    }
    view.mainsAltsLines[index] = line
    return line
end

local function renderMainsAlts(view)
    hideMainsAltsLines(view)
    view.text:Hide()
    local lineIndex = 0
    local offset = 4

    local function addLine(character, isAlt)
        lineIndex = lineIndex + 1
        local line = acquireMainsAltsLine(view, lineIndex)
        line.isAlt = isAlt == true
        line.hasAlts = not line.isAlt and character.altCount > 0
        line.identity = character.identity
        line.frame:ClearAllPoints()
        line.frame:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
        line.frame:SetHeight(MAINS_ALTS_ROW_HEIGHT)

        if line.isAlt then
            line.checkbox:Hide()
            line.expandButton:Hide()
            line.name:SetText(character.displayName)
        else
            line.checkbox:SetChecked(
                view.mainsAltsSelections[character.identity] == true
            )
            line.checkbox:SetScript("OnClick", function(button)
                view.mainsAltsSelections[character.identity] = button:GetChecked()
                    == true
                updateMainsAltsControlState(view)
            end)
            line.checkbox:Show()
            if line.hasAlts then
                line.name:SetText(string.format(
                    "%s (+%d)",
                    character.displayName,
                    character.altCount
                ))
                local expanded = view.expandedMainsAlts[character.identity] == true
                line.expandButton:SetText(expanded and "-" or "+")
                line.expandButton:SetScript("OnClick", function()
                    UI.ToggleMainsAltsGroup(character.identity)
                end)
                line.expandButton:Show()
            else
                line.name:SetText(character.displayName)
                line.expandButton:Hide()
            end
        end
        line.frame:Show()
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

    for index = lineIndex + 1, #view.mainsAltsLines do
        view.mainsAltsLines[index].frame:Hide()
    end
    view.mainsAltsTableHeight = offset + 4
    view.scrollFrame:SetVerticalScroll(0)
    updateMainsAltsControlState(view)
    refreshScrollChild(view)
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
    local frame = CreateFrame("Frame", nil, view.scrollChild)
    local header = {
        frame = frame,
        item = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        tab = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        slot = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        count = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        stable = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        age = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
    }
    for _, field in ipairs({ "item", "tab", "slot", "count", "stable", "age" }) do
        configureBankText(header[field])
    end
    header.item:SetText("Item")
    header.tab:SetText("Tab")
    header.slot:SetText("Slot")
    header.count:SetText("Count")
    header.stable:SetText("Stable since")
    header.age:SetText("Age")
    view.bankHeader = header
    return header
end

local function acquireBankLine(view, index)
    local line = view.bankRows[index]
    if line then
        return line
    end

    local frame = CreateFrame("Frame", nil, view.scrollChild)
    local itemButton = CreateFrame("Button", nil, frame)
    local itemIcon = itemButton:CreateTexture(nil, "ARTWORK")
    itemIcon:SetSize(BANK_ICON_SIZE, BANK_ICON_SIZE)
    local item = itemButton:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local tab = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local slot = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local count = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local stable = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local age = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    line = {
        frame = frame,
        itemButton = itemButton,
        itemIcon = itemIcon,
        item = item,
        tab = tab,
        slot = slot,
        count = count,
        stable = stable,
        age = age,
    }
    for _, field in ipairs({ "item", "tab", "slot", "count", "stable", "age" }) do
        configureBankText(line[field])
    end
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
    view.bankTitle:Show()
    view.bankMessage:Show()

    local timestampText = tab.lastAccessibleText
        and ("Last accessible: " .. tab.lastAccessibleText)
        or "No successful access yet"
    view.bankTitle:SetText(timestampText)
    view.bankTitle:ClearAllPoints()
    view.bankTitle:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -4)

    local offset = 4 + BANK_TITLE_HEIGHT
    if not tab.isViewable then
        view.bankMessage:SetText("|cffff5555No access|r")
        view.bankMessage:ClearAllPoints()
        view.bankMessage:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
        offset = offset + BANK_ROW_HEIGHT
    elseif #tab.rows == 0 then
        view.bankMessage:SetText("|cff888888No occupied slots|r")
        view.bankMessage:ClearAllPoints()
        view.bankMessage:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
        offset = offset + BANK_ROW_HEIGHT
    else
        view.bankMessage:Hide()
        local header = view.bankHeader or createBankHeader(view)
        header.frame:ClearAllPoints()
        header.frame:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
        header.frame:SetHeight(BANK_HEADER_HEIGHT)
        header.frame:Show()
        offset = offset + BANK_HEADER_HEIGHT

        for index, row in ipairs(tab.rows) do
            local line = acquireBankLine(view, index)
            line.itemLink = row.itemLink
            line.frame:ClearAllPoints()
            line.frame:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
            line.frame:SetHeight(BANK_ROW_HEIGHT)
            line.itemIcon:SetTexture(row.icon)
            line.item:SetText(row.itemName)
            line.tab:SetText(row.tabName)
            line.slot:SetText(tostring(row.slotIndex))
            line.count:SetText(tostring(row.quantity))
            line.stable:SetText(row.stableSinceDate)
            local ageLabel = row.ageDays == 1 and "1 day" or (row.ageDays .. " days")
            if row.isStale then
                ageLabel = "|cffff5555" .. ageLabel .. "|r"
            end
            line.age:SetText(ageLabel)
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

local function createView(parent, tabId)
    local view = CreateFrame("Frame", nil, parent)
    view:SetPoint("TOPLEFT", 18, -92)
    view:SetPoint("BOTTOMRIGHT", -38, 18)

    view.status = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.status:SetPoint("TOPLEFT", 2, 0)
    view.status:SetPoint("TOPRIGHT", tabId == "mainsalts" and -104 or -94, 0)
    view.status:SetJustifyH("LEFT")
    view.status:SetText(INITIAL_COPY[tabId])

    if tabId == "roster" or tabId == "bank" then
        view.refreshButton = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
        view.refreshButton:SetSize(84, 22)
        view.refreshButton:SetPoint("TOPRIGHT", 0, 4)
        view.refreshButton:SetText("Refresh")
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
        view.rankScrollFrame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -24)
        view.rankScrollFrame:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
        view.rankScrollFrame:SetWidth(RANK_TAB_WIDTH)

        view.rankScrollChild = CreateFrame("Frame", nil, view.rankScrollFrame)
        view.rankScrollChild:SetSize(RANK_TAB_WIDTH - 22, 1)
        view.rankScrollFrame:SetScrollChild(view.rankScrollChild)
        view.rankButtons = {}
        view.rosterLines = {}
        view.rankScrollFrame:SetScript("OnSizeChanged", function()
            refreshRankScrollChild(view)
        end)
    elseif tabId == "mainsalts" then
        view.mainsAltsAvailable = true
        view.mainsAltsScanInProgress = false
        view.mainsAltsLines = {}
        view.mainsAltsSelections = {}
        view.expandedMainsAlts = {}
        view.groupButton = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
        view.groupButton:SetSize(94, 22)
        view.groupButton:SetPoint("TOPRIGHT", 0, 4)
        view.groupButton:SetText("Group Toons")
        view.groupButton:SetEnabled(false)
        view.groupButton:SetScript("OnClick", function()
            local selectedIdentities = {}
            for _, row in ipairs(view.mainsAltsReport and view.mainsAltsReport.rows or {}) do
                if view.mainsAltsSelections[row.identity] == true then
                    selectedIdentities[#selectedIdentities + 1] = row.identity
                end
            end
            local grouped, groupError = RGMS.MainsAlts.GroupSelected(selectedIdentities)
            if not grouped and type(RGMS.Print) == "function" then
                RGMS.Print("Could not group characters: " .. tostring(groupError) .. ".")
            end
        end)
    elseif tabId == "bank" then
        view.bankTabScrollFrame = CreateFrame(
            "ScrollFrame",
            nil,
            view,
            "UIPanelScrollFrameTemplate"
        )
        view.bankTabScrollFrame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -24)
        view.bankTabScrollFrame:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
        view.bankTabScrollFrame:SetWidth(BANK_TAB_WIDTH)

        view.bankTabScrollChild = CreateFrame("Frame", nil, view.bankTabScrollFrame)
        view.bankTabScrollChild:SetSize(BANK_TAB_WIDTH - 22, 1)
        view.bankTabScrollFrame:SetScrollChild(view.bankTabScrollChild)
        view.bankTabButtons = {}
        view.bankRows = {}
        view.bankTabScrollFrame:SetScript("OnSizeChanged", function()
            refreshBankTabScrollChild(view)
        end)
    end

    view.scrollFrame = CreateFrame("ScrollFrame", nil, view, "UIPanelScrollFrameTemplate")
    if tabId == "roster" then
        view.scrollFrame:SetPoint(
            "TOPLEFT",
            view,
            "TOPLEFT",
            RANK_TAB_WIDTH + ROSTER_CONTENT_GAP,
            -24
        )
    elseif tabId == "bank" then
        view.scrollFrame:SetPoint(
            "TOPLEFT",
            view,
            "TOPLEFT",
            BANK_TAB_WIDTH + BANK_CONTENT_GAP,
            -24
        )
    else
        view.scrollFrame:SetPoint("TOPLEFT", 0, -24)
    end
    view.scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)

    view.scrollChild = CreateFrame("Frame", nil, view.scrollFrame)
    view.scrollChild:SetSize(1, 1)
    view.scrollFrame:SetScrollChild(view.scrollChild)

    view.text = view.scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    view.text:SetPoint("TOPLEFT", 4, -4)
    view.text:SetJustifyH("LEFT")
    view.text:SetJustifyV("TOP")
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
    end)

    return view
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
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.08, 0.96)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -17)
    title:SetPoint("TOPRIGHT", -46, -17)
    title:SetJustifyH("LEFT")
    title:SetText("Retail Guild Management System")
    frame.title = title

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        UI.Hide()
    end)
    frame.closeButton = closeButton

    local dragHandle = CreateFrame("Button", nil, frame)
    dragHandle:SetPoint("TOPLEFT", 12, -10)
    dragHandle:SetPoint("TOPRIGHT", -42, -10)
    dragHandle:SetHeight(32)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    dragHandle:SetScript("OnDragStop", function()
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
    end)
    frame.dragHandle = dragHandle

    frame.tabs = {}
    frame.views = {}
    for index, tabId in ipairs(TAB_ORDER) do
        local tab = CreateFrame(
            "Button",
            "RGMSMainFrameTab" .. index,
            frame,
            "PanelTabButtonTemplate"
        )
        tab:SetID(index)
        tab:SetText(TAB_TITLES[tabId])
        tab:SetWidth(100)
        if index == 1 then
            tab:SetPoint("TOPLEFT", 18, -51)
        end
        tab:SetScript("OnClick", function()
            UI.SelectPrimaryTab(tabId)
        end)
        frame.tabs[index] = tab
        frame.views[tabId] = createView(frame, tabId)
    end

    PanelTemplates_SetNumTabs(frame, #TAB_ORDER)

    frame:SetScript("OnShow", function()
        UI.ClampToScreen()
    end)
    frame:SetScript("OnHide", function()
        if type(RGMS.Bank) == "table"
            and type(RGMS.Bank.CancelScan) == "function" then
            RGMS.Bank.CancelScan()
        end
        if type(UI.CollapseMainsAltsGroups) == "function" then
            UI.CollapseMainsAltsGroups()
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

    for _, currentTabId in ipairs(TAB_ORDER) do
        local selected = currentTabId == tabId
        UI.frame.views[currentTabId]:SetShown(selected)
    end
    local selectedIndex
    for index, currentTabId in ipairs(TAB_ORDER) do
        if currentTabId == tabId then
            selectedIndex = index
            break
        end
    end
    PanelTemplates_SetTab(UI.frame, selectedIndex)
    UI.selectedTab = tabId
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
    local previousRankIndex = view.selectedRankIndex
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
        button:SetText(rank.label)
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

    local selectedRank = findRosterRank(view, previousRankIndex)
        or report.ranks[1]
    if selectedRank then
        return UI.SelectRosterRank(selectedRank.index)
    end

    view.selectedRankIndex = nil
    hideRosterLines(view)
    view.text:Show()
    view.text:SetText("No roster data yet")
    view.scrollFrame:SetVerticalScroll(0)
    refreshScrollChild(view)
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
    view.mainsAltsReport = report
    local availableSelections = {}
    for _, row in ipairs(report.rows) do
        if view.mainsAltsSelections[row.identity] == true then
            availableSelections[row.identity] = true
        end
    end
    view.mainsAltsSelections = availableSelections
    renderMainsAlts(view)
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
    view.mainsAltsSelections = {}
    view.expandedMainsAlts = { [mainIdentity] = true }
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

    view.expandedMainsAlts[identity] = not view.expandedMainsAlts[identity]
    renderMainsAlts(view)
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
    renderBankTab(view, tab)
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
    local previousTabIndex = view.selectedBankTabIndex
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

    local selectedTab = findBankTab(view, previousTabIndex) or report.tabs[1]
    if selectedTab then
        return UI.SelectBankTab(selectedTab.index)
    end

    view.selectedBankTabIndex = nil
    hideBankLines(view)
    view.text:Show()
    view.text:SetText("No bank tabs purchased")
    view.scrollFrame:SetVerticalScroll(0)
    refreshScrollChild(view)
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
    updateMainsAltsControlState(mainsAltsView)
    return true
end

local function updateBankRefreshButton(view)
    view.refreshButton:SetEnabled(
        UI.dataEnabled ~= false
            and view.bankOpen == true
            and view.bankScanInProgress ~= true
    )
end

local function updateRosterRefreshButton(view)
    view.refreshButton:SetEnabled(
        UI.dataEnabled ~= false
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

function UI.Show(tabId)
    if not UI.frame then
        local initialized, initializeError = UI.Initialize()
        if not initialized then
            return nil, initializeError
        end
    end
    if tabId then
        local selected, selectError = UI.SelectPrimaryTab(tabId)
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
