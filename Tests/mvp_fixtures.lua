-- Reusable, deterministic fixtures for the end-to-end MVP workflows.
-- Every timestamp is an explicit Pacific-day observation rendered in UTC.

local fixtures = require("Tests.fixtures")

local MvpFixtures = {}

local function copy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for key, item in pairs(value) do
        result[copy(key)] = copy(item)
    end
    return result
end

MvpFixtures.dates = {
    day1Morning = {
        pacificDate = "2024-06-01",
        unixSeconds = 1717257600,
        iso8601 = "2024-06-01T16:00:00Z",
    },
    day1Afternoon = {
        pacificDate = "2024-06-01",
        unixSeconds = 1717272000,
        iso8601 = "2024-06-01T20:00:00Z",
    },
    day2 = {
        pacificDate = "2024-06-02",
        unixSeconds = 1717344000,
        iso8601 = "2024-06-02T16:00:00Z",
    },
    day3 = {
        pacificDate = "2024-06-03",
        unixSeconds = 1717430400,
        iso8601 = "2024-06-03T16:00:00Z",
    },
    day4 = {
        pacificDate = "2024-06-04",
        unixSeconds = 1717516800,
        iso8601 = "2024-06-04T16:00:00Z",
    },
    day5 = {
        pacificDate = "2024-06-05",
        unixSeconds = 1717603200,
        iso8601 = "2024-06-05T16:00:00Z",
    },
    day6 = {
        pacificDate = "2024-06-06",
        unixSeconds = 1717689600,
        iso8601 = "2024-06-06T16:00:00Z",
    },
    day7 = {
        pacificDate = "2024-06-07",
        unixSeconds = 1717776000,
        iso8601 = "2024-06-07T16:00:00Z",
    },
    day8 = {
        pacificDate = "2024-06-08",
        unixSeconds = 1717862400,
        iso8601 = "2024-06-08T16:00:00Z",
    },
    missingDay21 = {
        pacificDate = "2024-06-24",
        unixSeconds = 1719244800,
        iso8601 = "2024-06-24T16:00:00Z",
    },
    missingDay22 = {
        pacificDate = "2024-06-25",
        unixSeconds = 1719331200,
        iso8601 = "2024-06-25T16:00:00Z",
    },
    reappeared = {
        pacificDate = "2024-06-26",
        unixSeconds = 1719417600,
        iso8601 = "2024-06-26T16:00:00Z",
    },
}

local function timestamp(date)
    return {
        unixSeconds = date.unixSeconds,
        iso8601 = date.iso8601,
    }
end

function MvpFixtures.guild_a()
    return fixtures.guild_identity({
        id = "guild-us-pacific-a-0001",
        name = "Pacific Vanguard",
        realm = {
            name = "Example Realm",
            slug = "example-realm",
        },
    })
end

function MvpFixtures.guild_b()
    return fixtures.guild_identity({
        id = "guild-us-pacific-b-0002",
        name = "Second Sunrise",
        realm = {
            name = "Other Realm",
            slug = "other-realm",
        },
    })
end

function MvpFixtures.ranks(memberRankName)
    return {
        fixtures.roster_rank({ index = 1, name = "Officer" }),
        fixtures.roster_rank({ index = 2, name = memberRankName or "Member" }),
        fixtures.roster_rank({ index = 3, name = "Initiate" }),
    }
end

function MvpFixtures.roster_member(date, overrides)
    overrides = overrides or {}
    local member = fixtures.roster_member({
        guid = overrides.guid or "Player-0000-00000042",
        name = overrides.name or "Aeloria",
        realm = overrides.realm or "Example Realm",
        displayName = overrides.displayName or "Aeloria-Example Realm",
        rankName = overrides.rankName or "Member",
        rankIndex = overrides.rankIndex or 2,
        isOnline = overrides.isOnline == true,
        lastOnline = overrides.lastOnline or {
            years = 0,
            months = 0,
            days = 2,
            hours = 0,
        },
        observedAt = timestamp(date),
    })
    member.rankTenureStartDate = nil
    member.lastSeenDate = nil
    member.isMissing = nil
    if member.isOnline then
        member.lastOnline = nil
    end
    return member
end

function MvpFixtures.roster_snapshot(date, options)
    options = options or {}
    return {
        guild = copy(options.guild or MvpFixtures.guild_a()),
        scannedAt = timestamp(date),
        ranks = copy(options.ranks or MvpFixtures.ranks()),
        members = copy(options.members or {}),
    }
end

function MvpFixtures.bank_tab(index, isViewable, name)
    local tab = fixtures.bank_tab({
        index = index,
        name = name or ("Tab " .. tostring(index)),
        isViewable = isViewable,
        canDeposit = isViewable,
        withdrawalsPerDay = isViewable and 5 or 0,
    })
    tab.lastAccessibleAt = nil
    return tab
end

function MvpFixtures.bank_slot(tabIndex, slotIndex, itemId, quantity)
    local slot = fixtures.bank_slot({
        tabIndex = tabIndex,
        slotIndex = slotIndex,
        itemId = itemId,
        itemLink = "|Hitem:" .. tostring(itemId) .. "|h[Scenario Item "
            .. tostring(itemId) .. "]|h",
        icon = 134400 + itemId,
        quantity = quantity,
    })
    slot.observedAt = nil
    slot.stableSinceDate = nil
    return slot
end

function MvpFixtures.bank_catalog(guild, secondTabAccessible)
    return {
        guild = copy(guild or MvpFixtures.guild_a()),
        tabs = {
            MvpFixtures.bank_tab(1, true, "Supplies"),
            MvpFixtures.bank_tab(2, secondTabAccessible == true, "Restricted"),
        },
    }
end

function MvpFixtures.expected_roster_after_reappearance()
    local member = MvpFixtures.roster_member(MvpFixtures.dates.reappeared, {
        rankName = "Raider",
        rankIndex = 2,
        isOnline = true,
    })
    member.rankTenureStartDate = "2024-06-26"
    member.lastSeenDate = "2024-06-26"
    member.isMissing = false
    return {
        guild = MvpFixtures.guild_a(),
        scannedAt = timestamp(MvpFixtures.dates.reappeared),
        ranks = MvpFixtures.ranks("Raider"),
        members = { member },
    }
end

function MvpFixtures.expected_bank_after_access_returns()
    local observedAt = timestamp(MvpFixtures.dates.day8)
    local slot = MvpFixtures.bank_slot(1, 2, 2002, 5)
    slot.observedAt = observedAt
    slot.stableSinceDate = "2024-06-06"
    local tabs = {
        MvpFixtures.bank_tab(1, true, "Supplies"),
        MvpFixtures.bank_tab(2, false, "Restricted"),
    }
    tabs[1].lastAccessibleAt = timestamp(MvpFixtures.dates.day8)
    return {
        guild = MvpFixtures.guild_a(),
        scannedAt = observedAt,
        tabs = tabs,
        slots = { slot },
    }
end

function MvpFixtures.empty_model(windowPosition)
    return {
        schemaVersion = 7,
        roster = {
            ranks = {},
            members = {},
        },
        bank = {
            tabs = {},
            slots = {},
        },
        ui = {
            windowPosition = copy(windowPosition),
        },
    }
end

return MvpFixtures
