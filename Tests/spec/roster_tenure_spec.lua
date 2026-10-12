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
    member.lastSeenDate = nil
    member.isMissing = nil

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

local function emptySnapshot(unixSeconds, ranks)
    local scannedAt = dateTime.utcTimestamp(unixSeconds)
    return {
        guild = fixtures.guild_identity(),
        scannedAt = scannedAt,
        ranks = ranks or { fixtures.roster_rank() },
        members = {},
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

    test.case("first absence retains and marks the member under the current rank", function()
        local first = reduce(
            emptyDataset(),
            completedSnapshot(dateFixtures.pacificMidnight.after)
        )
        local absent = reduce(
            first,
            emptySnapshot(dateFixtures.pacificMidnight.after + 24 * 60 * 60)
        )
        local member = absent.members[1]

        test.assert_equal(#absent.members, 1)
        test.assert_true(member.isMissing)
        test.assert_equal(member.lastSeenDate, "2024-06-01")
        test.assert_equal(member.rankName, "Officer")
        test.assert_equal(member.rankTenureStartDate, "2024-06-01")
        test.assert_equal(member.observedAt, first.members[1].observedAt)
        test.assert_equal(member.lastOnline.days, 3)
        test.assert_equal(member.lastOnline.hours, 3)
        test.assert_false(first.members[1].isMissing)
    end),

    test.case("missing members are retained at day 21 and removed on day 22", function()
        local startedAt = dateFixtures.pacificMidnight.after
        local first = reduce(emptyDataset(), completedSnapshot(startedAt))
        local firstAbsence = reduce(first, emptySnapshot(startedAt + 24 * 60 * 60))
        local day21 = reduce(firstAbsence, emptySnapshot(
            startedAt + 21 * 24 * 60 * 60
        ))
        local day22 = reduce(day21, emptySnapshot(
            startedAt + 22 * 24 * 60 * 60
        ))

        test.assert_equal(#day21.members, 1)
        test.assert_true(day21.members[1].isMissing)
        test.assert_equal(day21.members[1].lastOnline.days, 23)
        test.assert_equal(#day22.members, 0)
    end),

    test.case("scan gaps and Pacific midnight carry online age by calendar date", function()
        local currentSnapshot = completedSnapshot(dateFixtures.pacificMidnight.before)
        currentSnapshot.members[1].isOnline = true
        currentSnapshot.members[1].lastOnline = nil
        local first = reduce(emptyDataset(), currentSnapshot)
        local missing = reduce(
            first,
            emptySnapshot(dateFixtures.pacificMidnight.after)
        )

        test.assert_true(missing.members[1].isMissing)
        test.assert_false(missing.members[1].isOnline)
        test.assert_equal(missing.members[1].lastSeenDate, "2024-05-31")
        test.assert_equal(missing.members[1].lastOnline, {
            years = 0,
            months = 0,
            days = 1,
            hours = 0,
        })

        local afterGap = reduce(missing, emptySnapshot(
            dateFixtures.pacificMidnight.after + 4 * 24 * 60 * 60
        ))
        test.assert_equal(afterGap.members[1].lastOnline.days, 5)
        test.assert_equal(afterGap.members[1].lastSeenDate, "2024-05-31")
    end),

    test.case("reappearance resets tenure at the same or a different rank", function()
        for _, rankIndex in ipairs({ 1, 2 }) do
            local startedAt = dateFixtures.pacificMidnight.after
            local first = reduce(emptyDataset(), completedSnapshot(startedAt))
            local missing = reduce(first, emptySnapshot(startedAt + 24 * 60 * 60))
            local rankName = rankIndex == 1 and "Officer" or "Member"
            local returned = reduce(missing, completedSnapshot(
                startedAt + 2 * 24 * 60 * 60,
                { rankIndex = rankIndex, rankName = rankName }
            ))
            local member = returned.members[1]

            test.assert_false(member.isMissing)
            test.assert_equal(member.lastSeenDate, "2024-06-03")
            test.assert_equal(member.rankIndex, rankIndex)
            test.assert_equal(member.rankTenureStartDate, "2024-06-03")
        end
    end),

    test.case("removing a rank removes its retained missing members", function()
        local startedAt = dateFixtures.pacificMidnight.after
        local first = reduce(emptyDataset(), completedSnapshot(startedAt, {
            rankIndex = 2,
            rankName = "Member",
        }))
        local withoutFormerRank = reduce(first, emptySnapshot(
            startedAt + 24 * 60 * 60,
            { fixtures.roster_rank({ index = 1, name = "Officer" }) }
        ))

        test.assert_equal(#withoutFormerRank.members, 0)
    end),

    test.case("current members remain regardless of old last-online values", function()
        local startedAt = dateFixtures.pacificMidnight.after
        local firstSnapshot = completedSnapshot(startedAt)
        firstSnapshot.members[1].lastOnline = {
            years = 9,
            months = 11,
            days = 30,
            hours = 23,
        }
        local first = reduce(emptyDataset(), firstSnapshot)
        local currentSnapshot = completedSnapshot(startedAt + 22 * 24 * 60 * 60)
        currentSnapshot.members[1].lastOnline = {
            years = 10,
            months = 0,
            days = 0,
            hours = 0,
        }
        local current = reduce(first, currentSnapshot)

        test.assert_equal(#current.members, 1)
        test.assert_false(current.members[1].isMissing)
        test.assert_equal(current.members[1].lastOnline.years, 10)
        test.assert_equal(current.members[1].rankTenureStartDate, "2024-06-01")
    end),

    test.case("a current member with a repeated realm suffix reconciles canonically", function()
        local startedAt = dateFixtures.pacificMidnight.after
        local previous = reduce(emptyDataset(), completedSnapshot(startedAt))
        previous.members[1].realm = "Example Realm-Example Realm-Example Realm"
        previous.members[1].displayName = previous.members[1].name
            .. "-"
            .. previous.members[1].realm

        local current = reduce(
            previous,
            completedSnapshot(startedAt + 24 * 60 * 60)
        )

        test.assert_equal(#current.members, 1)
        test.assert_equal(current.members[1].realm, "Example Realm")
        test.assert_equal(
            current.members[1].displayName,
            "Aeloria-Example Realm"
        )
        test.assert_equal(current.members[1].rankTenureStartDate, "2024-06-01")
        test.assert_false(current.members[1].isMissing)
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
