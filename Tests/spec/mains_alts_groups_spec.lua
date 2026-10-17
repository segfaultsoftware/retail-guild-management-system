local groups = require("MainsAlts.Groups")
local test = require("Tests.lib.runner")

local function dataset(...)
    local members = {}
    for _, value in ipairs({ ... }) do
        members[#members + 1] = { name = value[1], realm = value[2] }
    end
    return { members = members }
end

return {
    test.case("grouping ungrouped characters chooses name then realm deterministically", function()
        local roster = dataset(
            { "Zulu", "Area52" },
            { "Alpha", "Zulu" },
            { "Alpha", "Area52" }
        )

        local result, mainIdentity = groups.apply(
            roster,
            {},
            { "zulu-area52", "alpha-zulu", "alpha-area52" }
        )

        test.assert_equal(mainIdentity, "alpha-area52")
        test.assert_equal(result, {
            ["Alpha-Area52"] = { "Alpha-Zulu", "Zulu-Area52" },
        })
    end),

    test.case("grouping extends one group and preserves its existing alts", function()
        local saved = {
            ["Main-Area52"] = { "Old-Area52" },
        }

        local result, mainIdentity = groups.apply(
            dataset(
                { "Main", "Area52" },
                { "Old", "Area52" },
                { "New", "Area52" }
            ),
            saved,
            { "new-area52", "main-area52" }
        )

        test.assert_equal(mainIdentity, "main-area52")
        test.assert_equal(result["Main-Area52"], {
            "New-Area52",
            "Old-Area52",
        })
        test.assert_equal(saved["Main-Area52"], { "Old-Area52" })
    end),

    test.case("grouping rejects merging groups without changing saved data", function()
        local saved = {
            ["First-Area52"] = { "FirstAlt-Area52" },
            ["Second-Area52"] = { "SecondAlt-Area52" },
        }
        local result, message = groups.apply(
            dataset(
                { "First", "Area52" },
                { "FirstAlt", "Area52" },
                { "Second", "Area52" },
                { "SecondAlt", "Area52" }
            ),
            saved,
            { "first-area52", "second-area52" }
        )

        test.assert_nil(result)
        test.assert_matches(message, "cannot be combined")
        test.assert_equal(saved["First-Area52"], { "FirstAlt-Area52" })
        test.assert_equal(saved["Second-Area52"], { "SecondAlt-Area52" })
    end),

    test.case("grouping rejects pre-existing duplicate memberships", function()
        local result, message = groups.apply(
            dataset(
                { "First", "Area52" },
                { "Second", "Area52" },
                { "Shared", "Area52" },
                { "New", "Area52" }
            ),
            {
                ["First-Area52"] = { "Shared-Area52" },
                ["Second-Area52"] = { "Shared-Area52" },
            },
            { "first-area52", "new-area52" }
        )

        test.assert_nil(result)
        test.assert_matches(message, "more than one group")
    end),

    test.case("promoting an alt swaps the main and sorts every remaining alt", function()
        local saved = {
            ["Zulu-Area52"] = {
                "Bravo-Zulu",
                "Alpha-Area52",
                "Charlie-Area52",
            },
        }

        local result, mainIdentity = groups.promote(saved, "bravo-zulu")

        test.assert_equal(mainIdentity, "bravo-zulu")
        test.assert_equal(result, {
            ["Bravo-Zulu"] = {
                "Alpha-Area52",
                "Charlie-Area52",
                "Zulu-Area52",
            },
        })
        test.assert_equal(saved["Zulu-Area52"], {
            "Bravo-Zulu",
            "Alpha-Area52",
            "Charlie-Area52",
        })
    end),

    test.case("removing an alt affects only its group and preserves the main", function()
        local saved = {
            ["Main-Area52"] = { "Removed-Area52", "Stayed-Area52" },
            ["Other-Area52"] = { "OtherAlt-Area52" },
        }

        local result, mainIdentity = groups.remove(saved, "removed-area52")

        test.assert_equal(mainIdentity, "main-area52")
        test.assert_equal(result, {
            ["Main-Area52"] = { "Stayed-Area52" },
            ["Other-Area52"] = { "OtherAlt-Area52" },
        })
        test.assert_equal(saved["Main-Area52"], {
            "Removed-Area52",
            "Stayed-Area52",
        })
    end),

    test.case("removing from a two-character group dissolves the group", function()
        local result, mainIdentity, groupRemains = groups.remove({
            ["Main-Area52"] = { "Alt-Area52" },
        }, "alt-area52")

        test.assert_equal(result, {})
        test.assert_equal(mainIdentity, "main-area52")
        test.assert_false(groupRemains)
    end),

    test.case("group changes reject characters that are not existing alts", function()
        local promoted, promoteError = groups.promote({
            ["Main-Area52"] = { "Alt-Area52" },
        }, "main-area52")
        local removed, removeError = groups.remove({
            ["Main-Area52"] = { "Alt-Area52" },
        }, "other-area52")

        test.assert_nil(promoted)
        test.assert_matches(promoteError, "not an alt")
        test.assert_nil(removed)
        test.assert_matches(removeError, "not an alt")
    end),

    test.case("roster reconciliation preserves retained members and removes orphans", function()
        local savedGroups = {
            ["Main-Area52"] = {
                "Gone-Area52",
                "Missing-Area52",
                "Stayed-Area52",
            },
            ["SoloMain-Area52"] = { "GoneAlt-Area52" },
            ["EmptyMain-Area52"] = { "EmptyAlt-Area52" },
        }
        local savedNotes = {
            ["main-area52"] = "Main note",
            ["gone-area52"] = "Delete me",
            ["missing-area52"] = "Missing note",
        }
        local roster = dataset(
            { "Main", "Area52" },
            { "Missing", "Area52" },
            { "Stayed", "Area52" },
            { "SoloMain", "Area52" }
        )
        roster.members[2].isMissing = true

        local result, notes = groups.reconcile(roster, savedGroups, savedNotes)

        test.assert_equal(result, {
            ["Main-Area52"] = { "Missing-Area52", "Stayed-Area52" },
        })
        test.assert_equal(notes, {
            ["main-area52"] = "Main note",
            ["missing-area52"] = "Missing note",
        })
        test.assert_equal(savedGroups["Main-Area52"][1], "Gone-Area52")
        test.assert_equal(savedNotes["gone-area52"], "Delete me")
    end),

    test.case("roster reconciliation promotes the first remaining name and realm", function()
        local result = assert(groups.reconcile(
            dataset(
                { "Zulu", "Area52" },
                { "Alpha", "Zulu" },
                { "Alpha", "Area52" }
            ),
            {
                ["Removed-Area52"] = {
                    "Zulu-Area52",
                    "Alpha-Zulu",
                    "Alpha-Area52",
                },
            },
            {}
        ))

        test.assert_equal(result, {
            ["Alpha-Area52"] = { "Alpha-Zulu", "Zulu-Area52" },
        })
    end),
}
