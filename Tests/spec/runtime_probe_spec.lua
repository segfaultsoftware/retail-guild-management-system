local test = require("Tests.lib.runner")
local runtimeFixtures = require("Tests.runtime_contract_fixtures")
local runtimeExporter = require("scripts.export-runtime-probe")

local function loadCore()
    local addon = {}
    local chunk = assert(loadfile("Diagnostics/RGMSRuntimeProbe/Core.lua"))
    local core = chunk("RGMSRuntimeProbe", addon)
    return core, addon
end

local function foreverRuntime()
    return {
        productId = 18,
        version = "1.60.1",
        build = "65432",
        interface = 16001,
        region = "US",
        realmName = "Private Forever Realm",
        normalizedRealmName = "PrivateForeverRealm",
        playerName = "Avery Ash",
        playerRealm = "Private Forever Realm",
        nameStyle = "forever",
    }
end

local function foreverObservation(trigger)
    return {
        trigger = trigger or "MANUAL_SNAPSHOT",
        nameStyle = "forever",
        guild = {
            name = "Private Forever Guild",
            realm = "Private Forever Realm",
            clubId = 987654321,
            memberCount = 2,
        },
        memberListCount = 2,
        guildRosterMemberCount = 2,
        guildRosterOnlineCount = 1,
        members = {
            {
                name = "Avery Ash",
                guid = "Player-Private-Ash",
            },
            {
                name = "Avery Birch",
                guid = "Player-Private-Birch",
            },
        },
    }
end

local function completeForeverExport()
    local core = loadCore()
    local state = core.newState()
    core.startSession(state, foreverRuntime(), "initial")
    core.recordEvent(state, {
        name = "GUILD_ROSTER_UPDATE",
        canRequestRosterUpdate = true,
    })
    core.recordObservation(state, foreverObservation())
    core.stopSession(state, true, "test-stop")
    return core, state, core.createExport(state)
end

local function withTemporaryFile(source, callback)
    local path = os.tmpname()
    local handle, openError = io.open(path, "wb")
    if not handle then
        error(openError, 0)
    end
    local wrote, writeError = handle:write(source)
    local closed, closeError = handle:close()
    if not wrote then
        os.remove(path)
        error(writeError, 0)
    end
    if not closed then
        os.remove(path)
        error(closeError, 0)
    end

    local succeeded, callbackError = pcall(callback, path)
    os.remove(path)
    if not succeeded then
        error(callbackError, 0)
    end
end

local RUNTIME_GLOBALS = {
    "C_Club",
    "C_GuildInfo",
    "CreateFrame",
    "DEFAULT_CHAT_FRAME",
    "GetBuildInfo",
    "GetCurrentRegion",
    "GetGuildInfo",
    "GetGuildRosterInfo",
    "GetNormalizedRealmName",
    "GetNumGuildMembers",
    "GetRealmName",
    "GuildRoster",
    "RGMSRuntimeProbeDB",
    "RGMSRuntimeProbeExport",
    "SLASH_RGMSRUNTIMEPROBE1",
    "SlashCmdList",
    "UnitFullName",
    "UnitName",
    "WOW_PROJECT_ID",
}

local function withRuntimeHarness(options, callback)
    if type(options) == "function" then
        callback = options
        options = {}
    end
    options = options or {}
    local previous = {}
    for _, name in ipairs(RUNTIME_GLOBALS) do
        previous[name] = _G[name]
    end

    local frames = {}
    local messages = {}
    local rosterRequests = 0
    local fallbackRosterRequests = 0
    local isForever = options.productId ~= 1
    _G.WOW_PROJECT_ID = isForever and 18 or 1
    _G.GetBuildInfo = function()
        if isForever then
            return "1.60.1", "65432", "Nov 9 2026", 16001
        end
        return "12.1.5", "65433", "Nov 9 2026", 120105
    end
    _G.GetCurrentRegion = function() return 1 end
    _G.GetRealmName = function() return "Private Forever Realm" end
    _G.GetNormalizedRealmName = function() return "PrivateForeverRealm" end
    _G.UnitName = function()
        if isForever then return "Avery", "Ash" end
        return "Retailer", "PrivateForeverRealm"
    end
    _G.UnitFullName = function()
        if isForever then return "Wrong", "SurnameIsNotARealm" end
        return "Retailer", "PrivateForeverRealm"
    end
    _G.GetGuildInfo = function()
        return "Private Forever Guild", nil, nil, "Private Forever Realm"
    end
    _G.GetNumGuildMembers = function() return 2, 1 end
    _G.GetGuildRosterInfo = function(index)
        if index == 1 then
            return isForever and "Avery Ash" or "Retailer-PrivateForeverRealm",
                nil, nil, nil, nil, nil, nil, nil, nil,
                nil, nil, nil, nil, nil, nil, nil, "Player-Private-Ash"
        end
        return isForever and "Avery Birch" or "Second-PrivateForeverRealm",
            nil, nil, nil, nil, nil, nil, nil, nil,
            nil, nil, nil, nil, nil, nil, nil, "Player-Private-Birch"
    end
    _G.C_GuildInfo = {
        GuildRoster = function()
            rosterRequests = rosterRequests + 1
            if options.modernRequestFails then
                error("modern request unavailable")
            end
        end,
    }
    _G.GuildRoster = function()
        fallbackRosterRequests = fallbackRosterRequests + 1
    end
    _G.C_Club = {
        GetGuildClubId = function() return 987654321 end,
        GetClubInfo = function()
            return { name = "Private Forever Guild", memberCount = 2 }
        end,
        GetClubMembers = function() return { 101, 202 } end,
        GetMemberInfo = function(_, memberId)
            if options.clubMemberInfoIncomplete then
                return {}
            end
            if memberId == 101 then
                return {
                    name = isForever and "Avery Ash"
                        or "Retailer-PrivateForeverRealm",
                    guid = "Player-Private-Ash",
                }
            end
            return {
                name = isForever and "Avery Birch"
                    or "Second-PrivateForeverRealm",
                guid = "Player-Private-Birch",
            }
        end,
    }
    _G.DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, message)
            messages[#messages + 1] = message
        end,
    }
    _G.CreateFrame = function()
        local frame = { scripts = {}, events = {} }
        function frame:RegisterEvent(event)
            self.events[event] = true
        end
        function frame:SetScript(scriptName, script)
            self.scripts[scriptName] = script
        end
        frames[#frames + 1] = frame
        return frame
    end
    _G.SlashCmdList = {}
    _G.RGMSRuntimeProbeDB = nil
    _G.RGMSRuntimeProbeExport = nil

    local core, addon = loadCore()
    local function loadRuntime()
        local runtimeAddon = { Core = core }
        local chunk = assert(loadfile("Diagnostics/RGMSRuntimeProbe/Runtime.lua"))
        local runtime = chunk("RGMSRuntimeProbe", runtimeAddon)
        local frame = frames[#frames]
        frame.scripts.OnEvent(frame, "ADDON_LOADED", "RGMSRuntimeProbe")
        return runtime, frame
    end

    local succeeded, callbackError = pcall(callback, {
        addon = addon,
        core = core,
        frames = frames,
        loadRuntime = loadRuntime,
        messages = messages,
        fallbackRosterRequests = function() return fallbackRosterRequests end,
        rosterRequests = function() return rosterRequests end,
    })

    for _, name in ipairs(RUNTIME_GLOBALS) do
        _G[name] = previous[name]
    end
    if not succeeded then
        error(callbackError, 0)
    end
end

return {
    test.case("runtime probe sanitizes stable Forever identities without raw values", function()
        local core, state, export = completeForeverExport()

        test.assert_true(export.complete)
        test.assert_false(export.truncated)
        local members = export.sessions[1].observations[1].members
        test.assert_equal(members[1].name, "First-001 Surname-001")
        test.assert_equal(members[2].name, "First-001 Surname-002")
        test.assert_true(members[1].name ~= members[2].name)

        core.startSession(state, foreverRuntime(), "reload")
        core.recordObservation(state, foreverObservation("PLAYER_LOGIN"))
        core.stopSession(state, true, "test-stop")
        export = core.createExport(state)
        test.assert_equal(export.sessions[2].boundary, "reload")
        test.assert_equal(
            export.sessions[2].observations[1].members[1].name,
            members[1].name
        )
        test.assert_equal(
            export.sessions[2].observations[1].members[1].guid,
            members[1].guid
        )

        local formatted = core.formatExport(export)
        for _, privateValue in ipairs({
            "Avery", "Ash", "Birch", "Private Forever Guild",
            "Private Forever Realm", "Player-Private", "987654321",
        }) do
            test.assert_nil(string.find(formatted, privateValue, 1, true))
        end
        test.assert_matches(formatted, "First%-001 Surname%-001")
    end),

    test.case("runtime probe records unavailable values explicitly", function()
        local core = loadCore()
        local state = core.newState()
        core.startSession(state, {
            productId = 18,
            version = "1.60.1",
            build = "65432",
            interface = 16001,
            region = "US",
            nameStyle = "forever",
            errors = { "GET_REALM_NAME_MISSING" },
        }, "initial")
        core.recordEvent(state, { name = "PLAYER_LOGIN" })
        core.recordObservation(state, {
            trigger = "PLAYER_LOGIN",
            nameStyle = "forever",
            errors = { "GET_GUILD_CLUB_ID_UNAVAILABLE" },
            guild = {},
            members = {},
        })
        core.stopSession(state, true, "test-stop")

        local export = core.createExport(state)
        local runtime = export.sessions[1].runtime
        local observation = export.sessions[1].observations[1]
        test.assert_false(runtime.availability.realmName)
        test.assert_equal(runtime.errors, { "GET_REALM_NAME_MISSING" })
        test.assert_false(runtime.availability.playerName)
        test.assert_nil(runtime.realmName)
        test.assert_false(observation.guild.availability.clubId)
        test.assert_equal(
            observation.errors,
            { "GET_GUILD_CLUB_ID_UNAVAILABLE" }
        )
        test.assert_false(observation.availability.memberListCount)
        test.assert_equal(observation.members, {})
        test.assert_not_nil(runtimeFixtures.validate(export))
    end),

    test.case("runtime probe refuses to call a truncated capture complete", function()
        local core = loadCore()
        local state = core.newState()
        core.startSession(state, foreverRuntime(), "initial")
        local observation = foreverObservation()
        observation.membersTruncated = true
        core.recordObservation(state, observation)
        core.stopSession(state, true, "test-stop")

        local export = core.createExport(state)
        test.assert_true(export.truncated)
        test.assert_false(export.complete)
    end),

    test.case("persisted probe state is re-bounded before reuse", function()
        local core, state = completeForeverExport()
        local session = state.sessions[1]
        for index = 1, core.LIMITS.events + 1 do
            session.events[index] = {
                sequence = index,
                name = "PLAYER_LOGIN",
                availability = {
                    clubId = false,
                    memberId = false,
                    canRequestRosterUpdate = false,
                },
            }
        end
        for index = 1, core.LIMITS.observations + 1 do
            session.observations[index] = session.observations[1]
        end

        state = core.loadState(state)
        test.assert_equal(#state.sessions[1].events, core.LIMITS.events)
        test.assert_equal(
            #state.sessions[1].observations,
            core.LIMITS.observations
        )
        test.assert_true(state.sessions[1].droppedEvents > 0)
        test.assert_true(state.sessions[1].droppedObservations > 0)
        test.assert_true(core.createExport(state).truncated)
    end),

    test.case("fixture formatter and restricted loaders round-trip only sanitized data", function()
        local _, _, export = completeForeverExport()
        local source = assert(runtimeFixtures.format(export))
        test.assert_equal(assert(runtimeFixtures.format(export)), source)

        withTemporaryFile(source, function(path)
            test.assert_equal(runtimeFixtures.load(path), export)
        end)

        local savedVariables = table.concat({
            "RGMSRuntimeProbeDB = { aliases = { raw = \"Private Raw Name\" } }\n",
            source,
        })
        withTemporaryFile(savedVariables, function(path)
            local loaded = assert(runtimeFixtures.loadSavedVariables(path))
            local sanitized = assert(runtimeFixtures.format(loaded))
            test.assert_nil(string.find(sanitized, "Private Raw Name", 1, true))
            test.assert_nil(string.find(sanitized, "RGMSRuntimeProbeDB", 1, true))
        end)
    end),

    test.case("fixture validation rejects raw aliases and executable input", function()
        local _, _, export = completeForeverExport()
        export.sessions[1].observations[1].members[1].name = "Avery Ash"
        local validated, validationError = runtimeFixtures.validate(export)
        test.assert_nil(validated)
        test.assert_matches(validationError, "sanitized character alias")

        withTemporaryFile(
            "RGMSRuntimeProbeExport = (function() return {} end)()\n",
            function(path)
                local loaded, loadError = runtimeFixtures.load(path)
                test.assert_nil(loaded)
                test.assert_matches(loadError, "not a literal SavedVariables file")
            end
        )
    end),

    test.case("fixture validation closes identifier-shaped side channels", function()
        local _, _, export = completeForeverExport()
        export.sessions[1].observations[1].guild.clubId = "Club-987654321"
        local validated, validationError = runtimeFixtures.validate(export)
        test.assert_nil(validated)
        test.assert_matches(validationError, "Club%-NNN alias")

        _, _, export = completeForeverExport()
        export.sessions[1].observations[1].guild.clubId = "Club-0001"
        validated, validationError = runtimeFixtures.validate(export)
        test.assert_nil(validated)
        test.assert_matches(validationError, "Club%-NNN alias")

        _, _, export = completeForeverExport()
        export.sessions[1].observations[1].members[1].guid = "Guid-987654321"
        validated, validationError = runtimeFixtures.validate(export)
        test.assert_nil(validated)
        test.assert_matches(validationError, "Guid%-NNN alias")

        _, _, export = completeForeverExport()
        export.sessions[1].events[1].availability.memberId = true
        export.sessions[1].events[1].memberId = "MemberId-987654321"
        validated, validationError = runtimeFixtures.validate(export)
        test.assert_nil(validated)
        test.assert_matches(validationError, "MemberId%-NNN alias")

        _, _, export = completeForeverExport()
        export.sessions[1].events[1].name = "PRIVATE_GUILD_NAME"
        validated, validationError = runtimeFixtures.validate(export)
        test.assert_nil(validated)
        test.assert_matches(validationError, "approved probe event")

        _, _, export = completeForeverExport()
        export.sessions[1].observations[1].trigger = "PRIVATE_GUILD_NAME"
        validated, validationError = runtimeFixtures.validate(export)
        test.assert_nil(validated)
        test.assert_matches(validationError, "approved probe trigger")

        _, _, export = completeForeverExport()
        export.sessions[1].runtime.errors = { "PRIVATE_GUILD_NAME" }
        validated, validationError = runtimeFixtures.validate(export)
        test.assert_nil(validated)
        test.assert_matches(validationError, "approved probe error code")

        _, _, export = completeForeverExport()
        export.sessions = {}
        validated, validationError = runtimeFixtures.validate(export)
        test.assert_nil(validated)
        test.assert_matches(validationError, "finalized session")
    end),

    test.case("fixture validation requires truncation for alias limit markers", function()
        local _, _, export = completeForeverExport()
        export.sessions[1].observations[1].members[1].guid = "Guid-Limit"

        local validated, validationError = runtimeFixtures.validate(export)
        test.assert_nil(validated)
        test.assert_matches(validationError, "truncated must be true")

        export.complete = false
        export.truncated = true
        test.assert_not_nil(runtimeFixtures.validate(export))
    end),

    test.case("fixture exporter writes only finalized data and never overwrites", function()
        local _, _, export = completeForeverExport()
        local source = assert(runtimeFixtures.format(export))
        local savedVariables = table.concat({
            "RGMSRuntimeProbeDB = { raw = \"Private Raw Name\" }\n",
            source,
        })

        withTemporaryFile(savedVariables, function(inputPath)
            local outputPath = os.tmpname()
            os.remove(outputPath)
            local exported, message = runtimeExporter.run(
                { inputPath, outputPath },
                { fixtures = runtimeFixtures }
            )
            test.assert_true(exported, message)
            local loaded = assert(runtimeFixtures.load(outputPath))
            test.assert_equal(loaded, export)

            local refused, refusal = runtimeExporter.run(
                { inputPath, outputPath },
                { fixtures = runtimeFixtures }
            )
            test.assert_nil(refused)
            test.assert_matches(refusal, "refusing to overwrite")
            test.assert_equal(assert(runtimeFixtures.load(outputPath)), export)
            os.remove(outputPath)
        end)

        export.complete = false
        source = assert(runtimeFixtures.format(export))
        withTemporaryFile(source, function(inputPath)
            local outputPath = os.tmpname()
            os.remove(outputPath)
            local exported, message = runtimeExporter.run(
                { inputPath, outputPath },
                { fixtures = runtimeFixtures }
            )
            test.assert_nil(exported)
            test.assert_matches(message, "not finalized")
            local output = io.open(outputPath, "rb")
            test.assert_nil(output)
        end)
    end),

    test.case("runtime adapter persists boundaries and scrubs raw state on stop", function()
        withRuntimeHarness(function(harness)
            local runtime, frame = harness.loadRuntime()
            runtime.handle("reset confirm")
            runtime.handle("start")
            test.assert_not_nil(_G.RGMSRuntimeProbeDB)
            test.assert_nil(_G.RGMSRuntimeProbeExport)
            test.assert_equal(
                _G.RGMSRuntimeProbeDB.sessions[1].runtime.playerName,
                "First-001 Surname-001"
            )
            test.assert_equal(
                _G.RGMSRuntimeProbeDB.sessions[1].runtime.playerRealm,
                "Realm-003"
            )

            runtime.handle("mark logout-login")
            frame.scripts.OnEvent(frame, "PLAYER_LOGOUT")
            test.assert_not_nil(_G.RGMSRuntimeProbeDB)
            test.assert_nil(_G.RGMSRuntimeProbeExport)

            local resumed = harness.loadRuntime()
            test.assert_equal(
                _G.RGMSRuntimeProbeDB.sessions[2].boundary,
                "logout-login"
            )
            resumed.handle("stop")
            resumed.handle("export")

            test.assert_nil(_G.RGMSRuntimeProbeDB)
            test.assert_true(_G.RGMSRuntimeProbeExport.complete)
            test.assert_false(_G.RGMSRuntimeProbeExport.truncated)
            local eventNames = {}
            for _, event in ipairs(_G.RGMSRuntimeProbeExport.sessions[1].events) do
                eventNames[#eventNames + 1] = event.name
            end
            test.assert_not_nil(
                string.find(table.concat(eventNames, " "), "MARK_LOGOUT_LOGIN", 1, true)
            )
            test.assert_true(harness.rosterRequests() >= 2)

            local formatted = harness.core.formatExport(_G.RGMSRuntimeProbeExport)
            test.assert_nil(string.find(formatted, "Avery", 1, true))
            test.assert_nil(string.find(formatted, "Private", 1, true))
        end)
    end),

    test.case("Retail adapter uses roster identities and request fallbacks", function()
        withRuntimeHarness({
            productId = 1,
            clubMemberInfoIncomplete = true,
            modernRequestFails = true,
        }, function(harness)
            local runtime = harness.loadRuntime()
            runtime.handle("reset confirm")
            runtime.handle("start")

            local observation = _G.RGMSRuntimeProbeDB
                .sessions[1].observations[1]
            test.assert_equal(observation.memberSource, "guild-roster")
            test.assert_equal(observation.members[1].name, "Member-002")
            test.assert_equal(observation.members[2].name, "Member-003")
            test.assert_equal(
                observation.errors,
                { "GET_MEMBER_INFO_INCOMPLETE" }
            )
            test.assert_true(harness.rosterRequests() >= 1)
            test.assert_true(harness.fallbackRosterRequests() >= 1)

            runtime.handle("stop")
            test.assert_true(_G.RGMSRuntimeProbeExport.complete)
            test.assert_not_nil(
                runtimeFixtures.validate(_G.RGMSRuntimeProbeExport)
            )
        end)
    end),
}
