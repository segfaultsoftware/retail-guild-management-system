-- Validation and loading helpers for sanitized runtime-contract probe exports.
--
-- This module deliberately contains no sample observations. Real observations
-- must come from the supported Retail and Forever clients and pass this schema
-- before they can be used as fixtures by dependent tests.

local RuntimeContractFixtures = {}

RuntimeContractFixtures.SCHEMA_VERSION = 1

local MAX_SOURCE_BYTES = 32 * 1024 * 1024
local MAX_VM_INSTRUCTIONS = 5000000
local ABSOLUTE_LIMITS = {
    sessions = 64,
    events = 4096,
    observations = 2048,
    membersPerObservation = 2048,
}
local MAX_ALIAS_INDEX = 4096
local MAX_ERRORS = 32

local ERROR_CODES = {
    EVENT_REGISTRATION_FAILED = true,
    GET_BUILD_INFO_FAILED = true,
    GET_BUILD_INFO_INCOMPLETE = true,
    GET_BUILD_INFO_MISSING = true,
    GET_CLUB_INFO_FAILED = true,
    GET_CLUB_INFO_MISSING = true,
    GET_CLUB_INFO_UNAVAILABLE = true,
    GET_CLUB_MEMBERS_FAILED = true,
    GET_CLUB_MEMBERS_MISSING = true,
    GET_CLUB_MEMBERS_UNAVAILABLE = true,
    GET_CURRENT_REGION_FAILED = true,
    GET_CURRENT_REGION_MISSING = true,
    GET_CURRENT_REGION_UNAVAILABLE = true,
    GET_GUILD_CLUB_ID_FAILED = true,
    GET_GUILD_CLUB_ID_MISSING = true,
    GET_GUILD_CLUB_ID_UNAVAILABLE = true,
    GET_GUILD_INFO_FAILED = true,
    GET_GUILD_INFO_MISSING = true,
    GET_GUILD_ROSTER_INFO_FAILED = true,
    GET_GUILD_ROSTER_INFO_INCOMPLETE = true,
    GET_GUILD_ROSTER_INFO_MISSING = true,
    GET_MEMBER_INFO_FAILED = true,
    GET_MEMBER_INFO_INCOMPLETE = true,
    GET_MEMBER_INFO_MISSING = true,
    GET_NORMALIZED_REALM_NAME_FAILED = true,
    GET_NORMALIZED_REALM_NAME_MISSING = true,
    GET_NORMALIZED_REALM_NAME_UNAVAILABLE = true,
    GET_NUM_GUILD_MEMBERS_FAILED = true,
    GET_NUM_GUILD_MEMBERS_MISSING = true,
    GET_NUM_GUILD_MEMBERS_UNAVAILABLE = true,
    GET_REALM_NAME_FAILED = true,
    GET_REALM_NAME_MISSING = true,
    GET_REALM_NAME_UNAVAILABLE = true,
    UNIT_FULL_NAME_FAILED = true,
    UNIT_FULL_NAME_MISSING = true,
    UNIT_NAME_FAILED = true,
    UNIT_NAME_INCOMPLETE = true,
    UNIT_NAME_MISSING = true,
}

local EVENT_NAMES = {
    ADDON_LOADED = true,
    CLUB_MEMBERS_UPDATED = true,
    CLUB_MEMBER_PRESENCE_UPDATED = true,
    CLUB_MEMBER_UPDATED = true,
    GUILD_ROSTER_UPDATE = true,
    INITIAL_CLUBS_LOADED = true,
    MANUAL_SNAPSHOT = true,
    MARK_COLD_RESTART = true,
    MARK_LOGOUT_LOGIN = true,
    MARK_RELOAD = true,
    PLAYER_ENTERING_WORLD = true,
    PLAYER_GUILD_UPDATE = true,
    PLAYER_LEAVING_WORLD = true,
    PLAYER_LOGIN = true,
    PLAYER_LOGOUT = true,
    PROBE_START = true,
    PROBE_STOP = true,
    ROSTER_REQUEST_FAILED = true,
    ROSTER_REQUEST_UNAVAILABLE = true,
}

local MEMBER_SOURCES = {
    club = true,
    ["guild-roster"] = true,
    none = true,
}

local function failure(path, message)
    return nil, path .. " " .. message
end

local function isInteger(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value % 1 == 0
end

local function validateInteger(value, path, minimum, maximum)
    if not isInteger(value) then
        return failure(path, "must be a finite integer")
    end
    if minimum ~= nil and value < minimum then
        return failure(path, "must be at least " .. tostring(minimum))
    end
    if maximum ~= nil and value > maximum then
        return failure(path, "must be at most " .. tostring(maximum))
    end
    return value
end

local function validateString(value, path, maximumLength, pattern, description)
    if type(value) ~= "string" or value == "" then
        return failure(path, "must be a non-empty string")
    end
    if #value > maximumLength then
        return failure(path, "must be at most " .. tostring(maximumLength) .. " bytes")
    end
    if pattern ~= nil and not value:match(pattern) then
        return failure(path, "must be " .. description)
    end
    return value
end

local function validateTable(value, path, context)
    if type(value) ~= "table" then
        return failure(path, "must be a table")
    end
    if getmetatable(value) ~= nil then
        return failure(path, "must not have a metatable")
    end
    if context.seen[value] then
        return failure(path, "must not reuse or recursively reference a table")
    end
    context.seen[value] = true
    return value
end

local function keySet(keys)
    local result = {}
    for _, key in ipairs(keys) do
        result[key] = true
    end
    return result
end

local function validateKeys(value, path, requiredKeys, optionalKeys)
    local allowed = keySet(requiredKeys)
    for _, key in ipairs(optionalKeys or {}) do
        allowed[key] = true
    end

    for key in pairs(value) do
        if type(key) ~= "string" or not allowed[key] then
            return failure(path, "contains unsupported field " .. tostring(key))
        end
    end

    for _, key in ipairs(requiredKeys) do
        if value[key] == nil then
            return failure(path .. "." .. key, "is required")
        end
    end
    return true
end

local function arrayLength(value, path, maximum)
    local largest = 0
    local count = 0
    for key in pairs(value) do
        if not isInteger(key) or key < 1 then
            return failure(path, "must contain only positive integer keys")
        end
        largest = math.max(largest, key)
        count = count + 1
    end
    if largest ~= count then
        return failure(path, "must be a contiguous array")
    end
    if count > maximum then
        return failure(path, "exceeds its configured limit of " .. tostring(maximum))
    end
    return count
end

local function copyAvailability(value, path, fields, context)
    local checked, checkedError = validateTable(value, path, context)
    if not checked then
        return nil, checkedError
    end
    local keysValid, keysError = validateKeys(value, path, fields)
    if not keysValid then
        return nil, keysError
    end

    local result = {}
    for _, field in ipairs(fields) do
        if type(value[field]) ~= "boolean" then
            return failure(path .. "." .. field, "must be a boolean")
        end
        result[field] = value[field]
    end
    return result
end

local function copyAvailableField(source, availability, field, path, validator)
    local value = source[field]
    if availability[field] then
        if value == nil then
            return failure(path .. "." .. field, "is marked available but is missing")
        end
        return validator(value, path .. "." .. field)
    end
    if value ~= nil then
        return failure(path .. "." .. field, "must be omitted when unavailable")
    end
    return nil
end

local function copyErrors(value, path, context)
    local checked, checkedError = validateTable(value, path, context)
    if not checked then return nil, checkedError end
    local count, countError = arrayLength(value, path, MAX_ERRORS)
    if not count then return nil, countError end

    local result = {}
    local seen = {}
    for index = 1, count do
        local code = value[index]
        if type(code) ~= "string" or not ERROR_CODES[code] then
            return failure(path .. "[" .. tostring(index) .. "]", "must be an approved probe error code")
        end
        if seen[code] then
            return failure(path .. "[" .. tostring(index) .. "]", "must not duplicate an error code")
        end
        seen[code] = true
        result[index] = code
    end
    return result
end

local function validateNumberedAlias(value, path, prefix)
    local limitMarker = prefix .. "-Limit"
    if value == limitMarker then
        return value
    end
    local digits = type(value) == "string"
        and value:match("^" .. prefix .. "%-(%d+)$")
        or nil
    local index = tonumber(digits)
    if not index or index < 1 or index > MAX_ALIAS_INDEX
        or value ~= string.format("%s-%03d", prefix, index) then
        return failure(path, "must be a " .. prefix .. "-NNN alias")
    end
    return value
end

local function containsLimitAlias(value)
    if type(value) == "string" then
        return value:find("-Limit", 1, true) ~= nil
    end
    if type(value) ~= "table" then
        return false
    end
    for _, child in pairs(value) do
        if containsLimitAlias(child) then
            return true
        end
    end
    return false
end

local function validateRealmAlias(value, path)
    return validateNumberedAlias(value, path, "Realm")
end

local function validateClubAlias(value, path)
    return validateNumberedAlias(value, path, "Club")
end

local function validateGuildAlias(value, path)
    return validateNumberedAlias(value, path, "Guild")
end

local function validateGuidAlias(value, path)
    return validateNumberedAlias(value, path, "Guid")
end

local function validateMemberIdAlias(value, path)
    return validateNumberedAlias(value, path, "MemberId")
end

local function validateCharacterAlias(value, path, productId)
    if type(value) ~= "string" then
        return failure(path, "must be a sanitized character alias string")
    end
    local isForever = productId == 18
    local first, surname = value:match("^(First%-%S+) (Surname%-%S+)$")
    local foreverAlias = first ~= nil
        and validateNumberedAlias(first, path, "First") ~= nil
        and validateNumberedAlias(surname, path, "Surname") ~= nil
    local otherAlias = validateNumberedAlias(value, path, "Member") ~= nil
    if (isForever and not foreverAlias)
        or (productId ~= nil and not isForever and not otherAlias)
        or (productId == nil and not foreverAlias and not otherAlias) then
        return failure(path, "must use the product-appropriate sanitized character alias")
    end
    return value
end

local RUNTIME_AVAILABILITY_FIELDS = {
    "productId",
    "version",
    "build",
    "interface",
    "region",
    "realmName",
    "normalizedRealmName",
    "playerName",
    "playerRealm",
}

local EVENT_AVAILABILITY_FIELDS = {
    "clubId",
    "memberId",
    "canRequestRosterUpdate",
}

local GUILD_AVAILABILITY_FIELDS = {
    "name",
    "clubId",
    "realm",
    "memberCount",
}

local MEMBER_AVAILABILITY_FIELDS = {
    "name",
    "guid",
}

local OBSERVATION_AVAILABILITY_FIELDS = {
    "memberListCount",
    "guildRosterMemberCount",
    "guildRosterOnlineCount",
}

local function copyRuntime(value, path, context)
    local checked, checkedError = validateTable(value, path, context)
    if not checked then
        return nil, checkedError
    end
    local keysValid, keysError = validateKeys(value, path, {
        "availability", "errors",
    }, RUNTIME_AVAILABILITY_FIELDS)
    if not keysValid then
        return nil, keysError
    end

    local availability, availabilityError = copyAvailability(
        value.availability,
        path .. ".availability",
        RUNTIME_AVAILABILITY_FIELDS,
        context
    )
    if not availability then
        return nil, availabilityError
    end

    local errors, errorsError = copyErrors(
        value.errors,
        path .. ".errors",
        context
    )
    if not errors then return nil, errorsError end

    local result = { availability = availability, errors = errors }
    local productId, productIdError = copyAvailableField(
        value,
        availability,
        "productId",
        path,
        function(item, itemPath)
            return validateInteger(item, itemPath, 1)
        end
    )
    if productIdError then return nil, productIdError end
    result.productId = productId

    local scalarValidators = {
        version = function(item, itemPath)
            return validateString(item, itemPath, 64, "^%d+[%.%d]*$", "a numeric client version")
        end,
        build = function(item, itemPath)
            return validateString(item, itemPath, 64, "^%d+$", "a numeric client build")
        end,
        interface = function(item, itemPath)
            return validateInteger(item, itemPath, 1)
        end,
        region = function(item, itemPath)
            if isInteger(item) then
                return validateInteger(item, itemPath, 1, 5)
            end
            local region, regionError = validateString(
                item,
                itemPath,
                2,
                "^[A-Z][A-Z]$",
                "a two-letter region code"
            )
            if not region then return nil, regionError end
            if not ({ US = true, KR = true, EU = true, TW = true, CN = true })[region] then
                return failure(itemPath, "must be a supported region code")
            end
            return region
        end,
        realmName = validateRealmAlias,
        normalizedRealmName = validateRealmAlias,
        playerRealm = validateRealmAlias,
        playerName = function(item, itemPath)
            return validateCharacterAlias(item, itemPath, productId)
        end,
    }

    for _, field in ipairs({
        "version", "build", "interface", "region", "realmName",
        "normalizedRealmName", "playerName", "playerRealm",
    }) do
        local copied, copyError = copyAvailableField(
            value,
            availability,
            field,
            path,
            scalarValidators[field]
        )
        if copyError then return nil, copyError end
        result[field] = copied
    end
    return result, productId
end

local function copyEvent(value, path, context)
    local checked, checkedError = validateTable(value, path, context)
    if not checked then return nil, checkedError end
    local keysValid, keysError = validateKeys(value, path, {
        "sequence", "name", "availability",
    }, EVENT_AVAILABILITY_FIELDS)
    if not keysValid then return nil, keysError end

    local sequence, sequenceError = validateInteger(value.sequence, path .. ".sequence", 1)
    if not sequence then return nil, sequenceError end
    local name, nameError = validateString(
        value.name,
        path .. ".name",
        64,
        "^[A-Z][A-Z0-9_]*$",
        "an uppercase event name"
    )
    if not name then return nil, nameError end
    if not EVENT_NAMES[name] then
        return failure(path .. ".name", "must be an approved probe event")
    end
    local availability, availabilityError = copyAvailability(
        value.availability,
        path .. ".availability",
        EVENT_AVAILABILITY_FIELDS,
        context
    )
    if not availability then return nil, availabilityError end

    local result = {
        sequence = sequence,
        name = name,
        availability = availability,
    }
    local validators = {
        clubId = validateClubAlias,
        memberId = validateMemberIdAlias,
        canRequestRosterUpdate = function(item, itemPath)
            if type(item) ~= "boolean" then
                return failure(itemPath, "must be a boolean")
            end
            return item
        end,
    }
    for _, field in ipairs(EVENT_AVAILABILITY_FIELDS) do
        local copied, copyError = copyAvailableField(
            value,
            availability,
            field,
            path,
            validators[field]
        )
        if copyError then return nil, copyError end
        result[field] = copied
    end
    return result
end

local function copyGuild(value, path, context)
    local checked, checkedError = validateTable(value, path, context)
    if not checked then return nil, checkedError end
    local keysValid, keysError = validateKeys(value, path, {
        "availability",
    }, GUILD_AVAILABILITY_FIELDS)
    if not keysValid then return nil, keysError end

    local availability, availabilityError = copyAvailability(
        value.availability,
        path .. ".availability",
        GUILD_AVAILABILITY_FIELDS,
        context
    )
    if not availability then return nil, availabilityError end

    local result = { availability = availability }
    local validators = {
        name = validateGuildAlias,
        clubId = validateClubAlias,
        realm = validateRealmAlias,
        memberCount = function(item, itemPath)
            return validateInteger(item, itemPath, 0)
        end,
    }
    for _, field in ipairs(GUILD_AVAILABILITY_FIELDS) do
        local copied, copyError = copyAvailableField(
            value,
            availability,
            field,
            path,
            validators[field]
        )
        if copyError then return nil, copyError end
        result[field] = copied
    end
    return result
end

local function copyMember(value, path, context, productId)
    local checked, checkedError = validateTable(value, path, context)
    if not checked then return nil, checkedError end
    local keysValid, keysError = validateKeys(value, path, {
        "availability",
    }, MEMBER_AVAILABILITY_FIELDS)
    if not keysValid then return nil, keysError end

    local availability, availabilityError = copyAvailability(
        value.availability,
        path .. ".availability",
        MEMBER_AVAILABILITY_FIELDS,
        context
    )
    if not availability then return nil, availabilityError end

    local result = { availability = availability }
    local name, nameError = copyAvailableField(
        value,
        availability,
        "name",
        path,
        function(item, itemPath)
            return validateCharacterAlias(item, itemPath, productId)
        end
    )
    if nameError then return nil, nameError end
    result.name = name

    local guid, guidError = copyAvailableField(
        value,
        availability,
        "guid",
        path,
        validateGuidAlias
    )
    if guidError then return nil, guidError end
    result.guid = guid
    return result
end

local function copyObservation(value, path, context, productId, limits)
    local checked, checkedError = validateTable(value, path, context)
    if not checked then return nil, checkedError end
    local keysValid, keysError = validateKeys(value, path, {
        "sequence", "trigger", "memberSource", "guild", "members",
        "availability", "errors",
    }, {
        "memberListCount", "guildRosterMemberCount", "guildRosterOnlineCount",
    })
    if not keysValid then return nil, keysError end

    local sequence, sequenceError = validateInteger(value.sequence, path .. ".sequence", 1)
    if not sequence then return nil, sequenceError end
    local trigger, triggerError = validateString(
        value.trigger,
        path .. ".trigger",
        64,
        "^[%w_-]+$",
        "a probe trigger label"
    )
    if not trigger then return nil, triggerError end
    if not EVENT_NAMES[trigger] then
        return failure(path .. ".trigger", "must be an approved probe trigger")
    end
    if type(value.memberSource) ~= "string"
        or not MEMBER_SOURCES[value.memberSource] then
        return failure(path .. ".memberSource", "must be club, guild-roster, or none")
    end
    local availability, availabilityError = copyAvailability(
        value.availability,
        path .. ".availability",
        OBSERVATION_AVAILABILITY_FIELDS,
        context
    )
    if not availability then return nil, availabilityError end
    local errors, errorsError = copyErrors(
        value.errors,
        path .. ".errors",
        context
    )
    if not errors then return nil, errorsError end

    local guild, guildError = copyGuild(value.guild, path .. ".guild", context)
    if not guild then return nil, guildError end

    local membersChecked, membersCheckedError = validateTable(
        value.members,
        path .. ".members",
        context
    )
    if not membersChecked then return nil, membersCheckedError end
    local memberCount, memberArrayError = arrayLength(
        value.members,
        path .. ".members",
        limits.membersPerObservation
    )
    if not memberCount then return nil, memberArrayError end

    local result = {
        sequence = sequence,
        trigger = trigger,
        memberSource = value.memberSource,
        guild = guild,
        availability = availability,
        errors = errors,
        members = {},
    }
    for index = 1, memberCount do
        local member, memberError = copyMember(
            value.members[index],
            path .. ".members[" .. tostring(index) .. "]",
            context,
            productId
        )
        if not member then return nil, memberError end
        result.members[index] = member
    end

    for _, field in ipairs(OBSERVATION_AVAILABILITY_FIELDS) do
        local copied, copyError = copyAvailableField(
            value,
            availability,
            field,
            path,
            function(item, itemPath)
                return validateInteger(item, itemPath, 0)
            end
        )
        if copyError then return nil, copyError end
        result[field] = copied
    end
    if result.memberSource == "none" and memberCount > 0 then
        return failure(path .. ".members", "must be empty when memberSource is none")
    end
    if result.memberSource == "club" and result.memberListCount ~= nil
        and memberCount > result.memberListCount then
        return failure(path .. ".members", "cannot exceed the club member list count")
    end
    if result.memberSource == "guild-roster"
        and result.guildRosterMemberCount ~= nil
        and memberCount > result.guildRosterMemberCount then
        return failure(path .. ".members", "cannot exceed the guild roster count")
    end
    return result
end

local BOUNDARIES = {
    initial = true,
    reload = true,
    ["logout-login"] = true,
    ["cold-restart"] = true,
    interrupted = true,
}

local function copySession(value, path, context, limits)
    local checked, checkedError = validateTable(value, path, context)
    if not checked then return nil, checkedError end
    local keysValid, keysError = validateKeys(value, path, {
        "index", "boundary", "runtime", "events", "observations",
    })
    if not keysValid then return nil, keysError end

    local index, indexError = validateInteger(value.index, path .. ".index", 1)
    if not index then return nil, indexError end
    local boundary, boundaryError = validateString(
        value.boundary,
        path .. ".boundary",
        64,
        "^[%w_-]+$",
        "a session-boundary label"
    )
    if not boundary then return nil, boundaryError end
    if not BOUNDARIES[boundary] then
        return failure(path .. ".boundary", "must be a supported session boundary")
    end

    local runtime, productIdOrError = copyRuntime(value.runtime, path .. ".runtime", context)
    if not runtime then return nil, productIdOrError end
    local productId = productIdOrError

    local eventsChecked, eventsCheckedError = validateTable(
        value.events,
        path .. ".events",
        context
    )
    if not eventsChecked then return nil, eventsCheckedError end
    local eventCount, eventCountError = arrayLength(value.events, path .. ".events", limits.events)
    if not eventCount then return nil, eventCountError end

    local observationsChecked, observationsCheckedError = validateTable(
        value.observations,
        path .. ".observations",
        context
    )
    if not observationsChecked then return nil, observationsCheckedError end
    local observationCount, observationCountError = arrayLength(
        value.observations,
        path .. ".observations",
        limits.observations
    )
    if not observationCount then return nil, observationCountError end

    local result = {
        index = index,
        boundary = boundary,
        runtime = runtime,
        events = {},
        observations = {},
    }
    local previousSequence = 0
    for eventIndex = 1, eventCount do
        local event, eventError = copyEvent(
            value.events[eventIndex],
            path .. ".events[" .. tostring(eventIndex) .. "]",
            context
        )
        if not event then return nil, eventError end
        if event.sequence <= previousSequence then
            return failure(
                path .. ".events[" .. tostring(eventIndex) .. "].sequence",
                "must increase within the event stream"
            )
        end
        previousSequence = event.sequence
        result.events[eventIndex] = event
    end

    previousSequence = 0
    for observationIndex = 1, observationCount do
        local observation, observationError = copyObservation(
            value.observations[observationIndex],
            path .. ".observations[" .. tostring(observationIndex) .. "]",
            context,
            productId,
            limits
        )
        if not observation then return nil, observationError end
        if observation.sequence <= previousSequence then
            return failure(
                path .. ".observations[" .. tostring(observationIndex) .. "].sequence",
                "must increase within the observation stream"
            )
        end
        previousSequence = observation.sequence
        result.observations[observationIndex] = observation
    end
    return result
end

function RuntimeContractFixtures.validate(value)
    local context = { seen = {} }
    local checked, checkedError = validateTable(value, "RGMSRuntimeProbeExport", context)
    if not checked then return nil, checkedError end
    local keysValid, keysError = validateKeys(value, "RGMSRuntimeProbeExport", {
        "schemaVersion", "complete", "truncated", "limits", "sessions",
    })
    if not keysValid then return nil, keysError end

    if value.schemaVersion ~= RuntimeContractFixtures.SCHEMA_VERSION then
        return failure(
            "RGMSRuntimeProbeExport.schemaVersion",
            "must equal " .. tostring(RuntimeContractFixtures.SCHEMA_VERSION)
        )
    end
    if type(value.complete) ~= "boolean" then
        return failure("RGMSRuntimeProbeExport.complete", "must be a boolean")
    end
    if type(value.truncated) ~= "boolean" then
        return failure("RGMSRuntimeProbeExport.truncated", "must be a boolean")
    end
    if value.complete and value.truncated then
        return failure("RGMSRuntimeProbeExport", "cannot be both complete and truncated")
    end

    local limitsChecked, limitsCheckedError = validateTable(
        value.limits,
        "RGMSRuntimeProbeExport.limits",
        context
    )
    if not limitsChecked then return nil, limitsCheckedError end
    local limitKeys = { "sessions", "events", "observations", "membersPerObservation" }
    local limitKeysValid, limitKeysError = validateKeys(
        value.limits,
        "RGMSRuntimeProbeExport.limits",
        limitKeys
    )
    if not limitKeysValid then return nil, limitKeysError end

    local limits = {}
    for _, field in ipairs(limitKeys) do
        local limit, limitError = validateInteger(
            value.limits[field],
            "RGMSRuntimeProbeExport.limits." .. field,
            1,
            ABSOLUTE_LIMITS[field]
        )
        if not limit then return nil, limitError end
        limits[field] = limit
    end

    local sessionsChecked, sessionsCheckedError = validateTable(
        value.sessions,
        "RGMSRuntimeProbeExport.sessions",
        context
    )
    if not sessionsChecked then return nil, sessionsCheckedError end
    local sessionCount, sessionCountError = arrayLength(
        value.sessions,
        "RGMSRuntimeProbeExport.sessions",
        limits.sessions
    )
    if not sessionCount then return nil, sessionCountError end
    if value.complete and sessionCount == 0 then
        return failure(
            "RGMSRuntimeProbeExport.sessions",
            "must contain at least one finalized session"
        )
    end

    local result = {
        schemaVersion = RuntimeContractFixtures.SCHEMA_VERSION,
        complete = value.complete,
        truncated = value.truncated,
        limits = limits,
        sessions = {},
    }
    local previousSessionIndex = 0
    local observationTotal = 0
    for index = 1, sessionCount do
        local session, sessionError = copySession(
            value.sessions[index],
            "RGMSRuntimeProbeExport.sessions[" .. tostring(index) .. "]",
            context,
            limits
        )
        if not session then return nil, sessionError end
        if session.index <= previousSessionIndex then
            return failure(
                "RGMSRuntimeProbeExport.sessions[" .. tostring(index) .. "].index",
                "must increase within the session stream"
            )
        end
        previousSessionIndex = session.index
        observationTotal = observationTotal + #session.observations
        result.sessions[index] = session
    end
    if value.complete and observationTotal == 0 then
        return failure(
            "RGMSRuntimeProbeExport.sessions",
            "must contain at least one finalized observation"
        )
    end
    if not result.truncated and containsLimitAlias(result) then
        return failure(
            "RGMSRuntimeProbeExport.truncated",
            "must be true when an alias limit marker is present"
        )
    end
    return result
end

local FORBIDDEN_SOURCE_WORDS = keySet({
    "and", "break", "do", "else", "elseif", "end", "for", "function",
    "if", "in", "local", "not", "or", "repeat", "return", "then",
    "until", "while",
})

local function preflightSource(source)
    local index = 1
    local length = #source
    while index <= length do
        local character = source:sub(index, index)
        local nextCharacter = source:sub(index + 1, index + 1)
        if character == "-" and nextCharacter == "-" then
            if source:sub(index + 2, index + 3) == "[[" then
                return nil, "long comments are not accepted"
            end
            local lineEnd = source:find("[\r\n]", index + 2)
            index = lineEnd or (length + 1)
        elseif character == "\"" or character == "'" then
            local quote = character
            index = index + 1
            local closed = false
            while index <= length do
                local stringCharacter = source:sub(index, index)
                if stringCharacter == "\\" then
                    index = index + 2
                elseif stringCharacter == quote then
                    index = index + 1
                    closed = true
                    break
                else
                    index = index + 1
                end
            end
            if not closed then
                return nil, "contains an unterminated string"
            end
        elseif character:match("[%a_]") then
            local word = source:match("[%a_][%w_]*", index)
            if FORBIDDEN_SOURCE_WORDS[word] then
                return nil, "contains forbidden Lua keyword " .. word
            end
            index = index + #word
        elseif character == "(" or character == ")" or character == ":"
            or character == "#" or character == "/" or character == "*"
            or character == "^" or character == "%" then
            return nil, "contains forbidden executable syntax " .. character
        elseif character == "[" and nextCharacter == "[" then
            return nil, "long strings are not accepted"
        elseif character:byte() >= 128 then
            return nil, "contains a non-ASCII token outside a quoted string"
        else
            index = index + 1
        end
    end
    return true
end

local function inspectSourceFile(path)
    if type(path) ~= "string" or path == "" then
        return nil, "input path must be a non-empty string"
    end
    local handle, openError = io.open(path, "rb")
    if not handle then
        return nil, "could not open " .. path .. ": " .. tostring(openError)
    end
    local source = handle:read("*a")
    handle:close()
    if #source > MAX_SOURCE_BYTES then
        return nil, "input exceeds " .. tostring(MAX_SOURCE_BYTES) .. " bytes"
    end
    if source:byte(1) == 27 then
        return nil, "compiled Lua chunks are not accepted"
    end
    local safe, safetyError = preflightSource(source)
    if not safe then
        return nil, "input is not a literal SavedVariables file: " .. safetyError
    end
    return source
end

local function runRestrictedChunk(chunk)
    local debugLibrary = debug
    if type(debugLibrary) ~= "table" or type(debugLibrary.sethook) ~= "function" then
        return nil, "Lua debug hooks are required for bounded SavedVariables loading"
    end

    local previousHook, previousMask, previousCount = debugLibrary.gethook()
    local instructionCount = 0
    debugLibrary.sethook(function()
        instructionCount = instructionCount + 1000
        if instructionCount > MAX_VM_INSTRUCTIONS then
            error("SavedVariables instruction limit exceeded", 0)
        end
    end, "", 1000)
    local results = { pcall(chunk) }
    if previousHook ~= nil then
        debugLibrary.sethook(previousHook, previousMask, previousCount)
    else
        debugLibrary.sethook()
    end
    if not results[1] then
        return nil, tostring(results[2])
    end
    return true
end

local function loadExport(path, allowRawDatabase)
    local source, sourceError = inspectSourceFile(path)
    if not source then return nil, sourceError end

    local chunk, loadError = loadstring(source, "@" .. path)
    if not chunk then
        return nil, "could not parse " .. path .. ": " .. tostring(loadError)
    end

    local exportValue
    local exportAssigned = false
    local databaseAssigned = false
    local environment = setmetatable({}, {
        __index = function(_, key)
            error("SavedVariables input attempted to read global " .. tostring(key), 0)
        end,
        __newindex = function(_, key, value)
            if key == "RGMSRuntimeProbeExport" then
                if exportAssigned then
                    error("RGMSRuntimeProbeExport was assigned more than once", 0)
                end
                exportAssigned = true
                exportValue = value
                return
            end
            if key == "RGMSRuntimeProbeDB" and allowRawDatabase then
                if databaseAssigned then
                    error("RGMSRuntimeProbeDB was assigned more than once", 0)
                end
                databaseAssigned = true
                -- Deliberately discard the raw alias state. It must never be
                -- returned by this module or written by the extractor.
                return
            end
            error("SavedVariables input attempted to assign global " .. tostring(key), 0)
        end,
        __metatable = false,
    })
    setfenv(chunk, environment)

    local ran, runError = runRestrictedChunk(chunk)
    if not ran then
        return nil, "could not safely load " .. path .. ": " .. runError
    end
    if not exportAssigned then
        return nil, path .. " does not define RGMSRuntimeProbeExport"
    end
    return RuntimeContractFixtures.validate(exportValue)
end

function RuntimeContractFixtures.load(path)
    return loadExport(path, false)
end

function RuntimeContractFixtures.loadSavedVariables(path)
    return loadExport(path, true)
end

local function quoteString(value)
    return "\"" .. value:gsub("[\\\"%z\1-\31\127-\255]", function(character)
        if character == "\\" then return "\\\\" end
        if character == "\"" then return "\\\"" end
        if character == "\n" then return "\\n" end
        if character == "\r" then return "\\r" end
        if character == "\t" then return "\\t" end
        return string.format("\\%03d", string.byte(character))
    end) .. "\""
end

local function sortedKeys(value)
    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(left, right)
        if type(left) == type(right) then
            return left < right
        end
        return type(left) == "number"
    end)
    return keys
end

local function isArray(value)
    local count = 0
    local largest = 0
    for key in pairs(value) do
        if not isInteger(key) or key < 1 then return false end
        count = count + 1
        largest = math.max(largest, key)
    end
    return count == largest
end

local function serializeValue(value, indent)
    local valueType = type(value)
    if valueType == "string" then return quoteString(value) end
    if valueType == "number" or valueType == "boolean" then return tostring(value) end

    local childIndent = indent .. "    "
    local lines = { "{" }
    if isArray(value) then
        for index = 1, #value do
            lines[#lines + 1] = childIndent .. serializeValue(value[index], childIndent) .. ","
        end
    else
        for _, key in ipairs(sortedKeys(value)) do
            local keySource
            if type(key) == "string" and key:match("^[%a_][%w_]*$") then
                keySource = key
            else
                keySource = "[" .. serializeValue(key, childIndent) .. "]"
            end
            lines[#lines + 1] = childIndent .. keySource .. " = "
                .. serializeValue(value[key], childIndent) .. ","
        end
    end
    lines[#lines + 1] = indent .. "}"
    return table.concat(lines, "\n")
end

function RuntimeContractFixtures.format(value)
    local sanitized, validationError = RuntimeContractFixtures.validate(value)
    if not sanitized then return nil, validationError end
    return "RGMSRuntimeProbeExport = " .. serializeValue(sanitized, "") .. "\n"
end

return RuntimeContractFixtures
