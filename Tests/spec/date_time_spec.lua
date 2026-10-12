local dateFixtures = require("Tests.date_fixtures")
local dateTime = require("Core.DateTime")
local test = require("Tests.lib.runner")

return {
    test.case("Pacific dates change at Pacific midnight", function()
        test.assert_equal(
            dateTime.currentPacificDate(dateFixtures.pacificMidnight.before),
            "2024-05-31"
        )
        test.assert_equal(
            dateTime.currentPacificDate(dateFixtures.pacificMidnight.after),
            "2024-06-01"
        )
    end),

    test.case("current Pacific values use server time instead of local time", function()
        local originalGetServerTime = _G.GetServerTime
        local originalDate = _G.date
        local originalTime = _G.time
        _G.GetServerTime = function()
            return dateFixtures.pacificMidnight.after
        end
        _G.date = function()
            error("local date must not be used")
        end
        _G.time = function()
            error("local time must not be used")
        end

        local dateSucceeded, currentDate = pcall(dateTime.currentPacificDate)
        local timestampSucceeded, currentTimestamp = pcall(
            dateTime.formatPacificTimestamp
        )

        _G.GetServerTime = originalGetServerTime
        _G.date = originalDate
        _G.time = originalTime

        test.assert_true(dateSucceeded, currentDate)
        test.assert_true(timestampSucceeded, currentTimestamp)
        test.assert_equal(currentDate, "2024-06-01")
        test.assert_equal(currentTimestamp, "2024-06-01 00:00 PT")
    end),

    test.case("multiple observations on one Pacific date have age zero", function()
        local morningDate = dateTime.currentPacificDate(1717246800)
        local eveningDate = dateTime.currentPacificDate(1717297200)

        test.assert_equal(morningDate, "2024-06-01")
        test.assert_equal(eveningDate, "2024-06-01")
        test.assert_equal(dateTime.calendarDayDifference(morningDate, eveningDate), 0)
    end),

    test.case("calendar-day differences cross leap day and year boundaries", function()
        test.assert_equal(
            dateTime.calendarDayDifference("2024-02-28", "2024-03-01"),
            2
        )
        test.assert_equal(
            dateTime.calendarDayDifference("2023-12-31", "2024-01-01"),
            1
        )
    end),

    test.case("a 23-hour spring-forward interval is one Pacific calendar day", function()
        local fixture = dateFixtures.springForward
        test.assert_equal(fixture.nextMidnight - fixture.firstMidnight, 23 * 60 * 60)

        local firstDate = dateTime.currentPacificDate(fixture.firstMidnight)
        local nextDate = dateTime.currentPacificDate(fixture.nextMidnight)
        test.assert_equal(dateTime.calendarDayDifference(firstDate, nextDate), 1)
        test.assert_equal(
            dateTime.formatPacificTimestamp(fixture.beforeTransition),
            "2024-03-10 01:59 PT"
        )
        test.assert_equal(
            dateTime.formatPacificTimestamp(fixture.afterTransition),
            "2024-03-10 03:00 PT"
        )
    end),

    test.case("a 25-hour fall-back interval is one Pacific calendar day", function()
        local fixture = dateFixtures.fallBack
        test.assert_equal(fixture.nextMidnight - fixture.firstMidnight, 25 * 60 * 60)

        local firstDate = dateTime.currentPacificDate(fixture.firstMidnight)
        local nextDate = dateTime.currentPacificDate(fixture.nextMidnight)
        test.assert_equal(dateTime.calendarDayDifference(firstDate, nextDate), 1)
        test.assert_equal(
            dateTime.formatPacificTimestamp(fixture.beforeTransition),
            "2024-11-03 01:59 PT"
        )
        test.assert_equal(
            dateTime.formatPacificTimestamp(fixture.afterTransition),
            "2024-11-03 01:00 PT"
        )
    end),

    test.case("stored dates parse only exact valid YYYY-MM-DD values", function()
        test.assert_equal(dateTime.parseStoredDate("2024-02-29"), {
            year = 2024,
            month = 2,
            day = 29,
        })

        local invalidDate, invalidDateError = dateTime.parseStoredDate("2023-02-29")
        test.assert_nil(invalidDate)
        test.assert_matches(invalidDateError, "not valid")

        local invalidForm, invalidFormError = dateTime.parseStoredDate("2024-2-29")
        test.assert_nil(invalidForm)
        test.assert_matches(invalidFormError, "YYYY%-MM%-DD")
    end),

    test.case("invalid and reversed dates report errors instead of ages", function()
        local invalidAge, invalidAgeError = dateTime.calendarDayDifference(
            "not-a-date",
            "2024-06-01"
        )
        test.assert_nil(invalidAge)
        test.assert_matches(invalidAgeError, "invalid earlier date")

        local reversedAge, reversedAgeError = dateTime.calendarDayDifference(
            "2024-06-02",
            "2024-06-01"
        )
        test.assert_nil(reversedAge)
        test.assert_matches(reversedAgeError, "precedes")
    end),

    test.case("date and timestamp formatting exactly match RGMS forms", function()
        test.assert_equal(dateTime.currentPacificDate(1709236800), "2024-02-29")
        test.assert_equal(
            dateTime.formatPacificTimestamp(1735718400),
            "2025-01-01 00:00 PT"
        )
        test.assert_equal(dateTime.utcTimestamp(1717245296), {
            unixSeconds = 1717245296,
            iso8601 = "2024-06-01T12:34:56Z",
        })
    end),
}
