local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local report = require("Roster.Report")
local test = require("Tests.lib.runner")

local CURRENT_DATE = "2024-06-01"

local function member(name, rankIndex, days, tenureStartDate, overrides)
    overrides = overrides or {}
    local values = {
        guid = "Player-0000-" .. name,
        name = name,
        displayName = name .. "-Example Realm",
        rankName = overrides.rankName or "Trial",
        rankIndex = rankIndex,
        lastOnline = days == nil and nil or {
            years = 0,
            months = 0,
            days = days,
            hours = 0,
        },
        rankTenureStartDate = tenureStartDate or CURRENT_DATE,
        isOnline = overrides.isOnline == true,
        isMissing = overrides.isMissing == true,
    }
    local rosterMember = fixtures.roster_member(values)
    if days == nil or values.isOnline then
        rosterMember.lastOnline = nil
    end
    return rosterMember
end

local function comprehensiveDataset()
    return {
        guild = fixtures.guild_identity(),
        scannedAt = fixtures.timestamp(),
        ranks = {
            fixtures.roster_rank({ index = 7, name = "Trial" }),
            fixtures.roster_rank({ index = 1, name = "Guild Master" }),
            fixtures.roster_rank({ index = 8, name = "Trial" }),
            fixtures.roster_rank({ index = 9, name = "Large Rank" }),
        },
        members = {
            member("Online", 7, nil, "2024-05-01", { isOnline = true }),
            member("DayZero", 7, 0, "2024-05-01"),
            member("DaySix", 7, 6, "2024-05-01"),
            member("DaySeven", 7, 7, "2024-05-01"),
            member("DayThirteen", 7, 13, "2024-05-01"),
            member("DayFourteen", 7, 14, "2024-05-01"),
            member("DayTwenty", 7, 20, "2024-05-01"),
            member("DayTwentyOne", 7, 21, "2024-05-01"),
            member("Unknown", 7, nil, "2024-05-01"),
            member("Zulu", 7, 3, "2024-05-15"),
            member("Alpha", 7, 4, "2024-05-15"),
            member("VeryOldCurrent", 7, 400, "2024-05-01"),
            member("RetainedMissing", 7, 10, "2024-05-01", {
                isMissing = true,
            }),
        },
    }
end

return {
    test.case("comprehensive fixture renders ordered and disambiguated rank tabs", function()
        local dataset = comprehensiveDataset()
        local rendered = assert(report.build(dataset, CURRENT_DATE, dateTime))

        test.assert_equal(#rendered.ranks, 4)
        test.assert_equal(rendered.ranks[1].label, "Guild Master")
        test.assert_equal(rendered.ranks[2].label, "Trial (Rank 7)")
        test.assert_equal(rendered.ranks[3].label, "Trial (Rank 8)")
        test.assert_equal(rendered.ranks[4].label, "Large Rank")
        for _, rank in ipairs(rendered.ranks) do
            test.assert_equal(#rank.groups, 4)
            for index, group in ipairs(rank.groups) do
                test.assert_equal(group.title, report.GROUPS[index].title)
                test.assert_equal(group.emptyText, "<no members in this bracket>")
            end
        end
        test.assert_equal(#rendered.ranks[1].groups[1].members, 0)
        test.assert_equal(#rendered.ranks[3].groups[4].members, 0)
    end),

    test.case("every approximate age boundary and unknown value uses its bracket", function()
        local rendered = assert(report.build(
            comprehensiveDataset(),
            CURRENT_DATE,
            dateTime
        ))
        local groups = rendered.ranks[2].groups

        local bracketByName = {}
        for groupIndex, group in ipairs(groups) do
            for _, row in ipairs(group.members) do
                bracketByName[row.name] = groupIndex
            end
        end
        test.assert_equal(bracketByName.Online, 1)
        test.assert_equal(bracketByName.DayZero, 1)
        test.assert_equal(bracketByName.DaySix, 1)
        test.assert_equal(bracketByName.DaySeven, 2)
        test.assert_equal(bracketByName.DayThirteen, 2)
        test.assert_equal(bracketByName.DayFourteen, 3)
        test.assert_equal(bracketByName.DayTwenty, 3)
        test.assert_equal(bracketByName.DayTwentyOne, 4)
        test.assert_equal(bracketByName.Unknown, 4)
        test.assert_equal(bracketByName.VeryOldCurrent, 4)
        test.assert_equal(bracketByName.RetainedMissing, 2)
    end),

    test.case("rows expose display fields and sort by tenure then character name", function()
        local rendered = assert(report.build(
            comprehensiveDataset(),
            CURRENT_DATE,
            dateTime
        ))
        local rows = rendered.ranks[2].groups[1].members

        test.assert_true(rows[1].tenureDays > rows[4].tenureDays)
        test.assert_equal(rows[4].displayName, "Alpha-Example Realm")
        test.assert_equal(rows[5].displayName, "Zulu-Example Realm")
        test.assert_equal(rows[4].tenureDays, rows[5].tenureDays)
        test.assert_equal(rows[4].lastOnlineText, "4 days ago")
        test.assert_equal(rows[3].lastOnlineText, "Online")
    end),

    test.case("missing rows expose their last-appeared date without mutating observations", function()
        local dataset = comprehensiveDataset()
        local missingMember
        local currentMember
        for _, rosterMember in ipairs(dataset.members) do
            if rosterMember.name == "RetainedMissing" then
                missingMember = rosterMember
                missingMember.lastSeenDate = "2024-05-22"
            elseif rosterMember.name == "DayZero" then
                currentMember = rosterMember
            end
        end

        local rendered = assert(report.build(dataset, CURRENT_DATE, dateTime))
        local renderedByName = {}
        for _, group in ipairs(rendered.ranks[2].groups) do
            for _, row in ipairs(group.members) do
                renderedByName[row.name] = row
            end
        end

        test.assert_true(renderedByName.RetainedMissing.isMissing)
        test.assert_equal(
            renderedByName.RetainedMissing.missingLastSeenDate,
            "2024-05-22"
        )
        test.assert_false(renderedByName.DayZero.isMissing)
        test.assert_nil(renderedByName.DayZero.missingLastSeenDate)
        test.assert_equal(missingMember.lastSeenDate, "2024-05-22")
        test.assert_nil(missingMember.missingLastSeenDate)
        test.assert_equal(currentMember.lastSeenDate, "2024-06-01")
    end),

    test.case("large rosters retain every row and leave observations unchanged", function()
        local dataset = comprehensiveDataset()
        dataset.members = {}
        for index = 1, 150 do
            dataset.members[index] = member(
                string.format("Member%03d", index),
                9,
                index % 22,
                CURRENT_DATE,
                { rankName = "Large Rank" }
            )
        end
        local beforeNames = {}
        local beforeDays = {}
        for index, rosterMember in ipairs(dataset.members) do
            beforeNames[index] = rosterMember.displayName
            beforeDays[index] = rosterMember.lastOnline.days
        end

        local rendered = assert(report.build(dataset, CURRENT_DATE, dateTime))
        local count = 0
        for _, group in ipairs(rendered.ranks[4].groups) do
            count = count + #group.members
        end

        test.assert_equal(count, 150)
        test.assert_equal(dataset.ranks[1].index, 7)
        for index, rosterMember in ipairs(dataset.members) do
            test.assert_equal(rosterMember.displayName, beforeNames[index])
            test.assert_equal(rosterMember.lastOnline.days, beforeDays[index])
        end
    end),

    test.case("elapsed Pacific days advance offline ages without false precision", function()
        local dataset = comprehensiveDataset()
        dataset.members = {
            member("Hours", 7, 0, CURRENT_DATE),
            member("Months", 7, 0, CURRENT_DATE),
        }
        dataset.members[1].lastOnline.hours = 5
        dataset.members[2].lastOnline.months = 2

        local rendered = assert(report.build(dataset, "2024-06-08", dateTime))
        local rows = rendered.ranks[2].groups[2].members
        test.assert_equal(rows[1].lastOnlineText, "7 days ago")
        test.assert_equal(
            rendered.ranks[2].groups[4].members[1].lastOnlineText,
            "2 months ago"
        )
    end),

    test.case("rendering collapses a repeated persisted realm without mutation", function()
        local dataset = comprehensiveDataset()
        dataset.members = {
            member("Nalla", 7, 2, CURRENT_DATE),
        }
        dataset.members[1].realm = "Ner'zhul-Ner'zhul-Ner'zhul"
        dataset.members[1].displayName = "Nalla-" .. dataset.members[1].realm

        local rendered = assert(report.build(dataset, CURRENT_DATE, dateTime))

        test.assert_equal(
            rendered.ranks[2].groups[1].members[1].displayName,
            "Nalla-Ner'zhul"
        )
        test.assert_equal(
            dataset.members[1].realm,
            "Ner'zhul-Ner'zhul-Ner'zhul"
        )
    end),
}
