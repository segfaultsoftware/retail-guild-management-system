-- Versioned, per-character SavedVariables model for RGMS. This module is kept
-- independent of WoW APIs so migrations and validation can be tested without
-- loading the game client.

local _, RGMS = ...

local SavedData = {}
local DateTime = type(RGMS) == "table" and RGMS.DateTime or require("Core.DateTime")

SavedData.CURRENT_SCHEMA_VERSION = 3

local ANCHOR_POINTS = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

local function isFiniteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function isInteger(value)
    return isFiniteNumber(value) and value == math.floor(value)
end

local function deepCopy(value, active)
    if type(value) ~= "table" then
        return value
    end

    active = active or {}
    if active[value] then
        return nil, "saved data contains a recursive table"
    end

    active[value] = true
    local result = {}
    for key, item in pairs(value) do
        local copiedKey, keyError = deepCopy(key, active)
        if keyError then
            active[value] = nil
            return nil, keyError
        end

        local copiedItem, itemError = deepCopy(item, active)
        if itemError then
            active[value] = nil
            return nil, itemError
        end

        result[copiedKey] = copiedItem
    end
    active[value] = nil

    return result
end

local function rejectUnknownKeys(value, allowedKeys, path)
    for key in pairs(value) do
        if not allowedKeys[key] then
            return nil, path .. " contains unexpected field " .. tostring(key)
        end
    end

    return true
end

local function requireTable(value, path)
    if type(value) ~= "table" then
        return nil, path .. " must be a table"
    end

    return true
end

local function requireString(value, path)
    if type(value) ~= "string" or value == "" then
        return nil, path .. " must be a non-empty string"
    end

    return true
end

local function requireBoolean(value, path)
    if type(value) ~= "boolean" then
        return nil, path .. " must be a boolean"
    end

    return true
end

local function requireInteger(value, path, minimum)
    if not isInteger(value) or (minimum and value < minimum) then
        local suffix = minimum and (" greater than or equal to " .. minimum) or ""
        return nil, path .. " must be an integer" .. suffix
    end

    return true
end

local function validateExactTable(value, allowedKeys, path)
    local valid, validationError = requireTable(value, path)
    if not valid then
        return nil, validationError
    end

    return rejectUnknownKeys(value, allowedKeys, path)
end

local function validateArray(value, path, validateItem)
    local valid, validationError = requireTable(value, path)
    if not valid then
        return nil, validationError
    end

    local count = 0
    local largestIndex = 0
    for key in pairs(value) do
        if not isInteger(key) or key < 1 then
            return nil, path .. " must contain only positive integer indexes"
        end
        count = count + 1
        if key > largestIndex then
            largestIndex = key
        end
    end

    if count ~= largestIndex then
        return nil, path .. " must not contain gaps"
    end

    for index = 1, count do
        valid, validationError = validateItem(value[index], path .. "[" .. index .. "]")
        if not valid then
            return nil, validationError
        end
    end

    return true
end

local function isLeapYear(year)
    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

local function daysInMonth(year, month)
    local lengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if month == 2 and isLeapYear(year) then
        return 29
    end

    return lengths[month]
end

local function calendarDayNumber(year, month, day)
    local previousYear = year - 1
    local result = 365 * previousYear
        + math.floor(previousYear / 4)
        - math.floor(previousYear / 100)
        + math.floor(previousYear / 400)
    local lengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    for currentMonth = 1, month - 1 do
        result = result + lengths[currentMonth]
    end
    if month > 2 and isLeapYear(year) then
        result = result + 1
    end

    return result + day - 1
end


local UNIX_EPOCH_DAY_NUMBER = calendarDayNumber(1970, 1, 1)

local function validateTimestamp(value, path)
    local valid, validationError = validateExactTable(value, {
        unixSeconds = true,
        iso8601 = true,
    }, path)
    if not valid then
        return nil, validationError
    end

    valid, validationError = requireInteger(value.unixSeconds, path .. ".unixSeconds", 0)
    if not valid then
        return nil, validationError
    end

    valid, validationError = requireString(value.iso8601, path .. ".iso8601")
    if not valid then
        return nil, validationError
    end
    local yearText, monthText, dayText, hourText, minuteText, secondText = string.match(
        value.iso8601,
        "^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)Z$"
    )
    if not yearText then
        return nil, path .. ".iso8601 must use UTC YYYY-MM-DDTHH:MM:SSZ form"
    end

    local year = tonumber(yearText)
    local month = tonumber(monthText)
    local day = tonumber(dayText)
    local hour = tonumber(hourText)
    local minute = tonumber(minuteText)
    local second = tonumber(secondText)
    if year < 1 or month < 1 or month > 12
        or day < 1 or day > daysInMonth(year, month)
        or hour > 23 or minute > 59 or second > 59 then
        return nil, path .. ".iso8601 is not a valid UTC date and time"
    end

    local expectedUnixSeconds = (
        calendarDayNumber(year, month, day) - UNIX_EPOCH_DAY_NUMBER
    ) * 24 * 60 * 60 + hour * 60 * 60 + minute * 60 + second
    if value.unixSeconds ~= expectedUnixSeconds then
        return nil, path .. ".unixSeconds and " .. path .. ".iso8601 must represent the same time"
    end

    return true
end

local function validateGuildIdentity(value, path)
    local valid, validationError = validateExactTable(value, {
        id = true,
        name = true,
        realm = true,
        region = true,
    }, path)
    if not valid then
        return nil, validationError
    end

    for _, field in ipairs({ "id", "name", "region" }) do
        valid, validationError = requireString(value[field], path .. "." .. field)
        if not valid then
            return nil, validationError
        end
    end

    valid, validationError = validateExactTable(value.realm, {
        name = true,
        slug = true,
    }, path .. ".realm")
    if not valid then
        return nil, validationError
    end

    for _, field in ipairs({ "name", "slug" }) do
        valid, validationError = requireString(value.realm[field], path .. ".realm." .. field)
        if not valid then
            return nil, validationError
        end
    end

    return true
end

local function validateRosterRank(value, path)
    local valid, validationError = validateExactTable(value, {
        index = true,
        name = true,
        permissions = true,
    }, path)
    if not valid then
        return nil, validationError
    end

    valid, validationError = requireInteger(value.index, path .. ".index", 0)
    if not valid then
        return nil, validationError
    end
    valid, validationError = requireString(value.name, path .. ".name")
    if not valid then
        return nil, validationError
    end

    valid, validationError = validateExactTable(value.permissions, {
        invite = true,
        remove = true,
        editOfficerNote = true,
    }, path .. ".permissions")
    if not valid then
        return nil, validationError
    end
    for _, field in ipairs({ "invite", "remove", "editOfficerNote" }) do
        valid, validationError = requireBoolean(
            value.permissions[field],
            path .. ".permissions." .. field
        )
        if not valid then
            return nil, validationError
        end
    end

    return true
end

local function validateRosterMember(value, path, requireTenureStartDate)
    local allowedKeys = {
        guid = true,
        name = true,
        realm = true,
        displayName = true,
        rankName = true,
        rankIndex = true,
        level = true,
        classId = true,
        classFileName = true,
        isOnline = true,
        lastOnline = true,
        observedAt = true,
    }
    if requireTenureStartDate then
        allowedKeys.rankTenureStartDate = true
    end

    local valid, validationError = validateExactTable(value, allowedKeys, path)
    if not valid then
        return nil, validationError
    end

    for _, field in ipairs({
        "guid",
        "name",
        "realm",
        "displayName",
        "rankName",
        "classFileName",
    }) do
        valid, validationError = requireString(value[field], path .. "." .. field)
        if not valid then
            return nil, validationError
        end
    end
    for _, field in ipairs({ "rankIndex", "level", "classId" }) do
        valid, validationError = requireInteger(value[field], path .. "." .. field, 0)
        if not valid then
            return nil, validationError
        end
    end
    valid, validationError = requireBoolean(value.isOnline, path .. ".isOnline")
    if not valid then
        return nil, validationError
    end
    if value.displayName ~= value.name .. "-" .. value.realm then
        return nil, path .. ".displayName must match name and realm"
    end

    if value.lastOnline ~= nil then
        if value.isOnline then
            return nil, path .. ".lastOnline must be absent for an online member"
        end
        valid, validationError = validateExactTable(value.lastOnline, {
            years = true,
            months = true,
            days = true,
            hours = true,
        }, path .. ".lastOnline")
        if not valid then
            return nil, validationError
        end
        for _, field in ipairs({ "years", "months", "days", "hours" }) do
            valid, validationError = requireInteger(
                value.lastOnline[field],
                path .. ".lastOnline." .. field,
                0
            )
            if not valid then
                return nil, validationError
            end
        end
    end

    valid, validationError = validateTimestamp(value.observedAt, path .. ".observedAt")
    if not valid then
        return nil, validationError
    end

    if requireTenureStartDate then
        local parsedDate, dateError = DateTime.parseStoredDate(
            value.rankTenureStartDate
        )
        if not parsedDate then
            return nil, path .. ".rankTenureStartDate " .. dateError
        end

        local observedDate, observedDateError = DateTime.currentPacificDate(
            value.observedAt.unixSeconds
        )
        if not observedDate then
            return nil, path .. ".observedAt " .. observedDateError
        end
        local tenureDays = DateTime.calendarDayDifference(
            value.rankTenureStartDate,
            observedDate
        )
        if tenureDays == nil then
            return nil, path .. ".rankTenureStartDate must not follow observedAt"
        end
    end

    return true
end

local function validateCurrentRosterMember(value, path)
    return validateRosterMember(value, path, true)
end

local function validateBankTab(value, path)
    local valid, validationError = validateExactTable(value, {
        index = true,
        name = true,
        icon = true,
        isViewable = true,
        canDeposit = true,
        withdrawalsPerDay = true,
    }, path)
    if not valid then
        return nil, validationError
    end

    valid, validationError = requireInteger(value.index, path .. ".index", 1)
    if not valid then
        return nil, validationError
    end
    valid, validationError = requireString(value.name, path .. ".name")
    if not valid then
        return nil, validationError
    end
    valid, validationError = requireInteger(value.icon, path .. ".icon", 0)
    if not valid then
        return nil, validationError
    end
    for _, field in ipairs({ "isViewable", "canDeposit" }) do
        valid, validationError = requireBoolean(value[field], path .. "." .. field)
        if not valid then
            return nil, validationError
        end
    end

    return requireInteger(value.withdrawalsPerDay, path .. ".withdrawalsPerDay", -1)
end

local function validateBankSlot(value, path)
    local valid, validationError = validateExactTable(value, {
        tabIndex = true,
        slotIndex = true,
        itemId = true,
        itemLink = true,
        quantity = true,
        isLocked = true,
        observedAt = true,
    }, path)
    if not valid then
        return nil, validationError
    end

    for _, field in ipairs({ "tabIndex", "slotIndex", "itemId", "quantity" }) do
        valid, validationError = requireInteger(value[field], path .. "." .. field, 1)
        if not valid then
            return nil, validationError
        end
    end
    valid, validationError = requireString(value.itemLink, path .. ".itemLink")
    if not valid then
        return nil, validationError
    end
    valid, validationError = requireBoolean(value.isLocked, path .. ".isLocked")
    if not valid then
        return nil, validationError
    end

    return validateTimestamp(value.observedAt, path .. ".observedAt")
end

local function validateWindowPosition(value, path)
    if value == nil then
        return true
    end

    local valid, validationError = validateExactTable(value, {
        point = true,
        relativePoint = true,
        x = true,
        y = true,
    }, path)
    if not valid then
        return nil, validationError
    end

    if not ANCHOR_POINTS[value.point] then
        return nil, path .. ".point is not a supported frame anchor"
    end
    if not ANCHOR_POINTS[value.relativePoint] then
        return nil, path .. ".relativePoint is not a supported frame anchor"
    end
    if not isFiniteNumber(value.x) then
        return nil, path .. ".x must be a finite number"
    end
    if not isFiniteNumber(value.y) then
        return nil, path .. ".y must be a finite number"
    end

    return true
end

local function validateDataset(value, path, collectionValidators)
    local allowedKeys = {
        guild = true,
        scannedAt = true,
    }
    for collectionName in pairs(collectionValidators) do
        allowedKeys[collectionName] = true
    end

    local valid, validationError = validateExactTable(value, allowedKeys, path)
    if not valid then
        return nil, validationError
    end

    if (value.guild == nil) ~= (value.scannedAt == nil) then
        return nil, path .. ".guild and " .. path .. ".scannedAt must both be present or absent"
    end
    if value.guild ~= nil then
        valid, validationError = validateGuildIdentity(value.guild, path .. ".guild")
        if not valid then
            return nil, validationError
        end
        valid, validationError = validateTimestamp(value.scannedAt, path .. ".scannedAt")
        if not valid then
            return nil, validationError
        end
    end

    local hasObservations = false
    for collectionName, validator in pairs(collectionValidators) do
        valid, validationError = validateArray(
            value[collectionName],
            path .. "." .. collectionName,
            validator
        )
        if not valid then
            return nil, validationError
        end
        if #value[collectionName] > 0 then
            hasObservations = true
        end
    end

    if hasObservations and value.guild == nil then
        return nil, path .. " observations require guild identity and scan timestamp"
    end

    return true
end

function SavedData.newModel()
    return {
        schemaVersion = SavedData.CURRENT_SCHEMA_VERSION,
        roster = {
            ranks = {},
            members = {},
        },
        bank = {
            tabs = {},
            slots = {},
        },
        ui = {},
    }
end

function SavedData.validate(model)
    local valid, validationError = validateExactTable(model, {
        schemaVersion = true,
        roster = true,
        bank = true,
        ui = true,
    }, "saved data")
    if not valid then
        return nil, validationError
    end

    if model.schemaVersion ~= SavedData.CURRENT_SCHEMA_VERSION then
        return nil, "saved data schemaVersion must be " .. SavedData.CURRENT_SCHEMA_VERSION
    end

    valid, validationError = validateDataset(model.roster, "saved data.roster", {
        ranks = validateRosterRank,
        members = validateCurrentRosterMember,
    })
    if not valid then
        return nil, validationError
    end

    valid, validationError = validateDataset(model.bank, "saved data.bank", {
        tabs = validateBankTab,
        slots = validateBankSlot,
    })
    if not valid then
        return nil, validationError
    end

    valid, validationError = validateExactTable(model.ui, {
        windowPosition = true,
    }, "saved data.ui")
    if not valid then
        return nil, validationError
    end

    return validateWindowPosition(model.ui.windowPosition, "saved data.ui.windowPosition")
end

function SavedData.copyGuildIdentity(identity)
    local valid, validationError = validateGuildIdentity(identity, "guild identity")
    if not valid then
        return nil, validationError
    end

    return deepCopy(identity)
end

local function migrateVersionZero(model)
    local valid, migrationError = validateExactTable(model, {
        schemaVersion = true,
        roster = true,
        bank = true,
        windowPosition = true,
    }, "schema version 0 data")
    if not valid then
        return nil, migrationError
    end

    if model.schemaVersion ~= 0 then
        return nil, "schema version 0 migration received the wrong version"
    end

    for _, datasetName in ipairs({ "roster", "bank" }) do
        local dataset = model[datasetName]
        valid, migrationError = validateExactTable(dataset, {
            guildIdentity = true,
            scanTimestamp = true,
            ranks = datasetName == "roster",
            members = datasetName == "roster",
            tabs = datasetName == "bank",
            slots = datasetName == "bank",
        }, "schema version 0 data." .. datasetName)
        if not valid then
            return nil, migrationError
        end
    end

    return {
        schemaVersion = 1,
        roster = {
            guild = model.roster.guildIdentity,
            scannedAt = model.roster.scanTimestamp,
            ranks = model.roster.ranks,
            members = model.roster.members,
        },
        bank = {
            guild = model.bank.guildIdentity,
            scannedAt = model.bank.scanTimestamp,
            tabs = model.bank.tabs,
            slots = model.bank.slots,
        },
        ui = {
            windowPosition = model.windowPosition,
        },
    }
end

local function splitMemberName(name, fallbackRealm)
    local characterName, realm = string.match(name or "", "^([^%-]+)%-(.+)$")
    if characterName and realm then
        return characterName, realm, name
    end

    characterName = name
    realm = fallbackRealm
    return characterName, realm, characterName .. "-" .. realm
end

local function validateVersionOneRosterMember(value, path)
    local valid, validationError = validateExactTable(value, {
        guid = true,
        name = true,
        realm = true,
        rankIndex = true,
        level = true,
        classId = true,
        classFileName = true,
        isOnline = true,
        observedAt = true,
    }, path)
    if not valid then
        return nil, validationError
    end

    for _, field in ipairs({ "guid", "name", "realm", "classFileName" }) do
        valid, validationError = requireString(value[field], path .. "." .. field)
        if not valid then
            return nil, validationError
        end
    end
    for _, field in ipairs({ "rankIndex", "level", "classId" }) do
        valid, validationError = requireInteger(value[field], path .. "." .. field, 0)
        if not valid then
            return nil, validationError
        end
    end
    valid, validationError = requireBoolean(value.isOnline, path .. ".isOnline")
    if not valid then
        return nil, validationError
    end

    return validateTimestamp(value.observedAt, path .. ".observedAt")
end

local function migrateVersionOne(model)
    if model.schemaVersion ~= 1 then
        return nil, "schema version 1 migration received the wrong version"
    end

    local valid, migrationError = validateExactTable(model, {
        schemaVersion = true,
        roster = true,
        bank = true,
        ui = true,
    }, "schema version 1 data")
    if not valid then
        return nil, migrationError
    end
    valid, migrationError = validateDataset(model.roster, "schema version 1 data.roster", {
        ranks = validateRosterRank,
        members = validateVersionOneRosterMember,
    })
    if not valid then
        return nil, migrationError
    end
    valid, migrationError = validateDataset(model.bank, "schema version 1 data.bank", {
        tabs = validateBankTab,
        slots = validateBankSlot,
    })
    if not valid then
        return nil, migrationError
    end
    valid, migrationError = validateExactTable(model.ui, {
        windowPosition = true,
    }, "schema version 1 data.ui")
    if not valid then
        return nil, migrationError
    end
    valid, migrationError = validateWindowPosition(
        model.ui.windowPosition,
        "schema version 1 data.ui.windowPosition"
    )
    if not valid then
        return nil, migrationError
    end

    local rankNames = {}
    for _, rank in ipairs(model.roster.ranks or {}) do
        rankNames[rank.index] = rank.name
    end

    for _, member in ipairs(model.roster.members or {}) do
        local name, realm, displayName = splitMemberName(member.name, member.realm)
        member.name = name
        member.realm = realm
        member.displayName = displayName
        member.rankName = rankNames[member.rankIndex] or "Unknown Rank"
    end
    model.schemaVersion = 2
    return model
end

local function migrateVersionTwo(model)
    if model.schemaVersion ~= 2 then
        return nil, "schema version 2 migration received the wrong version"
    end

    local valid, migrationError = validateExactTable(model, {
        schemaVersion = true,
        roster = true,
        bank = true,
        ui = true,
    }, "schema version 2 data")
    if not valid then
        return nil, migrationError
    end
    valid, migrationError = validateDataset(model.roster, "schema version 2 data.roster", {
        ranks = validateRosterRank,
        members = validateRosterMember,
    })
    if not valid then
        return nil, migrationError
    end
    valid, migrationError = validateDataset(model.bank, "schema version 2 data.bank", {
        tabs = validateBankTab,
        slots = validateBankSlot,
    })
    if not valid then
        return nil, migrationError
    end
    valid, migrationError = validateExactTable(model.ui, {
        windowPosition = true,
    }, "schema version 2 data.ui")
    if not valid then
        return nil, migrationError
    end
    valid, migrationError = validateWindowPosition(
        model.ui.windowPosition,
        "schema version 2 data.ui.windowPosition"
    )
    if not valid then
        return nil, migrationError
    end

    for _, member in ipairs(model.roster.members or {}) do
        local observedDate, observedDateError = DateTime.currentPacificDate(
            member.observedAt.unixSeconds
        )
        if not observedDate then
            return nil, observedDateError
        end
        member.rankTenureStartDate = observedDate
    end
    model.schemaVersion = 3
    return model
end

local MIGRATIONS = {
    [0] = migrateVersionZero,
    [1] = migrateVersionOne,
    [2] = migrateVersionTwo,
}

local function isLegacyDevelopmentState(value)
    if type(value) ~= "table" then
        return false
    end

    for key in pairs(value) do
        if key ~= "loadCount" and key ~= "lastLoadedAt" then
            return false
        end
    end

    return value.loadCount ~= nil or value.lastLoadedAt ~= nil
end

local function disabledState(status, message, original)
    return {
        enabled = false,
        status = status,
        error = message,
        original = original,
    }
end

-- Loads without mutating the supplied SavedVariables table. Callers should
-- replace the WoW global only when this returns enabled = true.
function SavedData.load(saved)
    if saved == nil then
        return {
            enabled = true,
            status = "ready",
            model = SavedData.newModel(),
            initialized = true,
        }
    end

    if type(saved) ~= "table" then
        return disabledState("corrupt", "saved data must be a table", saved)
    end

    if saved.schemaVersion == nil and isLegacyDevelopmentState(saved) then
        return {
            enabled = true,
            status = "ready",
            model = SavedData.newModel(),
            migratedFrom = "development-placeholder",
        }
    end

    if not isInteger(saved.schemaVersion) or saved.schemaVersion < 0 then
        return disabledState(
            "corrupt",
            "saved data has a missing or invalid schemaVersion",
            saved
        )
    end

    if saved.schemaVersion > SavedData.CURRENT_SCHEMA_VERSION then
        return disabledState(
            "incompatible",
            "saved data uses unsupported schema version " .. saved.schemaVersion,
            saved
        )
    end

    local working, copyError = deepCopy(saved)
    if not working then
        return disabledState("corrupt", copyError, saved)
    end

    local migratedFrom
    while working.schemaVersion < SavedData.CURRENT_SCHEMA_VERSION do
        local migration = MIGRATIONS[working.schemaVersion]
        if not migration then
            return disabledState(
                "incompatible",
                "no migration is available for schema version " .. working.schemaVersion,
                saved
            )
        end

        migratedFrom = migratedFrom or working.schemaVersion
        local migrated, migrationError = migration(working)
        if not migrated then
            return disabledState("corrupt", migrationError, saved)
        end
        working = migrated
    end

    local valid, validationError = SavedData.validate(working)
    if not valid then
        return disabledState("corrupt", validationError, saved)
    end

    return {
        enabled = true,
        status = "ready",
        model = working,
        migratedFrom = migratedFrom,
    }
end

local function copyValidWindowPosition(model)
    if type(model) ~= "table" then
        return nil
    end

    local position
    if type(model.ui) == "table" then
        position = model.ui.windowPosition
    end
    if position == nil then
        -- Schema version zero stored this at the top level. Keeping this
        -- fallback also lets recovery retain a usable position when migration
        -- fails for an unrelated field.
        position = model.windowPosition
    end

    local valid = validateWindowPosition(position, "saved window position")
    if not valid or position == nil then
        return nil
    end

    return deepCopy(position)
end

-- Observation resets deliberately keep UI state in a separate subtree. Only
-- the known, valid window-position field is recovered from unusable data; all
-- observations, identities, timestamps, and unknown fields are discarded.
function SavedData.resetObservations(model)
    local reset = SavedData.newModel()
    local copiedPosition, copyError = copyValidWindowPosition(model)
    if copyError then
        return nil, copyError
    end
    if copiedPosition ~= nil then
        reset.ui.windowPosition = copiedPosition
    end

    local valid, validationError = SavedData.validate(reset)
    if not valid then
        return nil, validationError
    end

    return reset
end

-- Guild changes replace one transactional dataset at a time. Keeping this
-- operation here makes the window-position invariant explicit for the future
-- roster and bank scanners.
function SavedData.resetDatasetObservations(model, datasetName)
    if datasetName ~= "roster" and datasetName ~= "bank" then
        return nil, "dataset name must be roster or bank"
    end

    local valid, validationError = SavedData.validate(model)
    if not valid then
        return nil, validationError
    end

    local reset, copyError = deepCopy(model)
    if not reset then
        return nil, copyError
    end
    reset[datasetName] = SavedData.newModel()[datasetName]

    valid, validationError = SavedData.validate(reset)
    if not valid then
        return nil, validationError
    end

    return reset
end

-- Commits one complete scan result without exposing partial state or changing
-- the other dataset and UI subtree. The replacement is copied so callers can
-- safely discard or reuse their transaction tables after the commit.
function SavedData.replaceDataset(model, datasetName, dataset)
    if datasetName ~= "roster" and datasetName ~= "bank" then
        return nil, "dataset name must be roster or bank"
    end

    local valid, validationError = SavedData.validate(model)
    if not valid then
        return nil, validationError
    end

    local replacement, copyError = deepCopy(model)
    if not replacement then
        return nil, copyError
    end

    local copiedDataset
    copiedDataset, copyError = deepCopy(dataset)
    if not copiedDataset then
        return nil, copyError
    end
    replacement[datasetName] = copiedDataset

    valid, validationError = SavedData.validate(replacement)
    if not valid then
        return nil, validationError
    end

    return replacement
end

if type(RGMS) == "table" then
    RGMS.SavedData = SavedData
end

return SavedData
