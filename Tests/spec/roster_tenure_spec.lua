local dateFixtures = require("Tests.date_fixtures")
local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local tenure = require("Roster.Tenure")
local test = require("Tests.lib.runner")

local function completedSnapshot(unixSeconds, options)
    options = options or {}
    local observedAt = dateTime.utcTimestamp(unixSeconds)
    local realm = options.realm or "Example Realm"
    local name = options.name or "Aeloria"
    local rankIndex = options.rankIndex or 1
    local rankName = options.rankName or "Officer"
    local member = fixtures.roster_member({
        name = name,
        realm = realm,
        displayName = name .. "-" .. realm,
        rankName = rankName,
        rankIndex = rankIndex,
        observedAt = observedAt,
    })
    member.rankTenureStartDate = nil

    return {
        guild = fixtures.guild_identity(),
        scannedAt = observedAt,
        ranks = {
            fixtures.roster_rank({
                index = rankIndex,
                name = rankName,
            }),
        },
        members = { member },
    }
end

local function emptyDataset()
    return {
        guild = fixtures.guild_identity(),
        ranks = {},
        members = {},
    }
end

local function reduce(previous, snapshot)
    local result, reduceError = tenure.reduce(previous, snapshot, dateTime)
    test.assert_not_nil(result, reduceError)
    return result
end

return {
    test.case("first observation starts rank tenure at zero", function()
        local snapshot = completedSnapshot(dateFixtures.pacificMidnight.after)
        local first = reduce(emptyDataset(), snapshot)

        test.assert_equal(first.members[1].rankTenureStartDate, "2024-06-01")
        test.assert_equal(
            tenure.daysSince(
                first.members[1].rankTenureStartDate,
                "2024-06-01",
                dateTime
            ),
            0
        )
        test.assert_nil(snapshot.members[1].rankTenureStartDate)
        test.assert_equal(first, reduce(emptyDataset(), snapshot))
    end),

    test.case("same-day rescans replace observations without adding tenure", function()
        local first = reduce(
            emptyDataset(),
            completedSnapshot(dateFixtures.pacificMidnight.after)
        )
        local sameDay = reduce(
            first,
            completedSnapshot(dateFixtures.pacificMidnight.after + 20 * 60 * 60)
        )

        test.assert_equal(sameDay.members[1].rankTenureStartDate, "2024-06-01")
        test.assert_equal(sameDay.scannedAt.unixSeconds, 1717297200)
        test.assert_equal(
            tenure.daysSince("2024-06-01", "2024-06-01", dateTime),
            0
        )
    end),

    test.case("multi-day gaps carry rank tenure forward", function()
        local first = reduce(
            emptyDataset(),
            completedSnapshot(dateFixtures.pacificMidnight.after)
        )
        local afterGap = reduce(
            first,
            completedSnapshot(dateFixtures.pacificMidnight.after + 3 * 24 * 60 * 60)
        )

        test.assert_equal(afterGap.members[1].rankTenureStartDate, "2024-06-01")
        test.assert_equal(
            tenure.daysSince("2024-06-01", "2024-06-04", dateTime),
            3
        )
    end),

    test.case("rank rename at the same index preserves tenure", function()
        local first = reduce(
            emptyDataset(),
            completedSnapshot(dateFixtures.pacificMidnight.after, {
                rankIndex = 4,
                rankName = "Raider",
            })
        )
        local renamed = reduce(
            first,
            completedSnapshot(dateFixtures.pacificMidnight.after + 2 * 24 * 60 * 60, {
                rankIndex = 4,
                rankName = "Core Raider",
            })
        )

        test.assert_equal(renamed.members[1].rankName, "Core Raider")
        test.assert_equal(renamed.members[1].rankTenureStartDate, "2024-06-01")
    end),

    test.case("promotion and demotion each reset tenure on the observation date", function()
        local first = reduce(
            emptyDataset(),
            completedSnapshot(dateFixtures.pacificMidnight.after, { rankIndex = 3 })
        )
        local promoted = reduce(
            first,
            completedSnapshot(dateFixtures.pacificMidnight.after + 24 * 60 * 60, {
                rankIndex = 2,
                rankName = "Raider",
            })
        )
        local demoted = reduce(
            promoted,
            completedSnapshot(dateFixtures.pacificMidnight.after + 2 * 24 * 60 * 60, {
                rankIndex = 3,
                rankName = "Member",
            })
        )

        test.assert_equal(promoted.members[1].rankTenureStartDate, "2024-06-02")
        test.assert_equal(demoted.members[1].rankTenureStartDate, "2024-06-03")
    end),

    test.case("displayed Name-Realm is the only member identity", function()
        local first = reduce(
            emptyDataset(),
            completedSnapshot(dateFixtures.pacificMidnight.after)
        )
        local transferred = reduce(
            first,
            completedSnapshot(dateFixtures.pacificMidnight.after + 24 * 60 * 60, {
                realm = "Other Realm",
            })
        )

        test.assert_equal(transferred.members[1].displayName, "Aeloria-Other Realm")
        test.assert_equal(transferred.members[1].rankTenureStartDate, "2024-06-02")
    end),

    test.case("year boundary tenure uses Pacific calendar dates", function()
        local januaryFirst = 1735718400 -- 2025-01-01 00:00:00 PST
        local first = reduce(
            emptyDataset(),
            completedSnapshot(januaryFirst - 24 * 60 * 60)
        )
        local nextYear = reduce(first, completedSnapshot(januaryFirst))

        test.assert_equal(nextYear.members[1].rankTenureStartDate, "2024-12-31")
        test.assert_equal(
            tenure.daysSince("2024-12-31", "2025-01-01", dateTime),
            1
        )
    end),

    test.case("DST boundaries each add one Pacific tenure day", function()
        local transitions = {
            dateFixtures.springForward,
            dateFixtures.fallBack,
        }

        for _, transition in ipairs(transitions) do
            local first = reduce(
                emptyDataset(),
                completedSnapshot(transition.firstMidnight)
            )
            local nextDay = reduce(
                first,
                completedSnapshot(transition.nextMidnight)
            )
            local currentDate = dateTime.currentPacificDate(
                transition.nextMidnight
            )

            test.assert_equal(
                tenure.daysSince(
                    nextDay.members[1].rankTenureStartDate,
                    currentDate,
                    dateTime
                ),
                1
            )
        end
    end),

    test.case("tenure days clamp reversed dates to zero", function()
        test.assert_equal(
            tenure.daysSince("2024-06-02", "2024-06-01", dateTime),
            0
        )

        local days, dateError = tenure.daysSince(
            "not-a-date",
            "2024-06-01",
            dateTime
        )
        test.assert_nil(days)
        test.assert_matches(dateError, "invalid earlier date")
    end),
}
