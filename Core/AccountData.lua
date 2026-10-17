-- Versioned account-wide storage partitioned by guild. Deprecated roster data
-- is migrated separately from bank data so each dataset remains independent.

local _, RGMS = ...

local AccountData = {}
local Realm = type(RGMS) == "table" and RGMS.Realm or require("Core.Realm")
local SavedData = type(RGMS) == "table"
    and RGMS.SavedData
    or require("Core.SavedData")

AccountData.CURRENT_SCHEMA_VERSION = 2
AccountData.MAX_CHARACTER_NOTE_LENGTH = 5500
AccountData.DEFAULT_MINIMAP_ANGLE = 225

local function characterCount(value)
    local withoutContinuationBytes = string.gsub(value, "[\128-\191]", "")
    return #withoutContinuationBytes
end

local function deepCopy(value, active)
    if type(value) ~= "table" then
        return value
    end

    active = active or {}
    if active[value] then
        return nil, "account data contains a recursive table"
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

local function disabledState(status, message, original)
    return {
        enabled = false,
        status = status,
        error = message,
        original = original,
    }
end

local function isInteger(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value == math.floor(value)
end

local function emptyDataset(datasetName)
    if datasetName == "roster" then
        return { ranks = {}, members = {} }
    end
    return { tabs = {}, slots = {} }
end

local function datasetIsEmpty(datasetName, dataset)
    if type(dataset) ~= "table"
        or dataset.guild ~= nil
        or dataset.scannedAt ~= nil then
        return false
    end
    if datasetName == "roster" then
        return type(dataset.ranks) == "table"
            and next(dataset.ranks) == nil
            and type(dataset.members) == "table"
            and next(dataset.members) == nil
    end
    return type(dataset.tabs) == "table"
        and next(dataset.tabs) == nil
        and type(dataset.slots) == "table"
        and next(dataset.slots) == nil
end

local function validateDataset(datasetName, dataset)
    local model = SavedData.newModel()
    local replacement, replacementError = SavedData.replaceDataset(
        model,
        datasetName,
        dataset
    )
    if not replacement then
        return nil, replacementError
    end
    return true
end

local function validateStringMap(value, path, validateValue)
    if type(value) ~= "table" then
        return nil, path .. " must be a table"
    end
    for key, item in pairs(value) do
        if type(key) ~= "string" or key == "" then
            return nil, path .. " keys must be non-empty strings"
        end
        local valid, validationError = validateValue(item, path .. "[" .. key .. "]")
        if not valid then
            return nil, validationError
        end
    end
    return true
end

local function validateGroups(value, path)
    return validateStringMap(value, path, function(alts, altPath)
        if type(alts) ~= "table" then
            return nil, altPath .. " must be an array"
        end
        local count = 0
        for key in pairs(alts) do
            if not isInteger(key) or key < 1 then
                return nil, altPath .. " must contain only positive integer indexes"
            end
            count = count + 1
        end
        if count ~= #alts then
            return nil, altPath .. " must not contain gaps"
        end
        for index, character in ipairs(alts) do
            if type(character) ~= "string" or character == "" then
                return nil, altPath .. "[" .. index .. "] must be a non-empty string"
            end
        end
        return true
    end)
end

local function validateNotes(value, path)
    return validateStringMap(value, path, function(note, notePath)
        if type(note) ~= "string" or note == "" then
            return nil, notePath .. " must be a non-empty string"
        end
        return true
    end)
end

function AccountData.guildKey(identity)
    if type(identity) ~= "table"
        or type(identity.name) ~= "string"
        or identity.name == ""
        or type(identity.realm) ~= "table"
        or type(identity.realm.slug) ~= "string"
        or identity.realm.slug == "" then
        return nil, "guild identity requires a name and normalized realm"
    end

    local realmKey = Realm.key(identity.realm.slug)
    if type(realmKey) ~= "string" or realmKey == "" then
        return nil, "guild identity requires a normalized realm"
    end
    return tostring(#identity.name) .. ":" .. identity.name .. ":" .. realmKey
end

function AccountData.newModel()
    return {
        schemaVersion = AccountData.CURRENT_SCHEMA_VERSION,
        settings = {
            minimapAngle = AccountData.DEFAULT_MINIMAP_ANGLE,
        },
        guilds = {},
    }
end

function AccountData.newGuild(identity)
    local copiedIdentity, identityError = SavedData.copyGuildIdentity(identity)
    if not copiedIdentity then
        return nil, identityError
    end
    return {
        identity = copiedIdentity,
        rosterInitialized = false,
        roster = emptyDataset("roster"),
        bankInitialized = false,
        bank = emptyDataset("bank"),
        mainAltGroups = {},
        characterNotes = {},
    }
end

function AccountData.validate(model)
    if type(model) ~= "table" then
        return nil, "account data must be a table"
    end
    for key in pairs(model) do
        if key ~= "schemaVersion" and key ~= "settings" and key ~= "guilds" then
            return nil, "account data contains unexpected field " .. tostring(key)
        end
    end
    if model.schemaVersion ~= AccountData.CURRENT_SCHEMA_VERSION then
        return nil, "account data schemaVersion must be "
            .. AccountData.CURRENT_SCHEMA_VERSION
    end
    if type(model.guilds) ~= "table" then
        return nil, "account data.guilds must be a table"
    end
    if type(model.settings) ~= "table" then
        return nil, "account data.settings must be a table"
    end
    for key in pairs(model.settings) do
        if key ~= "minimapAngle" then
            return nil, "account data.settings contains unexpected field " .. tostring(key)
        end
    end
    local minimapAngle = model.settings.minimapAngle
    if type(minimapAngle) ~= "number"
        or minimapAngle ~= minimapAngle
        or minimapAngle == math.huge
        or minimapAngle == -math.huge
        or minimapAngle < 0
        or minimapAngle >= 360 then
        return nil, "account data.settings.minimapAngle must be at least 0 and less than 360"
    end

    for key, guild in pairs(model.guilds) do
        if type(key) ~= "string" or key == "" or type(guild) ~= "table" then
            return nil, "account data.guilds must use non-empty string keys and table values"
        end
        local allowed = {
            identity = true,
            rosterInitialized = true,
            roster = true,
            bankInitialized = true,
            bank = true,
            mainAltGroups = true,
            characterNotes = true,
        }
        for field in pairs(guild) do
            if not allowed[field] then
                return nil, "account data.guilds[" .. key
                    .. "] contains unexpected field " .. tostring(field)
            end
        end

        local canonicalIdentity, identityError = SavedData.copyGuildIdentity(guild.identity)
        if not canonicalIdentity then
            return nil, identityError
        end
        if canonicalIdentity.realm.name ~= guild.identity.realm.name
            or canonicalIdentity.realm.slug ~= guild.identity.realm.slug then
            return nil, "account data guild identity realm must be canonical"
        end
        local expectedKey, keyError = AccountData.guildKey(guild.identity)
        if not expectedKey then
            return nil, keyError
        end
        if key ~= expectedKey then
            return nil, "account data guild key does not match its identity"
        end

        for _, datasetName in ipairs({ "roster", "bank" }) do
            local initializedField = datasetName .. "Initialized"
            if type(guild[initializedField]) ~= "boolean" then
                return nil, "account data.guilds[" .. key .. "]."
                    .. initializedField .. " must be a boolean"
            end
            local valid, validationError = validateDataset(datasetName, guild[datasetName])
            if not valid then
                return nil, validationError
            end
            if guild[datasetName].guild ~= nil then
                local datasetKey, datasetKeyError = AccountData.guildKey(
                    guild[datasetName].guild
                )
                if not datasetKey then
                    return nil, datasetKeyError
                end
                if datasetKey ~= key then
                    return nil, "account data " .. datasetName
                        .. " dataset does not match its guild partition"
                end
            end
            if not guild[initializedField]
                and not datasetIsEmpty(datasetName, guild[datasetName]) then
                return nil, "uninitialized " .. datasetName .. " data must be empty"
            end
        end

        local valid, validationError = validateGroups(
            guild.mainAltGroups,
            "account data.guilds[" .. key .. "].mainAltGroups"
        )
        if not valid then
            return nil, validationError
        end
        valid, validationError = validateNotes(
            guild.characterNotes,
            "account data.guilds[" .. key .. "].characterNotes"
        )
        if not valid then
            return nil, validationError
        end
    end
    return true
end

function AccountData.load(saved)
    if saved == nil then
        return {
            enabled = true,
            status = "ready",
            model = AccountData.newModel(),
            initialized = true,
        }
    end
    if type(saved) ~= "table" then
        return disabledState("corrupt", "account data must be a table", saved)
    end
    if not isInteger(saved.schemaVersion) or saved.schemaVersion < 1 then
        return disabledState(
            "corrupt",
            "account data has a missing or invalid schemaVersion",
            saved
        )
    end
    if saved.schemaVersion > AccountData.CURRENT_SCHEMA_VERSION then
        return disabledState(
            "incompatible",
            "account data uses unsupported schema version " .. saved.schemaVersion,
            saved
        )
    end
    local working, copyError = deepCopy(saved)
    if not working then
        return disabledState("corrupt", copyError, saved)
    end
    local migratedFrom
    if working.schemaVersion == 1 then
        for key in pairs(working) do
            if key ~= "schemaVersion" and key ~= "guilds" then
                return disabledState(
                    "corrupt",
                    "account data contains unexpected field " .. tostring(key),
                    saved
                )
            end
        end
        migratedFrom = 1
        working.schemaVersion = 2
        working.settings = {
            minimapAngle = AccountData.DEFAULT_MINIMAP_ANGLE,
        }
    end
    local valid, validationError = AccountData.validate(working)
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

function AccountData.findGuild(model, identity)
    local key, keyError = AccountData.guildKey(identity)
    if not key then
        return nil, keyError
    end
    return model.guilds[key], key
end

function AccountData.replaceDataset(model, identity, datasetName, dataset)
    if datasetName ~= "roster" and datasetName ~= "bank" then
        return nil, "dataset name must be roster or bank"
    end
    local valid, validationError = AccountData.validate(model)
    if not valid then
        return nil, validationError
    end
    valid, validationError = validateDataset(datasetName, dataset)
    if not valid then
        return nil, validationError
    end

    local replacement, copyError = deepCopy(model)
    if not replacement then
        return nil, copyError
    end
    local guild, key = AccountData.findGuild(replacement, identity)
    if not guild then
        local guildError
        guild, guildError = AccountData.newGuild(identity)
        if not guild then
            return nil, guildError
        end
        replacement.guilds[key] = guild
    end
    local copiedDataset
    copiedDataset, copyError = deepCopy(dataset)
    if not copiedDataset then
        return nil, copyError
    end
    guild[datasetName] = copiedDataset
    guild[datasetName .. "Initialized"] = true

    valid, validationError = AccountData.validate(replacement)
    if not valid then
        return nil, validationError
    end
    return replacement, guild, key
end

function AccountData.replaceRosterAndFeatures(
    model,
    identity,
    roster,
    groups,
    notes
)
    local valid, validationError = AccountData.validate(model)
    if not valid then
        return nil, validationError
    end
    valid, validationError = validateDataset("roster", roster)
    if not valid then
        return nil, validationError
    end
    valid, validationError = validateGroups(groups, "mainAltGroups")
    if not valid then
        return nil, validationError
    end
    valid, validationError = validateNotes(notes, "characterNotes")
    if not valid then
        return nil, validationError
    end

    local replacement, copyError = deepCopy(model)
    if not replacement then
        return nil, copyError
    end
    local guild, key = AccountData.findGuild(replacement, identity)
    if not guild then
        local guildError
        guild, guildError = AccountData.newGuild(identity)
        if not guild then
            return nil, guildError
        end
        replacement.guilds[key] = guild
    end

    guild.roster, copyError = deepCopy(roster)
    if not guild.roster then
        return nil, copyError
    end
    guild.mainAltGroups, copyError = deepCopy(groups)
    if not guild.mainAltGroups then
        return nil, copyError
    end
    guild.characterNotes, copyError = deepCopy(notes)
    if not guild.characterNotes then
        return nil, copyError
    end
    guild.rosterInitialized = true

    valid, validationError = AccountData.validate(replacement)
    if not valid then
        return nil, validationError
    end
    return replacement, guild, key
end

function AccountData.replaceMainAltGroups(model, identity, groups)
    local valid, validationError = AccountData.validate(model)
    if not valid then
        return nil, validationError
    end
    valid, validationError = validateGroups(groups, "mainAltGroups")
    if not valid then
        return nil, validationError
    end

    local replacement, copyError = deepCopy(model)
    if not replacement then
        return nil, copyError
    end
    local guild, key = AccountData.findGuild(replacement, identity)
    if not guild then
        local guildError
        guild, guildError = AccountData.newGuild(identity)
        if not guild then
            return nil, guildError
        end
        replacement.guilds[key] = guild
    end
    guild.mainAltGroups, copyError = deepCopy(groups)
    if not guild.mainAltGroups then
        return nil, copyError
    end

    valid, validationError = AccountData.validate(replacement)
    if not valid then
        return nil, validationError
    end
    return replacement, guild, key
end

function AccountData.replaceCharacterNote(model, identity, characterIdentity, note)
    local valid, validationError = AccountData.validate(model)
    if not valid then
        return nil, validationError
    end
    if type(characterIdentity) ~= "string" or characterIdentity == "" then
        return nil, "character note identity must be a non-empty string"
    end
    if note ~= nil and (type(note) ~= "string" or note == "") then
        return nil, "character note must be a non-empty string or nil"
    end
    if note ~= nil
        and characterCount(note) > AccountData.MAX_CHARACTER_NOTE_LENGTH then
        return nil, "character note must not exceed "
            .. AccountData.MAX_CHARACTER_NOTE_LENGTH
            .. " characters"
    end

    local replacement, copyError = deepCopy(model)
    if not replacement then
        return nil, copyError
    end
    local guild, key = AccountData.findGuild(replacement, identity)
    if not guild then
        local guildError
        guild, guildError = AccountData.newGuild(identity)
        if not guild then
            return nil, guildError
        end
        replacement.guilds[key] = guild
    end
    guild.characterNotes[characterIdentity] = note

    valid, validationError = AccountData.validate(replacement)
    if not valid then
        return nil, validationError
    end
    return replacement, guild, key
end

function AccountData.resetGuild(model, identity)
    local valid, validationError = AccountData.validate(model)
    if not valid then
        return nil, validationError
    end
    local replacement, copyError = deepCopy(model)
    if not replacement then
        return nil, copyError
    end
    local guild, key = AccountData.findGuild(replacement, identity)
    if not guild then
        local guildError
        guild, guildError = AccountData.newGuild(identity)
        if not guild then
            return nil, guildError
        end
        replacement.guilds[key] = guild
    end
    guild.rosterInitialized = true
    guild.roster = emptyDataset("roster")
    guild.bankInitialized = true
    guild.bank = emptyDataset("bank")
    guild.mainAltGroups = {}
    guild.characterNotes = {}

    valid, validationError = AccountData.validate(replacement)
    if not valid then
        return nil, validationError
    end
    return replacement, guild, key
end

function AccountData.view(model, identity, ui)
    local guild = identity and AccountData.findGuild(model, identity) or nil
    return {
        roster = guild and guild.roster or emptyDataset("roster"),
        bank = guild and guild.bank or emptyDataset("bank"),
        mainAltGroups = guild and guild.mainAltGroups or {},
        characterNotes = guild and guild.characterNotes or {},
        ui = ui or {},
    }
end

if type(RGMS) == "table" then
    RGMS.AccountData = AccountData
end

return AccountData
