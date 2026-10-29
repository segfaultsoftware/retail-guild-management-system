local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("Tags", function()
-- Keep tag management on RGMS's established fixed-header ScrollFrame pattern.
-- External table libraries add their own styling and selection model, while
-- the native modern ScrollBox wrappers do not improve this small three-column
-- view enough to justify a new bundled dependency.
TAG_MANAGEMENT_ROW_HEIGHT = 24
TAG_MANAGEMENT_NAME_WIDTH = 180
TAG_MANAGEMENT_DELETE_WIDTH = 36

function layoutTagManagementLines(view, availableWidth)
    if type(view.tagRows) ~= "table" then
        return
    end

    local previewWidth = math.max(
        1,
        availableWidth - TAG_MANAGEMENT_NAME_WIDTH - TAG_MANAGEMENT_DELETE_WIDTH
    )
    local lines = {}
    if view.tagHeader then
        lines[#lines + 1] = view.tagHeader
    end
    for _, line in ipairs(view.tagRows) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(lines) do
        line.frame:SetWidth(availableWidth)
        line.name:ClearAllPoints()
        line.preview:ClearAllPoints()
        line.name:SetPoint("LEFT", line.frame, "LEFT", 8, 0)
        line.name:SetWidth(math.max(1, TAG_MANAGEMENT_NAME_WIDTH - 8))
        line.preview:SetPoint(
            "LEFT",
            line.frame,
            "LEFT",
            TAG_MANAGEMENT_NAME_WIDTH,
            0
        )
        line.preview:SetWidth(previewWidth)
        if line.delete then
            line.delete:ClearAllPoints()
            line.delete:SetPoint("RIGHT", line.frame, "RIGHT", -8, 0)
            line.delete:SetWidth(math.max(1, TAG_MANAGEMENT_DELETE_WIDTH - 8))
        end
        if line.deleteButton then
            line.deleteButton:ClearAllPoints()
            line.deleteButton:SetPoint("RIGHT", line.frame, "RIGHT", -8, 0)
        end
    end
end


function configureTagManagementText(text)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    if type(text.SetWordWrap) == "function" then
        text:SetWordWrap(false)
    end
    if type(text.SetMaxLines) == "function" then
        text:SetMaxLines(1)
    end
end

function createTagManagementHeader(view)
    local frame = CreateFrame("Frame", nil, view, "BackdropTemplate")
    flatBackdrop(frame, PALETTE.control, PALETTE.border)
    frame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    frame:SetPoint("TOPRIGHT", view, "TOPRIGHT", -8, 0)
    frame:SetHeight(28)
    local header = {
        frame = frame,
        name = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        preview = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        delete = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
    }
    header.name:SetText("Tag")
    header.preview:SetText("")
    header.delete:SetText("")
    for _, label in ipairs({ header.name, header.preview, header.delete }) do
        configureTagManagementText(label)
        setFont(label, FONT_SEMIBOLD, 12)
        setTextColor(label, PALETTE.text)
    end
    view.tagHeader = header
    return header
end

function updateTagDeleteButton(line)
    local enabled = line.row ~= nil
        and line.row.immutable ~= true
        and UI.globalScanLocked ~= true
        and UI.dataEnabled ~= false
    line.deleteEnabled = enabled
    line.deleteButton:SetEnabled(enabled)
    if type(line.deleteButton.SetAlpha) == "function" then
        line.deleteButton:SetAlpha(line.deleteEnabled and 1 or 0.45)
    end
    setTextureColor(
        line.deleteIcon,
        line.deleteEnabled and PALETTE.text or PALETTE.disabled
    )
end

function hideTagManagementRows(view)
    for _, line in ipairs(view.tagRows or {}) do
        hideOwnedTooltip(line.deleteButton)
        line.frame:Hide()
    end
    view.tagTableHeight = nil
end

function acquireTagManagementRow(view, index)
    local line = view.tagRows[index]
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
    local name = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local preview = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local deleteButton = CreateFrame("Button", nil, frame)
    deleteButton:SetSize(20, 20)
    local deleteIcon = deleteButton:CreateTexture(nil, "ARTWORK")
    deleteIcon:SetAllPoints(deleteButton)
    if type(deleteIcon.SetAtlas) == "function" then
        deleteIcon:SetAtlas(TAG_DELETE_ATLAS)
    end
    line = {
        frame = frame,
        background = background,
        name = name,
        preview = preview,
        deleteButton = deleteButton,
        deleteIcon = deleteIcon,
    }
    configureTagManagementText(name)
    configureTagManagementText(preview)
    setFont(name, FONT_REGULAR, 12)
    setFont(preview, FONT_REGULAR, 12)
    setTextColor(name, PALETTE.text)
    setTextColor(preview, PALETTE.secondary)
    enableRowHover(line)
    deleteButton:SetScript("OnEnter", function(button)
        if line.deleteEnabled then
            line.background:SetVertexColor(unpackColor(PALETTE.control))
            setTextureColor(line.deleteIcon, PALETTE.pinkHover)
        end
    end)
    deleteButton:SetScript("OnLeave", function(button)
        line.background:SetVertexColor(unpackColor(line.baseColor or PALETTE.surface))
        updateTagDeleteButton(line)
    end)
    deleteButton:SetScript("OnClick", function()
        if line.row and line.deleteEnabled then
            UI.RequestTagDeletion(line.row)
        end
    end)
    view.tagRows[index] = line
    return line
end

function renderTagManagement(view, report)
    view.text:Hide()
    hideTagManagementRows(view)
    local header = view.tagHeader or createTagManagementHeader(view)
    header.frame:Show()

    local offset = 0
    for index, row in ipairs(report.rows) do
        local line = acquireTagManagementRow(view, index)
        line.row = row
        line.frame:ClearAllPoints()
        line.frame:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
        line.frame:SetHeight(TAG_MANAGEMENT_ROW_HEIGHT)
        line.name:SetText(row.name)
        line.preview:SetText(row.characterPreview)
        line.baseColor = (index % 2 == 0) and PALETTE.zebra or PALETTE.surface
        line.background:SetVertexColor(unpackColor(line.baseColor))
        updateTagDeleteButton(line)
        line.frame:Show()
        offset = offset + TAG_MANAGEMENT_ROW_HEIGHT
    end
    for index = #report.rows + 1, #view.tagRows do
        local line = view.tagRows[index]
        hideOwnedTooltip(line.deleteButton)
        line.row = nil
        line.frame:Hide()
    end
    view.tagTableHeight = offset + 4
    refreshScrollChild(view)
end


function UI.SetTagsReport(report)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(report) ~= "table" or type(report.rows) ~= "table" then
        return nil, "tag report must contain rows"
    end

    local view = UI.frame.views.tags
    view.tagReport = report
    renderTagManagement(view, report)
    return true
end

function ensureTagDeleteDialog()
    if type(StaticPopupDialogs) ~= "table" then
        return false
    end
    if StaticPopupDialogs[TAG_DELETE_DIALOG_KEY] == nil then
        StaticPopupDialogs[TAG_DELETE_DIALOG_KEY] = {
            text = "%s",
            button1 = ACCEPT,
            button2 = CANCEL,
            OnAccept = function(_, request)
                local deleted, deleteError
                if type(RGMS.MainsAlts) == "table"
                    and type(RGMS.MainsAlts.DeleteTag) == "function" then
                    deleted, deleteError = RGMS.MainsAlts.DeleteTag(request.name)
                else
                    deleteError = "character tag deletion is unavailable"
                end
                if not deleted and type(RGMS.Print) == "function" then
                    RGMS.Print(
                        "Could not delete tag '" .. tostring(request.name)
                            .. "': " .. tostring(deleteError) .. "."
                    )
                end
            end,
            OnCancel = function() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    return true
end

function UI.RequestTagDeletion(row)
    if type(row) ~= "table" or type(row.name) ~= "string" or row.name == "" then
        return nil, "tag deletion requires a tag row"
    end
    if row.immutable then
        return nil, "the me tag is immutable"
    end
    if UI.globalScanLocked == true then
        return nil, "scan-locked"
    end
    if not ensureTagDeleteDialog() or type(StaticPopup_Show) ~= "function" then
        return nil, "tag deletion confirmation is unavailable"
    end

    local count = tonumber(row.characterCount) or 0
    local message = "Delete tag '" .. row.name .. "'? This will remove it from "
        .. tostring(count) .. (count == 1 and " character" or " characters")
        .. " and cannot be undone."
    local request = { name = row.name }
    local popup = StaticPopup_Show(
        TAG_DELETE_DIALOG_KEY,
        message,
        nil,
        request
    )
    if not popup and type(RGMS.Print) == "function" then
        RGMS.Print(
            "Could not open the deletion confirmation for tag '"
                .. row.name .. "'. No data was changed."
        )
        return nil, "tag deletion confirmation could not be opened"
    end
    return popup
end


function createTagsView(view)
    view.tagRows = {}
    createTagManagementHeader(view)
    view.refreshVisible = function()
        if type(RGMS.MainsAlts) == "table"
            and type(RGMS.MainsAlts.RefreshTags) == "function" then
            RGMS.MainsAlts.RefreshTags()
        end
    end
end

end, {
    "SetTagsReport",
    "RequestTagDeletion",
})


