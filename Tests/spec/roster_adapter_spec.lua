local characterIdentity = require("Core.CharacterIdentity")
local clientFlavor = require("Core.ClientFlavor")
local dateTime = require("Core.DateTime")
local guildIdentity = require("Core.GuildIdentity")
local names = require("Roster.Names")
local test = require("Tests.lib.runner")

local GLOBAL_NAMES = {
    "C_Club",
    "C_CreatureInfo",
    "C_GuildInfo",
    "Enum",
    "GetCurrentRegion",
    "GetGuildInfo",
    "GetNormalizedRealmName",
    "GetRealmName",
    "GetServerTime",
    "GuildControlGetNumRanks",
    "GuildControlGetRankName",
    "IsInGuild",
}

local function withModernStubs(options, callback)
    options = options or {}
    local previous = {}
    for _, name in ipairs(GLOBAL_NAMES) do
        previous[name] = _G[name]
    end

    local flavor = options.flavor or clientFlavor.RETAIL
    local requested = 0
    local memberCount = 2
    local guildRealm = "ExampleRealm"
    local guildIdentityResolutions = 0
    local realmApiCalls = 0
    local memberNames = flavor == clientFlavor.FOREVER
        and {
            [101] = "First-048 Surname-043",
            [202] = "First-048 Surname-042",
        }
        or {
            [101] = "Zed-OtherRealm",
            [202] = "Ada",
        }
    C_GuildInfo = {
        GuildRoster = function()
            requested = requested + 1
        end,
    }
    if options.rankFlagsAvailable ~= false then
        C_GuildInfo.GuildControlGetRankFlags = function(rankOrder)
            if rankOrder == 1 then
                return {
                    [5] = true,
                    [7] = true,
                    [22] = true,
                }
            end
            if rankOrder == 2 then
                return { [5] = true }
            end
            return {}
        end
    end
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
                    name = memberNames[memberId],
                    guid = flavor == clientFlavor.FOREVER
                        and "Guid-049"
                        or "Player-0000-00000101",
                    guildRank = "Guild Master",
                    guildRankOrder = 1,
                    role = 1,
                    level = 80,
                    classID = 1,
                }
            end
            return {
                name = memberNames[memberId],
                guid = flavor == clientFlavor.FOREVER
                    and "Guid-048"
                    or "Player-0000-00000202",
                guildRank = "Member",
                guildRankOrder = 2,
                role = 2,
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
    Enum = {
        ClubRoleIdentifier = {
            Owner = 1,
            Moderator = 2,
            Leader = 3,
        },
    }
    IsInGuild = function()
        return true
    end
    GetGuildInfo = function()
        if flavor == clientFlavor.FOREVER then
            error("Forever adapter must obtain guild identity from the resolver")
        end
        return "Example Guild", nil, nil, guildRealm
    end
    GetNormalizedRealmName = function()
        realmApiCalls = realmApiCalls + 1
        if flavor == clientFlavor.FOREVER then
            error("Forever adapter must not read a normalized realm")
        end
        return "ExampleRealm"
    end
    GetRealmName = function()
        realmApiCalls = realmApiCalls + 1
        if flavor == clientFlavor.FOREVER then
            error("Forever adapter must not read a display realm")
        end
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

    local function resolveGuildIdentity()
        guildIdentityResolutions = guildIdentityResolutions + 1
        if options.guildIdentity ~= nil then
            return options.guildIdentity
        end
        if flavor == clientFlavor.FOREVER then
            return guildIdentity.create({
                flavor = clientFlavor.FOREVER,
                region = "US",
                name = "Example Guild",
                clubId = 42,
            })
        end
        return guildIdentity.create({
            flavor = clientFlavor.RETAIL,
            region = "US",
            name = "Example Guild",
            realm = {
                name = guildRealm,
                slug = guildRealm,
            },
        })
    end

    local rgms = {
        CharacterIdentity = characterIdentity,
        ClientFlavor = {
            RETAIL = clientFlavor.RETAIL,
            FOREVER = clientFlavor.FOREVER,
            getFlavor = function()
                return flavor
            end,
        },
        DateTime = dateTime,
        GuildIdentity = guildIdentity,
        ResolveCurrentGuildIdentity = resolveGuildIdentity,
        RosterNames = names,
        Reset = {},
        Print = function() end,
    }
    local chunk = assert(loadfile("Roster/Roster.lua"))
    local roster = chunk("RGMS", rgms)

    local succeeded, callbackError = pcall(function()
        callback({
            api = roster.CreateModernApi(),
            guildIdentityResolutions = function()
                return guildIdentityResolutions
            end,
            realmApiCalls = function()
                return realmApiCalls
            end,
            requested = function()
                return requested
            end,
            setMemberCount = function(value)
                memberCount = value
            end,
            setGuildRealm = function(value)
                guildRealm = value
            end,
            setMemberName = function(memberId, value)
                memberNames[memberId] = value
            end,
        })
    end)

    for _, name in ipairs(GLOBAL_NAMES) do
        _G[name] = previous[name]
    end
    if not succeeded then
        error(callbackError, 0)
    end
end

local function withRetailStubs(callback)
    return withModernStubs({ flavor = clientFlavor.RETAIL }, callback)
end

return {
    test.case("Retail adapter captures complete members ranks and last-online data", function()
        withRetailStubs(function(harness)
            harness.api:requestRoster()
            test.assert_equal(harness.requested(), 1)

            local snapshot = harness.api:captureSnapshot()
            test.assert_true(guildIdentity.validate(snapshot.guild))
            test.assert_equal(snapshot.guild.flavor, clientFlavor.RETAIL)
            test.assert_equal(snapshot.guild.name, "Example Guild")
            test.assert_equal(snapshot.guild.displayName, "Example Guild")
            test.assert_equal(snapshot.guild.realm.slug, "ExampleRealm")
            test.assert_equal(snapshot.guild.region, "US")
            test.assert_nil(snapshot.guild.clubId)
            test.assert_equal(snapshot.scannedAt.iso8601, "2024-06-01T12:34:56Z")
            test.assert_equal(#snapshot.ranks, 3)
            test.assert_equal(snapshot.ranks[3].name, "Empty Rank")
            test.assert_equal(#snapshot.members, 2)
            test.assert_equal(
                snapshot.members[1].identity,
                names.identity("Ada", "ExampleRealm")
            )
            test.assert_equal(snapshot.members[1].displayName, "Ada-ExampleRealm")
            test.assert_equal(snapshot.members[1].rankName, "Member")
            test.assert_equal(snapshot.members[1].rankIndex, 2)
            test.assert_equal(snapshot.members[1].leadershipRole, "officer")
            test.assert_equal(snapshot.members[1].lastOnline, {
                years = 0,
                months = 1,
                days = 2,
                hours = 3,
            })
            test.assert_false(snapshot.members[1].isOnline)
            test.assert_true(snapshot.members[2].isOnline)
            test.assert_equal(snapshot.members[2].leadershipRole, "guild-master")
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

    test.case("Retail adapter canonicalizes truncated repeated guild and member realms", function()
        withRetailStubs(function(harness)
            local corruptedRealm = "Ner'zhul-Ner'zhul-Ner'zhul-Ner'zh"
            harness.setGuildRealm(corruptedRealm)
            harness.setMemberName(101, "Nalla-" .. corruptedRealm)

            local snapshot = assert(harness.api:captureSnapshot())
            local nalla
            for _, member in ipairs(snapshot.members) do
                if member.name == "Nalla" then
                    nalla = member
                end
            end

            test.assert_equal(snapshot.guild.realm.name, "Ner'zhul")
            test.assert_equal(snapshot.guild.realm.slug, "Ner'zhul")
            test.assert_equal(nalla.realm, "Ner'zhul")
            test.assert_equal(nalla.identity, names.identity("Nalla", "Ner'zhul"))
            test.assert_equal(nalla.displayName, "Nalla-Ner'zhul")
        end)
    end),

    test.case("Forever adapter preserves complete same-first names and modern roster fields", function()
        withModernStubs({ flavor = clientFlavor.FOREVER }, function(harness)
            harness.api:requestRoster()
            test.assert_equal(harness.requested(), 1)

            local snapshot = assert(harness.api:captureSnapshot())
            local expectedGuild = assert(guildIdentity.create({
                flavor = clientFlavor.FOREVER,
                region = "US",
                name = "Example Guild",
                clubId = 42,
            }))
            local surname42 = assert(characterIdentity.create({
                flavor = clientFlavor.FOREVER,
                region = "US",
                name = "First-048 Surname-042",
                guid = "Guid-048",
            }))
            local surname43 = assert(characterIdentity.create({
                flavor = clientFlavor.FOREVER,
                region = "US",
                name = "First-048 Surname-043",
                guid = "Guid-049",
            }))

            test.assert_equal(harness.guildIdentityResolutions(), 1)
            test.assert_equal(harness.realmApiCalls(), 0)
            test.assert_equal(snapshot.guild, expectedGuild)
            test.assert_nil(snapshot.guild.realm)
            test.assert_equal(snapshot.scannedAt, {
                unixSeconds = 1717245296,
                iso8601 = "2024-06-01T12:34:56Z",
            })
            test.assert_equal(snapshot.ranks, {
                {
                    index = 1,
                    name = "Guild Master",
                    permissions = {
                        invite = true,
                        remove = true,
                        editOfficerNote = true,
                    },
                },
                {
                    index = 2,
                    name = "Member",
                    permissions = {
                        invite = true,
                        remove = false,
                        editOfficerNote = false,
                    },
                },
                {
                    index = 3,
                    name = "Empty Rank",
                    permissions = {
                        invite = false,
                        remove = false,
                        editOfficerNote = false,
                    },
                },
            })
            test.assert_equal(#snapshot.members, 2)

            local first = snapshot.members[1]
            test.assert_equal(first.identity, surname42.key)
            test.assert_equal(first.guid, "Guid-048")
            test.assert_equal(first.name, "First-048 Surname-042")
            test.assert_nil(first.realm)
            test.assert_equal(first.displayName, "First-048 Surname-042")
            test.assert_equal(first.rankName, "Member")
            test.assert_equal(first.rankIndex, 2)
            test.assert_equal(first.level, 80)
            test.assert_equal(first.classId, 8)
            test.assert_equal(first.classFileName, "MAGE")
            test.assert_equal(first.leadershipRole, "officer")
            test.assert_false(first.isOnline)
            test.assert_equal(first.lastOnline, {
                years = 0,
                months = 1,
                days = 2,
                hours = 3,
            })
            test.assert_equal(first.observedAt, snapshot.scannedAt)

            local second = snapshot.members[2]
            test.assert_equal(second.identity, surname43.key)
            test.assert_equal(second.guid, "Guid-049")
            test.assert_equal(second.name, "First-048 Surname-043")
            test.assert_nil(second.realm)
            test.assert_equal(second.displayName, "First-048 Surname-043")
            test.assert_equal(second.rankName, "Guild Master")
            test.assert_equal(second.rankIndex, 1)
            test.assert_equal(second.level, 80)
            test.assert_equal(second.classId, 1)
            test.assert_equal(second.classFileName, "WARRIOR")
            test.assert_equal(second.leadershipRole, "guild-master")
            test.assert_true(second.isOnline)
            test.assert_nil(second.lastOnline)
            test.assert_equal(second.observedAt, snapshot.scannedAt)
            test.assert_true(first.identity ~= second.identity)
        end)
    end),

    test.case("Forever adapter defaults permissions when the optional rank flags API is absent", function()
        withModernStubs({
            flavor = clientFlavor.FOREVER,
            rankFlagsAvailable = false,
        }, function(harness)
            local snapshot = assert(harness.api:captureSnapshot())

            for _, rank in ipairs(snapshot.ranks) do
                test.assert_equal(rank.permissions, {
                    invite = false,
                    remove = false,
                    editOfficerNote = false,
                })
            end
            test.assert_equal(harness.realmApiCalls(), 0)
        end)
    end),

    test.case("Forever adapter identifies a partial member list without realm parsing", function()
        withModernStubs({ flavor = clientFlavor.FOREVER }, function(harness)
            harness.setMemberCount(3)
            local snapshot, state, message = harness.api:captureSnapshot()

            test.assert_nil(snapshot)
            test.assert_equal(state, "incomplete")
            test.assert_matches(message, "partial")
            test.assert_equal(harness.realmApiCalls(), 0)
        end)
    end),

    test.case("Retail adapter rejects duplicate canonical identities", function()
        withRetailStubs(function(harness)
            harness.setMemberName(101, "Ada-ExampleRealm")
            harness.setMemberName(202, "ADA-examplerealm")

            local snapshot, state, message = harness.api:captureSnapshot()

            test.assert_nil(snapshot)
            test.assert_equal(state, "incomplete")
            test.assert_matches(message, "duplicated")
        end)
    end),
}
