-- Pure roster-news transitions. News compares complete API observations rather
-- than the retained roster projection, which deliberately keeps missing members.

local _, RGMS = ...

local News = {}
News.RETENTION_DAYS = 21

local function copyTimestamp(value)
    return {
        unixSeconds = value.unixSeconds,
        iso8601 = value.iso8601,
    }
end

local function copyArray(values)
    local result = {}
    for index, value in ipairs(values or {}) do
        if type(value) == "table" then
            local copied = {}
            for key, item in pairs(value) do
                copied[key] = item
            end
            result[index] = copied
        else
            result[index] = value
        end
    end
    return result
end

local function copySet(set)
    return {
        id = set.id,
        createdDate = set.createdDate,
        joiningMembers = copyArray(set.joiningMembers),
        leavingMembers = copyArray(set.leavingMembers),
        rankChanges = copyArray(set.rankChanges),
    }
end

local function displaySort(left, right)
    local leftName = string.lower(type(left) == "table" and left.name or left)
    local rightName = string.lower(type(right) == "table" and right.name or right)
    if leftName == rightName then
        return (type(left) == "table" and left.name or left)
            < (type(right) == "table" and right.name or right)
    end
    return leftName < rightName
end

local function observationFromSnapshot(snapshot)
    local observation = {
        scannedAt = copyTimestamp(snapshot.scannedAt),
        members = {},
    }
    local seenIdentities = {}
    for _, member in ipairs(snapshot.members or {}) do
        if type(member) ~= "table"
            or type(member.identity) ~= "string"
            or member.identity == "" then
            return nil, "completed roster observation member identity must be a non-empty string"
        end
        if type(member.displayName) ~= "string"
            or member.displayName == "" then
            return nil, "completed roster observation member displayName must be a non-empty string"
        end
        if seenIdentities[member.identity] then
            return nil, "completed roster observation contains duplicate member "
                .. member.identity
        end
        seenIdentities[member.identity] = true
        observation.members[#observation.members + 1] = {
            identity = member.identity,
            displayName = member.displayName,
            rankIndex = member.rankIndex,
            rankName = member.rankName,
        }
    end
    table.sort(observation.members, function(left, right)
        return left.identity < right.identity
    end)
    return observation
end

local function memberMap(observation, source)
    if type(observation) ~= "table" or type(observation.members) ~= "table" then
        return nil, source .. " must contain members"
    end
    local result = {}
    for _, member in ipairs(observation.members) do
        if type(member) ~= "table"
            or type(member.identity) ~= "string"
            or member.identity == "" then
            return nil, source .. " member identity must be a non-empty string"
        end
        if type(member.displayName) ~= "string"
            or member.displayName == "" then
            return nil, source .. " member displayName must be a non-empty string"
        end
        if result[member.identity] ~= nil then
            return nil, source .. " contains duplicate member " .. member.identity
        end
        result[member.identity] = member
    end
    return result
end

local function nextSetId(newsSets, unixSeconds)
    local prefix = tostring(unixSeconds)
    local used = {}
    for _, set in ipairs(newsSets) do
        used[set.id] = true
    end
    if not used[prefix] then
        return prefix
    end
    local suffix = 2
    while used[prefix .. "-" .. suffix] do
        suffix = suffix + 1
    end
    return prefix .. "-" .. suffix
end

function News.process(previousObservation, newsSets, snapshot, dateTime)
    if type(snapshot) ~= "table"
        or type(snapshot.scannedAt) ~= "table"
        or type(snapshot.scannedAt.unixSeconds) ~= "number"
        or type(snapshot.members) ~= "table" then
        return nil, "completed roster observation is invalid"
    end
    if type(dateTime) ~= "table"
        or type(dateTime.currentPacificDate) ~= "function"
        or type(dateTime.calendarDayDifference) ~= "function" then
        return nil, "Pacific calendar utilities are unavailable"
    end

    local scanDate, dateError = dateTime.currentPacificDate(
        snapshot.scannedAt.unixSeconds
    )
    if not scanDate then
        return nil, dateError
    end

    local retained = {}
    for _, set in ipairs(newsSets or {}) do
        local age, ageError = dateTime.calendarDayDifference(
            set.createdDate,
            scanDate
        )
        if age == nil then
            return nil, ageError
        end
        if age <= News.RETENTION_DAYS then
            retained[#retained + 1] = copySet(set)
        end
    end

    local observation, observationError = observationFromSnapshot(snapshot)
    if not observation then
        return nil, observationError
    end
    if previousObservation == nil then
        return {
            observation = observation,
            newsSets = retained,
            created = false,
        }
    end

    local previous, previousError = memberMap(
        previousObservation,
        "previous roster observation"
    )
    if not previous then
        return nil, previousError
    end
    local current, currentError = memberMap(
        observation,
        "completed roster observation"
    )
    if not current then
        return nil, currentError
    end
    local joiningMembers = {}
    local leavingMembers = {}
    local rankChanges = {}

    for identity, member in pairs(current) do
        local prior = previous[identity]
        if prior == nil then
            joiningMembers[#joiningMembers + 1] = member.displayName
        elseif prior.rankIndex ~= member.rankIndex then
            rankChanges[#rankChanges + 1] = {
                name = member.displayName,
                rankName = member.rankName,
            }
        end
    end
    for identity, member in pairs(previous) do
        if current[identity] == nil then
            leavingMembers[#leavingMembers + 1] = member.displayName
        end
    end

    table.sort(joiningMembers, displaySort)
    table.sort(leavingMembers, displaySort)
    table.sort(rankChanges, displaySort)

    local created = #joiningMembers > 0
        or #leavingMembers > 0
        or #rankChanges > 0
    if created then
        table.insert(retained, 1, {
            id = nextSetId(retained, snapshot.scannedAt.unixSeconds),
            createdDate = scanDate,
            joiningMembers = joiningMembers,
            leavingMembers = leavingMembers,
            rankChanges = rankChanges,
        })
    end

    return {
        observation = observation,
        newsSets = retained,
        created = created,
    }
end

function News.acknowledge(newsSets, setId)
    if type(setId) ~= "string" or setId == "" then
        return nil, "news set id must be a non-empty string"
    end
    local retained = {}
    local removed = false
    for _, set in ipairs(newsSets or {}) do
        if set.id == setId then
            removed = true
        else
            retained[#retained + 1] = copySet(set)
        end
    end
    if not removed then
        return nil, "news set was not found"
    end
    return retained
end

if type(RGMS) == "table" then
    RGMS.RosterNews = News
end

return News
