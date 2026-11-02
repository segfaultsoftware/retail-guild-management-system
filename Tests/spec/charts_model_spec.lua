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

local function bankSnapshot(dayOffset, money, tabs, slots, secondsOffset)
    return {
        scannedAt = timestamp(dayOffset, secondsOffset),
        money = money,
        tabs = tabs or {},
        slots = slots or {},
    }
end

local function slot(itemId, quantity, overrides)
    local value = {
        tabIndex = 1,
        slotIndex = itemId,
        itemId = itemId,
        itemLink = "|cff1eff00|Hitem:" .. itemId .. "|h[Item " .. itemId .. "]|h|r",
        quantity = quantity,
        icon = 9000 + itemId,
    }
    for key, item in pairs(overrides or {}) do
        value[key] = item
    end
    return value
end

local function point(date, value)
    return { date = date, value = value }
end

return {
    test.case("bank history aggregates accessible slots and replaces complete Pacific days", function()
        local first = assert(charts.recordBank(
            charts.newHistory(),
            bankSnapshot(0, 100, {
                { index = 1, isViewable = true },
                { index = 2, isViewable = false },
            }, {
                slot(10, 2, {
                    slotIndex = 2,
                    itemLink = "|Hitem:10|h[Silver Ore|A:Professions-ChatIcon-Quality-Tier1:17:15::1|a]|h",
                    craftingQuality = 1,
                    icon = 222,
                }),
                slot(10, 3, {
                    slotIndex = 1,
                    itemLink = "|Hitem:10|h[Silver Ore]|h",
                    craftingQuality = 1,
                    icon = 0,
                }),
                slot(20, 9, { tabIndex = 2 }),
            })
        ))

        test.assert_equal(first.gold, { point("2024-06-01", 100) })
        test.assert_equal(#first.items, 1)
        test.assert_equal(first.items[1].itemId, 10)
        test.assert_equal(first.items[1].name, "Silver Ore")
        test.assert_equal(first.items[1].icon, 222)
        test.assert_equal(first.items[1].points, { point("2024-06-01", 5) })

        local replaced = assert(charts.recordBank(
            first,
            bankSnapshot(0, 250, {
                { index = 1, isViewable = true },
                { index = 2, isViewable = false },
            }, {
                slot(30, 4, { itemLink = "|Hitem:30|h[New Item]|h" }),
                slot(20, 99, { tabIndex = 2 }),
            }, 3600)
        ))

        test.assert_equal(replaced.gold, { point("2024-06-01", 250) })
        test.assert_equal(#replaced.items, 1)
        test.assert_equal(replaced.items[1].itemId, 30)
        test.assert_equal(replaced.items[1].points, { point("2024-06-01", 4) })
        test.assert_equal(first.items[1].points, { point("2024-06-01", 5) })
    end),

    test.case("item metadata updates while vanished series remain until their final point expires", function()
        local history = assert(charts.recordBank(
            charts.newHistory(),
            bankSnapshot(0, 0, { { index = 1, isViewable = true } }, {
                slot(10, 2, { itemLink = "|Hitem:10|h[Old Name]|h", icon = 100 }),
            })
        ))
        history = assert(charts.recordBank(
            history,
            bankSnapshot(1, 0, { { index = 1, isViewable = true } }, {
                slot(10, 3, {
                    itemLink = "|Hitem:10|h[New Name]|h",
                    icon = 200,
                    craftingQuality = 2,
                }),
            })
        ))
        history = assert(charts.recordBank(
            history,
            bankSnapshot(2, 0, { { index = 1, isViewable = true } }, {})
        ))

        test.assert_equal(#history.items, 1)
        test.assert_equal(history.items[1].name, "New Name")
        test.assert_equal(history.items[1].icon, 200)
        test.assert_equal(history.items[1].craftingQuality, 2)
        test.assert_equal(#history.items[1].points, 2)

        local pruned = assert(charts.prune(history, "2024-11-29"))
        test.assert_equal(pruned.items, {})
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

    test.case("item selectors sort label duplicates stay distinct and recover expired choices", function()
        local history = charts.newHistory()
        history.items = {
            { itemId = 30, name = "zeta", icon = 30, points = { point("2024-06-01", 1) } },
            { itemId = 20, name = "Alpha", icon = 20, craftingQuality = 2, points = { point("2024-06-01", 1) } },
            { itemId = 10, name = "alpha", icon = 10, craftingQuality = 1, points = { point("2024-06-01", 1) } },
            { itemId = 21, name = "Alpha", icon = 21, craftingQuality = 2, points = { point("2024-06-01", 1) } },
        }
        local selections, options = charts.reconcileSelections(history, nil)
        test.assert_equal(selections, { 10, 20, 21 })
        test.assert_equal(options[2].label, "Alpha (Item ID 20)")
        test.assert_equal(options[3].label, "Alpha (Item ID 21)")
        local duplicate, duplicateError = charts.selectItem(history, selections, 1, 20)
        test.assert_nil(duplicate)
        test.assert_equal(duplicateError, "item selectors must contain different items")

        table.remove(history.items, 2)
        local recovered = charts.reconcileSelections(history, selections)
        test.assert_equal(recovered, { 10, 30, 21 })

        history.items = { history.items[1] }
        local sparse = charts.reconcileSelections(history, nil)
        test.assert_equal(sparse[1], 30)
        test.assert_nil(sparse[2])
        test.assert_nil(sparse[3])
    end),

    test.case("plot math fixes and pads the date domain scales values and clips regression", function()
        local history = charts.newHistory()
        history.gold = {
            point("2024-01-01", 999),
            point("2024-01-03", 0),
            point("2024-04-02", 90),
            point("2024-06-30", 179),
        }
        local plot = assert(charts.buildPlot(history, "gold", "2024-06-30", 189, 104))
        test.assert_equal(plot.firstDate, "2024-01-03")
        test.assert_equal(plot.lastDate, "2024-06-30")
        test.assert_equal(#plot.series[1].plotPoints, 3)
        test.assert_equal(plot.maximum, 179)
        test.assert_equal(plot.dotSize, 7)
        test.assert_equal(plot.horizontalPadding, 8.5)
        test.assert_equal(plot.verticalPadding, 5.5)
        test.assert_equal(plot.series[1].plotPoints[1].x, 8.5)
        test.assert_equal(
            plot.series[1].plotPoints[2].x,
            8.5 + 172 * 90 / 179
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
        test.assert_equal(#plot.monthBoundaries, 5)
        test.assert_equal(plot.monthBoundaries[1], {
            date = "2024-02-01",
            x = 8.5 + 172 * 29 / 179,
        })
        test.assert_equal(plot.monthBoundaries[5], {
            date = "2024-06-01",
            x = 8.5 + 172 * 150 / 179,
        })
        test.assert_true(plot.series[1].regression ~= nil)
        test.assert_equal(plot.series[1].regression.x1, 8.5)
        test.assert_equal(plot.series[1].regression.x2, 180.5)

        local singleHistory = charts.newHistory()
        singleHistory.gold = { point("2024-06-30", 7) }
        local singlePlot = assert(charts.buildPlot(
            singleHistory,
            "gold",
            "2024-06-30",
            189,
            104
        ))
        test.assert_equal(singlePlot.firstDate, "2024-01-03")
        test.assert_equal(singlePlot.lastDate, "2024-06-30")
        test.assert_equal(singlePlot.series[1].plotPoints[1].x, 180.5)

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
        local item = assert(charts.tooltip("items", {
            seriesName = "Flask", date = "2024-06-01", value = 4,
            icon = 123, craftingQuality = 2,
        }))
        test.assert_equal(item.icon, 123)
        test.assert_equal(item.craftingQuality, 2)
        local gold = assert(charts.tooltip("gold", {
            date = "2024-06-01", value = 12345,
        }))
        test.assert_equal(gold.money, 12345)
    end),
}
