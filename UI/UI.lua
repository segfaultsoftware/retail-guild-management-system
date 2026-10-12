local _, RGMS = ...

local UI = RGMS.UI or {}

local TAB_ORDER = { "roster", "bank" }
local TAB_TITLES = {
    roster = "Roster",
    bank = "Bank",
}

local PLACEHOLDER_COPY = {
    roster = "Roster report placeholder",
    bank = "Bank report placeholder",
}

local RANK_TAB_WIDTH = 242
local RANK_TAB_HEIGHT = 24
local RANK_TAB_GAP = 3
local ROSTER_CONTENT_GAP = 24
local ROSTER_TITLE_HEIGHT = 26
local ROSTER_GROUP_HEIGHT = 22
local ROSTER_ROW_HEIGHT = 20
local ROSTER_GROUP_GAP = 8
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

local function placeholderText(tabId)
    local lines = {
        PLACEHOLDER_COPY[tabId],
        "",
        "This scrollable region is ready for the "
            .. string.lower(TAB_TITLES[tabId])
            .. " report.",
        "",
        "Scrollable placeholder rows:",
    }
    for index = 1, 30 do
        lines[#lines + 1] = string.format("%02d. Placeholder content", index)
    end
    return table.concat(lines, "\n")
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

local function refreshScrollChild(view)
    local availableWidth = math.max(1, view.scrollFrame:GetWidth() - 8)
    view.scrollChild:SetWidth(availableWidth)
    view.text:SetWidth(availableWidth)
    layoutRosterLines(view, availableWidth)

    local viewportHeight = math.max(1, view.scrollFrame:GetHeight())
    local contentHeight = view.rosterTableHeight
        or (view.text:GetStringHeight() + 16)
    view.scrollChild:SetHeight(math.max(viewportHeight, contentHeight))
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

local function createView(parent, tabId)
    local view = CreateFrame("Frame", nil, parent)
    view:SetPoint("TOPLEFT", 18, -92)
    view:SetPoint("BOTTOMRIGHT", -38, 18)

    view.status = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.status:SetPoint("TOPLEFT", 2, 0)
    view.status:SetPoint("TOPRIGHT", tabId == "roster" and -94 or -2, 0)
    view.status:SetJustifyH("LEFT")
    view.status:SetText("Ready")

    if tabId == "roster" then
        view.refreshButton = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
        view.refreshButton:SetSize(84, 22)
        view.refreshButton:SetPoint("TOPRIGHT", 0, 4)
        view.refreshButton:SetText("Refresh")
        view.refreshButton:SetScript("OnClick", function()
            RGMS.Roster.RequestManualScan()
        end)

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
    view.text:SetText(placeholderText(tabId))

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
        return nil, "primary tab must be roster or bank"
    end
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    for _, currentTabId in ipairs(TAB_ORDER) do
        local selected = currentTabId == tabId
        UI.frame.views[currentTabId]:SetShown(selected)
    end
    PanelTemplates_SetTab(UI.frame, tabId == "roster" and 1 or 2)
    UI.selectedTab = tabId
    return true
end

function UI.SetViewContent(tabId, content)
    tabId = normalizeTabId(tabId)
    if not tabId then
        return nil, "primary tab must be roster or bank"
    end
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views[tabId]
    if tabId == "roster" then
        hideRosterLines(view)
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
        return nil, "primary tab must be roster or bank"
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

function UI.SetRosterScanInProgress(inProgress)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    UI.frame.views.roster.refreshButton:SetEnabled(not inProgress)
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
