-- Deterministic chart history reduction and plot math.
-- Retail frames consume the prepared plot; this module deliberately has no
-- dependency on WoW UI APIs so persistence and geometry remain testable.

local _, RGMS = ...

local Model = {}
local DateTime = type(RGMS) == "table"
    and RGMS.DateTime
    or require("Core.DateTime")

Model.RETENTION_DAYS = 180
Model.DOT_SIZE = 7
Model.HORIZONTAL_DOT_CLEARANCE = 5
Model.VERTICAL_DOT_CLEARANCE = 2
Model.CHART_TYPES = {
    { index = "gold", name = "Guild Bank Gold" },
    { index = "members", name = "Guild Members" },
}

local function isInteger(value, minimum)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value == math.floor(value)
        and (minimum == nil or value >= minimum)
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[deepCopy(key)] = deepCopy(item)
    end
    return result
end

local function exactKeys(value, allowed, path)
    if type(value) ~= "table" then
        return nil, path .. " must be a table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, path .. " contains unexpected field " .. tostring(key)
        end
    end
    return true
end

local function denseArray(value, path)
    if type(value) ~= "table" then
        return nil, path .. " must be an array"
    end
    local count = 0
    for key in pairs(value) do
        if not isInteger(key, 1) then
            return nil, path .. " must contain only positive integer indexes"
        end
        count = count + 1
    end
    if count ~= #value then
        return nil, path .. " must not contain gaps"
    end
    return true
end

local function validatePoints(points, path, requirePoint)
    local valid, validationError = denseArray(points, path)
    if not valid then
        return nil, validationError
    end
    if requirePoint and #points == 0 then
        return nil, path .. " must contain at least one point"
    end
    local previousDay
    for index, point in ipairs(points) do
        local pointPath = path .. "[" .. index .. "]"
        valid, validationError = exactKeys(point, {
            date = true,
            value = true,
        }, pointPath)
        if not valid then
            return nil, validationError
        end
        local dayNumber, dateError = DateTime.calendarDayNumber(point.date)
        if dayNumber == nil then
            return nil, pointPath .. ".date " .. dateError
        end
        if previousDay ~= nil and dayNumber <= previousDay then
            return nil, path .. " dates must be unique and chronological"
        end
        if not isInteger(point.value, 0) then
            return nil, pointPath .. ".value must be a non-negative integer"
        end
        previousDay = dayNumber
    end
    return true
end

function Model.newHistory()
    return {
        gold = {},
        members = {},
    }
end

function Model.validate(history, path)
    path = path or "chart history"
    local valid, validationError = exactKeys(history, {
        gold = true,
        members = true,
    }, path)
    if not valid then
        return nil, validationError
    end

    valid, validationError = validatePoints(history.gold, path .. ".gold", false)
    if not valid then
        return nil, validationError
    end

    valid, validationError = denseArray(history.members, path .. ".members")
    if not valid then
        return nil, validationError
    end
    local rankIndexes = {}
    for index, series in ipairs(history.members) do
        local seriesPath = path .. ".members[" .. index .. "]"
        valid, validationError = exactKeys(series, {
            rankIndex = true,
            name = true,
            points = true,
        }, seriesPath)
        if not valid then
            return nil, validationError
        end
        if not isInteger(series.rankIndex, 2) then
            return nil, seriesPath .. ".rankIndex must be an integer of at least 2"
        end
        if rankIndexes[series.rankIndex] then
            return nil, path .. ".members must use unique rank indexes"
        end
        rankIndexes[series.rankIndex] = true
        if type(series.name) ~= "string" or series.name == "" then
            return nil, seriesPath .. ".name must be a non-empty string"
        end
        valid, validationError = validatePoints(
            series.points,
            seriesPath .. ".points",
            true
        )
        if not valid then
            return nil, validationError
        end
    end
    return true
end

local function pointDay(point)
    return DateTime.calendarDayNumber(point.date)
end

local function sortPoints(points)
    table.sort(points, function(left, right)
        return pointDay(left) < pointDay(right)
    end)
end

local function replacePoint(points, date, value)
    local result = {}
    for _, point in ipairs(points or {}) do
        if point.date ~= date then
            result[#result + 1] = point
        end
    end
    if value ~= nil then
        result[#result + 1] = { date = date, value = value }
    end
    sortPoints(result)
    return result
end

local function retainedPoints(points, firstDay, lastDay)
    local result = {}
    for _, point in ipairs(points or {}) do
        local dayNumber = pointDay(point)
        if dayNumber >= firstDay and dayNumber <= lastDay then
            result[#result + 1] = point
        end
    end
    return result
end

function Model.prune(history, today)
    local valid, validationError = Model.validate(history)
    if not valid then
        return nil, validationError
    end
    local lastDay, dateError = DateTime.calendarDayNumber(today)
    if lastDay == nil then
        return nil, dateError
    end
    local firstDay = lastDay - Model.RETENTION_DAYS + 1
    local result = deepCopy(history)
    result.gold = retainedPoints(result.gold, firstDay, lastDay)

    local retainedMembers = {}
    for _, series in ipairs(result.members) do
        series.points = retainedPoints(series.points, firstDay, lastDay)
        if #series.points > 0 then
            retainedMembers[#retainedMembers + 1] = series
        end
    end
    result.members = retainedMembers
    return result
end

local function snapshotDate(snapshot)
    if type(snapshot) ~= "table"
        or type(snapshot.scannedAt) ~= "table"
        or not isInteger(snapshot.scannedAt.unixSeconds, 0) then
        return nil, "chart snapshot requires a completion timestamp"
    end
    return DateTime.currentPacificDate(snapshot.scannedAt.unixSeconds)
end

function Model.recordBank(history, snapshot)
    local date, dateError = snapshotDate(snapshot)
    if not date then
        return nil, dateError
    end
    if not isInteger(snapshot.money, 0) then
        return nil, "bank chart snapshot money must be a non-negative integer"
    end
    local result, pruneError = Model.prune(history, date)
    if not result then
        return nil, pruneError
    end
    result.gold = replacePoint(result.gold, date, snapshot.money)
    return Model.prune(result, date)
end

function Model.recordRoster(history, snapshot)
    local date, dateError = snapshotDate(snapshot)
    if not date then
        return nil, dateError
    end
    local result, pruneError = Model.prune(history, date)
    if not result then
        return nil, pruneError
    end

    local configured = {}
    for _, rank in ipairs(snapshot.ranks or {}) do
        if isInteger(rank.index, 2)
            and type(rank.name) == "string"
            and rank.name ~= "" then
            configured[rank.index] = { name = rank.name, count = 0 }
        end
    end
    for _, member in ipairs(snapshot.members or {}) do
        local rank = configured[member.rankIndex]
        if rank then
            rank.count = rank.count + 1
        end
    end

    local byRank = {}
    for _, series in ipairs(result.members) do
        series.points = replacePoint(series.points, date, nil)
        byRank[series.rankIndex] = series
    end
    for rankIndex, observed in pairs(configured) do
        local series = byRank[rankIndex]
        if not series then
            series = {
                rankIndex = rankIndex,
                name = observed.name,
                points = {},
            }
            byRank[rankIndex] = series
        end
        series.name = observed.name
        series.points = replacePoint(series.points, date, observed.count)
    end
    local memberSeries = {}
    for _, series in pairs(byRank) do
        if #series.points > 0 then
            memberSeries[#memberSeries + 1] = series
        end
    end
    table.sort(memberSeries, function(left, right)
        return left.rankIndex < right.rankIndex
    end)
    result.members = memberSeries
    return Model.prune(result, date)
end

function Model.linearRegression(points)
    if type(points) ~= "table" or #points < 2 then
        return nil
    end
    local firstX = points[1].dayNumber or DateTime.calendarDayNumber(points[1].date)
    local sumX, sumY = 0, 0
    for _, point in ipairs(points) do
        local x = (point.dayNumber or DateTime.calendarDayNumber(point.date)) - firstX
        sumX = sumX + x
        sumY = sumY + point.value
    end
    local meanX = sumX / #points
    local meanY = sumY / #points
    local numerator, denominator = 0, 0
    for _, point in ipairs(points) do
        local x = (point.dayNumber or DateTime.calendarDayNumber(point.date)) - firstX
        local deltaX = x - meanX
        numerator = numerator + deltaX * (point.value - meanY)
        denominator = denominator + deltaX * deltaX
    end
    if denominator == 0 then
        return nil
    end
    local slope = numerator / denominator
    return {
        slope = slope,
        intercept = meanY - slope * meanX,
        originDay = firstX,
    }
end

local function regressionValue(regression, dayNumber)
    return regression.intercept
        + regression.slope * (dayNumber - regression.originDay)
end

local function clippedRegression(regression, firstDay, lastDay, maximum)
    local startDay, endDay = firstDay, lastDay
    local startValue = regressionValue(regression, startDay)
    local endValue = regressionValue(regression, endDay)
    if maximum == 0 then
        if startValue == 0 and endValue == 0 then
            return startDay, 0, endDay, 0
        end
        return nil
    end
    if startValue < 0 and endValue < 0 then
        return nil
    end
    if startValue > maximum and endValue > maximum then
        return nil
    end
    local function dayAt(value)
        return regression.originDay + (value - regression.intercept) / regression.slope
    end
    if regression.slope ~= 0 then
        if startValue < 0 then
            startDay, startValue = dayAt(0), 0
        elseif startValue > maximum then
            startDay, startValue = dayAt(maximum), maximum
        end
        if endValue < 0 then
            endDay, endValue = dayAt(0), 0
        elseif endValue > maximum then
            endDay, endValue = dayAt(maximum), maximum
        end
    end
    if startDay > lastDay or endDay < firstDay or startDay > endDay then
        return nil
    end
    return math.max(firstDay, startDay), startValue,
        math.min(lastDay, endDay), endValue
end

local function sourceSeries(history, chartType)
    if chartType == "gold" then
        return { {
            id = "gold",
            name = "Gold",
            colorIndex = 1,
            points = history.gold,
        } }
    elseif chartType == "members" then
        local result = {}
        for _, series in ipairs(history.members) do
            result[#result + 1] = {
                id = series.rankIndex,
                rankIndex = series.rankIndex,
                name = series.name,
                colorIndex = series.rankIndex,
                points = series.points,
            }
        end
        return result
    end
    return nil, "chart type must be gold or members"
end

local function plotY(value, maximum, height, padding)
    if maximum == 0 then
        return padding
    end
    return padding + (height - padding * 2) * value / maximum
end

function Model.buildPlot(history, chartType, today, width, height)
    local valid, validationError = Model.validate(history)
    if not valid then
        return nil, validationError
    end
    width = tonumber(width) or 0
    height = tonumber(height) or 0
    if width <= 0 or height <= 0 then
        return nil, "plot width and height must be positive"
    end
    local lastDay, dateError = DateTime.calendarDayNumber(today)
    if lastDay == nil then
        return nil, dateError
    end
    local visibleHistory, pruneError = Model.prune(history, today)
    if not visibleHistory then
        return nil, pruneError
    end
    local series, seriesError = sourceSeries(visibleHistory, chartType)
    if not series then
        return nil, seriesError
    end
    local firstDay
    local finalDay
    local maximum = 0
    for _, entry in ipairs(series) do
        for _, point in ipairs(entry.points) do
            local dayNumber = DateTime.calendarDayNumber(point.date)
            firstDay = firstDay and math.min(firstDay, dayNumber) or dayNumber
            finalDay = finalDay and math.max(finalDay, dayNumber) or dayNumber
            maximum = math.max(maximum, point.value)
        end
    end
    firstDay = firstDay or lastDay
    finalDay = finalDay or lastDay
    local daySpan = finalDay - firstDay
    local dotRadius = Model.DOT_SIZE / 2
    local horizontalPadding = math.min(
        Model.HORIZONTAL_DOT_CLEARANCE + dotRadius,
        width / 2
    )
    local verticalPadding = math.min(
        Model.VERTICAL_DOT_CLEARANCE + dotRadius,
        height / 2
    )
    local interiorWidth = width - horizontalPadding * 2
    local function plotX(dayNumber)
        if daySpan == 0 then
            return width / 2
        end
        return horizontalPadding
            + interiorWidth * (dayNumber - firstDay) / daySpan
    end
    local flatPoints = {}
    for seriesIndex, entry in ipairs(series) do
        entry.plotPoints = {}
        for pointIndex, point in ipairs(entry.points) do
            local dayNumber = DateTime.calendarDayNumber(point.date)
            local prepared = {
                date = point.date,
                value = point.value,
                dayNumber = dayNumber,
                x = plotX(dayNumber),
                y = plotY(point.value, maximum, height, verticalPadding),
                seriesIndex = seriesIndex,
                pointIndex = pointIndex,
                seriesId = entry.id,
                seriesName = entry.name,
                rankIndex = entry.rankIndex,
                colorIndex = entry.colorIndex,
            }
            entry.plotPoints[#entry.plotPoints + 1] = prepared
            flatPoints[#flatPoints + 1] = prepared
        end
        local regression = Model.linearRegression(entry.plotPoints)
        if regression then
            local startDay, startValue, endDay, endValue = clippedRegression(
                regression,
                firstDay,
                finalDay,
                maximum
            )
            if startDay then
                entry.regression = {
                    x1 = plotX(startDay),
                    y1 = plotY(startValue, maximum, height, verticalPadding),
                    x2 = plotX(endDay),
                    y2 = plotY(endValue, maximum, height, verticalPadding),
                    slope = regression.slope,
                }
            end
        end
    end

    local monthBoundaries = {}
    for dayNumber = firstDay, finalDay do
        local date = DateTime.dateFromCalendarDayNumber(dayNumber)
        local parsed = DateTime.parseStoredDate(date)
        if parsed.day == 1 then
            monthBoundaries[#monthBoundaries + 1] = {
                date = date,
                x = plotX(dayNumber),
            }
        end
    end
    return {
        chartType = chartType,
        firstDate = DateTime.dateFromCalendarDayNumber(firstDay),
        lastDate = DateTime.dateFromCalendarDayNumber(finalDay),
        firstDay = firstDay,
        lastDay = finalDay,
        maximum = maximum,
        width = width,
        height = height,
        padding = verticalPadding,
        dotSize = Model.DOT_SIZE,
        horizontalDotClearance = Model.HORIZONTAL_DOT_CLEARANCE,
        verticalDotClearance = Model.VERTICAL_DOT_CLEARANCE,
        horizontalPadding = horizontalPadding,
        verticalPadding = verticalPadding,
        monthBoundaries = monthBoundaries,
        series = series,
        points = flatPoints,
    }
end

function Model.nearestPoint(points, cursorX, cursorY)
    local nearest
    local nearestDistance
    for _, point in ipairs(points or {}) do
        local dx = point.x - cursorX
        local dy = point.y - cursorY
        local distance = dx * dx + dy * dy
        if nearestDistance == nil or distance < nearestDistance then
            nearest = point
            nearestDistance = distance
        end
    end
    return nearest, nearestDistance
end

function Model.tooltip(chartType, point)
    if type(point) ~= "table" then
        return nil, "chart point is required"
    end
    local date, dateError = DateTime.formatLongDate(point.date)
    if not date then
        return nil, dateError
    end
    if chartType == "gold" then
        return {
            kind = "gold",
            title = "Gold",
            date = date,
            money = point.value,
        }
    elseif chartType == "members" then
        return {
            kind = "members",
            title = point.seriesName,
            date = date,
            valueText = tostring(point.value) .. " members",
        }
    end
    return nil, "chart type must be gold or members"
end

if type(RGMS) == "table" then
    RGMS.ChartModel = Model
end

return Model
