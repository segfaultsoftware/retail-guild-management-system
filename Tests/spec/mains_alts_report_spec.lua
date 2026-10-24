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
    test.case("ByName projects roster-only grouped and ungrouped rows", function()
        local dataset = {
            members = {
                member("Zulu", "Area52"),
                member("Alpha", "Zulu"),
                member("Main", "Area52", {
                    classFileName = "WARRIOR",
                    leadershipRole = "guild-master",
                }),
                member("Alpha", "Area52", { isMissing = true }),
                member("Alt", "Area52", {
                    classFileName = "DRUID",
                    leadershipRole = "officer",
                }),
            },
        }
        local groups = {
            ["Main-Area52"] = { "Zulu-Area52", "Alt-Area52" },
            ["NotOnRoster-Area52"] = { "Alpha-Area52" },
        }

        local result = assert(report.build(dataset, groups, {
            ["main-area52"] = "Main note",
            ["alt-area52"] = "Alt note",
            ["alpha-area52"] = "   ",
        }, {
            definitions = { me = true, raid = true },
            assignments = {
                ["main-area52"] = { raid = true, me = true },
                ["alt-area52"] = { me = true },
            },
        }))

        test.assert_equal(#result.rows, 2)
        test.assert_equal(result.rows[1].displayName, "Alpha-Zulu")
        test.assert_equal(result.rows[2].displayName, "Main-Area52")
        test.assert_equal(result.rows[2].classFileName, "WARRIOR")
        test.assert_equal(result.rows[2].leadershipRole, "guild-master")
        test.assert_equal(result.tagCatalog, { "me", "raid" })
        test.assert_equal(result.rows[2].tags, { "me", "raid" })
        test.assert_true(result.rows[2].hasNote)
        test.assert_equal(result.rows[2].note, "Main note")
        test.assert_equal(result.rows[2].altCount, 2)
        test.assert_equal(result.rows[2].alts[1].displayName, "Alt-Area52")
        test.assert_equal(result.rows[2].alts[1].classFileName, "DRUID")
        test.assert_equal(result.rows[2].alts[1].leadershipRole, "officer")
        test.assert_equal(result.rows[2].alts[1].tags, { "me" })
        test.assert_true(result.rows[2].alts[1].hasNote)
        test.assert_equal(result.rows[2].alts[1].note, "Alt note")
        test.assert_equal(result.rows[2].alts[2].displayName, "Zulu-Area52")
        test.assert_false(result.rows[2].alts[2].hasNote)
    end),

    test.case("ByName hides missing group members without deleting saved groups", function()
        local dataset = {
            members = {
                member("MissingMain", "Area52", { isMissing = true }),
                member("VisibleAlt", "Area52"),
                member("VisibleMain", "Area52"),
                member("MissingAlt", "Area52", { isMissing = true }),
            },
        }
        local groups = {
            ["MissingMain-Area52"] = { "VisibleAlt-Area52" },
            ["VisibleMain-Area52"] = { "MissingAlt-Area52" },
        }

        local result = assert(report.build(dataset, groups))

        test.assert_equal(#result.rows, 2)
        test.assert_equal(result.rows[1].displayName, "VisibleAlt-Area52")
        test.assert_equal(result.rows[2].displayName, "VisibleMain-Area52")
        test.assert_equal(result.rows[2].altCount, 0)
        test.assert_equal(groups["MissingMain-Area52"], { "VisibleAlt-Area52" })
        test.assert_equal(groups["VisibleMain-Area52"], { "MissingAlt-Area52" })
    end),

    test.case("ByName excludes stale group members without losing roster members", function()
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

    test.case("ByName rejects invalid roster input", function()
        local result, message = report.build({ members = { { name = "NoRealm" } } }, {})

        test.assert_nil(result)
        test.assert_matches(message, "roster member is invalid")
    end),
}
