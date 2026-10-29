local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("Window", function()
function isInsideMainWindow(parent)
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

function enableWindowDragging(surface)
    if not surface or type(surface.RegisterForDrag) ~= "function"
        or type(surface.HookScript) ~= "function" then
        return
    end
    surface:RegisterForDrag("LeftButton")
    surface:HookScript("OnDragStart", startWindowDrag)
    surface:HookScript("OnDragStop", stopWindowDrag)
end

function CreateFrame(frameType, name, parent, template)
    local frame = createFrame(frameType, name, parent, template)
    if frameType ~= "EditBox"
        and windowDragRoot and isInsideMainWindow(parent) then
        enableWindowDragging(frame)
    end
    return frame
end


HEADER_HEIGHT = 56
SIDEBAR_WIDTH = 136
CONTENT_PADDING = 16
GLOBAL_DIMMER_ALPHA = 0.8
GLOBAL_DIMMER_FRAME_LEVEL_OFFSET = 100

function getScreenSize()
    return UIParent:GetWidth(), UIParent:GetHeight()
end

function getFrameRectangle(frame)
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

function savePosition(position)
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

function applyClampedPosition(position, shouldSave)
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


function createView(parent, tabId)
    local view = CreateFrame("Frame", nil, parent)
    view:SetPoint(
        "TOPLEFT",
        SIDEBAR_WIDTH + CONTENT_PADDING,
        -HEADER_HEIGHT - CONTENT_PADDING
    )
    view:SetPoint("BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
    view.contextParent = parent
    view.contextStatusLeft = (tabId == "mainsalts" or tabId == "roster")
        and 680 or ProvisionUI.CONTEXT_STATUS_LEFT

    view.status = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local statusY = (tabId == "bank" or tabId == "provisions") and -8 or -20
    view.status:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        view.contextStatusLeft,
        statusY
    )
    view.status:SetPoint(
        "TOPRIGHT",
        parent,
        "TOPRIGHT",
        (tabId == "mainsalts" or tabId == "roster" or tabId == "bank"
            or tabId == "provisions" or tabId == "tags") and -96 or -148,
        statusY
    )
    if tabId == "bank" or tabId == "provisions" then
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
        if type(view.status.IsTruncated) == "function"
            and view.status:IsTruncated() then
            showOwnedTooltip(button, "Status", view.status:GetText())
        end
    end)
    view.statusHitbox:SetScript("OnLeave", function(button)
        hideOwnedTooltip(button)
    end)

    view.scrollFrame = CreateFrame(
        "ScrollFrame",
        nil,
        view,
        "UIPanelScrollFrameTemplate"
    )
    styleScrollFrame(view.scrollFrame)
    view.scrollFrame:SetPoint("TOPLEFT", 0, -28)
    view.scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    view.scrollChild = CreateFrame("Frame", nil, view.scrollFrame)
    view.scrollChild:SetSize(1, 1)
    view.scrollFrame:SetScrollChild(view.scrollChild)
    view.text = view.scrollChild:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontHighlight"
    )
    view.text:SetPoint("CENTER", view, "CENTER", 0, 0)
    view.text:SetJustifyH("CENTER")
    view.text:SetJustifyV("MIDDLE")
    view.text:SetText(INITIAL_COPY[tabId])

    if tabId == "roster" then
        createRosterByTenureView(view, parent)
    elseif tabId == "mainsalts" then
        createRosterByNameView(view, parent)
    elseif tabId == "bank" then
        createBankView(view, parent)
    elseif tabId == "provisions" then
        createProvisionsView(view, parent)
    elseif tabId == "tags" then
        createTagsView(view)
    end

    view.scrollFrame:SetScript("OnSizeChanged", function()
        refreshScrollChild(view)
        if view.onSizeChanged then
            view.onSizeChanged()
        end
    end)
    return view
end
function createWindow()
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

    local logo = header:CreateTexture(nil, "OVERLAY")
    logo:SetSize(40, 40)
    logo:SetPoint("TOPLEFT", header, "TOPLEFT", 8, -8)
    logo:SetTexture(LOGO_TEXTURE)
    frame.logo = logo
    frame.logoButton = CreateFrame("Button", nil, header)
    frame.logoButton:SetAllPoints(logo)
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
    frame.toasts = {}
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
    frame.modalDimmer:SetFrameLevel(
        frame:GetFrameLevel() + 90
    )
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
        local selectedView = UI.selectedTab == "roster"
            and rosterModeView(activeRosterMode())
            or frame.views[UI.selectedTab]
        refreshVisibleReport(selectedView)
    end)
    frame:SetScript("OnHide", function()
        UI.CancelProvisionDrag()
        UI.ClearToasts()
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
        frame.views.provisions.provisionScrollFrame:SetVerticalScroll(0)
        frame.views.tags.scrollFrame:SetVerticalScroll(0)
        if type(RGMS.PortalState) == "table" then
            RGMS.PortalState.rosterMode = "ByName"
        end
        UI.rosterMode = "ByName"
        UI.rosterScroll = { ByName = 0, ByTenure = 0 }
        UI.SelectPrimaryTab("roster")
        if type(RGMS.Provisions) == "table"
            and type(RGMS.Provisions.OnWindowClosed) == "function" then
            RGMS.Provisions.OnWindowClosed()
        end
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
    ProvisionUI.refreshScrollChild(UI.frame.views.provisions)

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


function UI.Toggle(tabId)
    if UI.frame and UI.frame:IsShown() then
        return UI.Hide()
    end
    return UI.Show(tabId)
end

function UI.IsShown()
    return UI.frame ~= nil and UI.frame:IsShown()
end


end, {
    "Initialize",
    "ClampToScreen",
    "HasSavedPosition",
    "AlignToRightOf",
    "Show",
    "Hide",
    "Toggle",
    "IsShown",
})



