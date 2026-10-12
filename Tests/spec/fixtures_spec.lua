local fixtures = require("Tests.fixtures")
local test = require("Tests.lib.runner")

return {
    test.case("guild identities can be customized", function()
        local guild = fixtures.guild_identity({ name = "Night Shift" })

        test.assert_equal(guild.name, "Night Shift")
        test.assert_equal(guild.region, "US")
        test.assert_equal(guild.realm.slug, "example-realm")
    end),

    test.case("roster fixtures include ranks and members", function()
        local rank = fixtures.roster_rank({ index = 2, name = "Raider" })
        local member = fixtures.roster_member({ rankIndex = rank.index })

        test.assert_equal(rank.name, "Raider")
        test.assert_equal(member.rankIndex, 2)
        test.assert_equal(member.observedAt.iso8601, "2024-06-01T12:34:56Z")
        test.assert_equal(member.rankTenureStartDate, "2024-06-01")
        test.assert_equal(member.lastSeenDate, "2024-06-01")
        test.assert_false(member.isMissing)
    end),

    test.case("bank fixtures include tabs and slots", function()
        local tab = fixtures.bank_tab({ index = 3, name = "Crafting" })
        local slot = fixtures.bank_slot({ tabIndex = tab.index, quantity = 7 })

        test.assert_equal(tab.name, "Crafting")
        test.assert_equal(slot.tabIndex, 3)
        test.assert_equal(slot.quantity, 7)
    end),

    test.case("fixture instances do not share nested state", function()
        local first = fixtures.guild_identity()
        local second = fixtures.guild_identity()
        first.realm.name = "Changed Realm"

        test.assert_equal(second.realm.name, "Example Realm")
    end),

    test.case("timestamps are fixed UTC values unless overridden", function()
        local defaultTimestamp = fixtures.timestamp()
        local laterTimestamp = fixtures.timestamp({
            unixSeconds = 1717245356,
            iso8601 = "2024-06-01T12:35:56Z",
        })

        test.assert_equal(defaultTimestamp, {
            unixSeconds = 1717245296,
            iso8601 = "2024-06-01T12:34:56Z",
        })
        test.assert_equal(laterTimestamp.iso8601, "2024-06-01T12:35:56Z")
    end),

    test.case("saved-data fixtures model current and version-zero shapes", function()
        local current = fixtures.saved_model()
        local previous = fixtures.saved_model_v0()

        test.assert_equal(current.schemaVersion, 4)
        test.assert_equal(current.roster.guild.name, "Example Guild")
        test.assert_equal(current.ui.windowPosition.point, "TOPLEFT")
        test.assert_equal(previous.schemaVersion, 0)
        test.assert_equal(previous.roster.guildIdentity.name, "Example Guild")
        test.assert_nil(previous.ui)
    end),
}
