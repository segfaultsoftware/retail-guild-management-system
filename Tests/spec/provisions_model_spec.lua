local model = require("Provisions.Model")
local fixtures = require("Tests.fixtures")
local test = require("Tests.lib.runner")

local function provision(id, name, quality, target)
    return {
        id = id,
        name = name,
        quality = quality,
        target = target,
    }
end

local function bank(slots)
    return {
        guild = fixtures.guild_identity(),
        scannedAt = fixtures.timestamp(),
        tabs = {
            fixtures.bank_tab({ index = 1, isViewable = true }),
            fixtures.bank_tab({ index = 2, isViewable = false }),
        },
        slots = slots,
    }
end

local function slot(tabIndex, slotIndex, name, quantity, quality, icon)
    local value = fixtures.bank_slot({
        tabIndex = tabIndex,
        slotIndex = slotIndex,
        itemLink = "|cff1eff00|Hitem:190001::::::::|h[" .. name .. "]|h|r",
        quantity = quantity,
    })
    value.craftingQuality = quality
    if icon ~= nil then
        value.icon = icon
    end
    return value
end

return {
    test.case("provision validation trims edges and enforces every boundary", function()
        local normalized = assert(model.normalizeDraft({
            name = "  Arcane Crystal  ",
            silver = true,
            gold = true,
            targetText = "99999",
        }))
        test.assert_equal(normalized, {
            name = "Arcane Crystal",
            quality = "either",
            target = 99999,
        })

        local unicode = assert(model.normalizeDraft({
            name = "水晶石",
            silver = true,
            targetText = "1",
        }))
        test.assert_equal(unicode.name, "水晶石")

        for _, draft in ipairs({
            { name = "ab", silver = true, targetText = "1" },
            { name = string.rep("a", 101), silver = true, targetText = "1" },
            { name = "valid", targetText = "1" },
            { name = "valid", gold = true, targetText = "0" },
            { name = "valid", gold = true, targetText = "100000" },
            { name = "valid", gold = true, targetText = "1.5" },
        }) do
            test.assert_nil(model.normalizeDraft(draft))
        end
    end),

    test.case("duplicate provisions keep stable independent creation IDs", function()
        local draft = assert(model.normalizeDraft({
            name = "Cauldron",
            silver = true,
            targetText = "20",
        }))
        local first, nextId, firstId = assert(model.add({}, 1, draft))
        local duplicated, finalNextId, secondId = assert(model.add(first, nextId, draft))
        test.assert_equal(firstId, 1)
        test.assert_equal(secondId, 2)
        test.assert_equal(finalNextId, 3)
        test.assert_equal(#duplicated, 2)

        local updated = assert(model.update(duplicated, secondId, {
            name = "Feast",
            quality = "gold",
            target = 5,
        }))
        test.assert_equal(updated[1].name, "Cauldron")
        test.assert_equal(updated[2].name, "Feast")
        local retained = assert(model.delete(updated, firstId))
        test.assert_equal(retained, {
            provision(2, "Feast", "gold", 5),
        })
    end),

    test.case("rows retain the authoritative saved manual order", function()
        local report = model.buildReport({
            provision(4, "zeta", "either", 1),
            provision(3, "Alpha", "silver", 1),
            provision(1, "alpha", "gold", 1),
        }, { tabs = {}, slots = {} })
        test.assert_equal(report.rows[1].id, 4)
        test.assert_equal(report.rows[2].id, 3)
        test.assert_equal(report.rows[3].id, 1)
    end),

    test.case("reordering preserves duplicate values by stable ID", function()
        local source = {
            provision(1, "Feast", "either", 10),
            provision(2, "Feast", "either", 10),
            provision(3, "Flask", "gold", 20),
        }
        local reordered = assert(model.reorder(source, { 2, 3, 1 }))
        test.assert_equal(reordered, {
            provision(2, "Feast", "either", 10),
            provision(3, "Flask", "gold", 20),
            provision(1, "Feast", "either", 10),
        })
        test.assert_equal(source[1].id, 1)
        test.assert_nil(model.reorder(source, { 1, 1, 3 }))
        test.assert_nil(model.reorder(source, { 1, 2 }))
    end),

    test.case("committed bank stacks aggregate by name and crafting quality", function()
        local report = model.buildReport({
            provision(1, "herb", "silver", 10),
            provision(2, "HERB", "gold", 10),
            provision(3, "Herb", "either", 10),
        }, bank({
            slot(1, 1, "Herb", 4, 1),
            slot(1, 2, "HERB", 7, 2),
            slot(2, 1, "Herb", 3, nil),
        }))
        test.assert_equal(report.rows[1].current, 4)
        test.assert_equal(report.rows[2].current, 7)
        test.assert_equal(report.rows[3].current, 14)
        test.assert_equal(report.rows[3].progressText, "14 / 10")
        test.assert_equal(report.rows[3].progress, 1)
        test.assert_equal(report.rows[1].icon, 236873)
        test.assert_equal(report.rows[2].icon, 236873)
        test.assert_equal(report.rows[3].icon, 236873)
    end),

    test.case("trailing crafting-quality icon markup is excluded from name matching", function()
        local report = model.buildReport({
            provision(1, "Foo Bar", "silver", 10),
            provision(2, "Foo Bar", "gold", 10),
            provision(3, "Foo Bar", "either", 10),
        }, bank({
            slot(
                1,
                1,
                "Foo Bar |A:Professions-Icon-Quality-12-Tier1:20:20|a",
                4,
                1
            ),
            slot(
                1,
                2,
                "Foo Bar |TInterface\\Icons\\INV_Misc_QuestionMark:20:20|t",
                7,
                2
            ),
        }))

        test.assert_equal(report.rows[1].current, 4)
        test.assert_equal(report.rows[2].current, 7)
        test.assert_equal(report.rows[3].current, 11)
        test.assert_equal(report.rows[1].icon, 236873)
        test.assert_equal(report.rows[2].icon, 236873)
        test.assert_equal(report.rows[3].icon, 236873)
    end),

    test.case("icons use deterministic first usable matches independent of quality", function()
        local report = model.buildReport({
            provision(1, "herb", "silver", 10),
            provision(2, "Path Item", "gold", 10),
        }, bank({
            slot(2, 1, "Herb", 1, 1, 900),
            slot(1, 5, "HERB", 1, 1, 500),
            slot(1, 2, "Herb", 1, 1, 0),
            slot(1, 3, "Herb", 1, 2, 300),
            slot(1, 4, "Herb", 1, 1, 400),
            slot(1, 6, "Path Item", 1, 1, "Interface\\Icons\\INV_Misc_QuestionMark"),
        }))

        test.assert_equal(report.rows[1].icon, 300)
        test.assert_equal(
            report.rows[2].icon,
            "Interface\\Icons\\INV_Misc_QuestionMark"
        )
    end),

    test.case("retained inaccessible-tab slots in saved snapshots provide icons", function()
        local report = model.buildReport({
            provision(1, "Retained Item", "either", 10),
        }, bank({
            slot(2, 7, "Retained Item", 4, nil, 777),
        }))

        test.assert_equal(report.rows[1].current, 4)
        test.assert_equal(report.rows[1].icon, 777)
    end),

    test.case("successful committed datasets replace and remove resolved icons", function()
        local provisions = { provision(1, "Herb", "either", 10) }
        local original = model.buildReport(provisions, bank({
            slot(1, 1, "Herb", 4, nil, 111),
        }))
        local replaced = model.buildReport(provisions, bank({
            slot(1, 1, "Herb", 4, nil, 222),
        }))
        local removed = model.buildReport(provisions, bank({
            slot(1, 1, "Different Herb", 4, nil, 333),
        }))

        test.assert_equal(original.rows[1].icon, 111)
        test.assert_equal(replaced.rows[1].icon, 222)
        test.assert_equal(removed.rows[1].icon, model.FALLBACK_ITEM_ICON)
    end),

    test.case("missing matches and unusable icons use the placeholder", function()
        local report = model.buildReport({
            provision(1, "No Match", "either", 10),
            provision(2, "No Icon", "either", 10),
        }, bank({
            slot(1, 1, "No Match Extended", 4, nil, 444),
            slot(1, 2, "No Icon", 4, nil, 0),
            slot(1, 3, "No Icon", 4, nil, ""),
            slot(1, 4, "No Icon", 4, nil, -1),
        }))

        test.assert_equal(report.rows[1].icon, model.FALLBACK_ITEM_ICON)
        test.assert_equal(report.rows[2].icon, model.FALLBACK_ITEM_ICON)
    end),

    test.case("no successful bank scan reports zero without inspecting slots", function()
        local report = model.buildReport({
            provision(1, "Herb", "either", 10),
        }, {
            tabs = {},
            slots = { slot(1, 1, "Herb", 99, nil) },
        })
        test.assert_equal(report.rows[1].current, 0)
        test.assert_equal(report.rows[1].progress, 0)
        test.assert_equal(report.rows[1].progressText, "0 / 10")
        test.assert_equal(report.rows[1].icon, model.FALLBACK_ITEM_ICON)
    end),
}
