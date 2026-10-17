local fixtures = require("Tests.fixtures")
local report = require("MainsAlts.Report")
local test = require("Tests.lib.runner")

local function member(name, realm, overrides)
    overrides = overrides or {}
    overrides.name = name
    overrides.realm = realm
    overrides.displayName = name .. "-" .. realm
    return fixtures.roster_member(overrides)
end

return {
    test.case("Mains/Alts report projects roster-only grouped and ungrouped rows", function()
        local dataset = {
            members = {
                member("Zulu", "Area52"),
                member("Alpha", "Zulu"),
                member("Main", "Area52"),
                member("Alpha", "Area52", { isMissing = true }),
                member("Alt", "Area52"),
            },
        }
        local groups = {
            ["Main-Area52"] = { "Zulu-Area52", "Alt-Area52" },
            ["NotOnRoster-Area52"] = { "Alpha-Area52" },
        }

        local result = assert(report.build(dataset, groups))

        test.assert_equal(#result.rows, 3)
        test.assert_equal(result.rows[1].displayName, "Alpha-Area52")
        test.assert_true(result.rows[1].isMissing)
        test.assert_equal(result.rows[2].displayName, "Alpha-Zulu")
        test.assert_equal(result.rows[3].displayName, "Main-Area52")
        test.assert_equal(result.rows[3].altCount, 2)
        test.assert_equal(result.rows[3].alts[1].displayName, "Alt-Area52")
        test.assert_equal(result.rows[3].alts[2].displayName, "Zulu-Area52")
    end),

    test.case("Mains/Alts report excludes stale group members without losing roster members", function()
        local dataset = {
            members = {
                member("Main", "Area52"),
                member("Solo", "Area52"),
            },
        }
        local groups = {
            ["Main-Area52"] = { "Removed-Area52" },
        }

        local result = assert(report.build(dataset, groups))

        test.assert_equal(#result.rows, 2)
        test.assert_equal(result.rows[1].displayName, "Main-Area52")
        test.assert_equal(result.rows[1].altCount, 0)
        test.assert_equal(result.rows[2].displayName, "Solo-Area52")
    end),

    test.case("Mains/Alts report rejects invalid roster input", function()
        local result, message = report.build({ members = { { name = "NoRealm" } } }, {})

        test.assert_nil(result)
        test.assert_matches(message, "roster member is invalid")
    end),
}
