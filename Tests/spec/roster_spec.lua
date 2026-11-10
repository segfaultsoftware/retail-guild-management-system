local test = require("Tests.lib.runner")

local EVENT_GLOBAL_NAMES = {
    "C_Club",
    "C_GuildInfo",
    "CreateFrame",
}

local function withEventHarness(callback)
    local previous = {}
    for _, name in ipairs(EVENT_GLOBAL_NAMES) do
        previous[name] = _G[name]
    end

    local calls = {
        activate = 0,
        capture = 0,
        requestScan = 0,
        requestRoster = 0,
    }
    local registeredEvents = {}
    local scripts = {}
    local scanner = {}

    function scanner:IsInProgress()
        return true
    end

    function scanner:OnDataUpdated()
        calls.capture = calls.capture + 1
    end

    function scanner:Request()
        calls.requestScan = calls.requestScan + 1
    end

    function scanner:RequestRosterUpdate()
        calls.requestRoster = calls.requestRoster + 1
    end

    function scanner:Update()
    end

    C_Club = {}
    C_GuildInfo = {}
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

    local fakeRGMS = {
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
            return { key = "guild" }, true
        end,
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
