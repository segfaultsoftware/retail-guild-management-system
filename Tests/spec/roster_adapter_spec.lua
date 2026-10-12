local dateTime = require("Core.DateTime")
local test = require("Tests.lib.runner")

local GLOBAL_NAMES = {
    "C_Club",
    "C_CreatureInfo",
    "C_GuildInfo",
    "GetCurrentRegion",
    "GetGuildInfo",
    "GetNormalizedRealmName",
    "GetRealmName",
    "GetServerTime",
    "GuildControlGetNumRanks",
    "GuildControlGetRankName",
    "IsInGuild",
}

local function withRetailStubs(callback)
    local previous = {}
    for _, name in ipairs(GLOBAL_NAMES) do
        previous[name] = _G[name]
    end

    local requested = 0
    local memberCount = 2
    C_GuildInfo = {
        GuildRoster = function()
            requested = requested + 1
        end,
        GuildControlGetRankFlags = function()
            return {}
        end,
    }
    C_Club = {
        GetGuildClubId = function()
            return 42
        end,
        GetClubInfo = function()
            return {
                name = "Example Guild",
                memberCount = memberCount,
            }
        end,
        GetClubMembers = function()
            return { 101, 202 }
        end,
        GetMemberInfo = function(_, memberId)
            if memberId == 101 then
                return {
                    name = "Zed-OtherRealm",
                    guid = "Player-0000-00000101",
                    guildRank = "Guild Master",
                    guildRankOrder = 1,
                    level = 80,
                    classID = 1,
                }
            end
            return {
                name = "Ada",
                guid = "Player-0000-00000202",
                guildRank = "Member",
                guildRankOrder = 2,
                level = 80,
                classID = 8,
                lastOnlineYear = 0,
                lastOnlineMonth = 1,
                lastOnlineDay = 2,
                lastOnlineHour = 3,
            }
        end,
    }
    C_CreatureInfo = {
        GetClassInfo = function(classId)
            return {
                classFile = classId == 1 and "WARRIOR" or "MAGE",
            }
        end,
    }
    IsInGuild = function()
        return true
    end
    GetGuildInfo = function()
        return "Example Guild", nil, nil, "ExampleRealm"
    end
    GetNormalizedRealmName = function()
        return "ExampleRealm"
    end
    GetRealmName = function()
        return "Example Realm"
    end
    GetCurrentRegion = function()
        return 1
    end
    GetServerTime = function()
        return 1717245296
    end
    GuildControlGetNumRanks = function()
        return 3
    end
    GuildControlGetRankName = function(index)
        return ({ "Guild Master", "Member", "Empty Rank" })[index]
    end

    local rgms = {
        DateTime = dateTime,
        Reset = {},
        Print = function() end,
    }
    local chunk = assert(loadfile("Roster/Roster.lua"))
    local roster = chunk("RGMS", rgms)

    local succeeded, callbackError = pcall(callback, {
        api = roster.CreateRetailApi(),
        requested = function()
            return requested
        end,
        setMemberCount = function(value)
            memberCount = value
        end,
    })

    for _, name in ipairs(GLOBAL_NAMES) do
        _G[name] = previous[name]
    end
    if not succeeded then
        error(callbackError, 0)
    end
end

return {
    test.case("Retail adapter captures complete members ranks and last-online data", function()
        withRetailStubs(function(harness)
            harness.api:requestRoster()
            test.assert_equal(harness.requested(), 1)

            local snapshot = harness.api:captureSnapshot()
            test.assert_equal(snapshot.guild.name, "Example Guild")
            test.assert_equal(snapshot.guild.realm.slug, "ExampleRealm")
            test.assert_equal(snapshot.guild.region, "US")
            test.assert_equal(snapshot.scannedAt.iso8601, "2024-06-01T12:34:56Z")
            test.assert_equal(#snapshot.ranks, 3)
            test.assert_equal(snapshot.ranks[3].name, "Empty Rank")
            test.assert_equal(#snapshot.members, 2)
            test.assert_equal(snapshot.members[1].displayName, "Ada-ExampleRealm")
            test.assert_equal(snapshot.members[1].rankName, "Member")
            test.assert_equal(snapshot.members[1].rankIndex, 2)
            test.assert_equal(snapshot.members[1].lastOnline, {
                years = 0,
                months = 1,
                days = 2,
                hours = 3,
            })
            test.assert_false(snapshot.members[1].isOnline)
            test.assert_true(snapshot.members[2].isOnline)
            test.assert_nil(snapshot.members[2].lastOnline)
        end)
    end),

    test.case("Retail adapter identifies a partial member list", function()
        withRetailStubs(function(harness)
            harness.setMemberCount(3)
            local snapshot, state, message = harness.api:captureSnapshot()

            test.assert_nil(snapshot)
            test.assert_equal(state, "incomplete")
            test.assert_matches(message, "partial")
        end)
    end),
}
