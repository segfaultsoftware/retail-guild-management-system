local names = require("Roster.Names")
local test = require("Tests.lib.runner")

return {
    test.case("clean API names remain canonical", function()
        local name, realm, displayName = names.splitDisplayName(
            "Nalla-Ner'zhul",
            "Ner'zhul"
        )

        test.assert_equal(name, "Nalla")
        test.assert_equal(realm, "Ner'zhul")
        test.assert_equal(displayName, "Nalla-Ner'zhul")
    end),

    test.case("repeated persisted realm suffixes collapse without mutating input", function()
        local realm = "Ner'zhul-Ner'zhul-Ner'zhul-Ner'zhul"

        test.assert_equal(names.collapseRepeatedRealm(realm), "Ner'zhul")
        test.assert_equal(names.displayName("Nalla", realm), "Nalla-Ner'zhul")
        test.assert_equal(realm, "Ner'zhul-Ner'zhul-Ner'zhul-Ner'zhul")
    end),

    test.case("truncated and case-varied repeated suffixes collapse", function()
        test.assert_equal(
            names.collapseRepeatedRealm(
                "Ner'zhul-Ner'zhul-Ner'zhul-Ner'zh"
            ),
            "Ner'zhul"
        )
        test.assert_equal(
            names.collapseRepeatedRealm("Area52-area52-Area"),
            "Area52"
        )
        test.assert_equal(
            names.collapseRepeatedRealm(
                "Deep-Rock-deep-rock-Deep-Rock-De"
            ),
            "Deep-Rock"
        )
    end),

    test.case("legitimate hyphenated realms are preserved", function()
        test.assert_equal(
            names.collapseRepeatedRealm("Azjol-Nerub"),
            "Azjol-Nerub"
        )
        test.assert_equal(
            names.collapseRepeatedRealm("Azjol-Nerub-Azjol-Nerub"),
            "Azjol-Nerub"
        )
        test.assert_equal(
            names.collapseRepeatedRealm("Deep-Rock-Depths"),
            "Deep-Rock-Depths"
        )
    end),

    test.case("member identities ignore realm and character casing", function()
        test.assert_equal(
            names.identity("Nalla", "Ner'Zhul-Ner'zhul-Ne"),
            names.identity("nalla", "ner'zhul")
        )
    end),
}
