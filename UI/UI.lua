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

local function refreshScrollChild(view)
    local availableWidth = math.max(1, view.scrollFrame:GetWidth() - 8)
    view.scrollChild:SetWidth(availableWidth)
    view.text:SetWidth(availableWidth)

    local viewportHeight = math.max(1, view.scrollFrame:GetHeight())
    local textHeight = view.text:GetStringHeight() + 16
    view.scrollChild:SetHeight(math.max(viewportHeight, textHeight))
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
    end

    view.scrollFrame = CreateFrame("ScrollFrame", nil, view, "UIPanelScrollFrameTemplate")
    view.scrollFrame:SetPoint("TOPLEFT", 0, -24)
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
