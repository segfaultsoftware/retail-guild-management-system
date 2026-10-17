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
}
