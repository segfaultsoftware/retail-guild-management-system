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
            ["main-area52"] = { "zulu-area52", "alt-area52" },
            ["notonroster-area52"] = { "alpha-area52" },
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
            ["missingmain-area52"] = { "visiblealt-area52" },
            ["visiblemain-area52"] = { "missingalt-area52" },
        }

        local result = assert(report.build(dataset, groups))

        test.assert_equal(#result.rows, 2)
        test.assert_equal(result.rows[1].displayName, "VisibleAlt-Area52")
        test.assert_equal(result.rows[2].displayName, "VisibleMain-Area52")
        test.assert_equal(result.rows[2].altCount, 0)
        test.assert_equal(groups["missingmain-area52"], { "visiblealt-area52" })
        test.assert_equal(groups["visiblemain-area52"], { "missingalt-area52" })
    end),

    test.case("ByName excludes stale group members without losing roster members", function()
        local dataset = {
            members = {
                member("Main", "Area52"),
                member("Solo", "Area52"),
            },
        }
        local groups = {
            ["main-area52"] = { "removed-area52" },
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

    test.case("ByName keeps same-first-name Forever identities distinct", function()
        local birchIdentity = "RGMS:CHARACTER:FOREVER:1:2:US:9:Ada Birch"
        local cedarIdentity = "RGMS:CHARACTER:FOREVER:1:2:US:9:Ada Cedar"
        local result = assert(report.build({
            members = {
                {
                    identity = cedarIdentity,
                    name = "Ada Cedar",
                    displayName = "Ada Cedar",
                    classFileName = "MAGE",
                },
                {
                    identity = birchIdentity,
                    name = "Ada Birch",
                    displayName = "Ada Birch",
                    classFileName = "DRUID",
                },
            },
        }, {
            [birchIdentity] = { cedarIdentity },
        }, {
            [birchIdentity] = "Birch note",
            [cedarIdentity] = "Cedar note",
        }))

        test.assert_equal(#result.rows, 1)
        test.assert_equal(result.rows[1].identity, birchIdentity)
        test.assert_equal(result.rows[1].displayName, "Ada Birch")
        test.assert_equal(result.rows[1].note, "Birch note")
        test.assert_equal(result.rows[1].alts[1].identity, cedarIdentity)
        test.assert_equal(result.rows[1].alts[1].displayName, "Ada Cedar")
        test.assert_equal(result.rows[1].alts[1].note, "Cedar note")
    end),
}
