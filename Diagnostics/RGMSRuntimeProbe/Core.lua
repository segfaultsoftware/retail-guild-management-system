-- Pure state, sanitization, and formatting for the opt-in runtime probe.
-- This file intentionally has no dependency on WoW globals so its behavior can
-- be exercised by the repository's Lua 5.1 test runner.

local _, addon = ...

local Core = {}

Core.SCHEMA_VERSION = 1
Core.LIMITS = {
    sessions = 5,
    events = 128,
    observations = 20,
    membersPerObservation = 1000,
    aliases = 4096,
    errors = 32,
}

local BOUNDARIES = {
    initial = true,
    reload = true,
    ["logout-login"] = true,
    ["cold-restart"] = true,
    interrupted = true,
}

local ALIAS_KINDS = {
    club = "Club",
    first = "First",
    guild = "Guild",
    guid = "Guid",
    member = "Member",
    memberId = "MemberId",
    realm = "Realm",
    surname = "Surname",
}

Core.ERROR_CODES = {
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

local sanitizeErrors

local function newAliasBucket()
    return {
        nextIndex = 1,
        count = 0,
        values = {},
    }
end

local function newAliases()
    local aliases = {}
    for kind in pairs(ALIAS_KINDS) do
        aliases[kind] = newAliasBucket()
    end
    return aliases
end

function Core.newState()
    return {
        schemaVersion = Core.SCHEMA_VERSION,
        enabled = false,
        captureStopped = false,
        nextSessionIndex = 1,
        currentSessionIndex = nil,
        pendingBoundary = nil,
        aliases = newAliases(),
        sessions = {},
        droppedSessions = 0,
        aliasLimitReached = false,
        errorsTruncated = false,
    }
end

local function ensureAliasBucket(aliases, kind)
    local bucket = aliases[kind]
    if type(bucket) ~= "table" then
        bucket = newAliasBucket()
        aliases[kind] = bucket
    end
    if type(bucket.values) ~= "table" then
        bucket.values = {}
    end
    if type(bucket.nextIndex) ~= "number" or bucket.nextIndex < 1 then
        bucket.nextIndex = 1
    end
    if type(bucket.count) ~= "number" or bucket.count < 0 then
        local count = 0
        for _ in pairs(bucket.values) do
            count = count + 1
        end
        bucket.count = count
    end
    return bucket
end

local function boundSession(state, session)
    if type(session) ~= "table" then
        return nil
    end

    session.events = type(session.events) == "table" and session.events or {}
    session.observations = type(session.observations) == "table"
        and session.observations
        or {}
    session.droppedEvents = math.max(0, tonumber(session.droppedEvents) or 0)
    session.droppedObservations = math.max(
        0,
        tonumber(session.droppedObservations) or 0
    )

    while #session.events > Core.LIMITS.events do
        table.remove(session.events)
        session.droppedEvents = session.droppedEvents + 1
    end
    while #session.observations > Core.LIMITS.observations do
        table.remove(session.observations)
        session.droppedObservations = session.droppedObservations + 1
    end

    for index = #session.events, 1, -1 do
        if type(session.events[index]) ~= "table" then
            table.remove(session.events, index)
            session.droppedEvents = session.droppedEvents + 1
        end
    end
    for index = #session.observations, 1, -1 do
        local observation = session.observations[index]
        if type(observation) ~= "table" then
            table.remove(session.observations, index)
            session.droppedObservations = session.droppedObservations + 1
        else
            observation.members = type(observation.members) == "table"
                and observation.members
                or {}
            for memberIndex = #observation.members, 1, -1 do
                if type(observation.members[memberIndex]) ~= "table" then
                    table.remove(observation.members, memberIndex)
                    observation.membersTruncated = true
                end
            end
            while #observation.members > Core.LIMITS.membersPerObservation do
                table.remove(observation.members)
                observation.membersTruncated = true
            end
        end
    end

    session.runtime = type(session.runtime) == "table" and session.runtime or {}
    session.runtime.errors = sanitizeErrors(state, session.runtime.errors)
    for _, observation in ipairs(session.observations) do
        observation.errors = sanitizeErrors(state, observation.errors)
    end

    local lastEvent = session.events[#session.events]
    local lastObservation = session.observations[#session.observations]
    session.nextEventSequence = math.max(
        tonumber(session.nextEventSequence) or 1,
        (type(lastEvent) == "table" and tonumber(lastEvent.sequence) or 0) + 1
    )
    session.nextObservationSequence = math.max(
        tonumber(session.nextObservationSequence) or 1,
        (type(lastObservation) == "table"
            and tonumber(lastObservation.sequence)
            or 0) + 1
    )
    return session
end

local function normalizeAliasBucket(state, aliases, kind)
    local bucket = ensureAliasBucket(aliases, kind)
    local prefix = ALIAS_KINDS[kind]
    local retained = {}
    local seenAliases = {}
    local count = 0
    local highestIndex = 0

    for raw, alias in pairs(bucket.values) do
        local aliasIndex = type(alias) == "string"
            and tonumber(alias:match("^" .. prefix .. "%-(%d+)$"))
            or nil
        if type(raw) == "string" and raw ~= ""
            and aliasIndex ~= nil
            and not seenAliases[alias]
            and count < Core.LIMITS.aliases then
            retained[raw] = alias
            seenAliases[alias] = true
            count = count + 1
            highestIndex = math.max(highestIndex, aliasIndex)
        else
            state.aliasLimitReached = true
        end
    end

    bucket.values = retained
    bucket.count = count
    bucket.nextIndex = math.max(
        tonumber(bucket.nextIndex) or 1,
        highestIndex + 1
    )
    return bucket
end

function Core.loadState(value)
    if type(value) ~= "table"
        or value.schemaVersion ~= Core.SCHEMA_VERSION then
        return Core.newState()
    end

    value.enabled = value.enabled == true
    value.captureStopped = value.captureStopped == true
    local sourceSessions = type(value.sessions) == "table" and value.sessions or {}
    local sourceAliases = type(value.aliases) == "table" and value.aliases or {}
    value.sessions = {}
    value.aliases = {}
    value.droppedSessions = tonumber(value.droppedSessions) or 0
    value.aliasLimitReached = value.aliasLimitReached == true
    value.errorsTruncated = value.errorsTruncated == true
    value.nextSessionIndex = tonumber(value.nextSessionIndex) or 1
    if value.nextSessionIndex < 1 then
        value.nextSessionIndex = 1
    end
    if not BOUNDARIES[value.pendingBoundary] then
        value.pendingBoundary = nil
    end

    for kind in pairs(ALIAS_KINDS) do
        value.aliases[kind] = sourceAliases[kind]
        normalizeAliasBucket(value, value.aliases, kind)
    end

    local firstRetained = math.max(1, #sourceSessions - Core.LIMITS.sessions + 1)
    for index = 1, #sourceSessions do
        local session = boundSession(value, sourceSessions[index])
        if session and index >= firstRetained then
            value.sessions[#value.sessions + 1] = session
        else
            value.droppedSessions = value.droppedSessions + 1
        end
    end
    while #value.sessions > Core.LIMITS.sessions do
        table.remove(value.sessions, 1)
        value.droppedSessions = value.droppedSessions + 1
    end

    return value
end

local function hasText(value)
    return type(value) == "string" and value ~= ""
end

local function hasScalar(value)
    return value ~= nil and (
        type(value) == "number"
        or type(value) == "boolean"
        or hasText(value)
    )
end

sanitizeErrors = function(state, values)
    local result = {}
    local seen = {}
    if values == nil then
        return result
    end
    if type(values) ~= "table" then
        state.errorsTruncated = true
        return result
    end

    for _, code in ipairs(values) do
        if type(code) == "string" and Core.ERROR_CODES[code]
            and not seen[code] then
            if #result >= Core.LIMITS.errors then
                state.errorsTruncated = true
                break
            end
            result[#result + 1] = code
            seen[code] = true
        elseif type(code) ~= "string" or not Core.ERROR_CODES[code] then
            state.errorsTruncated = true
        end
    end
    return result
end

local function aliasValue(state, kind, value)
    if not hasScalar(value) then
        return nil
    end

    local raw = tostring(value)
    if raw == "" then
        return nil
    end

    local bucket = ensureAliasBucket(state.aliases, kind)
    local existing = bucket.values[raw]
    if existing then
        return existing
    end

    local prefix = ALIAS_KINDS[kind]
    if bucket.count >= Core.LIMITS.aliases then
        state.aliasLimitReached = true
        return prefix .. "-Limit"
    end

    local result = string.format("%s-%03d", prefix, bucket.nextIndex)
    bucket.nextIndex = bucket.nextIndex + 1
    bucket.count = bucket.count + 1
    bucket.values[raw] = result
    return result
end

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function foreverNameParts(value)
    local supplied = trim(value)
    if supplied == "" then
        return nil, nil
    end

    local first, surname = supplied:match("^(%S+)%s+(.+)$")
    if not first then
        return nil, nil
    end
    surname = trim(surname)
    if surname == "" then
        surname = nil
    end
    if surname == nil then
        return nil, nil
    end
    return first, surname
end

function Core.sanitizeCompositeName(state, value, style)
    if not hasText(value) then
        return nil
    end

    if style ~= "forever" then
        return aliasValue(state, "member", value)
    end

    local first, surname = foreverNameParts(value)
    local firstAlias = aliasValue(state, "first", first)
    local surnameAlias = aliasValue(state, "surname", surname)
    if not firstAlias or not surnameAlias then
        return nil
    end
    return firstAlias .. " " .. surnameAlias
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
    "realm",
    "clubId",
    "memberCount",
}

local OBSERVATION_AVAILABILITY_FIELDS = {
    "memberListCount",
    "guildRosterMemberCount",
    "guildRosterOnlineCount",
}

local MEMBER_AVAILABILITY_FIELDS = {
    "name",
    "guid",
}

local MEMBER_SOURCES = {
    club = true,
    ["guild-roster"] = true,
    none = true,
}

local function sanitizeRuntime(state, raw)
    raw = type(raw) == "table" and raw or {}
    local result = {
        availability = {},
        errors = sanitizeErrors(state, raw.errors),
    }

    for _, field in ipairs({
        "productId",
        "version",
        "build",
        "interface",
        "region",
    }) do
        if hasScalar(raw[field]) then
            result[field] = raw[field]
            result.availability[field] = true
        else
            result.availability[field] = false
        end
    end

    result.realmName = aliasValue(state, "realm", raw.realmName)
    result.normalizedRealmName = aliasValue(state, "realm", raw.normalizedRealmName)
    result.playerName = Core.sanitizeCompositeName(
        state,
        raw.playerName,
        raw.nameStyle or (raw.productId == 18 and "forever" or "retail")
    )
    result.playerRealm = aliasValue(state, "realm", raw.playerRealm)

    for _, field in ipairs({
        "realmName",
        "normalizedRealmName",
        "playerName",
        "playerRealm",
    }) do
        result.availability[field] = result[field] ~= nil
    end

    return result
end

local function currentSession(state)
    local index = state.currentSessionIndex
    if type(index) ~= "number" then
        return nil
    end
    for _, session in ipairs(state.sessions) do
        if session.index == index then
            return session
        end
    end
    return nil
end

function Core.startSession(state, runtime, boundary)
    state = Core.loadState(state)

    local previous = currentSession(state)
    if previous and previous.stopped ~= true then
        previous.stopped = true
        previous.stopReason = "interrupted"
    end

    local selectedBoundary = state.pendingBoundary
        or (BOUNDARIES[boundary] and boundary)
        or "initial"
    state.pendingBoundary = nil

    local session = {
        index = state.nextSessionIndex,
        boundary = selectedBoundary,
        runtime = sanitizeRuntime(state, runtime),
        events = {},
        observations = {},
        nextEventSequence = 1,
        nextObservationSequence = 1,
        droppedEvents = 0,
        droppedObservations = 0,
        stopped = false,
    }
    state.nextSessionIndex = state.nextSessionIndex + 1
    state.currentSessionIndex = session.index
    state.enabled = true
    state.captureStopped = false
    state.sessions[#state.sessions + 1] = session

    if #state.sessions > Core.LIMITS.sessions then
        table.remove(state.sessions, 1)
        state.droppedSessions = state.droppedSessions + 1
    end

    return session
end

function Core.stopSession(state, disableCapture, reason)
    state = Core.loadState(state)
    local session = currentSession(state)
    if session then
        session.stopped = true
        session.stopReason = tostring(reason or "stop")
    end
    state.currentSessionIndex = nil
    if disableCapture == true then
        state.enabled = false
        state.captureStopped = true
    end
    return session
end

function Core.markBoundary(state, boundary)
    if not BOUNDARIES[boundary] or boundary == "initial"
        or boundary == "interrupted" then
        return nil, "unsupported boundary"
    end
    state.pendingBoundary = boundary
    return true
end

function Core.recordEvent(state, raw)
    local session = currentSession(state)
    if not session then
        return nil, "no active session"
    end
    if #session.events >= Core.LIMITS.events then
        session.droppedEvents = session.droppedEvents + 1
        return nil, "event limit reached"
    end

    raw = type(raw) == "table" and raw or {}
    local event = {
        sequence = session.nextEventSequence,
        name = tostring(raw.name or "UNKNOWN"),
        availability = {},
    }
    session.nextEventSequence = session.nextEventSequence + 1

    event.clubId = aliasValue(state, "club", raw.clubId)
    event.memberId = aliasValue(state, "memberId", raw.memberId)
    if type(raw.canRequestRosterUpdate) == "boolean" then
        event.canRequestRosterUpdate = raw.canRequestRosterUpdate
    end
    event.availability.clubId = event.clubId ~= nil
    event.availability.memberId = event.memberId ~= nil
    event.availability.canRequestRosterUpdate =
        event.canRequestRosterUpdate ~= nil

    session.events[#session.events + 1] = event
    return event
end

local function sanitizeGuild(state, raw)
    raw = type(raw) == "table" and raw or {}
    local result = { availability = {} }
    result.name = aliasValue(state, "guild", raw.name)
    result.realm = aliasValue(state, "realm", raw.realm)
    result.clubId = aliasValue(state, "club", raw.clubId)
    if type(raw.memberCount) == "number" then
        result.memberCount = raw.memberCount
    end
    result.availability.name = result.name ~= nil
    result.availability.realm = result.realm ~= nil
    result.availability.clubId = result.clubId ~= nil
    result.availability.memberCount = result.memberCount ~= nil
    return result
end

local function sanitizeMember(state, raw, style)
    raw = type(raw) == "table" and raw or {}
    local result = { availability = {} }
    result.name = Core.sanitizeCompositeName(state, raw.name, style)
    result.guid = aliasValue(state, "guid", raw.guid)
    result.availability.name = result.name ~= nil
    result.availability.guid = result.guid ~= nil
    return result
end

function Core.recordObservation(state, raw)
    local session = currentSession(state)
    if not session then
        return nil, "no active session"
    end
    if #session.observations >= Core.LIMITS.observations then
        session.droppedObservations = session.droppedObservations + 1
        return nil, "observation limit reached"
    end

    raw = type(raw) == "table" and raw or {}
    local observation = {
        sequence = session.nextObservationSequence,
        trigger = tostring(raw.trigger or "manual"),
        memberSource = MEMBER_SOURCES[raw.memberSource]
            and raw.memberSource
            or (type(raw.memberListCount) == "number" and "club" or "none"),
        availability = {},
        errors = sanitizeErrors(state, raw.errors),
        guild = sanitizeGuild(state, raw.guild),
        members = {},
        membersTruncated = raw.membersTruncated == true,
    }
    session.nextObservationSequence = session.nextObservationSequence + 1

    for _, field in ipairs({
        "memberListCount",
        "guildRosterMemberCount",
        "guildRosterOnlineCount",
    }) do
        if type(raw[field]) == "number" then
            observation[field] = raw[field]
            observation.availability[field] = true
        else
            observation.availability[field] = false
        end
    end

    local members = type(raw.members) == "table" and raw.members or {}
    local nameStyle = raw.nameStyle
        or (session.runtime.productId == 18 and "forever" or "retail")
    local captureCount = math.min(#members, Core.LIMITS.membersPerObservation)
    for index = 1, captureCount do
        observation.members[#observation.members + 1] = sanitizeMember(
            state,
            members[index],
            nameStyle
        )
    end
    observation.membersTruncated = observation.membersTruncated
        or #members > captureCount

    session.observations[#session.observations + 1] = observation
    return observation
end

local function copyAvailability(source, fields)
    local result = {}
    source = source or {}
    for _, field in ipairs(fields) do
        result[field] = source[field] == true
    end
    return result
end

local function copyRuntime(source)
    local result = {
        availability = copyAvailability(
            source.availability,
            RUNTIME_AVAILABILITY_FIELDS
        ),
        errors = {},
    }
    for _, code in ipairs(source.errors or {}) do
        result.errors[#result.errors + 1] = code
    end
    for _, field in ipairs(RUNTIME_AVAILABILITY_FIELDS) do
        if source[field] ~= nil then
            result[field] = source[field]
        end
    end
    return result
end

local function copyEvent(source)
    local result = {
        sequence = source.sequence,
        name = source.name,
        availability = copyAvailability(
            source.availability,
            EVENT_AVAILABILITY_FIELDS
        ),
    }
    for _, field in ipairs({
        "clubId",
        "memberId",
        "canRequestRosterUpdate",
    }) do
        if source[field] ~= nil then
            result[field] = source[field]
        end
    end
    return result
end

local function copyGuild(source)
    local result = {
        availability = copyAvailability(
            source.availability,
            GUILD_AVAILABILITY_FIELDS
        ),
    }
    for _, field in ipairs({ "name", "realm", "clubId", "memberCount" }) do
        if source[field] ~= nil then
            result[field] = source[field]
        end
    end
    return result
end

local function copyMember(source)
    local result = {
        availability = copyAvailability(
            source.availability,
            MEMBER_AVAILABILITY_FIELDS
        ),
    }
    if source.name ~= nil then
        result.name = source.name
    end
    if source.guid ~= nil then
        result.guid = source.guid
    end
    return result
end

local function copyObservation(source)
    local result = {
        sequence = source.sequence,
        trigger = source.trigger,
        memberSource = MEMBER_SOURCES[source.memberSource]
            and source.memberSource
            or "none",
        availability = copyAvailability(
            source.availability,
            OBSERVATION_AVAILABILITY_FIELDS
        ),
        errors = {},
        guild = copyGuild(source.guild or {}),
        members = {},
    }
    for _, code in ipairs(source.errors or {}) do
        result.errors[#result.errors + 1] = code
    end
    for _, field in ipairs({
        "memberListCount",
        "guildRosterMemberCount",
        "guildRosterOnlineCount",
    }) do
        if source[field] ~= nil then
            result[field] = source[field]
        end
    end
    for _, member in ipairs(source.members or {}) do
        result.members[#result.members + 1] = copyMember(member)
    end
    return result
end

local function isTruncated(state)
    if state.droppedSessions > 0 or state.aliasLimitReached
        or state.errorsTruncated then
        return true
    end
    for _, session in ipairs(state.sessions) do
        if (session.droppedEvents or 0) > 0
            or (session.droppedObservations or 0) > 0 then
            return true
        end
        for _, observation in ipairs(session.observations or {}) do
            if observation.membersTruncated == true then
                return true
            end
        end
    end
    return false
end

function Core.createExport(state)
    state = Core.loadState(state)
    local truncated = isTruncated(state)
    local result = {
        schemaVersion = Core.SCHEMA_VERSION,
        complete = state.captureStopped == true
            and state.enabled ~= true
            and #state.sessions > 0
            and not truncated,
        truncated = truncated,
        limits = {
            sessions = Core.LIMITS.sessions,
            events = Core.LIMITS.events,
            observations = Core.LIMITS.observations,
            membersPerObservation = Core.LIMITS.membersPerObservation,
        },
        sessions = {},
    }

    for _, source in ipairs(state.sessions) do
        local session = {
            index = source.index,
            boundary = source.boundary,
            runtime = copyRuntime(source.runtime or {}),
            events = {},
            observations = {},
        }
        for _, event in ipairs(source.events or {}) do
            session.events[#session.events + 1] = copyEvent(event)
        end
        for _, observation in ipairs(source.observations or {}) do
            session.observations[#session.observations + 1] =
                copyObservation(observation)
        end
        result.sessions[#result.sessions + 1] = session
    end

    return result
end

local function escaped(value)
    if value == nil then
        return ""
    end
    if type(value) == "boolean" then
        return value and "true" or "false"
    end
    local result = tostring(value)
    result = result:gsub("\\", "\\\\")
    result = result:gsub("|", "\\p")
    result = result:gsub("\r", "\\r")
    result = result:gsub("\n", "\\n")
    return result
end

local function addLine(lines, ...)
    local values = {}
    local count = select("#", ...)
    for index = 1, count do
        values[index] = escaped(select(index, ...))
    end
    lines[#lines + 1] = table.concat(values, "|")
end

local function addAvailabilityLine(lines, recordType, sessionIndex,
        sequence, availability, fields)
    local values = { recordType, sessionIndex, sequence }
    for _, field in ipairs(fields) do
        values[#values + 1] = field
        values[#values + 1] = availability[field] == true
    end
    addLine(lines, unpack(values))
end

function Core.formatExport(export)
    export = type(export) == "table" and export or {
        schemaVersion = Core.SCHEMA_VERSION,
        complete = false,
        truncated = true,
        limits = Core.LIMITS,
        sessions = {},
    }

    local lines = {}
    addLine(
        lines,
        "RGMS_RUNTIME_PROBE",
        export.schemaVersion,
        export.complete,
        export.truncated
    )
    local limits = export.limits or {}
    addLine(
        lines,
        "LIMITS",
        limits.sessions,
        limits.events,
        limits.observations,
        limits.membersPerObservation
    )

    for _, session in ipairs(export.sessions or {}) do
        local runtime = session.runtime or {}
        addLine(
            lines,
            "SESSION",
            session.index,
            session.boundary,
            runtime.productId,
            runtime.version,
            runtime.build,
            runtime.interface,
            runtime.region,
            runtime.realmName,
            runtime.normalizedRealmName,
            runtime.playerName,
            runtime.playerRealm
        )
        addAvailabilityLine(
            lines,
            "RUNTIME_AVAILABILITY",
            session.index,
            0,
            runtime.availability or {},
            RUNTIME_AVAILABILITY_FIELDS
        )
        for _, code in ipairs(runtime.errors or {}) do
            addLine(lines, "RUNTIME_ERROR", session.index, code)
        end

        for _, event in ipairs(session.events or {}) do
            addLine(
                lines,
                "EVENT",
                session.index,
                event.sequence,
                event.name,
                event.clubId,
                event.memberId,
                event.canRequestRosterUpdate
            )
            addAvailabilityLine(
                lines,
                "EVENT_AVAILABILITY",
                session.index,
                event.sequence,
                event.availability or {},
                EVENT_AVAILABILITY_FIELDS
            )
        end

        for _, observation in ipairs(session.observations or {}) do
            local guild = observation.guild or {}
            addLine(
                lines,
                "OBSERVATION",
                session.index,
                observation.sequence,
                observation.trigger,
                observation.memberSource,
                guild.name,
                guild.realm,
                guild.clubId,
                guild.memberCount,
                observation.memberListCount,
                observation.guildRosterMemberCount,
                observation.guildRosterOnlineCount,
                #(observation.members or {})
            )
            addAvailabilityLine(
                lines,
                "OBSERVATION_AVAILABILITY",
                session.index,
                observation.sequence,
                observation.availability or {},
                OBSERVATION_AVAILABILITY_FIELDS
            )
            for _, code in ipairs(observation.errors or {}) do
                addLine(
                    lines,
                    "OBSERVATION_ERROR",
                    session.index,
                    observation.sequence,
                    code
                )
            end
            addAvailabilityLine(
                lines,
                "GUILD_AVAILABILITY",
                session.index,
                observation.sequence,
                guild.availability or {},
                GUILD_AVAILABILITY_FIELDS
            )
            for memberIndex, member in ipairs(observation.members or {}) do
                addLine(
                    lines,
                    "MEMBER",
                    session.index,
                    observation.sequence,
                    memberIndex,
                    member.name,
                    member.guid
                )
                addAvailabilityLine(
                    lines,
                    "MEMBER_AVAILABILITY",
                    session.index,
                    tostring(observation.sequence) .. "." .. memberIndex,
                    member.availability or {},
                    MEMBER_AVAILABILITY_FIELDS
                )
            end
        end
    end

    return table.concat(lines, "\n")
end

if type(addon) == "table" then
    addon.Core = Core
end

return Core
