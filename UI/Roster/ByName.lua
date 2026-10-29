local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("RosterByName", function()
MAINS_ALTS_ROW_HEIGHT = 24
MAINS_ALTS_CHECKBOX_SIZE = 16
MAINS_ALTS_CHECKBOX_LEFT = 8
MAINS_ALTS_CONTROL_GAP = 4
MAINS_ALTS_CHARACTER_LEFT = MAINS_ALTS_CHECKBOX_LEFT
    + MAINS_ALTS_CHECKBOX_SIZE + MAINS_ALTS_CONTROL_GAP
MAINS_ALTS_ALT_INDENT = 64
MAINS_ALTS_EXPAND_WIDTH = 16
MAINS_ALTS_PROMOTE_WIDTH = 76
MAINS_ALTS_REMOVE_WIDTH = 68
MAINS_ALTS_NOTE_SIZE = 16
MAINS_ALTS_NOTE_GAP = 4
MAINS_ALTS_TAG_WIDTH = 24
MAINS_ALTS_TAG_SIZE = 16
MAINS_ALTS_RANK_ICON_SIZE = 16
MAINS_ALTS_RANK_ICON_GAP = 4
MAINS_ALTS_SCROLL_DURATION = 0
MAINS_ALTS_WHEEL_ROWS = 3
-- The legacy ScrollFrame is retained for exact pixel anchors and existing styling;
-- only enough complex row controls for the viewport are kept live and recycled.
MAINS_ALTS_VIEWPORT_BUFFER_ROWS = 1
MAINS_ALTS_SEARCH_WIDTH = 252
MAINS_ALTS_SEARCH_HEIGHT = 32
MAINS_ALTS_FILTER_WIDTH = 124
MAINS_ALTS_FILTER_HEIGHT = 28
BY_RANK_CHECKBOX_SIZE = 18
BY_RANK_CONTROL_WIDTH = 88

function layoutMainsAltsLines(view, availableWidth)
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


function createMainsAltsHeader(view)
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


function mainsAltsControlsEnabled(view)
    return UI.dataEnabled ~= false
        and UI.globalScanLocked ~= true
        and view.mainsAltsAvailable ~= false
        and view.mainsAltsScanInProgress ~= true
end

function hideMainsAltsLines(view)
    for _, line in ipairs(view.mainsAltsLinePool or {}) do
        line.frame:Hide()
    end
    view.mainsAltsLines = {}
    view.mainsAltsRows = {}
    view.mainsAltsViewportFirst = nil
    view.mainsAltsViewportLast = nil
    view.mainsAltsTableHeight = nil
end

function updateMainsAltsControlState(view)
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

function acquireMainsAltsLine(view, index)
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

function bindMainsAltsLine(view, line, row, rowIndex)
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

function renderMainsAltsViewport(view, explicitOffset, force)
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

function mainsAltsMaximumScroll(view)
    local contentHeight = type(view.mainsAltsTableHeight) == "number"
        and view.mainsAltsTableHeight
        or view.scrollChild:GetHeight()
    return math.max(0, contentHeight - view.scrollFrame:GetHeight())
end

function clampMainsAltsScroll(view, offset)
    return math.max(0, math.min(offset or 0, mainsAltsMaximumScroll(view)))
end

function setMainsAltsScroll(view, offset)
    view.settingMainsAltsScroll = true
    local clampedOffset = clampMainsAltsScroll(view, offset)
    view.scrollFrame:SetVerticalScroll(clampedOffset)
    view.settingMainsAltsScroll = false
    renderMainsAltsViewport(view, clampedOffset)
end

function cancelMainsAltsScrollAnimation(view)
    view.mainsAltsScrollAnimation = nil
end

function cancelMainsAltsScrollWork(view)
    cancelMainsAltsScrollAnimation(view)
    view.pendingMainsAltsScrollTarget = nil
end

function captureMainsAltsScrollAnchor(view)
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

function findMainsAltsRow(view, identity, topLevelOnly)
    for _, row in ipairs(view.mainsAltsRows or {}) do
        if row.identity == identity
            and (not topLevelOnly or not row.isAlt) then
            return row
        end
    end
    return nil
end

function restoreMainsAltsScrollAnchor(view, anchor)
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

function startMainsAltsScrollAnimation(view, line)
    cancelMainsAltsScrollAnimation(view)
    setMainsAltsScroll(view, line.offset)
end

function updateMainsAltsScrollAnimation(view, elapsed)
    cancelMainsAltsScrollAnimation(view)
end

function renderMainsAlts(view, resolvePendingTarget, preferredAnchor)
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

function updateMainsAltsSearchAppearance(view)
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

function applyMainsAltsSearch(view, resetScroll, resolvePendingTarget)
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

function clearMainsAltsSearch(view, keepFocus)
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

function clearMainsAltsFilters(view, keepSearchFocus)
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

function createMainsAltsSearch(view)
    local editBox = CreateFrame("EditBox", nil, view, "BackdropTemplate")
    editBox:SetSize(MAINS_ALTS_SEARCH_WIDTH, MAINS_ALTS_SEARCH_HEIGHT)
    editBox:SetPoint("TOPLEFT", view:GetParent(), "TOPLEFT", 64, -12)
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


function createRosterByNameView(view, parent)
    createRefreshButton(view, parent, true, "Refresh the guild roster.", function()
        RGMS.Roster.RequestManualScan()
    end)
    view.rosterAvailable = true
    view.rosterScanInProgress = false
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
        "LEFT", view.mainsAltsTagFilterButton, "RIGHT", CONTROL_GAP, 0
    )
    createByRankControl(view, false, view.status, "RIGHT", "LEFT", -CONTROL_GAP, 0)
    createMainsAltsHeader(view)
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
    view.onSizeChanged = function()
        renderMainsAltsViewport(view, nil, true)
    end
    view.refreshVisible = function()
        if type(view.mainsAltsReport) == "table" then
            renderMainsAlts(view)
        end
    end
    createMainsAltsTagPopovers(view)
end

end, {
    "SetMainsAltsReport",
    "CompleteRosterScan",
    "CompleteMainsAltsGrouping",
    "CompleteMainsAltsChange",
    "ToggleMainsAltsGroup",
    "CollapseMainsAltsGroups",
})


