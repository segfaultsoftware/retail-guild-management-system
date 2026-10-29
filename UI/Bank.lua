local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("Bank", function()
BANK_TAB_WIDTH = 0
BANK_CONTENT_GAP = 18
BANK_TAB_HEIGHT = 28
BANK_TAB_GAP = 3
BANK_ROW_HEIGHT = 24
BANK_ICON_SIZE = 18
BANK_HEADER_HEIGHT = 28
BANK_TITLE_HEIGHT = 0

function layoutBankLines(view, availableWidth)
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


function refreshBankTabScrollChild(view)
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


function hideBankLines(view)
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

function configureBankText(text)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    if type(text.SetWordWrap) == "function" then
        text:SetWordWrap(false)
    end
end

function createBankHeader(view)
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

function acquireBankLine(view, index)
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

function renderBankTab(view, tab)
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

function findBankTab(view, tabIndex)
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


function createBankView(view, parent)
    ProvisionUI.createGuildBankBalanceFrame(view, "bank")
    createRefreshButton(view, parent, false, "Refresh the guild bank.", function()
        RGMS.Bank.RequestManualScan()
    end)
    view.bankOpen = false
    view.bankScanInProgress = false
    view.bankTabScrollFrame = CreateFrame(
        "ScrollFrame", nil, view, "UIPanelScrollFrameTemplate"
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
    view.bankTitle = view.scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    configureBankText(view.bankTitle)
    view.bankTitle:Hide()
    view.bankMessage = view.scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    configureBankText(view.bankMessage)
    view.bankMessage:Hide()
    view.refreshVisible = function()
        local tab = findBankTab(view, view.selectedBankTabIndex)
        if tab then
            updateDropdownLabel(view.bankDropdown, tab, "No bank tabs", true)
            renderBankTab(view, tab)
        end
    end
end

end, {
    "SelectBankTab",
    "SetBankReport",
})


