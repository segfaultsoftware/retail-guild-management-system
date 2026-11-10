local groups = require("MainsAlts.Groups")
local test = require("Tests.lib.runner")

local function character(identity, name, realm)
    return {
        identity = identity,
        name = name,
        realm = realm,
        displayName = realm and name .. "-" .. realm or name,
    }
end

local function retail(name, realm)
    return character(string.lower(name .. "-" .. realm), name, realm)
end

local function dataset(...)
    return { members = { ... } }
end

return {
    test.case("grouping ungrouped characters chooses roster name then realm deterministically", function()
        local roster = dataset(
            retail("Zulu", "Area52"),
            retail("Alpha", "Zulu"),
            retail("Alpha", "Area52")
        )

        local result, mainIdentity = groups.apply(
            roster,
            {},
            { "zulu-area52", "alpha-zulu", "alpha-area52" }
        )

        test.assert_equal(mainIdentity, "alpha-area52")
        test.assert_equal(result, {
            ["alpha-area52"] = { "alpha-zulu", "zulu-area52" },
        })
    end),

    test.case("grouping extends one identity-keyed group and preserves its existing alts", function()
        local saved = {
            ["main-area52"] = { "old-area52" },
        }

        local result, mainIdentity = groups.apply(
            dataset(
                retail("Main", "Area52"),
                retail("Old", "Area52"),
                retail("New", "Area52")
            ),
            saved,
            { "new-area52", "main-area52" }
        )

        test.assert_equal(mainIdentity, "main-area52")
        test.assert_equal(result["main-area52"], {
            "new-area52",
            "old-area52",
        })
        test.assert_equal(saved["main-area52"], { "old-area52" })
    end),

    test.case("grouping rejects merging groups without changing saved data", function()
        local saved = {
            ["first-area52"] = { "firstalt-area52" },
            ["second-area52"] = { "secondalt-area52" },
        }
        local result, message = groups.apply(
            dataset(
                retail("First", "Area52"),
                retail("FirstAlt", "Area52"),
                retail("Second", "Area52"),
                retail("SecondAlt", "Area52")
            ),
            saved,
            { "first-area52", "second-area52" }
        )

        test.assert_nil(result)
        test.assert_matches(message, "cannot be combined")
        test.assert_equal(saved["first-area52"], { "firstalt-area52" })
        test.assert_equal(saved["second-area52"], { "secondalt-area52" })
    end),

    test.case("grouping rejects pre-existing duplicate identity memberships", function()
        local result, message = groups.apply(
            dataset(
                retail("First", "Area52"),
                retail("Second", "Area52"),
                retail("Shared", "Area52"),
                retail("New", "Area52")
            ),
            {
                ["first-area52"] = { "shared-area52" },
                ["second-area52"] = { "shared-area52" },
            },
            { "first-area52", "new-area52" }
        )

        test.assert_nil(result)
        test.assert_matches(message, "more than one group")
    end),

    test.case("promoting an alt sorts opaque identities by active roster labels", function()
        local saved = {
            ["zulu-area52"] = {
                "bravo-zulu",
                "charlie-area52",
                "alpha-area52",
            },
        }

        local result, mainIdentity = groups.promote(dataset(
            retail("Zulu", "Area52"),
            retail("Bravo", "Zulu"),
            retail("Charlie", "Area52"),
            retail("Alpha", "Area52")
        ), saved, "bravo-zulu")

        test.assert_equal(mainIdentity, "bravo-zulu")
        test.assert_equal(result, {
            ["bravo-zulu"] = {
                "alpha-area52",
                "charlie-area52",
                "zulu-area52",
            },
        })
        test.assert_equal(saved["zulu-area52"], {
            "bravo-zulu",
            "charlie-area52",
            "alpha-area52",
        })
    end),

    test.case("Forever promotion sorts same-first-name alts by roster labels", function()
        local birch = "opaque:promoted"
        local cedar = "opaque:zz-main"
        local zed = "opaque:aa-alt"
        local result, mainIdentity = groups.promote(dataset(
            character(zed, "Ada Zed"),
            character(cedar, "Ada Cedar"),
            character(birch, "Ada Birch")
        ), {
            [cedar] = { birch, zed },
        }, birch)

        test.assert_equal(mainIdentity, birch)
        test.assert_equal(result, {
            [birch] = { cedar, zed },
        })
    end),

    test.case("removing an alt affects only its group and preserves the main identity", function()
        local saved = {
            ["main-area52"] = {
                "zulu-area52",
                "removed-area52",
                "alpha-area52",
            },
            ["other-area52"] = { "otheralt-area52" },
        }

        local result, mainIdentity = groups.remove(dataset(
            retail("Main", "Area52"),
            retail("Zulu", "Area52"),
            retail("Removed", "Area52"),
            retail("Alpha", "Area52")
        ), saved, "removed-area52")

        test.assert_equal(mainIdentity, "main-area52")
        test.assert_equal(result, {
            ["main-area52"] = { "alpha-area52", "zulu-area52" },
            ["other-area52"] = { "otheralt-area52" },
        })
        test.assert_equal(saved["main-area52"], {
            "zulu-area52",
            "removed-area52",
            "alpha-area52",
        })
    end),

    test.case("removing from a two-character group dissolves the group", function()
        local result, mainIdentity, groupRemains = groups.remove(dataset(
            retail("Main", "Area52"),
            retail("Alt", "Area52")
        ), {
            ["main-area52"] = { "alt-area52" },
        }, "alt-area52")

        test.assert_equal(result, {})
        test.assert_equal(mainIdentity, "main-area52")
        test.assert_false(groupRemains)
    end),

    test.case("group changes reject characters that are not existing alts", function()
        local roster = dataset(
            retail("Main", "Area52"),
            retail("Alt", "Area52")
        )
        local promoted, promoteError = groups.promote(roster, {
            ["main-area52"] = { "alt-area52" },
        }, "main-area52")
        local removed, removeError = groups.remove(roster, {
            ["main-area52"] = { "alt-area52" },
        }, "other-area52")

        test.assert_nil(promoted)
        test.assert_matches(promoteError, "not an alt")
        test.assert_nil(removed)
        test.assert_matches(removeError, "not an alt")
    end),

    test.case("roster reconciliation preserves retained identities and removes orphans", function()
        local savedGroups = {
            ["main-area52"] = {
                "gone-area52",
                "missing-area52",
                "stayed-area52",
            },
            ["solomain-area52"] = { "gonealt-area52" },
            ["emptymain-area52"] = { "emptyalt-area52" },
        }
        local savedNotes = {
            ["main-area52"] = "Main note",
            ["gone-area52"] = "Delete me",
            ["missing-area52"] = "Missing note",
        }
        local roster = dataset(
            retail("Main", "Area52"),
            retail("Missing", "Area52"),
            retail("Stayed", "Area52"),
            retail("SoloMain", "Area52")
        )
        roster.members[2].isMissing = true

        local result, notes = groups.reconcile(roster, savedGroups, savedNotes)

        test.assert_equal(result, {
            ["main-area52"] = { "missing-area52", "stayed-area52" },
        })
        test.assert_equal(notes, {
            ["main-area52"] = "Main note",
            ["missing-area52"] = "Missing note",
        })
        test.assert_equal(savedGroups["main-area52"][1], "gone-area52")
        test.assert_equal(savedNotes["gone-area52"], "Delete me")
    end),

    test.case("roster reconciliation promotes by roster label instead of identity contents", function()
        local result = assert(groups.reconcile(
            dataset(
                character("opaque:01", "Zulu", "Area52"),
                character("opaque:02", "Alpha", "Zulu"),
                character("opaque:99", "Alpha", "Area52")
            ),
            {
                ["removed:identity"] = {
                    "opaque:01",
                    "opaque:02",
                    "opaque:99",
                },
            },
            {}
        ))

        test.assert_equal(result, {
            ["opaque:99"] = { "opaque:02", "opaque:01" },
        })
    end),

    test.case("same-first-name Forever characters group by complete roster labels", function()
        local birch = "RGMS:CHARACTER:FOREVER:1:2:US:9:Ada Birch"
        local cedar = "RGMS:CHARACTER:FOREVER:1:2:US:9:Ada Cedar"
        local result, mainIdentity = groups.apply(
            dataset(
                character(cedar, "Ada Cedar"),
                character(birch, "Ada Birch")
            ),
            {},
            { cedar, birch }
        )

        test.assert_equal(mainIdentity, birch)
        test.assert_equal(result, {
            [birch] = { cedar },
        })
    end),
}
