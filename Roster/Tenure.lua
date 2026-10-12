-- Pure roster rank-tenure transitions. This module receives complete snapshots
-- and date helpers explicitly so it never needs WoW UI APIs or the current
-- machine clock.

local _, RGMS = ...

local Tenure = {}

local function deepCopy(value, active)
    if type(value) ~= "table" then
        return value
    end

    active = active or {}
    if active[value] then
        return nil, "roster snapshot contains a recursive table"
    end

    active[value] = true
    local result = {}
    for key, item in pairs(value) do
        local copiedKey, keyError = deepCopy(key, active)
        if keyError then
            active[value] = nil
            return nil, keyError
        end

        local copiedItem, itemError = deepCopy(item, active)
        if itemError then
            active[value] = nil
            return nil, itemError
        end
        result[copiedKey] = copiedItem
    end
    active[value] = nil
    return result
end

local function requireDateTime(dateTime)
    if type(dateTime) ~= "table"
        or type(dateTime.currentPacificDate) ~= "function"
        or type(dateTime.calendarDayDifference) ~= "function" then
        return nil, "Pacific date utilities are unavailable"
    end
    return true
end

local function indexMembers(members, source)
    if type(members) ~= "table" then
        return nil, source .. " members must be a table"
    end

    local indexed = {}
    for _, member in ipairs(members) do
        if type(member) ~= "table"
            or type(member.displayName) ~= "string"
            or member.displayName == "" then
            return nil, source .. " member displayName must be a non-empty string"
        end
        if indexed[member.displayName] ~= nil then
            return nil, source .. " contains duplicate member " .. member.displayName
        end
        indexed[member.displayName] = member
    end
    return indexed
end

function Tenure.reduce(previousDataset, snapshot, dateTime)
    local dateTimeAvailable, dateTimeError = requireDateTime(dateTime)
    if not dateTimeAvailable then
        return nil, dateTimeError
    end
    if type(previousDataset) ~= "table" then
        return nil, "previous roster dataset must be a table"
    end
    if type(snapshot) ~= "table"
        or type(snapshot.scannedAt) ~= "table"
        or type(snapshot.scannedAt.unixSeconds) ~= "number"
        or type(snapshot.ranks) ~= "table" then
        return nil, "completed roster snapshot is invalid"
    end

    local observedDate, dateError = dateTime.currentPacificDate(
        snapshot.scannedAt.unixSeconds
    )
    if not observedDate then
        return nil, dateError
    end

    local previousMembers, previousError = indexMembers(
        previousDataset.members,
        "previous roster dataset"
    )
    if not previousMembers then
        return nil, previousError
    end
    local currentMembers, currentError = indexMembers(
        snapshot.members,
        "completed roster snapshot"
    )
    if not currentMembers then
        return nil, currentError
    end

    local nextDataset, copyError = deepCopy({
        guild = snapshot.guild,
        scannedAt = snapshot.scannedAt,
        ranks = snapshot.ranks,
        members = snapshot.members,
    })
    if not nextDataset then
        return nil, copyError
    end

    for _, member in ipairs(nextDataset.members) do
        local previous = previousMembers[member.displayName]
        if previous ~= nil and previous.rankIndex == member.rankIndex then
            member.rankTenureStartDate = previous.rankTenureStartDate
        else
            member.rankTenureStartDate = observedDate
        end
    end

    return nextDataset
end

function Tenure.daysSince(rankTenureStartDate, currentDate, dateTime)
    local dateTimeAvailable, dateTimeError = requireDateTime(dateTime)
    if not dateTimeAvailable then
        return nil, dateTimeError
    end

    local days, differenceError = dateTime.calendarDayDifference(
        rankTenureStartDate,
        currentDate
    )
    if days ~= nil then
        return days
    end
    if type(differenceError) == "string"
        and string.find(differenceError, "later date precedes earlier date", 1, true) then
        return 0
    end
    return nil, differenceError
end

if type(RGMS) == "table" then
    RGMS.RosterTenure = Tenure
end

return Tenure
