-- Deterministic fixture builders for RGMS domain data. Defaults are fixed and
-- never consult the current clock, local timezone, WoW installation, or network.

local Fixtures = {}

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

local function withOverrides(defaults, overrides)
    local result = copy(defaults)
    for key, value in pairs(overrides or {}) do
        result[key] = copy(value)
    end
    return result
end

function Fixtures.timestamp(overrides)
    return withOverrides({
        unixSeconds = 1717245296,
        iso8601 = "2024-06-01T12:34:56Z",
    }, overrides)
end

function Fixtures.guild_identity(overrides)
    return withOverrides({
        id = "guild-us-example-realm-00000001",
        name = "Example Guild",
        realm = {
            name = "Example Realm",
            slug = "example-realm",
        },
        region = "US",
    }, overrides)
end

function Fixtures.roster_rank(overrides)
    return withOverrides({
        index = 1,
        name = "Officer",
        permissions = {
            invite = true,
            remove = true,
            editOfficerNote = true,
        },
    }, overrides)
end

function Fixtures.roster_member(overrides)
    return withOverrides({
        guid = "Player-0000-00000001",
        name = "Aeloria",
        realm = "Example Realm",
        rankIndex = 1,
        level = 80,
        classId = 8,
        classFileName = "MAGE",
        isOnline = false,
        observedAt = Fixtures.timestamp(),
    }, overrides)
end

function Fixtures.bank_tab(overrides)
    return withOverrides({
        index = 1,
        name = "Consumables",
        icon = 134400,
        isViewable = true,
        canDeposit = true,
        withdrawalsPerDay = 5,
    }, overrides)
end

function Fixtures.bank_slot(overrides)
    return withOverrides({
        tabIndex = 1,
        slotIndex = 1,
        itemId = 191384,
        itemLink = "|Hitem:191384::::::::80:::::|h[Refreshing Healing Potion]|h",
        quantity = 20,
        isLocked = false,
        observedAt = Fixtures.timestamp(),
    }, overrides)
end


return Fixtures
