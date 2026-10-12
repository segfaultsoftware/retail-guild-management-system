local dateFixtures = require("Tests.date_fixtures")
local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local state = require("Bank.State")
local test = require("Tests.lib.runner")

local STARTED_AT = dateFixtures.pacificMidnight.after

local function tab(index, isViewable, overrides)
    overrides = overrides or {}
    overrides.index = index
    overrides.isViewable = isViewable
    overrides.name = overrides.name or ("Tab " .. index)
    return fixtures.bank_tab(overrides)
end

local function slot(tabIndex, slotIndex, itemId, quantity, observedAt)
    local value = fixtures.bank_slot({
        tabIndex = tabIndex,
        slotIndex = slotIndex,
        itemId = itemId,
        itemLink = "|Hitem:" .. itemId .. "|h[Test Item]|h",
        quantity = quantity,
        observedAt = observedAt,
    })
    value.stableSinceDate = nil
    return value
end

local function snapshot(day, tabs, slots, guild)
    local scannedAt = assert(dateTime.utcTimestamp(STARTED_AT + day * 24 * 60 * 60))
    for _, observedSlot in ipairs(slots) do
        observedSlot.observedAt = scannedAt
    end
    return {
        guild = guild or fixtures.guild_identity(),
        scannedAt = scannedAt,
        tabs = tabs,
        slots = slots,
    }
end

local function emptyDataset()
    return {
        tabs = {},
        slots = {},
    }
end

local function reduce(previous, completedSnapshot)
    local result, reduceError = state.reduce(previous, completedSnapshot, dateTime)
    test.assert_not_nil(result, reduceError)
    return result
end

local function expectedSlot(observedSlot, stableSinceDate)
    return {
        tabIndex = observedSlot.tabIndex,
        slotIndex = observedSlot.slotIndex,
        itemId = observedSlot.itemId,
        itemLink = observedSlot.itemLink,
        icon = observedSlot.icon,
        quantity = observedSlot.quantity,
        isLocked = observedSlot.isLocked,
        observedAt = observedSlot.observedAt,
        stableSinceDate = stableSinceDate,
    }
end

return {
    test.case("multi-scan slot changes reset only the affected numeric location", function()
        local firstSnapshot = snapshot(0, { tab(1, true) }, {
            slot(1, 1, 100, 5),
            slot(1, 2, 100, 5),
        })
        local first = reduce(emptyDataset(), firstSnapshot)
        test.assert_equal(first.tabs[1].lastAccessibleAt, firstSnapshot.scannedAt)
        test.assert_equal(first.slots, {
            expectedSlot(firstSnapshot.slots[1], "2024-06-01"),
            expectedSlot(firstSnapshot.slots[2], "2024-06-01"),
        })
        test.assert_equal(state.daysSince(
            first.slots[1].stableSinceDate,
            "2024-06-01",
            dateTime
        ), 0)

        local unchangedSnapshot = snapshot(2, { tab(1, true) }, {
            slot(1, 1, 100, 5),
            slot(1, 2, 100, 5),
        })
        local unchanged = reduce(first, unchangedSnapshot)
        test.assert_equal(unchanged.slots, {
            expectedSlot(unchangedSnapshot.slots[1], "2024-06-01"),
            expectedSlot(unchangedSnapshot.slots[2], "2024-06-01"),
        })
        test.assert_equal(state.daysSince(
            unchanged.slots[1].stableSinceDate,
            "2024-06-03",
            dateTime
        ), 2)

        local changedSnapshot = snapshot(3, { tab(1, true) }, {
            slot(1, 1, 100, 8),
            slot(1, 2, 200, 5),
        })
        local changed = reduce(unchanged, changedSnapshot)
        test.assert_equal(changed.slots, {
            expectedSlot(changedSnapshot.slots[1], "2024-06-04"),
            expectedSlot(changedSnapshot.slots[2], "2024-06-04"),
        })

        local decreasedSnapshot = snapshot(4, { tab(1, true) }, {
            slot(1, 1, 100, 2),
            slot(1, 2, 200, 5),
        })
        local decreased = reduce(changed, decreasedSnapshot)
        test.assert_equal(decreased.slots, {
            expectedSlot(decreasedSnapshot.slots[1], "2024-06-05"),
            expectedSlot(decreasedSnapshot.slots[2], "2024-06-04"),
        })
    end),

    test.case("empty, refill, and movement start new destination state", function()
        local firstSnapshot = snapshot(0, { tab(1, true) }, {
            slot(1, 1, 300, 4),
        })
        local first = reduce(emptyDataset(), firstSnapshot)

        local emptied = reduce(first, snapshot(1, { tab(1, true) }, {}))
        test.assert_equal(emptied.slots, {})

        local refillSnapshot = snapshot(2, { tab(1, true) }, {
            slot(1, 1, 300, 4),
        })
        local refilled = reduce(emptied, refillSnapshot)
        test.assert_equal(refilled.slots, {
            expectedSlot(refillSnapshot.slots[1], "2024-06-03"),
        })

        local movedSnapshot = snapshot(3, { tab(1, true) }, {
            slot(1, 9, 300, 4),
        })
        local moved = reduce(refilled, movedSnapshot)
        test.assert_equal(moved.slots, {
            expectedSlot(movedSnapshot.slots[1], "2024-06-04"),
        })
    end),

    test.case("inaccessible periods retain slots and compare on restored access", function()
        local firstSnapshot = snapshot(0, { tab(1, true, {
            name = "Materials",
            icon = 1000,
        }) }, {
            slot(1, 4, 400, 12),
        })
        local first = reduce(emptyDataset(), firstSnapshot)

        local hiddenSnapshot = snapshot(2, { tab(1, false, {
            name = "Hidden Materials",
            icon = 2000,
        }) }, {})
        local hidden = reduce(first, hiddenSnapshot)
        test.assert_false(hidden.tabs[1].isViewable)
        test.assert_equal(hidden.tabs[1].name, "Hidden Materials")
        test.assert_equal(hidden.tabs[1].icon, 2000)
        test.assert_equal(hidden.tabs[1].lastAccessibleAt, firstSnapshot.scannedAt)
        test.assert_equal(hidden.slots, first.slots)

        local restoredSnapshot = snapshot(4, { tab(1, true, {
            name = "Restored Materials",
            icon = 3000,
        }) }, {
            slot(1, 4, 400, 12),
        })
        local restored = reduce(hidden, restoredSnapshot)
        test.assert_true(restored.tabs[1].isViewable)
        test.assert_equal(restored.tabs[1].name, "Restored Materials")
        test.assert_equal(
            restored.tabs[1].lastAccessibleAt,
            restoredSnapshot.scannedAt
        )
        test.assert_equal(restored.slots, {
            expectedSlot(restoredSnapshot.slots[1], "2024-06-01"),
        })
        test.assert_equal(state.daysSince(
            restored.slots[1].stableSinceDate,
            "2024-06-05",
            dateTime
        ), 4)
    end),

    test.case("empty accessible tabs retain their access timestamp while hidden", function()
        local firstSnapshot = snapshot(0, { tab(1, true) }, {})
        local first = reduce(emptyDataset(), firstSnapshot)
        test.assert_equal(first.tabs[1].lastAccessibleAt, firstSnapshot.scannedAt)

        local hidden = reduce(first, snapshot(3, { tab(1, false) }, {}))
        test.assert_equal(hidden.tabs[1].lastAccessibleAt, firstSnapshot.scannedAt)
        test.assert_equal(hidden.slots, {})
    end),

    test.case("restored access resets state only when contents differ", function()
        local first = reduce(emptyDataset(), snapshot(0, { tab(1, true) }, {
            slot(1, 1, 500, 10),
        }))
        local hidden = reduce(first, snapshot(1, { tab(1, false) }, {}))
        local changedSnapshot = snapshot(3, { tab(1, true) }, {
            slot(1, 1, 500, 11),
        })
        local restored = reduce(hidden, changedSnapshot)

        test.assert_equal(restored.slots, {
            expectedSlot(changedSnapshot.slots[1], "2024-06-04"),
        })
    end),

    test.case("age uses Pacific calendar days and never becomes negative", function()
        test.assert_equal(
            state.daysSince("2024-06-01", "2024-06-04", dateTime),
            3
        )
        test.assert_equal(
            state.daysSince("2024-06-02", "2024-06-01", dateTime),
            0
        )

        local days, dateError = state.daysSince(
            "not-a-date",
            "2024-06-01",
            dateTime
        )
        test.assert_nil(days)
        test.assert_matches(dateError, "invalid earlier date")
    end),

    test.case("the reducer is deterministic and does not mutate its inputs", function()
        local completedSnapshot = snapshot(1, { tab(1, true) }, {
            slot(1, 2, 600, 1),
        })
        local previous = emptyDataset()
        local first = reduce(previous, completedSnapshot)
        local second = reduce(previous, completedSnapshot)

        test.assert_equal(first, second)
        test.assert_equal(previous.slots, {})
        test.assert_nil(completedSnapshot.slots[1].stableSinceDate)
    end),
}
