local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local report = require("Bank.Report")
local test = require("Tests.lib.runner")

local CURRENT_DATE = "2024-06-22"

local function tab(index, name, isViewable, overrides)
    overrides = overrides or {}
    overrides.index = index
    overrides.name = name
    overrides.isViewable = isViewable
    return fixtures.bank_tab(overrides)
end

local function slot(tabIndex, slotIndex, name, stableSinceDate, overrides)
    overrides = overrides or {}
    overrides.tabIndex = tabIndex
    overrides.slotIndex = slotIndex
    overrides.itemId = overrides.itemId or (190000 + tabIndex * 100 + slotIndex)
    overrides.itemLink = string.format(
        "|Hitem:%d::::::::80:::::|h[%s]|h",
        overrides.itemId,
        name
    )
    overrides.stableSinceDate = stableSinceDate
    return fixtures.bank_slot(overrides)
end

return {
    test.case("zero and empty tabs project without synthetic rows", function()
        test.assert_equal(
            assert(report.build({ tabs = {}, slots = {} }, CURRENT_DATE, dateTime)),
            { tabs = {} }
        )

        local rendered = assert(report.build({
            tabs = { tab(1, "Empty", true) },
            slots = {},
        }, CURRENT_DATE, dateTime))
        test.assert_equal(#rendered.tabs, 1)
        test.assert_equal(rendered.tabs[1].name, "Empty")
        test.assert_equal(rendered.tabs[1].rows, {})
        test.assert_equal(
            rendered.tabs[1].lastAccessibleText,
            "2024-06-01 05:34 PT"
        )
    end),

    test.case("mixed access hides retained rows and represents never-accessible tabs", function()
        local dataset = {
            tabs = {
                tab(3, "Never", false),
                tab(1, "Visible", true),
                tab(2, "Restricted", false),
            },
            slots = {
                slot(1, 1, "Visible Item", "2024-06-10"),
                slot(2, 1, "Retained Item", "2024-05-01"),
            },
        }
        dataset.tabs[1].lastAccessibleAt = nil
        local rendered = assert(report.build(dataset, CURRENT_DATE, dateTime))

        test.assert_equal(rendered.tabs[1].name, "Visible")
        test.assert_equal(rendered.tabs[2].name, "Restricted")
        test.assert_equal(rendered.tabs[3].name, "Never")
        test.assert_equal(#rendered.tabs[1].rows, 1)
        test.assert_equal(rendered.tabs[2].rows, {})
        test.assert_equal(rendered.tabs[3].rows, {})
        test.assert_false(rendered.tabs[2].isViewable)
        test.assert_nil(rendered.tabs[3].lastAccessibleText)
    end),

    test.case("restored and renamed tabs expose every field and age boundaries", function()
        local dataset = {
            tabs = { tab(1, "Renamed Supplies", true) },
            slots = {
                slot(1, 2, "Twenty Days", "2024-06-02", { quantity = 4 }),
                slot(1, 1, "Twenty One Days", "2024-06-01", { quantity = 12 }),
            },
        }
        local rendered = assert(report.build(dataset, CURRENT_DATE, dateTime))
        local rows = rendered.tabs[1].rows

        test.assert_equal(rows[1].itemName, "Twenty One Days")
        test.assert_equal(rows[1].tabName, "Renamed Supplies")
        test.assert_equal(rows[1].slotIndex, 1)
        test.assert_equal(rows[1].quantity, 12)
        test.assert_equal(rows[1].stableSinceDate, "2024-06-01")
        test.assert_equal(rows[1].ageDays, 21)
        test.assert_true(rows[1].isStale)
        test.assert_equal(rows[2].ageDays, 20)
        test.assert_false(rows[2].isStale)
        test.assert_matches(rows[1].itemLink, "Twenty One Days")
        test.assert_equal(rows[1].icon, fixtures.bank_slot().icon)
    end),

    test.case("equal ages sort by numeric location and rendering is observation-safe", function()
        local dataset = {
            tabs = {
                tab(2, "Second", true),
                tab(1, "First", true),
            },
            slots = {
                slot(2, 1, "Beta", "2024-06-01"),
                slot(1, 2, "Zulu", "2024-06-01"),
                slot(1, 1, "Alpha", "2024-06-01"),
            },
        }
        local beforeLink = dataset.slots[1].itemLink
        local rendered = assert(report.build(dataset, CURRENT_DATE, dateTime))

        test.assert_equal(rendered.tabs[1].rows[1].itemName, "Alpha")
        test.assert_equal(rendered.tabs[1].rows[2].itemName, "Zulu")
        test.assert_equal(rendered.tabs[2].rows[1].itemName, "Beta")
        test.assert_equal(dataset.tabs[1].index, 2)
        test.assert_equal(dataset.slots[1].itemLink, beforeLink)
        test.assert_nil(dataset.slots[1].ageDays)
    end),

    test.case("large inventories retain all occupied rows", function()
        local dataset = {
            tabs = { tab(1, "Warehouse", true) },
            slots = {},
        }
        for index = 1, 98 do
            dataset.slots[index] = slot(
                1,
                index,
                string.format("Item %03d", index),
                "2024-06-01"
            )
        end

        local rendered = assert(report.build(dataset, CURRENT_DATE, dateTime))
        test.assert_equal(#rendered.tabs[1].rows, 98)
        test.assert_equal(rendered.tabs[1].rows[1].slotIndex, 1)
        test.assert_equal(rendered.tabs[1].rows[98].slotIndex, 98)
    end),
}
