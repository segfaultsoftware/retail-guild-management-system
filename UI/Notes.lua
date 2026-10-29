local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("Notes", function()
CHARACTER_NOTE_LIMIT = 5500
GUILD_NOTE_LIMIT = 31
CHARACTER_NOTE_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\notebook-pen.png"
CHARACTER_TAG_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\tag.png"
GUILD_MASTER_TEXTURE = "Interface\\GroupFrame\\UI-Group-LeaderIcon"
OFFICER_TEXTURE = "Interface\\GroupFrame\\UI-Group-AssistantIcon"
MISSING_WARNING_SIZE = 16

function characterCount(value)
    if type(strlenutf8) == "function" then
        local counted, length = pcall(strlenutf8, value)
        if counted and type(length) == "number" then
            return length
        end
    end
    local withoutContinuationBytes = string.gsub(value, "[\128-\191]", "")
    return #withoutContinuationBytes
end

function truncateCharacters(value, maximum)
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


function createNoteField(editor, key, labelText, y, height, limit, readOnly)
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

function createNotesEditor(owner)
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


end, {
    "OpenCharacterNote",
    "CloseCharacterNoteEditor",
    "SetCharacterNoteState",
})

