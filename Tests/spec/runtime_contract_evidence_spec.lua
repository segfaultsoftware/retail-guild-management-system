local test = require("Tests.lib.runner")
local fixtureLoader = require("Tests.runtime_contract_fixtures")

local RETAIL_PATH = "Tests/fixtures/runtime_contract/retail.lua"
local FOREVER_PATH = "Tests/fixtures/runtime_contract/forever.lua"
local FOREVER_SAME_FIRST_PATH =
    "Tests/fixtures/runtime_contract/forever_same_first.lua"

local retail = assert(fixtureLoader.load(RETAIL_PATH))
local forever = assert(fixtureLoader.load(FOREVER_PATH))
local foreverSameFirst = assert(fixtureLoader.load(FOREVER_SAME_FIRST_PATH))

local function memberMap(observation)
    local result = {}
    for _, member in ipairs(observation.members) do
        if member.availability.name and member.availability.guid then
            result[member.name] = member.guid
        end
    end
    return result
end

local function guidNameMap(observation)
    local result = {}
    for _, member in ipairs(observation.members) do
        if member.availability.name and member.availability.guid then
            result[member.guid] = member.name
        end
    end
    return result
end

local function keyCount(value)
    local count = 0
    for _ in pairs(value) do
        count = count + 1
    end
    return count
end

local function keySet(value)
    local result = {}
    for key in pairs(value) do
        result[key] = true
    end
    return result
end

local function assertUniqueCompleteMapping(observation, expectedCount)
    local byName = {}
    local byGuid = {}
    test.assert_equal(#observation.members, expectedCount)
    for _, member in ipairs(observation.members) do
        test.assert_true(member.availability.name)
        test.assert_true(member.availability.guid)
        test.assert_nil(byName[member.name])
        test.assert_nil(byGuid[member.guid])
        byName[member.name] = member.guid
        byGuid[member.guid] = member.name
    end
    test.assert_equal(keyCount(byName), expectedCount)
    test.assert_equal(keyCount(byGuid), expectedCount)
    return byName, byGuid
end

local function isConverged(observation)
    local memberCount = observation.guild.memberCount
    local listCount = observation.memberListCount
    local rosterCount = observation.guildRosterMemberCount
    if observation.memberSource ~= "club"
        or observation.guild.clubId == nil
        or memberCount == nil
        or listCount == nil
        or rosterCount == nil
        or memberCount ~= listCount
        or listCount ~= rosterCount
        or #observation.members ~= listCount then
        return false
    end

    for _, member in ipairs(observation.members) do
        if not member.availability.name or not member.availability.guid then
            return false
        end
    end
    return true
end

local function convergedObservations(export)
    local result = {}
    for _, session in ipairs(export.sessions) do
        for _, observation in ipairs(session.observations) do
            if isConverged(observation) then
                result[#result + 1] = observation
            end
        end
    end
    return result
end

local function firstConverged(session)
    for index, observation in ipairs(session.observations) do
        if isConverged(observation) then
            return observation, index
        end
    end
    return nil
end

local function eventExists(session, name, canRequestRosterUpdate)
    for _, event in ipairs(session.events) do
        if event.name == name
            and (canRequestRosterUpdate == nil
                or event.canRequestRosterUpdate == canRequestRosterUpdate) then
            return true
        end
    end
    return false
end

local function firstObservationFromSource(session, source, expectedCount)
    for index, observation in ipairs(session.observations) do
        if observation.memberSource == source
            and #observation.members == expectedCount then
            return observation, index
        end
    end
    return nil
end

local function errorCounts(export)
    local result = {}
    local function add(errors)
        for _, code in ipairs(errors) do
            result[code] = (result[code] or 0) + 1
        end
    end

    for _, session in ipairs(export.sessions) do
        add(session.runtime.errors)
        for _, observation in ipairs(session.observations) do
            add(observation.errors)
        end
    end
    return result
end

local function assertStableConvergedMembers(export, expectedCount)
    local observations = convergedObservations(export)
    test.assert_true(#observations > 0)
    local expected, expectedByGuid =
        assertUniqueCompleteMapping(observations[1], expectedCount)

    for _, observation in ipairs(observations) do
        local actual, actualByGuid =
            assertUniqueCompleteMapping(observation, expectedCount)
        test.assert_equal(actual, expected)
        test.assert_equal(actualByGuid, expectedByGuid)
        for _, code in ipairs(observation.errors) do
            test.assert_equal(code, "GET_GUILD_ROSTER_INFO_INCOMPLETE")
        end
        test.assert_equal(observation.guild.clubId, "Club-001")
        test.assert_equal(observation.guild.name, "Guild-001")
    end
    return expected, #observations
end

local function multipleNamesPerGuid(export)
    local guidNames = {}
    for _, session in ipairs(export.sessions) do
        for _, observation in ipairs(session.observations) do
            for _, member in ipairs(observation.members) do
                if member.name and member.guid then
                    guidNames[member.guid] = guidNames[member.guid] or {}
                    guidNames[member.guid][member.name] = true
                end
            end
        end
    end

    local multiple = 0
    for _, names in pairs(guidNames) do
        local count = 0
        for _ in pairs(names) do
            count = count + 1
        end
        if count > 1 then
            multiple = multiple + 1
        end
    end
    return multiple
end

local function sameFirstNameGroups(export)
    local groups = {}
    for _, session in ipairs(export.sessions) do
        for _, observation in ipairs(session.observations) do
            for _, member in ipairs(observation.members) do
                local first = member.availability.name
                    and member.name:match("^(First%-%d+)")
                if first then
                    groups[first] = groups[first] or {}
                    groups[first][member.name] = true
                end
            end
        end
    end

    local matches = 0
    for _, names in pairs(groups) do
        local count = 0
        for _ in pairs(names) do
            count = count + 1
        end
        if count > 1 then
            matches = matches + 1
        end
    end
    return matches
end

return {
    test.case("captured Retail and Forever fixtures retain exact runtime metadata", function()
        test.assert_true(retail.complete)
        test.assert_false(retail.truncated)
        test.assert_equal(#retail.sessions, 4)
        test.assert_equal({
            retail.sessions[1].boundary,
            retail.sessions[2].boundary,
            retail.sessions[3].boundary,
            retail.sessions[4].boundary,
        }, { "initial", "reload", "logout-login", "cold-restart" })
        for _, session in ipairs(retail.sessions) do
            test.assert_equal(session.runtime.productId, 1)
            test.assert_equal(session.runtime.version, "12.1.5")
            test.assert_equal(session.runtime.build, "70783")
            test.assert_equal(session.runtime.interface, 120105)
            test.assert_equal(session.runtime.region, "US")
        end

        test.assert_true(forever.complete)
        test.assert_false(forever.truncated)
        test.assert_equal(#forever.sessions, 5)
        test.assert_equal({
            forever.sessions[1].boundary,
            forever.sessions[2].boundary,
            forever.sessions[3].boundary,
            forever.sessions[4].boundary,
            forever.sessions[5].boundary,
        }, {
            "initial", "reload", "logout-login", "cold-restart", "initial",
        })
        for _, session in ipairs(forever.sessions) do
            test.assert_equal(session.runtime.productId, 18)
            test.assert_equal(session.runtime.version, "1.60.1")
            test.assert_equal(session.runtime.build, "70888")
            test.assert_equal(session.runtime.interface, 16001)
            test.assert_equal(session.runtime.region, "US")
        end

        test.assert_true(foreverSameFirst.complete)
        test.assert_false(foreverSameFirst.truncated)
        test.assert_equal(#foreverSameFirst.sessions, 2)
        test.assert_equal({
            foreverSameFirst.sessions[1].boundary,
            foreverSameFirst.sessions[2].boundary,
        }, { "initial", "reload" })
        for _, session in ipairs(foreverSameFirst.sessions) do
            test.assert_equal(session.runtime.productId, 18)
            test.assert_equal(session.runtime.version, "1.60.1")
            test.assert_equal(session.runtime.build, "70888")
            test.assert_equal(session.runtime.interface, 16001)
            test.assert_equal(session.runtime.region, "US")
        end
    end),

    test.case("converged guild and member aliases remain stable across every boundary", function()
        local retailMembers, retailObservationCount =
            assertStableConvergedMembers(retail, 652)
        local foreverMembers, foreverObservationCount =
            assertStableConvergedMembers(forever, 56)
        local sameFirstMembers, sameFirstObservationCount =
            assertStableConvergedMembers(foreverSameFirst, 57)

        test.assert_equal(retailObservationCount, 36)
        test.assert_equal(foreverObservationCount, 38)
        test.assert_equal(sameFirstObservationCount, 30)
        test.assert_equal(retailMembers["Member-001"], "Guid-286")
        test.assert_equal(
            foreverMembers["First-001 Surname-001"],
            "Guid-047"
        )
        test.assert_equal(
            sameFirstMembers["First-001 Surname-001"],
            "Guid-047"
        )

        for sessionIndex = 1, #retail.sessions do
            test.assert_not_nil(firstConverged(retail.sessions[sessionIndex]))
        end
        for sessionIndex = 1, #forever.sessions do
            test.assert_not_nil(firstConverged(forever.sessions[sessionIndex]))
        end
        for sessionIndex = 1, #foreverSameFirst.sessions do
            test.assert_not_nil(firstConverged(
                foreverSameFirst.sessions[sessionIndex]
            ))
        end
    end),

    test.case("captured startup streams wait for club convergence", function()
        for _, sessionIndex in ipairs({ 3, 4 }) do
            local retailSession = retail.sessions[sessionIndex]
            local first = retailSession.observations[1]
            test.assert_nil(first.guild.clubId)
            test.assert_equal(first.guildRosterMemberCount, 0)
            test.assert_true(eventExists(
                retailSession,
                "GUILD_ROSTER_UPDATE",
                true
            ))

            local partial = retailSession.observations[10]
            test.assert_equal(partial.trigger, "GUILD_ROSTER_UPDATE")
            test.assert_equal(partial.guild.memberCount, 101)
            test.assert_equal(partial.memberListCount, 652)
            test.assert_equal(#partial.members, 652)
            test.assert_equal(
                retailSession.observations[11].trigger,
                "CLUB_MEMBERS_UPDATED"
            )
            test.assert_true(isConverged(retailSession.observations[11]))

        end

        local expectedForeverConvergence = {
            [3] = { index = 11, trigger = "GUILD_ROSTER_UPDATE" },
            [4] = { index = 10, trigger = "GUILD_ROSTER_UPDATE" },
            [5] = { index = 9, trigger = "CLUB_MEMBERS_UPDATED" },
        }
        for sessionIndex = 3, 5 do
            local foreverSession = forever.sessions[sessionIndex]
            local first = foreverSession.observations[1]
            test.assert_nil(first.guild.clubId)
            test.assert_equal(first.guildRosterMemberCount, 0)
            test.assert_true(eventExists(
                foreverSession,
                "GUILD_ROSTER_UPDATE"
            ))
            if sessionIndex < 5 then
                test.assert_true(eventExists(
                    foreverSession,
                    "GUILD_ROSTER_UPDATE",
                    true
                ))
            end

            local fallback, fallbackIndex = firstObservationFromSource(
                foreverSession,
                "guild-roster",
                56
            )
            local converged, convergedIndex = firstConverged(foreverSession)
            test.assert_not_nil(fallback)
            test.assert_not_nil(converged)
            test.assert_true(fallbackIndex < convergedIndex)
            test.assert_equal(memberMap(fallback), memberMap(converged))
            test.assert_equal(guidNameMap(fallback), guidNameMap(converged))
            test.assert_equal(
                convergedIndex,
                expectedForeverConvergence[sessionIndex].index
            )
            test.assert_equal(
                converged.trigger,
                expectedForeverConvergence[sessionIndex].trigger
            )
        end
    end),

    test.case("realm observations prohibit Forever realm-based identity", function()
        test.assert_equal(retail.sessions[1].runtime.realmName, "Realm-001")
        test.assert_equal(
            retail.sessions[1].runtime.normalizedRealmName,
            retail.sessions[1].runtime.playerRealm
        )
        test.assert_equal(retail.sessions[1].runtime.playerRealm, "Realm-002")
        test.assert_false(
            retail.sessions[3].runtime.availability.normalizedRealmName
        )

        for _, session in ipairs(forever.sessions) do
            test.assert_equal(session.runtime.realmName, "Realm-001")
            test.assert_equal(session.runtime.playerRealm, "Realm-003")
            test.assert_true(
                session.runtime.realmName ~= session.runtime.playerRealm
            )
            for _, observation in ipairs(session.observations) do
                test.assert_false(observation.guild.availability.realm)
            end
        end
        test.assert_equal(
            forever.sessions[1].runtime.normalizedRealmName,
            "Realm-002"
        )
        test.assert_false(
            forever.sessions[3].runtime.availability.normalizedRealmName
        )
    end),

    test.case("captured unavailability errors remain explicit", function()
        local retailErrors = errorCounts(retail)
        test.assert_equal(retailErrors, {
            GET_GUILD_CLUB_ID_UNAVAILABLE = 18,
            GET_GUILD_ROSTER_INFO_INCOMPLETE = 8,
            GET_NORMALIZED_REALM_NAME_UNAVAILABLE = 2,
        })

        local foreverErrors = errorCounts(forever)
        test.assert_equal(foreverErrors, {
            GET_GUILD_CLUB_ID_UNAVAILABLE = 29,
            GET_GUILD_ROSTER_INFO_INCOMPLETE = 6,
            GET_NORMALIZED_REALM_NAME_UNAVAILABLE = 3,
        })
        test.assert_equal(errorCounts(foreverSameFirst), {})
    end),

    test.case("GUID evidence is correlation metadata and partial names are not canonical", function()
        test.assert_equal(multipleNamesPerGuid(retail), 42)
        test.assert_equal(multipleNamesPerGuid(forever), 0)

        for _, sessionIndex in ipairs({ 3, 4 }) do
            local partial = guidNameMap(
                retail.sessions[sessionIndex].observations[10]
            )
            local converged = guidNameMap(
                retail.sessions[sessionIndex].observations[11]
            )
            test.assert_equal(keyCount(partial), 652)
            test.assert_equal(keyCount(converged), 652)
            test.assert_equal(keySet(partial), keySet(converged))
            local changed = 0
            for guid, name in pairs(partial) do
                if converged[guid] ~= name then
                    changed = changed + 1
                end
            end
            test.assert_equal(changed, 42)
        end
    end),

    test.case("combined Forever evidence composes boundary stability and same-first distinguishability", function()
        local boundaries = {}
        for _, session in ipairs(forever.sessions) do
            boundaries[session.boundary] = true
        end
        test.assert_true(boundaries.initial)
        test.assert_true(boundaries.reload)
        test.assert_true(boundaries["logout-login"])
        test.assert_true(boundaries["cold-restart"])

        local baseRuntime = forever.sessions[1].runtime
        local supplementalRuntime = foreverSameFirst.sessions[1].runtime
        for _, field in ipairs({
            "productId", "version", "build", "interface", "region",
        }) do
            test.assert_equal(supplementalRuntime[field], baseRuntime[field])
        end

        test.assert_equal(sameFirstNameGroups(forever), 0)
        test.assert_equal(sameFirstNameGroups(foreverSameFirst), 1)

        local firstA, surnameA =
            ("First-048 Surname-042"):match(
                "^(First%-%d+) (Surname%-%d+)$"
            )
        local firstB, surnameB =
            ("First-048 Surname-043"):match(
                "^(First%-%d+) (Surname%-%d+)$"
            )
        test.assert_equal(firstA, firstB)
        test.assert_true(surnameA ~= surnameB)

        for _, session in ipairs(foreverSameFirst.sessions) do
            local converged = firstConverged(session)
            test.assert_not_nil(converged)
            local members = memberMap(converged)
            test.assert_equal(
                members["First-048 Surname-042"],
                "Guid-048"
            )
            test.assert_equal(
                members["First-048 Surname-043"],
                "Guid-049"
            )
            test.assert_true(
                members["First-048 Surname-042"]
                    ~= members["First-048 Surname-043"]
            )
        end
    end),
}
