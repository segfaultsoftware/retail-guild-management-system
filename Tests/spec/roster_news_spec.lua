local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local news = require("Roster.News")
local test = require("Tests.lib.runner")

local START = 1717245356

local function member(name, rankIndex, rankName, realm)
    return {
        name = name,
        realm = realm or "Example Realm",
        displayName = name .. "-" .. (realm or "Example Realm"),
        rankIndex = rankIndex or 2,
        rankName = rankName or "Member",
    }
end

local function snapshot(day, members)
    return {
        guild = fixtures.guild_identity(),
        scannedAt = assert(dateTime.utcTimestamp(START + day * 24 * 60 * 60)),
        ranks = {},
        members = members,
    }
end

local function advance(state, day, members)
    return assert(news.process(
        state and state.observation or nil,
        state and state.newsSets or {},
        snapshot(day, members),
        dateTime
    ))
end

return {
    test.case("first successful roster observation establishes a news-free baseline", function()
        local state = advance(nil, 0, { member("Alpha") })

        test.assert_false(state.created)
        test.assert_equal(state.newsSets, {})
        test.assert_equal(state.observation.members[1].identity, "alpha-example realm")
    end),

    test.case("joining leaving returning and numeric rank changes create exact sets", function()
        local state = advance(nil, 0, {
            member("Bravo", 2),
            member("Alpha", 2),
        })
        state = advance(state, 1, {
            member("Alpha", 1, "Officer"),
            member("Charlie", 2),
        })

        test.assert_true(state.created)
        test.assert_equal(state.newsSets[1].joiningMembers, { "Charlie-Example Realm" })
        test.assert_equal(state.newsSets[1].leavingMembers, { "Bravo-Example Realm" })
        test.assert_equal(state.newsSets[1].rankChanges, {
            { name = "Alpha-Example Realm", rankName = "Officer" },
        })

        state = advance(state, 2, {
            member("Alpha", 1, "Renamed Officer"),
            member("Charlie", 2),
        })
        test.assert_false(state.created)
        test.assert_equal(#state.newsSets, 1)

        state = advance(state, 3, {
            member("Alpha", 1, "Renamed Officer"),
            member("Bravo", 3, "Initiate"),
            member("Charlie", 2),
        })
        test.assert_true(state.created)
        test.assert_equal(state.newsSets[1].joiningMembers, { "Bravo-Example Realm" })
        test.assert_equal(state.newsSets[1].rankChanges, {})
    end),

    test.case("an absence is reported once while independent sets stay newest first", function()
        local state = advance(nil, 0, { member("Alpha"), member("Bravo") })
        state = advance(state, 1, { member("Alpha") })
        local departureId = state.newsSets[1].id
        state = advance(state, 2, { member("Alpha") })

        test.assert_false(state.created)
        test.assert_equal(#state.newsSets, 1)
        test.assert_equal(state.newsSets[1].id, departureId)

        state = advance(state, 3, { member("Alpha"), member("Charlie") })
        test.assert_equal(#state.newsSets, 2)
        test.assert_equal(state.newsSets[2].id, departureId)
        local retained = assert(news.acknowledge(state.newsSets, departureId))
        test.assert_equal(#retained, 1)
        test.assert_equal(retained[1].joiningMembers, { "Charlie-Example Realm" })
    end),

    test.case("canonical case-insensitive Name-Realm identity drives transitions", function()
        local state = advance(nil, 0, { member("Alpha", 2, "Member", "Area-52") })
        state = advance(state, 1, { member("ALPHA", 2, "Member", "area-52") })
        test.assert_false(state.created)

        state = advance(state, 2, { member("Alpha", 2, "Member", "Illidan") })
        test.assert_true(state.created)
        test.assert_equal(state.newsSets[1].joiningMembers, { "Alpha-Illidan" })
        test.assert_equal(state.newsSets[1].leavingMembers, { "ALPHA-area-52" })
    end),

    test.case("news remains through Pacific day 21 and expires on day 22", function()
        local state = advance(nil, 0, { member("Alpha") })
        state = advance(state, 1, { member("Alpha"), member("Bravo") })
        test.assert_equal(#state.newsSets, 1)

        state = advance(state, 22, { member("Alpha"), member("Bravo") })
        test.assert_equal(#state.newsSets, 1)

        state = advance(state, 23, { member("Alpha"), member("Bravo") })
        test.assert_equal(state.newsSets, {})
    end),

    test.case("failed acknowledgement leaves every immutable set unchanged", function()
        local state = advance(nil, 0, { member("Alpha") })
        state = advance(state, 1, { member("Alpha"), member("Bravo") })
        local before = state.newsSets[1]
        local result, resultError = news.acknowledge(state.newsSets, "missing")

        test.assert_nil(result)
        test.assert_matches(resultError, "not found")
        test.assert_true(state.newsSets[1] == before)
    end),
}
