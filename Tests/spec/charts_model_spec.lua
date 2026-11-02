local charts = require("Charts.Model")
local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local test = require("Tests.lib.runner")

local DAY = 24 * 60 * 60

local function timestamp(dayOffset, secondsOffset)
    return assert(dateTime.utcTimestamp(
        fixtures.timestamp().unixSeconds
            + (dayOffset or 0) * DAY
            + (secondsOffset or 0)
    ))
end

local function bankSnapshot(dayOffset, money, secondsOffset)
    return {
        scannedAt = timestamp(dayOffset, secondsOffset),
        money = money,
        tabs = { { index = 1, isViewable = true } },
        slots = { { tabIndex = 1, slotIndex = 1, itemId = 10, quantity = 2 } },
    }
end

local function point(date, value)
    return { date = date, value = value }
end

return {
    test.case("bank history records only gold and replaces Pacific days", function()
        local first = assert(charts.recordBank(
            charts.newHistory(),
            bankSnapshot(0, 100)
        ))

        test.assert_equal(first.gold, { point("2024-06-01", 100) })
        test.assert_equal(first, {
            gold = { point("2024-06-01", 100) },
            members = {},
        })

        local replaced = assert(charts.recordBank(
            first,
            bankSnapshot(0, 250, 3600)
        ))

        test.assert_equal(replaced.gold, { point("2024-06-01", 250) })
        test.assert_equal(
            assert(charts.goldStatistics(replaced, "2024-06-01")),
            {
                totalScans = 1,
                maximum = 250,
                minimum = 250,
            }
        )
    end),

    test.case("gold statistics handle empty single and standard money values", function()
        test.assert_equal(
            assert(charts.goldStatistics(charts.newHistory(), "2024-06-30")),
            { totalScans = 0 }
        )

        local history = charts.newHistory()
        history.gold = { point("2024-06-30", 123456789) }
        test.assert_equal(
            assert(charts.goldStatistics(history, "2024-06-30")),
            {
                totalScans = 1,
                maximum = 123456789,
                minimum = 123456789,
            }
        )
    end),

    test.case("gold statistics retain at most 180 Pacific-date observations", function()
        local history = charts.newHistory()
        local firstDay = assert(dateTime.calendarDayNumber("2024-01-02"))
        for offset = 0, 180 do
            history.gold[#history.gold + 1] = point(
                dateTime.dateFromCalendarDayNumber(firstDay + offset),
                1000 + offset
            )
        end

        test.assert_equal(
            assert(charts.goldStatistics(history, "2024-06-30")),
            {
                totalScans = 180,
                maximum = 1180,
                minimum = 1001,
                averageWeeklyBurn = 7,
                direction = "up",
            }
        )
    end),

    test.case("gold statistics calculate extrema rounded burn and direction", function()
        local growth = charts.newHistory()
        growth.gold = {
            point("2024-06-01", 100),
            point("2024-06-08", 500),
            point("2024-06-15", 101),
        }
        test.assert_equal(
            assert(charts.goldStatistics(growth, "2024-06-15")),
            {
                totalScans = 3,
                maximum = 500,
                minimum = 100,
                averageWeeklyBurn = 1,
                direction = "up",
            }
        )

        local decline = charts.newHistory()
        decline.gold = {
            point("2024-06-01", 100),
            point("2024-06-04", 98),
        }
        test.assert_equal(
            assert(charts.goldStatistics(decline, "2024-06-04")),
            {
                totalScans = 2,
                maximum = 100,
                minimum = 98,
                averageWeeklyBurn = 5,
                direction = "down",
            }
        )

        local unchanged = charts.newHistory()
        unchanged.gold = {
            point("2024-06-01", 100),
            point("2024-06-02", 25),
            point("2024-06-03", 100),
        }
        test.assert_equal(
            assert(charts.goldStatistics(unchanged, "2024-06-03")),
            {
                totalScans = 3,
                maximum = 100,
                minimum = 25,
                averageWeeklyBurn = 0,
            }
        )

        local roundedToZero = charts.newHistory()
        roundedToZero.gold = {
            point("2024-06-01", 100),
            point("2024-06-30", 101),
        }
        test.assert_equal(
            assert(charts.goldStatistics(roundedToZero, "2024-06-30")),
            {
                totalScans = 2,
                maximum = 101,
                minimum = 100,
                averageWeeklyBurn = 0,
                direction = "up",
            }
        )
    end),

    test.case("roster history counts raw non-GM ranks including configured zeroes and continuity", function()
        local firstSnapshot = {
            scannedAt = timestamp(0),
            ranks = {
                { index = 1, name = "Guild Master" },
                { index = 2, name = "Officer" },
                { index = 3, name = "Member" },
            },
            members = {
                { rankIndex = 1 },
                { rankIndex = 2 },
                { rankIndex = 2 },
            },
        }
        local history = assert(charts.recordRoster(charts.newHistory(), firstSnapshot))
        test.assert_equal(#history.members, 2)
        test.assert_equal(history.members[1], {
            rankIndex = 2,
            name = "Officer",
            points = { point("2024-06-01", 2) },
        })
        test.assert_equal(history.members[2].points, { point("2024-06-01", 0) })

        local secondSnapshot = {
            scannedAt = timestamp(1),
            ranks = {
                { index = 1, name = "Guild Master" },
                { index = 2, name = "Veteran" },
            },
            members = { { rankIndex = 2 } },
        }
        history = assert(charts.recordRoster(history, secondSnapshot))
        test.assert_equal(history.members[1].name, "Veteran")
        test.assert_equal(history.members[1].points[2], point("2024-06-02", 1))
        test.assert_equal(history.members[2].name, "Member")
        test.assert_equal(#history.members[2].points, 1)
    end),

    test.case("plot math fits the displayed date domain scales values and clips regression", function()
        local history = charts.newHistory()
        history.gold = {
            point("2024-01-01", 999),
            point("2024-04-03", 0),
            point("2024-05-03", 90),
            point("2024-06-02", 180),
        }
        local plot = assert(charts.buildPlot(history, "gold", "2024-06-30", 189, 104))
        test.assert_equal(plot.firstDate, "2024-04-03")
        test.assert_equal(plot.lastDate, "2024-06-02")
        test.assert_equal(#plot.series[1].plotPoints, 3)
        test.assert_equal(plot.maximum, 180)
        test.assert_equal(plot.dotSize, 7)
        test.assert_equal(plot.horizontalPadding, 8.5)
        test.assert_equal(plot.verticalPadding, 5.5)
        test.assert_equal(plot.series[1].plotPoints[1].x, 8.5)
        test.assert_equal(
            plot.series[1].plotPoints[2].x,
            8.5 + 172 * 30 / 60
        )
        test.assert_equal(plot.series[1].plotPoints[3].x, 180.5)
        test.assert_equal(plot.series[1].plotPoints[1].y, 5.5)
        test.assert_equal(plot.series[1].plotPoints[3].y, 98.5)
        test.assert_equal(
            plot.series[1].plotPoints[1].x - plot.dotSize / 2,
            5
        )
        test.assert_equal(
            plot.width - plot.series[1].plotPoints[3].x - plot.dotSize / 2,
            5
        )
        test.assert_equal(
            plot.series[1].plotPoints[1].y - plot.dotSize / 2,
            2
        )
        test.assert_equal(
            plot.height - plot.series[1].plotPoints[3].y - plot.dotSize / 2,
            2
        )
        test.assert_equal(#plot.monthBoundaries, 2)
        test.assert_equal(plot.monthBoundaries[1], {
            date = "2024-05-01",
            x = 8.5 + 172 * 28 / 60,
        })
        test.assert_equal(plot.monthBoundaries[2], {
            date = "2024-06-01",
            x = 8.5 + 172 * 59 / 60,
        })
        test.assert_true(plot.series[1].regression ~= nil)
        test.assert_equal(plot.series[1].regression.x1, 8.5)
        test.assert_equal(plot.series[1].regression.x2, 180.5)

        local singleHistory = charts.newHistory()
        singleHistory.gold = { point("2024-06-15", 7) }
        local singlePlot = assert(charts.buildPlot(
            singleHistory,
            "gold",
            "2024-06-30",
            189,
            104
        ))
        test.assert_equal(singlePlot.firstDate, "2024-06-15")
        test.assert_equal(singlePlot.lastDate, "2024-06-15")
        test.assert_equal(singlePlot.series[1].plotPoints[1].x, 94.5)

        local emptyPlot = assert(charts.buildPlot(
            charts.newHistory(),
            "gold",
            "2024-06-30",
            189,
            104
        ))
        test.assert_equal(emptyPlot.firstDate, "2024-06-30")
        test.assert_equal(emptyPlot.lastDate, "2024-06-30")
        test.assert_equal(emptyPlot.points, {})

        local zeroHistory = charts.newHistory()
        zeroHistory.gold = {
            point("2024-06-29", 0),
            point("2024-06-30", 0),
        }
        local zeroPlot = assert(charts.buildPlot(
            zeroHistory,
            "gold",
            "2024-06-30",
            189,
            104
        ))
        test.assert_equal(zeroPlot.maximum, 0)
        test.assert_equal(zeroPlot.series[1].plotPoints[1].y, 5.5)
        test.assert_equal(zeroPlot.series[1].plotPoints[2].y, 5.5)
        test.assert_equal(zeroPlot.series[1].regression.y1, 5.5)
        test.assert_equal(zeroPlot.series[1].regression.y2, 5.5)
    end),

    test.case("regression hover ties and tooltip content are deterministic", function()
        local regression = assert(charts.linearRegression({
            { dayNumber = 100, value = 3 },
            { dayNumber = 102, value = 7 },
            { dayNumber = 104, value = 11 },
        }))
        test.assert_equal(regression.slope, 2)
        test.assert_equal(regression.intercept, 3)

        local first = { x = 0, y = 0, seriesName = "First", date = "2024-06-01", value = 2 }
        local second = { x = 2, y = 0, seriesName = "Second", date = "2024-06-01", value = 2 }
        test.assert_true(charts.nearestPoint({ first, second }, 1, 0) == first)
        test.assert_equal(charts.tooltip("members", first), {
            kind = "members",
            title = "First",
            date = "01 June 2024",
            valueText = "2 members",
        })
        local gold = assert(charts.tooltip("gold", {
            date = "2024-06-01", value = 12345,
        }))
        test.assert_equal(gold.money, 12345)
    end),
}
