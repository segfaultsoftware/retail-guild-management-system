local test = require("Tests.lib.runner")

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
