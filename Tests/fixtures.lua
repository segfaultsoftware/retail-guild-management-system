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
        displayName = "Aeloria-Example Realm",
        rankName = "Officer",
        rankIndex = 1,
        level = 80,
        classId = 8,
        classFileName = "MAGE",
        isOnline = false,
        lastOnline = {
            years = 0,
            months = 0,
            days = 2,
            hours = 3,
        },
        observedAt = Fixtures.timestamp(),
        rankTenureStartDate = "2024-06-01",
        lastSeenDate = "2024-06-01",
        isMissing = false,
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
        lastAccessibleAt = Fixtures.timestamp(),
    }, overrides)
end

function Fixtures.bank_slot(overrides)
    return withOverrides({
        tabIndex = 1,
        slotIndex = 1,
        itemId = 191384,
        itemLink = "|Hitem:191384::::::::80:::::|h[Refreshing Healing Potion]|h",
        icon = 236873,
        quantity = 20,
        isLocked = false,
        observedAt = Fixtures.timestamp(),
        stableSinceDate = "2024-06-01",
    }, overrides)
end

function Fixtures.window_position(overrides)
    return withOverrides({
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        x = 120,
        y = -80,
    }, overrides)
end

function Fixtures.saved_model(overrides)
    local guild = Fixtures.guild_identity()
    local timestamp = Fixtures.timestamp()

    return withOverrides({
        schemaVersion = 7,
        roster = {
            guild = guild,
            scannedAt = timestamp,
            ranks = { Fixtures.roster_rank() },
            members = { Fixtures.roster_member() },
        },
        bank = {
            guild = guild,
            scannedAt = timestamp,
            tabs = { Fixtures.bank_tab() },
            slots = { Fixtures.bank_slot() },
        },
        ui = {
            windowPosition = Fixtures.window_position(),
        },
    }, overrides)
end

local function removeVersionSevenBankFields(model)
    for _, tab in ipairs(model.bank.tabs) do
        tab.lastAccessibleAt = nil
    end
    for _, slot in ipairs(model.bank.slots) do
        slot.icon = nil
    end
end

function Fixtures.saved_model_v0(overrides)
    local guild = Fixtures.guild_identity()
    local timestamp = Fixtures.timestamp()
    local member = Fixtures.roster_member()
    member.displayName = nil
    member.rankName = nil
    member.lastOnline = nil
    member.rankTenureStartDate = nil
    member.lastSeenDate = nil
    member.isMissing = nil

    local model = withOverrides({
        schemaVersion = 0,
        roster = {
            guildIdentity = guild,
            scanTimestamp = timestamp,
            ranks = { Fixtures.roster_rank() },
            members = { member },
        },
        bank = {
            guildIdentity = guild,
            scanTimestamp = timestamp,
            tabs = { Fixtures.bank_tab() },
            slots = { Fixtures.bank_slot() },
        },
        windowPosition = Fixtures.window_position(),
    }, overrides)
    for _, slot in ipairs(model.bank.slots) do
        slot.stableSinceDate = nil
    end
    removeVersionSevenBankFields(model)
    return model
end

function Fixtures.saved_model_v1(overrides)
    local model = Fixtures.saved_model(overrides)
    model.schemaVersion = 1
    for _, member in ipairs(model.roster.members) do
        member.displayName = nil
        member.rankName = nil
        member.lastOnline = nil
        member.rankTenureStartDate = nil
        member.lastSeenDate = nil
        member.isMissing = nil
    end
    for _, slot in ipairs(model.bank.slots) do
        slot.stableSinceDate = nil
    end
    removeVersionSevenBankFields(model)
    return model
end

function Fixtures.saved_model_v2(overrides)
    local model = Fixtures.saved_model(overrides)
    model.schemaVersion = 2
    for _, member in ipairs(model.roster.members) do
        member.rankTenureStartDate = nil
        member.lastSeenDate = nil
        member.isMissing = nil
    end
    for _, slot in ipairs(model.bank.slots) do
        slot.stableSinceDate = nil
    end
    removeVersionSevenBankFields(model)
    return model
end

function Fixtures.saved_model_v3(overrides)
    local model = Fixtures.saved_model(overrides)
    model.schemaVersion = 3
    for _, member in ipairs(model.roster.members) do
        member.lastSeenDate = nil
        member.isMissing = nil
    end
    for _, slot in ipairs(model.bank.slots) do
        slot.stableSinceDate = nil
    end
    removeVersionSevenBankFields(model)
    return model
end

function Fixtures.saved_model_v4(overrides)
    local model = Fixtures.saved_model(overrides)
    model.schemaVersion = 4
    for _, slot in ipairs(model.bank.slots) do
        slot.stableSinceDate = nil
    end
    removeVersionSevenBankFields(model)
    return model
end

function Fixtures.saved_model_v5(overrides)
    local model = Fixtures.saved_model(overrides)
    model.schemaVersion = 5
    for _, slot in ipairs(model.bank.slots) do
        slot.stableSinceDate = nil
    end
    removeVersionSevenBankFields(model)
    return model
end

function Fixtures.saved_model_v6(overrides)
    local model = Fixtures.saved_model(overrides)
    model.schemaVersion = 6
    removeVersionSevenBankFields(model)
    return model
end


return Fixtures
