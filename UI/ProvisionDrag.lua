local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("ProvisionDrag", function()
function ProvisionUI.ensureDragPreview(view)
    if view.provisionDragPreview then
        return view.provisionDragPreview
    end
    local preview = ProvisionUI.createRowVisual(UIParent)
    preview.frame:SetFrameStrata("TOOLTIP")
    preview.frame:SetFrameLevel(ProvisionUI.DRAG_FRAME_LEVEL)
    preview.frame:EnableMouse(false)
    preview.deleteButton:EnableMouse(false)
    preview.frame:Hide()
    view.provisionDragPreview = preview
    return preview
end

function ProvisionUI.positionDragPreview(view, x, y)
    local drag = view.provisionDrag
    if not drag or not drag.dragging then
        return
    end
    local preview = ProvisionUI.ensureDragPreview(view)
    local left = ProvisionUI.frameRect(view.provisionScrollFrame)
    left = left or drag.previewLeft or 0
    drag.previewLeft = left
    preview.frame:ClearAllPoints()
    preview.frame:SetPoint(
        "TOPLEFT",
        UIParent,
        "BOTTOMLEFT",
        left,
        y + drag.grabOffset
    )
end

function ProvisionUI.findRowIndex(rows, id)
    for index, row in ipairs(rows or {}) do
        if row.id == id then
            return index
        end
    end
    return nil
end

function ProvisionUI.applyProspectiveOrder(view)
    local drag = view.provisionDrag
    if not drag then
        return
    end
    ProvisionUI.setRowsAlpha(view, 1)
    view.applyingProvisionDrag = true
    UI.SetProvisionsReport({ rows = drag.rows }, view.selectedProvisionId)
    view.applyingProvisionDrag = nil
    local index = ProvisionUI.findRowIndex(drag.rows, drag.sourceId)
    local line = index and view.provisionRows[index] or nil
    if line then
        line.frame:SetAlpha(0)
    end
end

function ProvisionUI.beginDrag(view, x, y)
    local drag = view.provisionDrag
    if not drag or drag.dragging then
        return
    end
    drag.dragging = true
    drag.line.suppressNextClick = true
    local preview = ProvisionUI.ensureDragPreview(view)
    ProvisionUI.renderRow(preview, drag.sourceRow)
    for _, edge in pairs(preview.selectionBorder) do
        edge:SetShown(drag.sourceId == view.selectedProvisionId)
    end
    preview.frame:SetWidth(math.max(1, view.provisionScrollChild:GetWidth()))
    local sourceTop = type(drag.line.frame.GetTop) == "function"
        and drag.line.frame:GetTop()
        or nil
    drag.grabOffset = type(sourceTop) == "number"
        and sourceTop - y
        or ProvisionUI.ROW_HEIGHT / 2
    preview.frame:Show()
    ProvisionUI.applyProspectiveOrder(view)
    ProvisionUI.positionDragPreview(view, x, y)
end

function ProvisionUI.pressRow(view, line)
    if UI.dataEnabled == false or UI.globalScanLocked == true
        or not line.row or view.provisionDrag then
        return nil
    end
    line.suppressNextClick = nil
    local rows = type(view.provisionsReport) == "table"
        and view.provisionsReport.rows
        or nil
    local sourceIndex = ProvisionUI.findRowIndex(rows, line.row.id)
    if not sourceIndex then
        return nil
    end
    local x, y = ProvisionUI.cursorPosition()
    view.provisionDrag = {
        dragging = false,
        sourceId = line.row.id,
        sourceRow = line.row,

        sourceIndex = sourceIndex,
        line = line,
        startX = x,
        startY = y,
        rows = ProvisionUI.copyRows(rows),
        originalRows = ProvisionUI.copyRows(rows),
    }
    return true
end

function ProvisionUI.updateProspectiveIndex(view, x, y)
    local drag = view.provisionDrag
    local left, bottom, right, top = ProvisionUI.frameRect(view.provisionScrollFrame)
    if not left or x < left or x > right then
        return false
    end
    local index = ProvisionUI.findRowIndex(drag.rows, drag.sourceId)
    if not index then
        return false
    end
    local pitch = ProvisionUI.ROW_HEIGHT + ProvisionUI.ROW_GAP
    local boundedY = math.max(bottom, math.min(top, y))
    local contentY = top - boundedY + view.provisionScrollFrame:GetVerticalScroll()
    local changed = false
    while index > 1 do
        local previousMidpoint = 2 + (index - 2) * pitch + ProvisionUI.ROW_HEIGHT / 2
        if contentY >= previousMidpoint then
            break
        end
        drag.rows[index], drag.rows[index - 1] = drag.rows[index - 1], drag.rows[index]
        index = index - 1
        changed = true
    end
    while index < #drag.rows do
        local nextMidpoint = 2 + index * pitch + ProvisionUI.ROW_HEIGHT / 2
        if contentY <= nextMidpoint then
            break
        end
        drag.rows[index], drag.rows[index + 1] = drag.rows[index + 1], drag.rows[index]
        index = index + 1
        changed = true
    end
    if changed then
        ProvisionUI.applyProspectiveOrder(view)
    end
    return changed
end

function ProvisionUI.updateAutoScroll(view, x, y, elapsed)
    local left, bottom, right, top = ProvisionUI.frameRect(view.provisionScrollFrame)
    if not left or x < left or x > right then
        return false
    end
    local direction = 0
    if y >= top - ProvisionUI.DRAG_EDGE_ZONE then
        direction = -1
    elseif y <= bottom + ProvisionUI.DRAG_EDGE_ZONE then
        direction = 1
    end
    if direction == 0 then
        return false
    end
    local maximum = math.max(
        0,
        view.provisionScrollChild:GetHeight() - view.provisionScrollFrame:GetHeight()
    )
    local current = view.provisionScrollFrame:GetVerticalScroll()
    local target = math.max(
        0,
        math.min(maximum, current + direction * ProvisionUI.DRAG_SCROLL_SPEED * elapsed)
    )
    if target == current then
        return false
    end
    view.provisionScrollFrame:SetVerticalScroll(target)
    return true
end

function ProvisionUI.updateDrag(view, elapsed)
    local drag = view.provisionDrag
    if not drag then
        return
    end
    local x, y = ProvisionUI.cursorPosition()
    if not drag.dragging then
        local dx = x - drag.startX
        local dy = y - drag.startY
        if dx * dx + dy * dy >= ProvisionUI.DRAG_THRESHOLD * ProvisionUI.DRAG_THRESHOLD then
            ProvisionUI.beginDrag(view, x, y)
        end
    end
    if drag.dragging then
        ProvisionUI.updateAutoScroll(view, x, y, elapsed or 0)
        ProvisionUI.updateProspectiveIndex(view, x, y)
        ProvisionUI.positionDragPreview(view, x, y)
    end
    if type(IsMouseButtonDown) == "function" and not IsMouseButtonDown("LeftButton") then
        ProvisionUI.finishDrag(view)
    end
end

function ProvisionUI.orderIds(rows)
    local ids = {}
    for index, row in ipairs(rows or {}) do
        ids[index] = row.id
    end
    return ids
end

function ProvisionUI.orderChanged(drag)
    for index, row in ipairs(drag.rows) do
        if drag.originalRows[index] ~= row then
            return true
        end
    end
    return false
end

function ProvisionUI.finishDrag(view)
    local drag = view.provisionDrag
    if not drag then
        return false
    end
    if not drag.dragging then
        view.provisionDrag = nil
        return false
    end

    local changed = ProvisionUI.orderChanged(drag)
    ProvisionUI.setRowsAlpha(view, 1)
    if view.provisionDragPreview then
        view.provisionDragPreview.frame:Hide()
    end
    view.provisionDrag = nil
    if not changed then
        view.applyingProvisionDrag = true
        UI.SetProvisionsReport({ rows = drag.originalRows }, view.selectedProvisionId)
        view.applyingProvisionDrag = nil
        return false
    end

    local reordered, reorderError
    if type(RGMS.Provisions) == "table"
        and type(RGMS.Provisions.Reorder) == "function" then
        reordered, reorderError = RGMS.Provisions.Reorder(ProvisionUI.orderIds(drag.rows))
    else
        reorderError = "provision reordering is unavailable"
    end
    if not reordered then
        view.applyingProvisionDrag = true
        UI.SetProvisionsReport({ rows = drag.originalRows }, view.selectedProvisionId)
        view.applyingProvisionDrag = nil
        return nil, reorderError
    end
    return true
end

function UI.CancelProvisionDrag()
    if not UI.frame then
        return false
    end
    local view = UI.frame.views.provisions
    local drag = view and view.provisionDrag
    if not drag then
        return false
    end
    ProvisionUI.setRowsAlpha(view, 1)
    if view.provisionDragPreview then
        view.provisionDragPreview.frame:Hide()
    end
    view.provisionDrag = nil
    view.applyingProvisionDrag = true
    UI.SetProvisionsReport({ rows = drag.originalRows }, view.selectedProvisionId)
    view.applyingProvisionDrag = nil
    return true
end


end, {
    "CancelProvisionDrag",
})

