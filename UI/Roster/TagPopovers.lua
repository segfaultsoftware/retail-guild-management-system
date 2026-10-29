local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("RosterTagPopovers", function()
TAG_POPOVER_WIDTH = 340
TAG_PILL_HEIGHT = 20
TAG_PILL_GAP = 6
TAG_POPOVER_PADDING = 8

-- AceGUI supplies generic buttons and edit boxes but no wrapping tag-pill
-- selector anchored to virtualized rows; LibQTip is a tabular tooltip library.
-- These small portal-native frames avoid bundling either framework while
-- preserving RGMS styling, immediate persistence, and unrestricted wrapping.
function setTagPillAppearance(button, selected)
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

function acquireTagPill(container, index)
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

function layoutTagPills(container, names, selected, onClick, startX, startY)
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

function findMainsAltsCharacter(report, identity)
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

function updateTagDismissLayer(view)
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

function createMainsAltsTagPopovers(view)
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


end, {
    "OpenMainsAltsTagEditor",
    "ToggleMainsAltsTagFilter",
    "ShowMainsAltsTagPreview",
    "HideMainsAltsTagPreview",
})

