local tags = require("MainsAlts.Tags")
local test = require("Tests.lib.runner")

return {
    test.case("character tags normalize only edges and ASCII case", function()
        test.assert_equal(tags.normalize("  Raid  Lead  "), "raid  lead")
        test.assert_equal(tags.normalize(" ÉTÉ "), "ÉtÉ")
        test.assert_false(tags.normalize("Été") == tags.normalize("été"))
        test.assert_equal(tags.normalize("\tme\n"), "me")
    end),

    test.case("tag creation deduplicates definitions and keeps assignments idempotent", function()
        local state = tags.newState()
        local created, wasCreated, name = tags.resolveAndAssign(
            state,
            "main-area52",
            " Raid Lead "
        )
        test.assert_true(wasCreated)
        test.assert_equal(name, "raid lead")
        test.assert_true(created.definitions.me)
        test.assert_true(created.definitions["raid lead"])
        test.assert_true(created.assignments["main-area52"]["raid lead"])

        local reused, duplicateCreated = tags.resolveAndAssign(
            created,
            "main-area52",
            "RAID LEAD"
        )
        test.assert_false(duplicateCreated)
        test.assert_equal(tags.sortedDefinitions(reused), { "me", "raid lead" })
        test.assert_equal(tags.assignedTo(reused, "main-area52"), { "raid lead" })
        test.assert_nil(state.definitions["raid lead"])
    end),

    test.case("tag toggles preserve definitions and roster reconciliation removes only departed assignments", function()
        local state = {
            definitions = { me = true, raid = true },
            assignments = {
                ["main-area52"] = { me = true, raid = true },
                ["gone-area52"] = { raid = true },
            },
        }
        local toggled, assigned = tags.toggle(state, "main-area52", "raid")
        test.assert_false(assigned)
        test.assert_true(toggled.assignments["main-area52"].me)
        test.assert_nil(toggled.assignments["main-area52"].raid)

        local reconciled = assert(tags.reconcile({
            members = { { name = "Main", realm = "Area52" } },
        }, toggled))
        test.assert_nil(reconciled.assignments["gone-area52"])
        test.assert_true(reconciled.definitions.raid)
        test.assert_true(reconciled.definitions.me)
    end),

    test.case("tag catalog sorts definitions and roster-visible character previews", function()
        local catalog = assert(tags.buildCatalog({
            definitions = { me = true, raid = true, bench = true },
            assignments = {
                ["zeta-area52"] = { raid = true },
                ["alpha-area52"] = { raid = true, me = true },
                ["retained-area52"] = { bench = true, raid = true },
            },
        }, {
            members = {
                { name = "Zeta", realm = "Area52" },
                { name = "Alpha", realm = "Area52" },
                { name = "Unused", realm = "Area52" },
            },
        }))

        test.assert_equal(catalog.rows[1], {
            name = "bench",
            characters = {},
            characterCount = 0,
            characterPreview = "",
            immutable = false,
        })
        test.assert_equal(catalog.rows[2].name, "me")
        test.assert_true(catalog.rows[2].immutable)
        test.assert_equal(catalog.rows[2].characterPreview, "Alpha-Area52")
        test.assert_equal(catalog.rows[3].characters, {
            "Alpha-Area52",
            "Zeta-Area52",
        })
        test.assert_equal(catalog.rows[3].characterPreview,
            "Alpha-Area52, Zeta-Area52")
    end),

    test.case("tag deletion removes every assignment without mutating the source", function()
        local state = {
            definitions = { me = true, raid = true, bench = true },
            assignments = {
                ["visible-area52"] = { me = true, raid = true },
                ["retained-area52"] = { raid = true },
                ["bench-area52"] = { bench = true },
            },
        }

        local deleted = assert(tags.deleteDefinition(state, "raid"))

        test.assert_nil(deleted.definitions.raid)
        test.assert_true(deleted.assignments["visible-area52"].me)
        test.assert_nil(deleted.assignments["visible-area52"].raid)
        test.assert_nil(deleted.assignments["retained-area52"])
        test.assert_true(deleted.assignments["bench-area52"].bench)
        test.assert_true(state.definitions.raid)
        test.assert_true(state.assignments["retained-area52"].raid)

        local immutable, immutableError = tags.deleteDefinition(state, "me")
        test.assert_nil(immutable)
        test.assert_matches(immutableError, "immutable")
    end),
}
