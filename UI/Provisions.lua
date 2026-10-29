local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("Provisions", function()
ProvisionUI = {
    PANE_GAP = 16,
    CONTEXT_STATUS_LEFT = 280,
    CONTEXT_AUCTIONATOR_STATUS_LEFT = 424,
    CONTEXT_STATUS_RIGHT = -96,
    CONTEXT_STATUS_TOP = -8,
    CONTEXT_STATUS_HEIGHT = 40,
    CONTEXT_STATUS_STACK_HEIGHT = 18,
    CONTEXT_BALANCE_RIGHT = -84,
    CONTEXT_BALANCE_TOP = -29,
    CONTEXT_BALANCE_SCALE = 1,
    ROW_HEIGHT = 64,
    ROW_GAP = 6,
    ICON_SIZE = 38,
    PROGRESS_WIDTH = 180,
    PROGRESS_HEIGHT = 18,
    DRAG_THRESHOLD = 5,
    DRAG_EDGE_ZONE = 28,
    DRAG_SCROLL_SPEED = 120,
    DRAG_FRAME_LEVEL = 10000,
    TOAST_FRAME_LEVEL_OFFSET = 50,
    TOAST_MAX_WIDTH = 560,
    TOAST_BORDER_INSET = 1,
    TOAST_TEXT_HORIZONTAL_PADDING = 18,
    TOAST_TEXT_VERTICAL_PADDING = 12,
    TOAST_MIN_HEIGHT = 40,
    TOAST_TOP_OFFSET = 10,
    TOAST_GAP = 2,
    TOAST_HOLD_SECONDS = 3,
    TOAST_FADE_SECONDS = 1,
    QUALITY_ATLASES = {
        silver = "Professions-Icon-Quality-12-Tier1",
        gold = "Professions-Icon-Quality-12-Tier2",
    },
}
-- AceGUI and table libraries were evaluated for this feature. RGMS keeps its
-- native-frame composition because Provisions shares the portal's scan lock,
-- styling, and lifecycle; another widget framework would add compatibility
-- surface without supplying bank matching or transactional persistence.
-- LibToast-1.0 was also evaluated for Provision success feedback. Its global
-- queue and presentation model do not provide RGMS's window-relative anchor,
-- exact dimmer layering, or tested close lifecycle, so the small native stack
-- remains within the existing adapter instead of adding a bundled dependency.
-- Blizzard's ScrollUtil linear drag behavior was evaluated for manual ordering,
-- but it requires a ScrollBox/data-provider rewrite. Provisions intentionally
-- stays on RGMS's fixed-row ScrollFrame, so its small drag adapter remains local.

function ProvisionUI.draft(view)
    local r1 = view.provisionR1:GetChecked()
    local r2 = view.provisionR2:GetChecked()
    local either = view.provisionEither:GetChecked()
    return {
        name = view.provisionNameInput:GetText(),
        silver = r1 or either,
        gold = r2 or either,
        targetText = view.provisionTargetInput:GetText(),
    }
end

function ProvisionUI.updateControlState(view)
    if not view or not view.newProvisionButton then
        return
    end
    local available = UI.dataEnabled ~= false and UI.globalScanLocked ~= true
    view.newProvisionButton:SetEnabled(available)
    if view.auctionatorShoppingListButton then
        view.auctionatorShoppingListButton:SetEnabled(
            available
                and type(view.provisionsReport) == "table"
                and view.provisionsReport.canCreateShoppingList == true
        )
    end
    view.saveProvisionButton:SetEnabled(
        available and view.provisionDraftValid == true
            and view.provisionDraftChanged == true
    )
    for _, line in ipairs(view.provisionRows or {}) do
        local deleteEnabled = available and line.row ~= nil
        line.deleteEnabled = deleteEnabled
        line.deleteButton:SetEnabled(deleteEnabled)
        if type(line.deleteButton.SetAlpha) == "function" then
            line.deleteButton:SetAlpha(deleteEnabled and 1 or 0.45)
        end
        setTextureColor(
            line.deleteIcon,
            deleteEnabled and PALETTE.text or PALETTE.disabled
        )
    end
    setEditBoxEnabled(view.provisionNameInput, available)
    setEditBoxEnabled(view.provisionTargetInput, available)
    view.provisionR1:SetEnabled(available)
    view.provisionR2:SetEnabled(available)
    view.provisionEither:SetEnabled(available)
    if type(view.provisionEditor.SetAlpha) == "function" then
        view.provisionEditor:SetAlpha(available and 1 or 0.5)
    end
end

function ProvisionUI.notifyDraftChanged(view)
    if view.settingProvisionEditor then
        return
    end
    if type(RGMS.Provisions) == "table"
        and type(RGMS.Provisions.SetDraft) == "function" then
        RGMS.Provisions.SetDraft(ProvisionUI.draft(view))
    end
end

function ProvisionUI.createInput(parent, labelText, y, maximum)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    label:SetText(labelText)
    setFont(label, FONT_SEMIBOLD, 11)
    setTextColor(label, PALETTE.text)

    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    input:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, y - 20)
    input:SetHeight(30)
    input:SetAutoFocus(false)
    input:SetMaxLetters(maximum)
    input:SetTextInsets(8, 8, 0, 0)
    setFont(input, FONT_REGULAR, 12)
    setTextColor(input, PALETTE.text)
    flatBackdrop(input, PALETTE.control, PALETTE.border)
    input:SetScript("OnEscapePressed", function(editBox)
        editBox:ClearFocus()
    end)
    return input, label
end

function ProvisionUI.setQualitySelection(view, selection, notify)
    for mode, control in pairs({
        r1 = view.provisionR1,
        r2 = view.provisionR2,
        either = view.provisionEither,
    }) do
        local checked = mode == selection
        control:SetChecked(checked)
        control.dot:SetShown(checked)
    end
    if notify then
        ProvisionUI.notifyDraftChanged(view)
    end
end

function ProvisionUI.createQualityRadio(parent, mode, x, atlas, labelText)
    local radio = CreateFrame("CheckButton", nil, parent)
    radio:SetSize(labelText and 72 or 48, 24)
    radio:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -119)

    radio.ring = radio:CreateTexture(nil, "ARTWORK")
    radio.ring:SetSize(16, 16)
    radio.ring:SetPoint("LEFT", radio, "LEFT", 0, 0)
    radio.ring:SetTexture(CIRCLE_TEXTURE)
    setTextureColor(radio.ring, PALETTE.border)

    radio.interior = radio:CreateTexture(nil, "ARTWORK")
    radio.interior:SetSize(12, 12)
    radio.interior:SetPoint("CENTER", radio.ring, "CENTER", 0, 0)
    radio.interior:SetTexture(CIRCLE_TEXTURE)
    setTextureColor(radio.interior, PALETTE.shell)

    radio.dot = radio:CreateTexture(nil, "ARTWORK")
    radio.dot:SetSize(8, 8)
    radio.dot:SetPoint("CENTER", radio.ring, "CENTER", 0, 0)
    radio.dot:SetTexture(CIRCLE_TEXTURE)
    setTextureColor(radio.dot, PALETTE.pink)
    radio.dot:Hide()

    if atlas then
        radio.symbol = radio:CreateTexture(nil, "ARTWORK")
        radio.symbol:SetSize(20, 20)
        radio.symbol:SetPoint("LEFT", radio.ring, "RIGHT", 6, 0)
        if type(radio.symbol.SetAtlas) == "function" then
            radio.symbol:SetAtlas(atlas)
        end
    else
        radio.label = radio:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        radio.label:SetPoint("LEFT", radio.ring, "RIGHT", 6, 0)
        radio.label:SetText(labelText)
        setFont(radio.label, FONT_REGULAR, 12)
        setTextColor(radio.label, PALETTE.text)
    end

    radio:SetScript("OnClick", function()
        ProvisionUI.setQualitySelection(parent.provisionView, mode, true)
    end)
    return radio
end

function ProvisionUI.fitActionButton(button, text)
    button:SetText(text)
    local textWidth = #text * 7
    if type(button.GetFontString) == "function" then
        local label = button:GetFontString()
        if label and type(label.GetStringWidth) == "function" then
            textWidth = label:GetStringWidth()
        end
    end
    button:SetWidth(math.ceil(textWidth) + 14)
end

function ProvisionUI.refreshScrollChild(view)
    if not view.provisionScrollFrame then
        return
    end
    local viewportHeight = math.max(1, view.provisionScrollFrame:GetHeight())
    local count = type(view.provisionsReport) == "table"
        and type(view.provisionsReport.rows) == "table"
        and #view.provisionsReport.rows
        or 0
    local contentHeight = count * (ProvisionUI.ROW_HEIGHT + ProvisionUI.ROW_GAP) + 4
    view.provisionScrollChild:SetWidth(
        math.max(1, view.provisionScrollFrame:GetWidth() - 18)
    )
    view.provisionScrollChild:SetHeight(math.max(viewportHeight, contentHeight))
    setScrollBarShown(view.provisionScrollFrame, contentHeight > viewportHeight)
end

function ProvisionUI.createRowVisual(parent)
    local frame = createFrame("Button", nil, parent, "BackdropTemplate")
    frame:SetHeight(ProvisionUI.ROW_HEIGHT)
    flatBackdrop(frame, PALETTE.control, PALETTE.border)
    local selectionBorder = {}
    for _, edge in ipairs({ "top", "bottom", "left", "right" }) do
        local texture = frame:CreateTexture(nil, "OVERLAY")
        texture:SetTexture(WHITE_TEXTURE)
        setTextureColor(texture, PALETTE.pink)
        texture:Hide()
        selectionBorder[edge] = texture
    end
    selectionBorder.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    selectionBorder.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    selectionBorder.top:SetHeight(2)
    selectionBorder.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    selectionBorder.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    selectionBorder.bottom:SetHeight(2)
    selectionBorder.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    selectionBorder.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    selectionBorder.left:SetWidth(2)
    selectionBorder.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    selectionBorder.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    selectionBorder.right:SetWidth(2)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ProvisionUI.ICON_SIZE, ProvisionUI.ICON_SIZE)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    local badge = frame:CreateTexture(nil, "OVERLAY")
    badge:SetSize(16, 16)
    badge:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 3, -3)
    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
    name:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -11)
    name:SetJustifyH("LEFT")
    setFont(name, FONT_SEMIBOLD, 12)
    setTextColor(name, PALETTE.text)
    local progress = createFrame("Frame", nil, frame, "BackdropTemplate")
    progress:SetSize(ProvisionUI.PROGRESS_WIDTH, ProvisionUI.PROGRESS_HEIGHT)
    progress:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 1)
    flatBackdrop(progress, PALETTE.shell, PALETTE.border)
    local fill = progress:CreateTexture(nil, "ARTWORK")
    fill:SetTexture(WHITE_TEXTURE)
    fill:SetPoint("TOPLEFT", progress, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", progress, "BOTTOMLEFT", 1, 1)
    fill:SetWidth(1)
    setTextureColor(fill, PALETTE.pink)
    local progressText = progress:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    progressText:SetPoint("CENTER", progress, "CENTER", 0, 0)
    setFont(progressText, FONT_SEMIBOLD, 10)
    setTextColor(progressText, PALETTE.text)
    local deleteButton = createFrame("Button", nil, frame)
    deleteButton:SetSize(20, 20)
    deleteButton:SetPoint("LEFT", progress, "RIGHT", 6, 0)
    local deleteIcon = deleteButton:CreateTexture(nil, "ARTWORK")
    deleteIcon:SetAllPoints(deleteButton)
    if type(deleteIcon.SetAtlas) == "function" then
        deleteIcon:SetAtlas(TAG_DELETE_ATLAS)
    end
    return {
        frame = frame,
        icon = icon,
        badge = badge,
        name = name,
        progress = progress,
        fill = fill,
        progressText = progressText,
        deleteButton = deleteButton,
        deleteIcon = deleteIcon,
        selectionBorder = selectionBorder,
    }
end

function ProvisionUI.renderRow(line, row)
    line.icon:SetTexture(row.icon or 134400)
    line.name:SetText(row.name)
    line.progressText:SetText(row.progressText)
    line.fill:SetWidth(math.max(1, (ProvisionUI.PROGRESS_WIDTH - 2) * row.progress))
    line.fill:SetShown(row.progress > 0)
    if row.quality == "silver" or row.quality == "gold" then
        if type(line.badge.SetAtlas) == "function" then
            line.badge:SetAtlas(
                row.quality == "silver"
                    and ProvisionUI.QUALITY_ATLASES.silver
                    or ProvisionUI.QUALITY_ATLASES.gold
            )
        end
        line.badge:Show()
    else
        line.badge:Hide()
    end
end

function ProvisionUI.createView(view)
    view.scrollFrame:Hide()
    view.text:Hide()

    view.provisionStatusPane = CreateFrame("Frame", nil, view, "BackdropTemplate")
    view.provisionStatusPane:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    view.provisionStatusPane:SetPoint(
        "BOTTOMRIGHT",
        view,
        "BOTTOM",
        -ProvisionUI.PANE_GAP / 2,
        0
    )
    flatBackdrop(view.provisionStatusPane, PALETTE.surface, PALETTE.border)

    view.provisionScrollFrame = CreateFrame(
        "ScrollFrame",
        nil,
        view.provisionStatusPane,
        "UIPanelScrollFrameTemplate"
    )
    styleScrollFrame(view.provisionScrollFrame)
    view.provisionScrollFrame:SetPoint(
        "TOPLEFT",
        view.provisionStatusPane,
        "TOPLEFT",
        10,
        -10
    )
    view.provisionScrollFrame:SetPoint(
        "TOPRIGHT",
        view.provisionStatusPane,
        "TOPRIGHT",
        -10,
        -10
    )
    view.provisionScrollFrame:SetPoint("BOTTOMRIGHT", view.provisionStatusPane, "BOTTOMRIGHT", -10, 10)
    view.provisionScrollChild = CreateFrame("Frame", nil, view.provisionScrollFrame)
    view.provisionScrollChild:SetSize(1, 1)
    view.provisionScrollFrame:SetScrollChild(view.provisionScrollChild)
    view.provisionRows = {}
    view.provisionDragWatcher = createFrame("Frame", nil, UIParent)
    view.provisionDragWatcher:SetScript("OnUpdate", function(_, elapsed)
        ProvisionUI.updateDrag(view, elapsed)
    end)
    view.provisionScrollFrame:SetScript("OnSizeChanged", function()
        ProvisionUI.refreshScrollChild(view)
    end)

    local editor = CreateFrame("Frame", nil, view, "BackdropTemplate")
    editor:SetPoint(
        "TOPLEFT",
        view,
        "TOP",
        ProvisionUI.PANE_GAP / 2,
        0
    )
    editor:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
    flatBackdrop(editor, PALETTE.surface, PALETTE.border)
    editor.provisionView = view
    view.provisionEditor = editor
    view.provisionNameInput, view.provisionNameLabel = ProvisionUI.createInput(
        editor,
        "Item Name",
        -16,
        100
    )
    local qualityLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    qualityLabel:SetPoint("TOPLEFT", editor, "TOPLEFT", 16, -99)
    qualityLabel:SetText("Quality")
    setFont(qualityLabel, FONT_SEMIBOLD, 11)
    setTextColor(qualityLabel, PALETTE.text)
    view.provisionQualityLabel = qualityLabel
    view.provisionR1 = ProvisionUI.createQualityRadio(
        editor,
        "r1",
        16,
        ProvisionUI.QUALITY_ATLASES.silver
    )
    view.provisionR2 = ProvisionUI.createQualityRadio(
        editor,
        "r2",
        70,
        ProvisionUI.QUALITY_ATLASES.gold
    )
    view.provisionEither = ProvisionUI.createQualityRadio(
        editor,
        "either",
        124,
        nil,
        "Either"
    )
    view.provisionTargetInput, view.provisionTargetLabel = ProvisionUI.createInput(
        editor,
        "Target Inventory Count",
        -169,
        5
    )

    view.saveProvisionButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    styleButton(view.saveProvisionButton, "primary", 32)
    ProvisionUI.fitActionButton(view.saveProvisionButton, "Save")
    view.saveProvisionButton:SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -16, 16)

    view.provisionNameInput:SetScript("OnTextChanged", function()
        ProvisionUI.notifyDraftChanged(view)
    end)
    view.provisionTargetInput:SetScript("OnTextChanged", function()
        ProvisionUI.notifyDraftChanged(view)
    end)
    view.saveProvisionButton:SetScript("OnClick", function()
        if type(RGMS.Provisions) == "table" then
            RGMS.Provisions.Save()
        end
    end)
    view.provisionDraftValid = false
    view.provisionDraftChanged = false
    ProvisionUI.updateControlState(view)
end

function ProvisionUI.acquireRow(view, index)
    local line = view.provisionRows[index]
    if line then
        return line
    end
    line = ProvisionUI.createRowVisual(view.provisionScrollChild)
    local frame = line.frame
    local deleteButton = line.deleteButton
    frame:SetScript("OnClick", function()
        if line.suppressNextClick then
            line.suppressNextClick = nil
            return
        end
        if line.row and type(RGMS.Provisions) == "table" then
            RGMS.Provisions.Select(line.row.id)
        end
    end)
    frame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            ProvisionUI.pressRow(view, line)
        end
    end)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            ProvisionUI.finishDrag(view)
        end
    end)
    deleteButton:SetScript("OnClick", function()
        if line.row and line.deleteEnabled
            and type(RGMS.Provisions) == "table" then
            RGMS.Provisions.Delete(line.row.id)
        end
    end)
    deleteButton:SetScript("OnEnter", function(button)
        if button:IsEnabled() then
            setTextureColor(line.deleteIcon, PALETTE.pinkHover)
        end
        showOwnedTooltip(button, "Delete", "Delete this provision.")
    end)
    deleteButton:SetScript("OnLeave", function(button)
        setTextureColor(
            line.deleteIcon,
            button:IsEnabled() and PALETTE.text or PALETTE.disabled
        )
        hideOwnedTooltip(button)
    end)
    view.provisionRows[index] = line
    return line
end

function ProvisionUI.copyRows(rows)
    local copied = {}
    for index, row in ipairs(rows or {}) do
        copied[index] = row
    end
    return copied
end

function ProvisionUI.cursorPosition()
    if type(GetCursorPosition) ~= "function" then
        return 0, 0
    end
    local x, y = GetCursorPosition()
    local scale = type(UIParent.GetEffectiveScale) == "function"
        and UIParent:GetEffectiveScale()
        or 1
    if type(scale) ~= "number" or scale <= 0 then
        scale = 1
    end
    return x / scale, y / scale
end

function ProvisionUI.frameRect(frame)
    if not frame or type(frame.GetLeft) ~= "function"
        or type(frame.GetBottom) ~= "function" then
        return nil
    end
    local left = frame:GetLeft()
    local bottom = frame:GetBottom()
    if type(left) ~= "number" or type(bottom) ~= "number" then
        return nil
    end
    local width = frame:GetWidth()
    local height = frame:GetHeight()
    local top = type(frame.GetTop) == "function" and frame:GetTop() or nil
    top = type(top) == "number" and top or bottom + height
    return left, bottom, left + width, top
end

function ProvisionUI.setRowsAlpha(view, alpha)
    for _, line in ipairs(view.provisionRows or {}) do
        line.frame:SetAlpha(alpha)
    end
end


function ProvisionUI.setContextStatusLayout(view, hasBalance)
    view.status:ClearAllPoints()
    view.status:SetPoint(
        "TOPLEFT",
        view.contextParent,
        "TOPLEFT",
        view.contextStatusLeft,
        ProvisionUI.CONTEXT_STATUS_TOP
    )
    view.status:SetPoint(
        "TOPRIGHT",
        view.contextParent,
        "TOPRIGHT",
        ProvisionUI.CONTEXT_STATUS_RIGHT,
        ProvisionUI.CONTEXT_STATUS_TOP
    )
    view.status:SetHeight(
        hasBalance and ProvisionUI.CONTEXT_STATUS_STACK_HEIGHT
            or ProvisionUI.CONTEXT_STATUS_HEIGHT
    )
    view.status:SetJustifyV("MIDDLE")
end

function ProvisionUI.createGuildBankBalanceFrame(view, tabId)
    local frame = CreateFrame(
        "Frame",
        tabId == "bank" and "RGMSBankBalanceFrame" or "RGMSProvisionsBalanceFrame",
        view,
        "SmallMoneyFrameTemplate"
    )
    SmallMoneyFrame_OnLoad(frame)
    -- This static preset preserves Retail's denomination and coin-icon
    -- presentation without subscribing saved snapshots to live bank money.
    MoneyFrame_SetType(frame, "GUILD_REPAIR")
    frame:SetScale(ProvisionUI.CONTEXT_BALANCE_SCALE)
    frame:SetPoint(
        "TOPRIGHT",
        view.contextParent,
        "TOPRIGHT",
        ProvisionUI.CONTEXT_BALANCE_RIGHT,
        ProvisionUI.CONTEXT_BALANCE_TOP
    )
    frame:Hide()
    view.guildBankBalanceFrame = frame
    ProvisionUI.setContextStatusLayout(view, false)
end


function UI.SelectProvisionRow(id)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    local view = UI.frame.views.provisions
    view.selectedProvisionId = id
    for _, line in ipairs(view.provisionRows or {}) do
        local selected = line.row ~= nil and line.row.id == id
        for _, edge in pairs(line.selectionBorder or {}) do
            edge:SetShown(selected)
        end
    end
    ProvisionUI.updateControlState(view)
    return true
end

function UI.SetProvisionsReport(report, selectedId)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(report) ~= "table" or type(report.rows) ~= "table" then
        return nil, "provisions report must contain rows"
    end
    local view = UI.frame.views.provisions
    if view.provisionDrag and not view.applyingProvisionDrag then
        UI.CancelProvisionDrag()
    end
    view.provisionsReport = report
    for index, row in ipairs(report.rows) do
        local line = ProvisionUI.acquireRow(view, index)
        line.row = row
        line.frame:ClearAllPoints()
        if index == 1 then
            line.frame:SetPoint("TOPLEFT", view.provisionScrollChild, "TOPLEFT", 0, -2)
            line.frame:SetPoint("TOPRIGHT", view.provisionScrollChild, "TOPRIGHT", 0, -2)
        else
            line.frame:SetPoint(
                "TOPLEFT",
                view.provisionRows[index - 1].frame,
                "BOTTOMLEFT",
                0,
                -ProvisionUI.ROW_GAP
            )
            line.frame:SetPoint(
                "TOPRIGHT",
                view.provisionRows[index - 1].frame,
                "BOTTOMRIGHT",
                0,
                -ProvisionUI.ROW_GAP
            )
        end
        ProvisionUI.renderRow(line, row)
        line.frame:Show()
    end
    for index = #report.rows + 1, #view.provisionRows do
        local line = view.provisionRows[index]
        hideOwnedTooltip(line.deleteButton)
        line.row = nil
        line.frame:Hide()
    end
    ProvisionUI.refreshScrollChild(view)
    UI.SelectProvisionRow(selectedId)
    return true
end

function UI.SetGuildBankBalance(money)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if money ~= nil
        and (type(money) ~= "number"
            or money < 0
            or money ~= math.floor(money)) then
        return nil, "guild-bank balance must be a non-negative integer or absent"
    end
    for _, tabId in ipairs({ "bank", "provisions" }) do
        local view = UI.frame.views[tabId]
        local moneyFrame = view.guildBankBalanceFrame
        ProvisionUI.setContextStatusLayout(view, money ~= nil)
        if money == nil then
            moneyFrame:Hide()
        else
            MoneyFrame_Update(moneyFrame, money, true)
            moneyFrame:Show()
        end
    end
    return true
end

-- Retain the old internal entry point for callers that may still be loaded
-- during an addon upgrade; the balance is now shared by both relevant tabs.
UI.SetProvisionsMoney = UI.SetGuildBankBalance

function UI.SetProvisionsEditor(state)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    state = type(state) == "table" and state or {}
    local draft = type(state.draft) == "table" and state.draft or {}
    local view = UI.frame.views.provisions
    view.settingProvisionEditor = true
    view.provisionNameInput:SetText(draft.name or "")
    local qualitySelection
    if draft.silver == true and draft.gold == true then
        qualitySelection = "either"
    elseif draft.silver == true then
        qualitySelection = "r1"
    elseif draft.gold == true then
        qualitySelection = "r2"
    end
    ProvisionUI.setQualitySelection(view, qualitySelection, false)
    view.provisionTargetInput:SetText(draft.targetText or "")
    view.settingProvisionEditor = false
    view.selectedProvisionId = state.selectedId
    view.provisionDraftValid = state.valid == true
    view.provisionDraftChanged = state.changed == true
    view.provisionValidationError = state.validationError
    UI.SelectProvisionRow(state.selectedId)
    ProvisionUI.updateControlState(view)
    return true
end

updateRosterRefreshButton = nil


function createProvisionsView(view, parent)
    ProvisionUI.createGuildBankBalanceFrame(view, "provisions")
    view.newProvisionButton = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
    styleButton(view.newProvisionButton, "secondary", 32)
    ProvisionUI.fitActionButton(view.newProvisionButton, "New Provision")
    view.newProvisionButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 64, -12)
    view.newProvisionButton:SetScript("OnClick", function()
        if type(RGMS.Provisions) == "table" then
            RGMS.Provisions.New()
        end
    end)

    local auctionatorAvailable = type(RGMS.AuctionatorIntegration) == "table"
        and type(RGMS.AuctionatorIntegration.IsAvailable) == "function"
        and RGMS.AuctionatorIntegration.IsAvailable()
    if auctionatorAvailable then
        view.auctionatorShoppingListButton = CreateFrame(
            "Button", nil, view, "UIPanelButtonTemplate"
        )
        styleButton(view.auctionatorShoppingListButton, "secondary", 32)
        ProvisionUI.fitActionButton(
            view.auctionatorShoppingListButton,
            "Create Auctionator Shopping List"
        )
        view.auctionatorShoppingListButton:SetPoint(
            "LEFT", view.newProvisionButton, "RIGHT", 8, 0
        )
        view.contextStatusLeft = ProvisionUI.CONTEXT_AUCTIONATOR_STATUS_LEFT
        ProvisionUI.setContextStatusLayout(view, false)
        view.auctionatorShoppingListButton:SetScript("OnClick", function()
            if type(RGMS.Provisions) == "table"
                and type(RGMS.Provisions.CreateAuctionatorShoppingList) == "function" then
                RGMS.Provisions.CreateAuctionatorShoppingList()
            end
        end)
    end
    createRefreshButton(view, parent, false, "Refresh the guild bank.", function()
        RGMS.Bank.RequestManualScan()
    end)
    view.bankOpen = false
    view.bankScanInProgress = false
    ProvisionUI.createView(view)
end

end, {
    "SelectProvisionRow",
    "SetProvisionsReport",
    "SetGuildBankBalance",
    "SetProvisionsMoney",
    "SetProvisionsEditor",
})


