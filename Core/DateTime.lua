-- Pacific calendar-date utilities. All timezone conversion is done from Unix
-- seconds so the computer's configured timezone never affects RGMS results.

local _, RGMS = ...

local DateTime = {}

local SECONDS_PER_DAY = 24 * 60 * 60
local PACIFIC_STANDARD_OFFSET_SECONDS = -8 * 60 * 60
local PACIFIC_DAYLIGHT_OFFSET_SECONDS = -7 * 60 * 60

local function isLeapYear(year)
    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

local function daysInMonth(year, month)
    local monthLengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if month == 2 and isLeapYear(year) then
        return 29
    end

    return monthLengths[month]
end

-- Returns the number of days before the supplied Gregorian calendar date.
-- 0001-01-01 is day zero.
local function calendarDayNumber(year, month, day)
    local previousYear = year - 1
    local result = 365 * previousYear
        + math.floor(previousYear / 4)
        - math.floor(previousYear / 100)
        + math.floor(previousYear / 400)

    local monthLengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    for currentMonth = 1, month - 1 do
        result = result + monthLengths[currentMonth]
    end
    if month > 2 and isLeapYear(year) then
        result = result + 1
    end

    return result + day - 1
end

local UNIX_EPOCH_DAY_NUMBER = calendarDayNumber(1970, 1, 1)

-- Converts a day relative to the Unix epoch to a Gregorian date. This is the
-- civil_from_days algorithm, expressed using only Lua 5.1-compatible syntax.
local function calendarDateFromUnixDay(unixDay)
    local adjustedDay = unixDay + 719468
    local era = math.floor(adjustedDay / 146097)
    local dayOfEra = adjustedDay - era * 146097
    local yearOfEra = math.floor((dayOfEra
        - math.floor(dayOfEra / 1460)
        + math.floor(dayOfEra / 36524)
        - math.floor(dayOfEra / 146096)) / 365)
    local year = yearOfEra + era * 400
    local dayOfYear = dayOfEra - (365 * yearOfEra
        + math.floor(yearOfEra / 4)
        - math.floor(yearOfEra / 100))
    local shiftedMonth = math.floor((5 * dayOfYear + 2) / 153)
    local day = dayOfYear - math.floor((153 * shiftedMonth + 2) / 5) + 1
    local month
    if shiftedMonth < 10 then
        month = shiftedMonth + 3
    else
        month = shiftedMonth - 9
    end
    if month <= 2 then
        year = year + 1
    end

    return year, month, day
end

local function unixSecondsForUtc(year, month, day, hour)
    local unixDay = calendarDayNumber(year, month, day) - UNIX_EPOCH_DAY_NUMBER
    return unixDay * SECONDS_PER_DAY + hour * 60 * 60
end

local function firstSundayOfMonth(year, month)
    -- 0001-01-01 was a Monday, so remainder 6 represents Sunday.
    local firstWeekday = calendarDayNumber(year, month, 1) % 7
    return 1 + ((6 - firstWeekday) % 7)
end

local function pacificOffsetSeconds(unixSeconds)
    local utcDay = math.floor(unixSeconds / SECONDS_PER_DAY)
    local year = calendarDateFromUnixDay(utcDay)

    -- Since 2007, Pacific daylight time begins at 02:00 PST on the second
    -- Sunday in March (10:00 UTC), and ends at 02:00 PDT on the first Sunday
    -- in November (09:00 UTC). RGMS data is contemporary, so these are the
    -- rules used consistently for all supported timestamps.
    local secondSundayInMarch = firstSundayOfMonth(year, 3) + 7
    local firstSundayInNovember = firstSundayOfMonth(year, 11)
    local daylightStart = unixSecondsForUtc(year, 3, secondSundayInMarch, 10)
    local daylightEnd = unixSecondsForUtc(year, 11, firstSundayInNovember, 9)

    if unixSeconds >= daylightStart and unixSeconds < daylightEnd then
        return PACIFIC_DAYLIGHT_OFFSET_SECONDS
    end

    return PACIFIC_STANDARD_OFFSET_SECONDS
end

local function validatedUnixSeconds(unixSeconds)
    if unixSeconds == nil then
        if type(GetServerTime) ~= "function" then
            return nil, "current time is unavailable outside the WoW client"
        end
        unixSeconds = GetServerTime()
    end

    if type(unixSeconds) ~= "number"
        or unixSeconds ~= unixSeconds
        or unixSeconds == math.huge
        or unixSeconds == -math.huge
        or unixSeconds ~= math.floor(unixSeconds) then
        return nil, "timestamp must be an integer number of Unix seconds"
    end

    return unixSeconds
end

local function pacificDateTimeParts(unixSeconds)
    local validated, validationError = validatedUnixSeconds(unixSeconds)
    if not validated then
        return nil, validationError
    end

    local pacificSeconds = validated + pacificOffsetSeconds(validated)
    local pacificDay = math.floor(pacificSeconds / SECONDS_PER_DAY)
    local secondsSinceMidnight = pacificSeconds - pacificDay * SECONDS_PER_DAY
    local year, month, day = calendarDateFromUnixDay(pacificDay)
    if year < 1 or year > 9999 then
        return nil, "timestamp is outside the supported years 0001 through 9999"
    end

    return {
        year = year,
        month = month,
        day = day,
        hour = math.floor(secondsSinceMidnight / (60 * 60)),
        minute = math.floor(secondsSinceMidnight / 60) % 60,
    }
end

function DateTime.currentPacificDate(unixSeconds)
    local parts, partsError = pacificDateTimeParts(unixSeconds)
    if not parts then
        return nil, partsError
    end

    return string.format("%04d-%02d-%02d", parts.year, parts.month, parts.day)
end

function DateTime.formatPacificTimestamp(unixSeconds)
    local parts, partsError = pacificDateTimeParts(unixSeconds)
    if not parts then
        return nil, partsError
    end

    return string.format(
        "%04d-%02d-%02d %02d:%02d PT",
        parts.year,
        parts.month,
        parts.day,
        parts.hour,
        parts.minute
    )
end

function DateTime.parseStoredDate(value)
    if type(value) ~= "string" then
        return nil, "date must be a string in YYYY-MM-DD form"
    end

    local yearText, monthText, dayText = string.match(
        value,
        "^(%d%d%d%d)%-(%d%d)%-(%d%d)$"
    )
    if not yearText then
        return nil, "date must use YYYY-MM-DD form"
    end

    local year = tonumber(yearText)
    local month = tonumber(monthText)
    local day = tonumber(dayText)
    if year < 1 then
        return nil, "date year must be between 0001 and 9999"
    end
    if month < 1 or month > 12 then
        return nil, "date month must be between 01 and 12"
    end
    if day < 1 or day > daysInMonth(year, month) then
        return nil, "date day is not valid for its month and year"
    end

    return {
        year = year,
        month = month,
        day = day,
    }
end

function DateTime.calendarDayDifference(earlierDate, laterDate)
    local earlier, earlierError = DateTime.parseStoredDate(earlierDate)
    if not earlier then
        return nil, "invalid earlier date: " .. earlierError
    end

    local later, laterError = DateTime.parseStoredDate(laterDate)
    if not later then
        return nil, "invalid later date: " .. laterError
    end

    local earlierDay = calendarDayNumber(earlier.year, earlier.month, earlier.day)
    local laterDay = calendarDayNumber(later.year, later.month, later.day)
    if laterDay < earlierDay then
        return nil, "later date precedes earlier date"
    end

    return laterDay - earlierDay
end

if type(RGMS) == "table" then
    RGMS.DateTime = DateTime
end

return DateTime
