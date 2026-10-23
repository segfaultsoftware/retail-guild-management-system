-- Pure roster-report projection. It derives navigable rank tabs and grouped
-- member rows without retaining references to, or mutating, saved observations.

local _, RGMS = ...

local Report = {}
local Names = type(RGMS) == "table"
    and RGMS.RosterNames
    or require("Roster.Names")

Report.EMPTY_GROUP_TEXT = "<no members in this bracket>"
Report.GROUPS = {
    { id = "this-week", title = "This Week", minimumDays = 0, maximumDays = 6 },
    { id = "last-week", title = "Last Week", minimumDays = 7, maximumDays = 13 },
    { id = "two-weeks-ago", title = "Two Weeks Ago", minimumDays = 14, maximumDays = 20 },
    { id = "been-a-while", title = "It's Been a While", minimumDays = 21 },
}

local function pluralized(value, singular)
    if value == 1 then
        return "1 " .. singular .. " ago"
    end
    return tostring(value) .. " " .. singular .. "s ago"
end

local function approximateLastOnline(member, elapsedDays)
    if member.isOnline then
        return 0, "Online"
    end
    if type(member.lastOnline) ~= "table" then
        return nil, "Unknown"
    end

    local years = member.lastOnline.years or 0
    local months = member.lastOnline.months or 0
    local days = (member.lastOnline.days or 0) + elapsedDays
    local hours = member.lastOnline.hours or 0
    local ageDays = years * 365 + months * 30 + days

    -- Retain the largest unit supplied by the game instead of converting it
    -- to a more precise-looking value that the source observation cannot prove.
    if years > 0 then
        return ageDays, pluralized(math.max(1, math.floor(ageDays / 365)), "year")
    end
    if months > 0 then
        return ageDays, pluralized(math.max(1, math.floor(ageDays / 30)), "month")
    end
    if days > 0 then
        return ageDays, pluralized(days, "day")
    end
    if hours > 0 then
        return ageDays, pluralized(hours, "hour")
    end
    return ageDays, "Less than an hour ago"
end

local function differenceOrZero(earlierDate, laterDate, dateTime)
    local days, differenceError = dateTime.calendarDayDifference(
        earlierDate,
        laterDate
    )
    if days ~= nil then
        return days
    end
    if type(differenceError) == "string"
        and string.find(
            differenceError,
            "later date precedes earlier date",
            1,
            true
        ) then
        return 0
    end
    return nil, differenceError
end

local function groupIndexForAge(ageDays)
    if ageDays == nil or ageDays >= 21 then
        return 4
    end
    if ageDays >= 14 then
        return 3
    end
    if ageDays >= 7 then
        return 2
    end
    return 1
end

local function memberComesBefore(left, right)
    if left.tenureDays ~= right.tenureDays then
        return left.tenureDays > right.tenureDays
    end

    local leftName = string.lower(left.name)
    local rightName = string.lower(right.name)
    if leftName ~= rightName then
        return leftName < rightName
    end
    return string.lower(left.displayName) < string.lower(right.displayName)
end

local function newGroups()
    local groups = {}
    for index, definition in ipairs(Report.GROUPS) do
        groups[index] = {
            id = definition.id,
            title = definition.title,
            emptyText = Report.EMPTY_GROUP_TEXT,
            members = {},
        }
    end
    return groups
end

function Report.build(dataset, currentDate, dateTime)
    if type(dataset) ~= "table"
        or type(dataset.ranks) ~= "table"
        or type(dataset.members) ~= "table" then
        return nil, "roster report dataset is invalid"
    end
    if type(dateTime) ~= "table"
        or type(dateTime.currentPacificDate) ~= "function"
        or type(dateTime.calendarDayDifference) ~= "function" then
        return nil, "Pacific date utilities are unavailable"
    end

    if currentDate == nil then
        local dateError
        currentDate, dateError = dateTime.currentPacificDate()
        if not currentDate then
            return nil, dateError
        end
    end

    local scanDate = currentDate
    if dataset.scannedAt ~= nil then
        local scanDateError
        scanDate, scanDateError = dateTime.currentPacificDate(
            dataset.scannedAt.unixSeconds
        )
        if not scanDate then
            return nil, scanDateError
        end
    end
    local elapsedDays, elapsedError = differenceOrZero(
        scanDate,
        currentDate,
        dateTime
    )
    if elapsedDays == nil then
        return nil, elapsedError
    end

    local orderedRanks = {}
    local duplicateNames = {}
    for _, rank in ipairs(dataset.ranks) do
        orderedRanks[#orderedRanks + 1] = rank
        duplicateNames[rank.name] = (duplicateNames[rank.name] or 0) + 1
    end
    table.sort(orderedRanks, function(left, right)
        return left.index < right.index
    end)

    local result = { ranks = {} }
    local ranksByIndex = {}
    for _, rank in ipairs(orderedRanks) do
        local label = rank.name
        if duplicateNames[rank.name] > 1 then
            label = string.format("%s (Rank %d)", rank.name, rank.index)
        end
        local projectedRank = {
            index = rank.index,
            name = rank.name,
            label = label,
            groups = newGroups(),
        }
        result.ranks[#result.ranks + 1] = projectedRank
        ranksByIndex[rank.index] = projectedRank
    end

    for _, member in ipairs(dataset.members) do
        if member.isMissing ~= true then
            local projectedRank = ranksByIndex[member.rankIndex]
            if projectedRank == nil then
                return nil, "roster member refers to an unavailable rank"
            end

            local tenureDays, tenureError = differenceOrZero(
                member.rankTenureStartDate,
                currentDate,
                dateTime
            )
            if tenureDays == nil then
                return nil, tenureError
            end
            local ageDays, lastOnlineText = approximateLastOnline(
                member,
                elapsedDays
            )
            local group = projectedRank.groups[groupIndexForAge(ageDays)]
            group.members[#group.members + 1] = {
                name = member.name,
                displayName = Names.displayName(member.name, member.realm),
                classFileName = member.classFileName,
                lastOnlineText = lastOnlineText,
                tenureDays = tenureDays,
            }
        end
    end

    for _, rank in ipairs(result.ranks) do
        for _, group in ipairs(rank.groups) do
            table.sort(group.members, memberComesBefore)
        end
    end

    return result
end

if type(RGMS) == "table" then
    RGMS.RosterReport = Report
end

return Report
