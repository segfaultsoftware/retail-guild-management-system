local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI component files must load before UI/UI.lua")

Runtime.Register("Facade", function()
function normalizeTabId(tabId)
    if type(tabId) ~= "string" then
        return nil
    end

    tabId = string.lower(tabId)
    if TAB_TITLES[tabId] or tabId == "mainsalts" then
        return tabId
    end
    return nil
end

function activeRosterMode()
    if type(RGMS.PortalState) == "table"
        and RGMS.PortalState.rosterMode == "ByTenure" then
        return "ByTenure"
    end
    if UI.rosterMode == "ByTenure" then
        return "ByTenure"
    end
    return "ByName"
end

function rosterModeView(mode)
    if not UI.frame then
        return nil
    end
    return mode == "ByTenure"
        and UI.frame.views.roster
        or UI.frame.views.mainsalts
end

function setRosterModeScroll(mode, offset)
    offset = math.max(0, tonumber(offset) or 0)
    if type(RGMS.PortalState) == "table" then
        RGMS.PortalState:setScroll("roster", offset, mode)
    else
        UI.rosterScroll = UI.rosterScroll or { ByName = 0, ByTenure = 0 }
        UI.rosterScroll[mode] = offset
    end
end

function getRosterModeScroll(mode)
    if type(RGMS.PortalState) == "table" then
        return RGMS.PortalState.scroll.roster[mode] or 0
    end
    return UI.rosterScroll and UI.rosterScroll[mode] or 0
end


function refreshVisibleReport(view)
    if view and type(view.refreshVisible) == "function" then
        view.refreshVisible()
    end
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
        return nil, "primary tab must be roster, bank, provisions, or tags"
    end
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if UI.globalScanLocked == true and UI.frame:IsShown() then
        return nil, "scan-locked"
    end
    if previousTabId == "provisions" and tabId ~= "provisions" then
        UI.CancelProvisionDrag()
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
    if tabId == "provisions" and previousTabId ~= "provisions"
        and type(RGMS.Provisions) == "table"
        and type(RGMS.Provisions.OnTabSelected) == "function" then
        RGMS.Provisions.OnTabSelected()
    end
    if tabId == "roster" and mode == "ByName" and previousTabId ~= "roster"
        and type(RGMS.MainsAlts) == "table"
        and type(RGMS.MainsAlts.RequestGuildNotes) == "function" then
        RGMS.MainsAlts.RequestGuildNotes()
    end
    local selectedView = tabId == "roster" and rosterModeView(mode)
        or UI.frame.views[tabId]
    if UI.frame:IsShown() then
        refreshVisibleReport(selectedView)
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
        refreshVisibleReport(selectedView)
        selectedView.scrollFrame:SetVerticalScroll(savedScroll)
    end
    updateRosterModeControls()
    return true
end

function UI.SetViewContent(tabId, content)
    tabId = normalizeTabId(tabId)
    if not tabId then
        return nil, "primary tab must be roster, bank, provisions, or tags"
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
    elseif tabId == "provisions" then
        UI.CancelProvisionDrag()
        view.provisionsReport = { rows = {} }
        for _, line in ipairs(view.provisionRows or {}) do
            line.row = nil
            line.frame:Hide()
        end
        ProvisionUI.refreshScrollChild(view)
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
        return nil, "primary tab must be roster, mainsalts, bank, provisions, or tags"
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
    if UI.globalScanLocked then
        UI.CancelProvisionDrag()
    end
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
        if view.provisionScrollFrame then
            view.provisionScrollFrame:EnableMouse(not UI.globalScanLocked)
            view.provisionScrollFrame:EnableMouseWheel(not UI.globalScanLocked)
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
        if tabId == "provisions" then
            ProvisionUI.updateControlState(view)
        end
    end
    updateRosterRefreshButton(UI.frame.views.roster)
    updateRosterRefreshButton(UI.frame.views.mainsalts)
    ProvisionUI.updateBankRefreshButton(UI.frame.views.bank)
    ProvisionUI.updateBankRefreshButton(UI.frame.views.provisions)
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

ProvisionUI.updateBankRefreshButton = function(view)
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
    ProvisionUI.updateBankRefreshButton(view)
    local provisionsView = UI.frame.views.provisions
    provisionsView.bankOpen = isOpen == true
    ProvisionUI.updateBankRefreshButton(provisionsView)
    return true
end

function UI.SetBankScanInProgress(inProgress)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.bank
    view.bankScanInProgress = inProgress == true
    ProvisionUI.updateBankRefreshButton(view)
    local provisionsView = UI.frame.views.provisions
    provisionsView.bankScanInProgress = inProgress == true
    ProvisionUI.updateBankRefreshButton(provisionsView)
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
    if not UI.dataEnabled then
        UI.CancelProvisionDrag()
        UI.SetGuildBankBalance(nil)
    end
    updateRosterRefreshButton(UI.frame.views.roster)
    updateRosterRefreshButton(UI.frame.views.mainsalts)
    ProvisionUI.updateBankRefreshButton(UI.frame.views.bank)
    ProvisionUI.updateBankRefreshButton(UI.frame.views.provisions)
    updateMainsAltsControlState(UI.frame.views.mainsalts)
    updateRosterModeControls()
    for _, line in ipairs(UI.frame.views.tags.tagRows or {}) do
        updateTagDeleteButton(line)
    end
    ProvisionUI.updateControlState(UI.frame.views.provisions)

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


end, {
    "SelectPrimaryTab",
    "SelectRosterMode",
    "SetViewContent",
    "SetViewStatus",
    "SetGlobalScanLock",
    "SetRosterScanInProgress",
    "SetRosterAvailable",
    "SetMainsAltsAvailable",
    "SetGuildBankOpen",
    "SetBankScanInProgress",
    "SetDataState",
    "GetContentHost",
})

return Runtime.Build()
