local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local names = require("Roster.Names")
local news = require("Roster.News")
local test = require("Tests.lib.runner")

local START = 1717245356

local function member(name, rankIndex, rankName, realm, overrides)
    overrides = overrides or {}
    realm = realm or "Example Realm"
    return {
        identity = overrides.identity or names.identity(name, realm),
        name = name,
        realm = realm,
        displayName = overrides.displayName or name .. "-" .. realm,
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
        test.assert_equal(
            state.observation.members[1].displayName,
            "Alpha-Example Realm"
        )
        test.assert_nil(state.observation.members[1].name)
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

    test.case("stored opaque identity and display labels drive transitions", function()
        local opaqueIdentity = "Opaque:Retail:Alpha"
        local state = advance(nil, 0, {
            member("Alpha", 2, "Member", "Area-52", {
                identity = opaqueIdentity,
                displayName = "Alpha of Area 52",
            }),
        })
        state = advance(state, 1, {
            member("Renamed", 2, "Member", "Other-Realm", {
                identity = opaqueIdentity,
                displayName = "Renamed Display Label",
            }),
        })
        test.assert_false(state.created)
        test.assert_equal(
            state.observation.members[1].displayName,
            "Renamed Display Label"
        )

        state = advance(state, 2, {
            member("Renamed", 2, "Member", "Other-Realm", {
                identity = "Opaque:Retail:Different",
                displayName = "Renamed Display Label",
            }),
        })
        test.assert_true(state.created)
        test.assert_equal(
            state.newsSets[1].joiningMembers,
            { "Renamed Display Label" }
        )
        test.assert_equal(
            state.newsSets[1].leavingMembers,
            { "Renamed Display Label" }
        )
    end),

    test.case("same-first Forever identities stay distinct through news", function()
        local ashIdentity = "RGMS:CHARACTER:FOREVER:1:2:US:9:Avery Ash"
        local birchIdentity = "RGMS:CHARACTER:FOREVER:1:2:US:11:Avery Birch"
        local state = advance(nil, 0, {
            member("Avery Ash", 2, "Member", nil, {
                identity = ashIdentity,
                displayName = "Avery Ash",
            }),
            member("Avery Birch", 2, "Member", nil, {
                identity = birchIdentity,
                displayName = "Avery Birch",
            }),
        })

        state = advance(state, 1, {
            member("Avery Ash", 1, "Officer", nil, {
                identity = ashIdentity,
                displayName = "Avery Ash",
            }),
        })

        test.assert_equal(state.newsSets[1].joiningMembers, {})
        test.assert_equal(state.newsSets[1].leavingMembers, { "Avery Birch" })
        test.assert_equal(state.newsSets[1].rankChanges, {
            { name = "Avery Ash", rankName = "Officer" },
        })
    end),

    test.case("duplicate opaque identities are rejected without overwriting", function()
        local duplicate = "Opaque:Duplicate"
        local current, currentError = news.process(nil, {}, snapshot(0, {
            member("First", 2, "Member", nil, {
                identity = duplicate,
                displayName = "First Label",
            }),
            member("Second", 2, "Member", nil, {
                identity = duplicate,
                displayName = "Second Label",
            }),
        }), dateTime)

        test.assert_nil(current)
        test.assert_equal(
            currentError,
            "completed roster observation contains duplicate member Opaque:Duplicate"
        )

        local state = advance(nil, 0, { member("Alpha") })
        state.observation.members[2] = {
            identity = state.observation.members[1].identity,
            displayName = "Conflicting historical label",
            rankIndex = 2,
            rankName = "Member",
        }
        local previous, previousError = news.process(
            state.observation,
            state.newsSets,
            snapshot(1, { member("Alpha") }),
            dateTime
        )

        test.assert_nil(previous)
        test.assert_equal(
            previousError,
            "previous roster observation contains duplicate member alpha-example realm"
        )
        test.assert_equal(
            state.observation.members[2].displayName,
            "Conflicting historical label"
        )
    end),

    test.case("retained historical news labels remain immutable display records", function()
        local state = advance(nil, 0, { member("Alpha") })
        state.newsSets = {
            {
                id = "historical",
                createdDate = "2024-06-01",
                joiningMembers = { "Saved Join Label" },
                leavingMembers = { "Saved Leave Label" },
                rankChanges = {
                    { name = "Saved Rank Label", rankName = "Old Rank" },
                },
            },
        }

        local nextState = advance(state, 1, { member("Alpha") })

        test.assert_equal(nextState.newsSets, state.newsSets)
        test.assert_false(nextState.newsSets[1] == state.newsSets[1])
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
