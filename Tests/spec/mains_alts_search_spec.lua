local search = require("MainsAlts.Search")
local test = require("Tests.lib.runner")

local function character(name, realm, options)
    options = options or {}
    return {
        name = name,
        realm = realm or "Area52",
        displayName = name .. "-" .. (realm or "Area52"),
        identity = string.lower(name .. "-" .. (realm or "Area52")),
        isMissing = options.isMissing == true,
        note = options.note or "",
        tags = options.tags or {},
        altCount = options.altCount or 0,
        alts = options.alts or {},
    }
end

return {
    test.case("Mains/Alts search normalizes spaces and case for ordered matching", function()
        test.assert_equal(search.normalize(" M T V S "), "mtvs")
        test.assert_true(search.matches("Mountvesuvius", "mtvs"))
        test.assert_true(search.matches("Mountvesuvius", "MTVS"))
        test.assert_true(search.matches("Mountvesuvius", "m t v s"))
        test.assert_false(search.matches("Mountvesuvius", "mstv"))
        test.assert_false(search.matches("Café", "e"))
    end),

    test.case("Mains/Alts search keeps full matching groups in report order", function()
        local matchingAlt = character("Mountvesuvius")
        local first = character("Alpha")
        local group = character("Main", "Area52", {
            altCount = 2,
            alts = {
                character("OtherAlt"),
                matchingAlt,
            },
        })
        local retainedMissing = character("MissingMatch", "Area52", {
            isMissing = true,
        })
        local report = { rows = { first, group, retainedMissing } }

        local filtered, expanded, _, matchingCharacters = search.filter(
            report,
            "mtvs"
        )

        test.assert_equal(filtered.rows, { group })
        test.assert_equal(filtered.rows[1].alts, group.alts)
        test.assert_true(expanded[group.identity])
        test.assert_equal(matchingCharacters, {
            [matchingAlt.identity] = true,
        })
        test.assert_equal(search.filter(report, "main").rows, { group })
        test.assert_equal(search.filter(report, "m").rows, {
            group,
            retainedMissing,
        })

        local missing = search.filter(report, "mm")
        test.assert_equal(missing.rows, { retainedMissing })
    end),

    test.case("Mains/Alts search ignores realms notes and unmatched rows", function()
        local realmOnly = character("Hero", "Searchrealm")
        local noteOnly = character("Other", "Area52", { note = "search note" })
        local report = { rows = { realmOnly, noteOnly } }

        test.assert_equal(search.filter(report, "search").rows, {})
        test.assert_equal(search.filter(report, "zzz").rows, {})
        test.assert_equal(search.filter(report, "").rows, report.rows)
    end),

    test.case("tag filters use same-character AND semantics with name search", function()
        local group = character("Main", "Area52", {
            altCount = 2,
            tags = { "tank" },
            alts = {
                character("NamedAlt", "Area52", { tags = { "healer" } }),
                character("OtherAlt", "Area52", { tags = { "healer", "raid" } }),
            },
        })
        local solo = character("NamedSolo", "Area52", {
            tags = { "healer", "raid" },
        })
        local report = { rows = { group, solo } }

        test.assert_equal(search.filter(report, "", {
            healer = true,
            raid = true,
        }).rows, { group, solo })
        test.assert_equal(search.filter(report, "named", {
            healer = true,
            raid = true,
        }).rows, { solo })
        test.assert_equal(search.filter(report, "other", {
            healer = true,
            raid = true,
        }).rows, { group })

        local filtered, expanded, _, matchingCharacters = search.filter(
            report,
            "other",
            {
                healer = true,
                raid = true,
            }
        )
        test.assert_equal(filtered.rows[1].alts, group.alts)
        test.assert_true(expanded[group.identity])
        test.assert_equal(matchingCharacters, {
            [group.alts[2].identity] = true,
        })

        local allMatching, _, _, allMatchingCharacters = search.filter(
            report,
            "",
            { healer = true }
        )
        test.assert_equal(allMatching.rows, { group, solo })
        test.assert_equal(allMatchingCharacters, {
            [group.alts[1].identity] = true,
            [group.alts[2].identity] = true,
            [solo.identity] = true,
        })

        local unfiltered, _, _, unfilteredMatches = search.filter(report, "")
        test.assert_equal(unfiltered.rows, report.rows)
        test.assert_equal(unfilteredMatches, {})
    end),
}
