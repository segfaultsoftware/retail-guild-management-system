local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("Charts", function()
local CHART_TYPE_OPTIONS = RGMS.ChartModel.CHART_TYPES
local MEMBER_COLORS = {
    PALETTE.pink,
    PALETTE.success,
    PALETTE.warning,
    { 0.231, 0.51, 0.965, 1 },
    { 0.655, 0.545, 0.98, 1 },
    { 0.133, 0.827, 0.933, 1 },
    { 0.984, 0.455, 0.306, 1 },
    { 0.518, 0.8, 0.086, 1 },
    { 0.953, 0.439, 0.714, 1 },
    { 0.71, 0.639, 0.537, 1 },
}
local CHART_PLOT_HEIGHT = 306
local DOT_SIZE = RGMS.ChartModel.DOT_SIZE
local HALO_SIZE = 14

local function colorFor(chartType, colorIndex)
    if chartType == "members" then
        return MEMBER_COLORS[((colorIndex - 2) % #MEMBER_COLORS) + 1]
    end
    return PALETTE.pink
end

local function acquireTexture(pool, parent, layer, index)
    local texture = pool[index]
    if texture == nil then
        texture = parent:CreateTexture(nil, layer or "ARTWORK")
        pool[index] = texture
    end
    texture:Show()
    return texture
end

local function hidePool(pool)
    for _, texture in ipairs(pool or {}) do
        texture:Hide()
    end
end

local function lineAngle(dy, dx)
    if type(math.atan2) == "function" then
        return math.atan2(dy, dx)
    end
    if dx == 0 then
        return dy >= 0 and math.pi / 2 or -math.pi / 2
    end
    local angle = math.atan(dy / dx)
    if dx < 0 then
        angle = angle + math.pi
    end
    return angle
end

local function drawSolidLine(view, x1, y1, x2, y2, color, thickness)
    local dx, dy = x2 - x1, y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length <= 0 then
        return
    end
    view.chartLineCount = view.chartLineCount + 1
    local line = acquireTexture(
        view.chartLineTextures,
        view.chartPlot,
        "ARTWORK",
        view.chartLineCount
    )
    line:ClearAllPoints()
    line:SetTexture(WHITE_TEXTURE)
    line:SetSize(length, thickness or 2)
    line:SetPoint("CENTER", view.chartPlot, "BOTTOMLEFT", (x1 + x2) / 2, (y1 + y2) / 2)
    line:SetRotation(lineAngle(dy, dx))
    line:SetVertexColor(unpackColor(color))
end

local function drawLine(view, x1, y1, x2, y2, color, dashed, thickness)
    if not dashed then
        drawSolidLine(view, x1, y1, x2, y2, color, thickness)
        return
    end
    local dx, dy = x2 - x1, y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length <= 0 then
        return
    end
    local dash, gap = 7, 5
    local offset = 0
    while offset < length do
        local finish = math.min(length, offset + dash)
        local startRatio = offset / length
        local endRatio = finish / length
        drawSolidLine(
            view,
            x1 + dx * startRatio,
            y1 + dy * startRatio,
            x1 + dx * endRatio,
            y1 + dy * endRatio,
            color,
            thickness
        )
        offset = offset + dash + gap
    end
end

local function drawDot(view, point, color)
    view.chartDotCount = view.chartDotCount + 1
    local dot = acquireTexture(
        view.chartDotTextures,
        view.chartPlot,
        "OVERLAY",
        view.chartDotCount
    )
    dot:ClearAllPoints()
    dot:SetTexture(CIRCLE_TEXTURE)
    dot:SetSize(DOT_SIZE, DOT_SIZE)
    dot:SetPoint("CENTER", view.chartPlot, "BOTTOMLEFT", point.x, point.y)
    dot:SetVertexColor(unpackColor(color))
end

local function resetDrawing(view)
    hidePool(view.chartLineTextures)
    hidePool(view.chartDotTextures)
    view.chartLineCount = 0
    view.chartDotCount = 0
    view.chartHalo:Hide()
    view.chartTooltip:Hide()
end

local function findChartTypeOption(chartType)
    for _, option in ipairs(CHART_TYPE_OPTIONS) do
        if option.index == chartType then
            return option
        end
    end
    return nil
end

local function setTooltipContent(view, point)
    local card = RGMS.ChartModel.tooltip(view.chartType, point)
    if not card then
        view.chartTooltip:Hide()
        return
    end
    local tooltip = view.chartTooltip
    tooltip.title:SetText(card.title)
    tooltip.date:SetText(card.date)
    tooltip.value:SetText(card.valueText or "")
    tooltip.money:SetShown(card.kind == "gold")
    tooltip.value:SetShown(card.kind ~= "gold")
    tooltip.title:ClearAllPoints()
    tooltip.date:ClearAllPoints()
    tooltip.value:ClearAllPoints()
    tooltip.money:ClearAllPoints()
    if card.kind == "gold" then
        tooltip.title:SetJustifyH("LEFT")
        tooltip.title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, -9)
        tooltip.title:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -10, -9)
    else
        tooltip.title:SetJustifyH("LEFT")
        tooltip.title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, -9)
        tooltip.title:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -10, -9)
    end
    if card.kind == "gold" then
        tooltip.money:SetPoint("LEFT", tooltip, "LEFT", 10, 0)
        tooltip.date:SetJustifyH("LEFT")
        tooltip.date:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", 10, 10)
        MoneyFrame_Update(tooltip.money, card.money, true)
    else
        tooltip.date:SetJustifyH("LEFT")
        tooltip.date:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", 10, 10)
        tooltip.value:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -10, 10)
    end
    tooltip:Show()
end

local function updateHover(view)
    local plot = view.chartPlot
    local prepared = view.chartPreparedPlot
    if not prepared or #prepared.points == 0
        or type(plot.IsMouseOver) ~= "function"
        or not plot:IsMouseOver() then
        view.chartHalo:Hide()
        view.chartTooltip:Hide()
        return
    end
    local left, bottom = plot:GetLeft(), plot:GetBottom()
    local frameLeft, frameBottom = UI.frame:GetLeft(), UI.frame:GetBottom()
    if left == nil or bottom == nil or frameLeft == nil or frameBottom == nil then
        return
    end
    local scale = plot:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    local point = RGMS.ChartModel.nearestPoint(
        prepared.points,
        cursorX - left,
        cursorY - bottom
    )
    if not point then
        return
    end
    local color = colorFor(view.chartType, point.colorIndex)
    view.chartHalo:ClearAllPoints()
    view.chartHalo:SetPoint("CENTER", plot, "BOTTOMLEFT", point.x, point.y)
    view.chartHalo:SetVertexColor(color[1], color[2], color[3], 0.35)
    view.chartHalo:Show()
    setTooltipContent(view, point)
    local tooltip = view.chartTooltip
    local x = cursorX - frameLeft + 14
    local y = cursorY - frameBottom + 14
    x = math.max(4, math.min(x, UI.frame:GetWidth() - tooltip:GetWidth() - 4))
    y = math.max(4, math.min(y, UI.frame:GetHeight() - tooltip:GetHeight() - 4))
    tooltip:ClearAllPoints()
    tooltip:SetPoint("BOTTOMLEFT", UI.frame, "BOTTOMLEFT", x, y)
end

local function emptyCopy(chartType)
    if chartType == "gold" then
        return "No guild-bank gold history yet"
    end
    return "No guild-member history yet"
end

local function renderChart(view)
    if not view.chartHistory or not view.chartToday then
        return false
    end
    resetDrawing(view)
    view.chartPlot:SetHeight(CHART_PLOT_HEIGHT)
    local width = math.max(1, view.chartPlot:GetWidth())
    local height = math.max(1, view.chartPlot:GetHeight())
    local prepared, prepareError = RGMS.ChartModel.buildPlot(
        view.chartHistory,
        view.chartType,
        view.chartToday,
        width,
        height
    )
    if not prepared then
        view.chartEmpty:SetText("Charts unavailable: " .. tostring(prepareError))
        view.chartEmpty:Show()
        return nil, prepareError
    end
    view.chartPreparedPlot = prepared
    for _, boundary in ipairs(prepared.monthBoundaries) do
        drawLine(
            view,
            boundary.x,
            0,
            boundary.x,
            height,
            { 0.8, 0.8, 0.82, 0.35 },
            true,
            1
        )
    end
    for _, series in ipairs(prepared.series) do
        local color = colorFor(view.chartType, series.colorIndex)
        if series.regression then
            local regression = series.regression
            drawLine(
                view,
                regression.x1,
                regression.y1,
                regression.x2,
                regression.y2,
                color,
                true,
                2
            )
        end
        for _, point in ipairs(series.plotPoints) do
            drawDot(view, point, color)
        end
    end
    if #prepared.points == 0 then
        view.chartEmpty:SetText(emptyCopy(view.chartType))
        view.chartEmpty:Show()
    else
        view.chartEmpty:Hide()
    end
    return true
end

function UI.SelectChartType(chartType)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    local option = findChartTypeOption(chartType)
    if not option then
        return nil, "chart type must be gold or members"
    end
    if UI.globalScanLocked == true and UI.frame:IsShown() then
        return nil, "scan-locked"
    end
    local view = UI.frame.views.charts
    view.chartType = chartType
    updateDropdownLabel(view.chartTypeDropdown, option, "Guild Bank Gold", true)
    return renderChart(view)
end

function UI.SetChartsHistory(history, today)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    local valid, validationError = RGMS.ChartModel.validate(history)
    if not valid then
        return nil, validationError
    end
    local view = UI.frame.views.charts
    view.chartHistory = history
    view.chartToday = today
    return renderChart(view)
end

function UI.ResetCharts()
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    local view = UI.frame.views.charts
    view.chartType = "gold"
    updateDropdownLabel(
        view.chartTypeDropdown,
        CHART_TYPE_OPTIONS[1],
        "Guild Bank Gold",
        true
    )
    return renderChart(view)
end

local function createChartTooltip(view, parent)
    local tooltip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    tooltip:SetSize(220, 76)
    tooltip:SetFrameLevel(parent:GetFrameLevel() + 80)
    flatBackdrop(tooltip, PALETTE.shell, PALETTE.border)
    tooltip.title = tooltip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    setFont(tooltip.title, FONT_SEMIBOLD, 12)
    setTextColor(tooltip.title, PALETTE.text)
    tooltip.date = tooltip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tooltip.date:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", 10, 10)
    setFont(tooltip.date, FONT_REGULAR, 11)
    setTextColor(tooltip.date, PALETTE.secondary)
    tooltip.value = tooltip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tooltip.value:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -10, 10)
    setFont(tooltip.value, FONT_SEMIBOLD, 12)
    setTextColor(tooltip.value, PALETTE.text)
    tooltip.money = CreateFrame("Frame", nil, tooltip, "SmallMoneyFrameTemplate")
    SmallMoneyFrame_OnLoad(tooltip.money)
    MoneyFrame_SetType(tooltip.money, "GUILD_REPAIR")
    tooltip.money:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -8, 5)
    tooltip:Hide()
    view.chartTooltip = tooltip
end

function createChartsView(view, parent)
    view.scrollFrame:Hide()
    view.text:Hide()
    ProvisionUI.createGuildBankBalanceFrame(view, "charts")
    createRefreshButton(view, parent, false, "Refresh the guild bank.", function()
        RGMS.Bank.RequestManualScan()
    end)
    view.bankOpen = false
    view.bankScanInProgress = false
    view.chartType = "gold"
    view.chartHistory = RGMS.ChartModel.newHistory()
    view.chartTypeDropdown = createDropdown(
        view,
        220,
        "Guild Bank Gold",
        function(chartType)
            UI.SelectChartType(chartType)
        end,
        function()
            return CHART_TYPE_OPTIONS
        end
    )
    view.chartTypeDropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 64, -12)
    updateDropdownLabel(
        view.chartTypeDropdown,
        CHART_TYPE_OPTIONS[1],
        "Guild Bank Gold",
        true
    )

    view.chartPlot = CreateFrame("Frame", nil, view, "BackdropTemplate")
    view.chartPlot:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -28)
    view.chartPlot:SetPoint("TOPRIGHT", view, "TOPRIGHT", 0, -28)
    view.chartPlot:SetHeight(CHART_PLOT_HEIGHT)
    view.chartPlot:SetClipsChildren(true)
    view.chartPlot:EnableMouse(true)
    flatBackdrop(view.chartPlot, { 0, 0, 0, 1 }, PALETTE.border)
    view.chartLineTextures = {}
    view.chartDotTextures = {}
    view.chartLineCount = 0
    view.chartDotCount = 0
    view.chartEmpty = view.chartPlot:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.chartEmpty:SetPoint("CENTER", view.chartPlot, "CENTER", 0, 0)
    view.chartEmpty:SetText(emptyCopy("gold"))
    setFont(view.chartEmpty, FONT_REGULAR, 13)
    setTextColor(view.chartEmpty, PALETTE.secondary)
    view.chartHalo = view.chartPlot:CreateTexture(nil, "OVERLAY")
    view.chartHalo:SetTexture(CIRCLE_TEXTURE)
    view.chartHalo:SetSize(HALO_SIZE, HALO_SIZE)
    view.chartHalo:Hide()
    createChartTooltip(view, parent)
    view.chartPlot:SetScript("OnUpdate", function()
        updateHover(view)
    end)
    view.refreshVisible = function()
        updateDropdownLabel(
            view.chartTypeDropdown,
            findChartTypeOption(view.chartType),
            "Guild Bank Gold",
            true
        )
        renderChart(view)
    end
end

end, {
    "SelectChartType",
    "SetChartsHistory",
    "ResetCharts",
})
