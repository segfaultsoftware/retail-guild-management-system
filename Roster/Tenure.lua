-- Pure roster rank-tenure transitions. This module receives complete snapshots
-- and date helpers explicitly so it never needs WoW UI APIs or the current
-- machine clock.

local _, RGMS = ...

local Tenure = {}
local Names = type(RGMS) == "table"
    and type(RGMS.RosterNames) == "table"
    and RGMS.RosterNames
    or require("Roster.Names")

Tenure.MISSING_RETENTION_DAYS = 21

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

local function indexMembers(members, source, repairEquivalentNames)
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
        local identity = Names.identity(member.name, member.realm)
        if indexed[identity] ~= nil then
            if not repairEquivalentNames then
                return nil, source .. " contains duplicate member " .. identity
            end
            if indexed[identity].isMissing and not member.isMissing then
                indexed[identity] = member
            end
        else
            indexed[identity] = member
        end
    end
    return indexed
end

local function indexRanks(ranks)
    local indexed = {}
    for _, rank in ipairs(ranks) do
        if type(rank) ~= "table" or type(rank.index) ~= "number" then
            return nil, "completed roster rank index must be a number"
        end
        if indexed[rank.index] ~= nil then
            return nil, "completed roster contains duplicate rank index " .. rank.index
        end
        indexed[rank.index] = rank
    end
    return indexed
end

local function pacificDateForTimestamp(timestamp, dateTime, source)
    if type(timestamp) ~= "table" or type(timestamp.unixSeconds) ~= "number" then
        return nil, source .. " timestamp is invalid"
    end

    local date, dateError = dateTime.currentPacificDate(timestamp.unixSeconds)
    if not date then
        return nil, dateError
    end
    return date
end

local function carryLastOnlineForward(member, elapsedDays)
    if member.isOnline then
        member.lastOnline = {
            years = 0,
            months = 0,
            days = elapsedDays,
            hours = 0,
        }
    elseif member.lastOnline ~= nil then
        member.lastOnline.days = member.lastOnline.days + elapsedDays
    end
    member.isOnline = false
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

    local observedDate, dateError = pacificDateForTimestamp(
        snapshot.scannedAt,
        dateTime,
        "completed roster snapshot"
    )
    if not observedDate then
        return nil, dateError
    end

    local previousMembers, previousError = indexMembers(
        previousDataset.members,
        "previous roster dataset",
        true
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
    local currentRanks, rankError = indexRanks(snapshot.ranks)
    if not currentRanks then
        return nil, rankError
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
        member.realm = Names.collapseRepeatedRealm(member.realm)
        member.displayName = Names.displayName(member.name, member.realm)
        local identity = Names.identity(member.name, member.realm)
        local previous = previousMembers[identity]
        if previous ~= nil
            and not previous.isMissing
            and previous.rankIndex == member.rankIndex then
            member.rankTenureStartDate = previous.rankTenureStartDate
        else
            member.rankTenureStartDate = observedDate
        end
        member.lastSeenDate = observedDate
        member.isMissing = false
    end

    local previousScanDate
    if #previousDataset.members > 0 then
        previousScanDate, dateError = pacificDateForTimestamp(
            previousDataset.scannedAt,
            dateTime,
            "previous roster dataset"
        )
        if not previousScanDate then
            return nil, dateError
        end
    end

    for _, previous in ipairs(previousDataset.members) do
        local identity = Names.identity(previous.name, previous.realm)
        if previousMembers[identity] == previous
            and currentMembers[identity] == nil then
            local currentRank = currentRanks[previous.rankIndex]
            if currentRank ~= nil then
                local missingDays, missingError = dateTime.calendarDayDifference(
                    previous.lastSeenDate,
                    observedDate
                )
                if missingDays == nil then
                    return nil, missingError
                end

                if missingDays <= Tenure.MISSING_RETENTION_DAYS then
                    local elapsedDays, elapsedError = dateTime.calendarDayDifference(
                        previousScanDate,
                        observedDate
                    )
                    if elapsedDays == nil then
                        return nil, elapsedError
                    end

                    local retained, retainedError = deepCopy(previous)
                    if not retained then
                        return nil, retainedError
                    end
                    retained.rankName = currentRank.name
                    retained.isMissing = true
                    retained.realm = Names.collapseRepeatedRealm(retained.realm)
                    retained.displayName = Names.displayName(
                        retained.name,
                        retained.realm
                    )
                    carryLastOnlineForward(retained, elapsedDays)
                    nextDataset.members[#nextDataset.members + 1] = retained
                end
            end
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
