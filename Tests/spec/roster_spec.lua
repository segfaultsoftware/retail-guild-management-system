local test = require("Tests.lib.runner")

local EVENT_GLOBAL_NAMES = {
    "C_Club",
    "C_GuildInfo",
    "CreateFrame",
    "IsInGuild",
}

local function withEventHarness(options, callback)
    if type(options) == "function" then
        callback = options
        options = {}
    end
    options = options or {}

    local previous = {}
    for _, name in ipairs(EVENT_GLOBAL_NAMES) do
        previous[name] = _G[name]
    end

    local calls = {
        activate = 0,
        capture = 0,
        requestScan = 0,
        requestRoster = 0,
        scanSources = {},
        statuses = {},
        contents = {},
    }
    local registeredEvents = {}
    local scripts = {}
    local scanner = {
        inProgress = options.inProgress ~= false,
    }
    local timers = {}
    local scanLocked = options.scanLocked == true
    local activationIndex = 0
    local activationResults = options.activationResults or {
        {
            identity = { key = "guild" },
            initialized = true,
        },
    }

    function scanner:IsInProgress()
        return self.inProgress
    end

    function scanner:OnDataUpdated()
        calls.capture = calls.capture + 1
    end

    function scanner:Request(source)
        calls.requestScan = calls.requestScan + 1
        calls.scanSources[#calls.scanSources + 1] = source
        if type(options.requestScan) == "function" then
            local accepted, reason, admitted = options.requestScan(source, self)
            if not accepted then
                return nil, reason, admitted
            end
        end
        self.inProgress = true
        return true, nil, true
    end

    function scanner:RequestRosterUpdate()
        calls.requestRoster = calls.requestRoster + 1
    end

    function scanner:Update()
    end

    C_Club = {}
    C_GuildInfo = {}
    IsInGuild = function()
        return options.inGuild ~= false
    end
    CreateFrame = function()
        return {
            RegisterEvent = function(_, event)
                registeredEvents[event] = true
            end,
            SetScript = function(_, scriptName, handler)
                scripts[scriptName] = handler
            end,
        }
    end

    local fakeRGMS
    fakeRGMS = {
        RosterScanner = {
            create = function()
                return scanner
            end,
        },
        Reset = {
            canScan = function()
                return true
            end,
            canReport = function()
                return true
            end,
        },
        ActivateCurrentGuild = function()
            calls.activate = calls.activate + 1
            activationIndex = activationIndex + 1
            local result = activationResults[activationIndex]
                or activationResults[#activationResults]
            if result.identity ~= nil then
                fakeRGMS.ActiveGuildIdentity = result.identity
            elseif result.reason ~= "guild-identity-pending" then
                fakeRGMS.ActiveGuildIdentity = nil
            end
            if result.database ~= nil then
                fakeRGMS.DB = result.database
            end
            return result.identity,
                result.initialized,
                result.error,
                result.reason
        end,
        IsScanLocked = function()
            return scanLocked
        end,
        NewTimer = function(delay, timerCallback)
            local timer = {
                delay = delay,
                callback = timerCallback,
                cancelled = false,
            }
            function timer:Cancel()
                self.cancelled = true
            end
            timers[#timers + 1] = timer
            return timer
        end,
        UI = {
            SetGuildIdentityPending = function(waiting, actionable)
                calls.guildIdentityPending = {
                    waiting = waiting,
                    actionable = actionable,
                }
            end,
            SetRosterAvailable = function()
            end,
            SetViewContent = function(tabId, content)
                calls.contents[#calls.contents + 1] = {
                    tabId = tabId,
                    content = content,
                }
            end,
            SetViewStatus = function(tabId, status)
                calls.statuses[#calls.statuses + 1] = {
                    tabId = tabId,
                    status = status,
                }
            end,
        },
        SavedDataState = options.savedDataDisabled and {
            enabled = false,
            status = "incompatible",
        } or nil,
        DB = options.database,
        Print = function()
        end,
    }

    local chunk = assert(loadfile("Roster/Roster.lua"))
    local roster = chunk("RGMS", fakeRGMS)
    local succeeded, callbackError = pcall(callback, {
        calls = calls,
        onEvent = scripts.OnEvent,
        registeredEvents = registeredEvents,
        roster = roster,
        scanner = scanner,
        timers = timers,
        api = fakeRGMS,
        fireTimer = function(index)
            timers[index].callback()
        end,
        setLocked = function(locked)
            scanLocked = locked == true
        end,
        setInProgress = function(inProgress)
            scanner.inProgress = inProgress == true
        end,
    })

    for _, name in ipairs(EVENT_GLOBAL_NAMES) do
        _G[name] = previous[name]
    end
    if not succeeded then
        error(callbackError, 0)
    end
end

local function newHarness(options)
    options = options or {}
    local actions = {}
    local scanner = {
        inProgress = options.inProgress == true,
    }
    function scanner:IsInProgress()
        return self.inProgress
    end

    local fakeRGMS = {
        Roster = {
            Scanner = scanner,
        },
        Reset = {
            canScan = function()
                return true
            end,
            canReport = function()
                return true
            end,
        },
        UI = {
            SetRosterAvailable = function(isAvailable)
                actions[#actions + 1] = {
                    action = "available",
                    value = isAvailable,
                }
            end,
            SetRosterReport = function(report)
                actions[#actions + 1] = {
                    action = "report",
                    report = report,
                }
            end,
            SetViewStatus = function(tabId, status)
                actions[#actions + 1] = {
                    action = "status",
                    tabId = tabId,
                    status = status,
                }
            end,
        },
        DB = options.database,
        RosterReport = options.rosterReport,
        DateTime = options.dateTime,
    }

    local previousIsInGuild = IsInGuild
    IsInGuild = function()
        return options.inGuild ~= false
    end

    local chunk = assert(loadfile("Roster/Roster.lua"))
    local roster = chunk("RGMS", fakeRGMS)

    return {
        actions = actions,
        roster = roster,
        restore = function()
            IsInGuild = previousIsInGuild
        end,
    }
end

return {
    test.case("login waits for a transient guild identity and schedules one retry", function()
        withEventHarness({
            inProgress = false,
            activationResults = {
                {
                    error = "guild club is not initialized",
                    reason = "guild-identity-pending",
                },
            },
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")

            test.assert_equal(harness.calls.activate, 1)
            test.assert_equal(harness.calls.requestScan, 0)
            test.assert_equal(#harness.timers, 1)
            test.assert_equal(harness.timers[1].delay, 0.5)
            test.assert_equal(
                harness.roster.GetGuildIdentityReadiness(),
                "waiting"
            )
            test.assert_equal(harness.calls.statuses[#harness.calls.statuses], {
                tabId = "roster",
                status = "Waiting for guild data…",
            })
            test.assert_equal(harness.calls.contents[#harness.calls.contents], {
                tabId = "roster",
                content = "Waiting for guild data…",
            })
        end)
    end),

    test.case("pre-login readiness binds cache but login alone admits the refresh", function()
        local cached = {
            roster = {
                ranks = {},
                members = { {} },
            },
        }
        withEventHarness({
            inProgress = false,
            activationResults = {
                {
                    identity = { key = "guild" },
                    initialized = false,
                    database = cached,
                },
            },
        }, function(harness)
            test.assert_true(harness.roster.PrimeGuildIdentityPending(
                "guild-identity-pending"
            ))
            test.assert_equal(
                harness.roster.GetGuildIdentityReadiness(),
                "waiting"
            )

            harness.onEvent(nil, "CLUB_MEMBERS_UPDATED")
            test.assert_true(harness.api.DB == cached)
            test.assert_equal(harness.calls.requestScan, 0)
            test.assert_nil(harness.roster.GetGuildIdentityReadiness())

            harness.onEvent(nil, "PLAYER_LOGIN")
            harness.onEvent(nil, "INITIAL_CLUBS_LOADED")
            harness.onEvent(nil, "CLUB_MEMBERS_UPDATED")
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_equal(harness.calls.scanSources, { "automatic" })
            test.assert_equal(#harness.timers, 0)
        end)
    end),

    test.case("unguilded login retains the established silent scan path", function()
        withEventHarness({
            inGuild = false,
            inProgress = false,
            activationResults = { {} },
            requestScan = function(source)
                test.assert_equal(source, "automatic")
                return nil, "not-in-guild"
            end,
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")

            test.assert_equal(harness.calls.activate, 1)
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_equal(harness.calls.scanSources, { "automatic" })
            test.assert_false(harness.scanner:IsInProgress())
            test.assert_nil(harness.roster.GetGuildIdentityReadiness())
            test.assert_equal(#harness.timers, 0)
        end)
    end),

    test.case("hard identity errors do not enter transient recovery", function()
        withEventHarness({
            inProgress = false,
            activationResults = {
                {
                    error = "guild identity is invalid",
                    reason = "invalid-guild-identity",
                },
            },
            requestScan = function(source)
                test.assert_equal(source, "automatic")
                return nil, "identity-unavailable"
            end,
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")

            test.assert_equal(harness.calls.activate, 1)
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_false(harness.scanner:IsInProgress())
            test.assert_nil(harness.roster.GetGuildIdentityReadiness())
            test.assert_equal(#harness.timers, 0)
        end)
    end),

    test.case("normal successful login admits one automatic refresh", function()
        local cached = { roster = { ranks = {}, members = { {} } } }
        withEventHarness({
            inProgress = false,
            activationResults = {
                {
                    identity = { key = "retail-guild" },
                    initialized = false,
                    database = cached,
                },
            },
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")
            harness.onEvent(nil, "PLAYER_GUILD_UPDATE")

            test.assert_true(harness.api.DB == cached)
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_equal(harness.calls.scanSources, { "automatic" })
            test.assert_equal(#harness.timers, 0)
            test.assert_nil(harness.roster.GetGuildIdentityReadiness())
        end)
    end),

    test.case("public automatic scan requests one scan after activation", function()
        withEventHarness({
            inProgress = false,
            activationResults = {
                {
                    identity = { key = "guild" },
                    initialized = false,
                    database = { roster = { ranks = {}, members = {} } },
                },
            },
        }, function(harness)
            test.assert_true(harness.roster.RequestAutomaticScan())
            test.assert_equal(harness.calls.activate, 1)
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_equal(harness.calls.scanSources, { "automatic" })
        end)
    end),

    test.case("disabled data still routes through scanner recovery guidance", function()
        withEventHarness({
            savedDataDisabled = true,
            inProgress = false,
            requestScan = function(_, scanner)
                scanner.inProgress = false
                return nil, "scanning-disabled"
            end,
        }, function(harness)
            local started, reason = harness.roster.RequestManualScan()
            test.assert_nil(started)
            test.assert_equal(reason, "scanning-disabled")

            harness.onEvent(nil, "PLAYER_LOGIN")
            test.assert_equal(harness.calls.activate, 0)
            test.assert_equal(harness.calls.requestScan, 2)
            test.assert_equal(
                harness.calls.scanSources,
                { "manual", "automatic" }
            )
            test.assert_nil(harness.roster.GetGuildIdentityReadiness())
            test.assert_equal(#harness.timers, 0)
        end)
    end),

    test.case("club member readiness binds cached data and starts one refresh", function()
        local cached = {
            roster = {
                ranks = {},
                members = { {} },
            },
        }
        withEventHarness({
            inProgress = false,
            activationResults = {
                {
                    error = "guild club is not initialized",
                    reason = "guild-identity-pending",
                },
                {
                    identity = { key = "guild" },
                    initialized = false,
                    database = cached,
                },
            },
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")
            harness.onEvent(nil, "CLUB_MEMBERS_UPDATED")

            test.assert_true(harness.api.DB == cached)
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_equal(harness.calls.scanSources, { "automatic" })
            test.assert_equal(harness.calls.capture, 1)
            test.assert_true(harness.timers[1].cancelled)
            test.assert_nil(harness.roster.GetGuildIdentityReadiness())

            harness.onEvent(nil, "CLUB_MEMBERS_UPDATED")
            harness.onEvent(nil, "INITIAL_CLUBS_LOADED")
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_equal(harness.calls.capture, 2)
            test.assert_equal(harness.calls.requestRoster, 1)
            test.assert_equal(#harness.timers, 1)
        end)
    end),

    test.case("initial clubs readiness starts the recovered refresh once", function()
        withEventHarness({
            inProgress = false,
            activationResults = {
                { reason = "guild-identity-pending" },
                {
                    identity = { key = "guild" },
                    initialized = false,
                    database = { roster = { ranks = {}, members = {} } },
                },
            },
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")
            harness.onEvent(nil, "INITIAL_CLUBS_LOADED")

            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_equal(harness.calls.scanSources, { "automatic" })
            test.assert_equal(harness.calls.requestRoster, 1)
            test.assert_true(harness.timers[1].cancelled)
        end)
    end),

    test.case("a global scan lock retains one silent startup refresh", function()
        local cached = { roster = { ranks = {}, members = { {} } } }
        withEventHarness({
            inProgress = false,
            scanLocked = true,
            activationResults = {
                {
                    identity = { key = "guild" },
                    initialized = false,
                    database = cached,
                },
            },
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")

            test.assert_true(harness.api.DB == cached)
            test.assert_equal(harness.calls.requestScan, 0)

            harness.setLocked(false)
            test.assert_true(harness.roster.OnGlobalScanLockReleased())
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_equal(harness.calls.scanSources, { "automatic" })
            test.assert_false(harness.roster.OnGlobalScanLockReleased())
            test.assert_equal(harness.calls.requestScan, 1)
        end)
    end),

    test.case("admitted request failure does not queue a second startup scan", function()
        withEventHarness({
            inProgress = false,
            activationResults = {
                {
                    identity = { key = "guild" },
                    initialized = false,
                    database = { roster = { ranks = {}, members = {} } },
                },
            },
            requestScan = function()
                return nil, "api-failure", true
            end,
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_false(harness.scanner:IsInProgress())

            test.assert_false(harness.roster.OnGlobalScanLockReleased())
            harness.onEvent(nil, "INITIAL_CLUBS_LOADED")
            test.assert_equal(harness.calls.requestScan, 1)
        end)
    end),

    test.case("identity retries are bounded and expose an actionable status", function()
        local original = { roster = { ranks = {}, members = {} } }
        withEventHarness({
            inProgress = false,
            database = original,
            activationResults = {
                { reason = "guild-identity-pending" },
            },
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")
            for index = 1, 5 do
                harness.fireTimer(index)
            end

            test.assert_equal(#harness.timers, 5)
            test.assert_equal(harness.timers[1].delay, 0.5)
            test.assert_equal(harness.timers[2].delay, 1)
            test.assert_equal(harness.timers[3].delay, 2)
            test.assert_equal(harness.timers[4].delay, 4)
            test.assert_equal(harness.timers[5].delay, 8)
            local readiness, message =
                harness.roster.GetGuildIdentityReadiness()
            test.assert_equal(readiness, "exhausted")
            test.assert_equal(
                message,
                "Guild data is still unavailable. Click Refresh to retry."
            )
            test.assert_true(harness.api.DB == original)
            test.assert_equal(harness.calls.requestScan, 0)
            test.assert_true(harness.calls.guildIdentityPending.actionable)
        end)
    end),

    test.case("a membership transition ignores a stale timer generation", function()
        withEventHarness({
            inProgress = false,
            activationResults = {
                { reason = "guild-identity-pending" },
                {},
            },
            requestScan = function()
                return nil, "not-in-guild"
            end,
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")
            harness.onEvent(nil, "PLAYER_GUILD_UPDATE")

            test.assert_equal(#harness.timers, 1)
            test.assert_true(harness.timers[1].cancelled)
            test.assert_equal(harness.calls.activate, 2)

            harness.fireTimer(1)
            test.assert_equal(harness.calls.activate, 2)
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_false(harness.scanner:IsInProgress())
        end)
    end),

    test.case("repeated pending readiness events do not stack timers", function()
        withEventHarness({
            inProgress = false,
            activationResults = {
                { reason = "guild-identity-pending" },
            },
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")
            harness.onEvent(nil, "PLAYER_GUILD_UPDATE")
            harness.onEvent(nil, "CLUB_MEMBERS_UPDATED")
            harness.onEvent(nil, "INITIAL_CLUBS_LOADED")

            test.assert_equal(#harness.timers, 1)
            test.assert_false(harness.timers[1].cancelled)
            test.assert_equal(harness.calls.requestScan, 0)
        end)
    end),

    test.case("late readiness event recovers after timer exhaustion", function()
        local results = {}
        for index = 1, 6 do
            results[index] = { reason = "guild-identity-pending" }
        end
        local cached = { roster = { ranks = {}, members = { {} } } }
        results[7] = {
            identity = { key = "guild" },
            initialized = false,
            database = cached,
        }

        withEventHarness({
            inProgress = false,
            activationResults = results,
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")
            for index = 1, 5 do
                harness.fireTimer(index)
            end
            test.assert_equal(
                harness.roster.GetGuildIdentityReadiness(),
                "exhausted"
            )

            harness.onEvent(nil, "CLUB_MEMBERS_UPDATED")
            test.assert_true(harness.api.DB == cached)
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_equal(harness.calls.scanSources, { "automatic" })
            test.assert_equal(#harness.timers, 5)
            test.assert_nil(harness.roster.GetGuildIdentityReadiness())

            harness.onEvent(nil, "INITIAL_CLUBS_LOADED")
            test.assert_equal(harness.calls.requestScan, 1)
        end)
    end),

    test.case("manual retry after exhaustion recovers through the same helper", function()
        local results = {}
        for index = 1, 6 do
            results[index] = { reason = "guild-identity-pending" }
        end
        local cached = { roster = { ranks = {}, members = { {} } } }
        results[7] = {
            identity = { key = "guild" },
            initialized = false,
            database = cached,
        }

        withEventHarness({
            inProgress = false,
            activationResults = results,
        }, function(harness)
            harness.onEvent(nil, "PLAYER_LOGIN")
            for index = 1, 5 do
                harness.fireTimer(index)
            end
            test.assert_equal(
                harness.roster.GetGuildIdentityReadiness(),
                "exhausted"
            )

            test.assert_true(harness.roster.RequestManualScan())
            test.assert_true(harness.api.DB == cached)
            test.assert_equal(harness.calls.requestScan, 1)
            test.assert_equal(harness.calls.scanSources, { "automatic" })
            test.assert_nil(harness.roster.GetGuildIdentityReadiness())
        end)
    end),

    test.case("an in-progress guild update re-reads without starting another scan", function()
        withEventHarness(function(harness)
            test.assert_true(type(harness.onEvent) == "function")

            harness.onEvent(nil, "PLAYER_GUILD_UPDATE")

            test.assert_equal(harness.calls.activate, 1)
            test.assert_equal(harness.calls.capture, 1)
            test.assert_equal(harness.calls.requestRoster, 0)
            test.assert_equal(harness.calls.requestScan, 0)
        end)
    end),

    test.case("roster events use only the approved retry triggers", function()
        withEventHarness(function(harness)
            for _, event in ipairs({
                "GUILD_ROSTER_UPDATE",
                "INITIAL_CLUBS_LOADED",
                "CLUB_MEMBERS_UPDATED",
                "PLAYER_GUILD_UPDATE",
            }) do
                test.assert_true(harness.registeredEvents[event] == true)
            end
            test.assert_nil(harness.registeredEvents.CLUB_MEMBER_UPDATED)
            test.assert_nil(harness.registeredEvents.CLUB_MEMBER_PRESENCE_UPDATED)

            harness.onEvent(nil, "GUILD_ROSTER_UPDATE", false)
            harness.onEvent(nil, "INITIAL_CLUBS_LOADED")
            harness.onEvent(nil, "CLUB_MEMBERS_UPDATED")
            harness.onEvent(nil, "PLAYER_GUILD_UPDATE")

            test.assert_equal(harness.calls.capture, 3)
            test.assert_equal(harness.calls.requestRoster, 1)
            test.assert_equal(harness.calls.requestScan, 0)
        end)
    end),

    test.case("roster status renders its committed report and independent timestamp", function()
        local projected = { ranks = { { index = 1 } } }
        local dataset = {
            scannedAt = { unixSeconds = 100 },
            ranks = {},
            members = {
                { isMissing = false },
                { isMissing = true },
                {},
            },
        }
        local harness = newHarness({
            database = { roster = dataset },
            rosterReport = {
                build = function(value)
                    test.assert_true(value == dataset)
                    return projected
                end,
            },
            dateTime = {
                formatPacificTimestamp = function(unixSeconds)
                    test.assert_equal(unixSeconds, 100)
                    return "2024-06-01 05:34 PT"
                end,
            },
        })

        harness.roster.RefreshStatus()

        test.assert_equal(harness.actions, {
            { action = "available", value = true },
            { action = "report", report = projected },
            {
                action = "status",
                tabId = "roster",
                status = "2 roster characters",
            },
        })
        harness.restore()
    end),

    test.case("roster status keeps its timestamp visible while updating", function()
        local harness = newHarness({
            inProgress = true,
            database = {
                roster = {
                    scannedAt = { unixSeconds = 100 },
                    ranks = {},
                    members = {},
                },
            },
            rosterReport = {
                build = function()
                    return { ranks = {} }
                end,
            },
            dateTime = {
                formatPacificTimestamp = function()
                    return "2024-06-01 05:34 PT"
                end,
            },
        })

        harness.roster.RefreshStatus()

        test.assert_equal(harness.actions[#harness.actions], {
            action = "status",
            tabId = "roster",
            status = "Updating... Last successful update: 2024-06-01 05:34 PT",
        })
        harness.restore()
    end),

    test.case("fresh and unguilded roster states are explicit", function()
        local harness = newHarness({
            inGuild = false,
            database = {
                roster = {
                    ranks = {},
                    members = {},
                },
            },
            rosterReport = {
                build = function()
                    return { ranks = {} }
                end,
            },
            dateTime = {},
        })

        harness.roster.RefreshStatus()

        test.assert_equal(harness.actions[1], {
            action = "available",
            value = false,
        })
        test.assert_equal(harness.actions[#harness.actions], {
            action = "status",
            tabId = "roster",
            status = "Not in a guild. No roster data yet",
        })
        harness.restore()
    end),

    test.case("report projection failures do not replace prior content", function()
        local harness = newHarness({
            database = {
                roster = {
                    ranks = {},
                    members = {},
                },
            },
            rosterReport = {
                build = function()
                    return nil, "simulated projection failure"
                end,
            },
            dateTime = {},
        })

        harness.roster.RefreshStatus()

        test.assert_equal(harness.actions, {
            { action = "available", value = true },
            {
                action = "status",
                tabId = "roster",
                status = "Roster report unavailable: simulated projection failure",
            },
        })
        harness.restore()
    end),
}
