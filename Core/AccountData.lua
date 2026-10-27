-- Versioned account-wide storage partitioned by guild. Deprecated roster data
-- is migrated separately from bank data so each dataset remains independent.

local _, RGMS = ...

local AccountData = {}
local Realm = type(RGMS) == "table" and RGMS.Realm or require("Core.Realm")
local SavedData = type(RGMS) == "table"
    and RGMS.SavedData
    or require("Core.SavedData")

AccountData.CURRENT_SCHEMA_VERSION = 7
AccountData.MAX_CHARACTER_NOTE_LENGTH = 5500
AccountData.MAX_TAG_NAME_LENGTH = 32
AccountData.DEFAULT_MINIMAP_POSITION = 225

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

local function validateDenseArray(value, path, validateValue)
    if type(value) ~= "table" then
        return nil, path .. " must be an array"
    end
    local count = 0
    for key in pairs(value) do
        if not isInteger(key) or key < 1 then
            return nil, path .. " must contain only positive integer indexes"
        end
        count = count + 1
    end
    if count ~= #value then
        return nil, path .. " must not contain gaps"
    end
    for index, item in ipairs(value) do
        local valid, validationError = validateValue(item, path .. "[" .. index .. "]")
        if not valid then
            return nil, validationError
        end
    end
    return true
end

local function validateProvisions(value, nextId, path)
    if not isInteger(nextId) or nextId < 1 then
        return nil, path .. " next ID must be a positive integer"
    end
    local seenIds = {}
    local largestId = 0
    local valid, validationError = validateDenseArray(value, path, function(provision, itemPath)
        if type(provision) ~= "table" then
            return nil, itemPath .. " must be a table"
        end
        for key in pairs(provision) do
            if key ~= "id" and key ~= "name" and key ~= "quality" and key ~= "target" then
                return nil, itemPath .. " contains unexpected field " .. tostring(key)
            end
        end
        if not isInteger(provision.id) or provision.id < 1 then
            return nil, itemPath .. ".id must be a positive integer"
        end
        if seenIds[provision.id] then
            return nil, itemPath .. ".id must be unique"
        end
        seenIds[provision.id] = true
        largestId = math.max(largestId, provision.id)
        if type(provision.name) ~= "string" or provision.name == "" then
            return nil, itemPath .. ".name must be a non-empty string"
        end
        local length = characterCount(provision.name)
        if length < 3 or length > 100
            or provision.name ~= string.gsub(string.gsub(provision.name, "^%s+", ""), "%s+$", "") then
            return nil, itemPath .. ".name must be trimmed and contain 3 through 100 characters"
        end
        if provision.quality ~= "silver"
            and provision.quality ~= "gold"
            and provision.quality ~= "either" then
            return nil, itemPath .. ".quality must be silver, gold, or either"
        end
        if not isInteger(provision.target)
            or provision.target < 1 or provision.target > 99999 then
            return nil, itemPath .. ".target must be an integer from 1 through 99999"
        end
        return true
    end)
    if not valid then
        return nil, validationError
    end
    if nextId <= largestId then
        return nil, path .. " next ID must follow every saved provision ID"
    end
    return true
end

local function validateRosterObservation(value, path)
    if value == nil then
        return true
    end
    if type(value) ~= "table" or type(value.scannedAt) ~= "table"
        or type(value.members) ~= "table" then
        return nil, path .. " must contain scannedAt and members"
    end
    for key in pairs(value) do
        if key ~= "scannedAt" and key ~= "members" then
            return nil, path .. " contains unexpected field " .. tostring(key)
        end
    end
    if not isInteger(value.scannedAt.unixSeconds)
        or type(value.scannedAt.iso8601) ~= "string" then
        return nil, path .. ".scannedAt is invalid"
    end
    for key in pairs(value.scannedAt) do
        if key ~= "unixSeconds" and key ~= "iso8601" then
            return nil, path .. ".scannedAt contains unexpected field " .. tostring(key)
        end
    end
    local seenIdentities = {}
    return validateDenseArray(value.members, path .. ".members", function(member, memberPath)
        if type(member) ~= "table" then
            return nil, memberPath .. " must be a table"
        end
        for key in pairs(member) do
            if key ~= "identity" and key ~= "name"
                and key ~= "rankIndex" and key ~= "rankName" then
                return nil, memberPath .. " contains unexpected field " .. tostring(key)
            end
        end
        if type(member.identity) ~= "string" or member.identity == ""
            or member.identity ~= string.lower(member.identity)
            or type(member.name) ~= "string" or member.name == ""
            or not isInteger(member.rankIndex)
            or type(member.rankName) ~= "string" or member.rankName == "" then
            return nil, memberPath .. " is invalid"
        end
        if seenIdentities[member.identity] then
            return nil, memberPath .. ".identity must be unique"
        end
        seenIdentities[member.identity] = true
        return true
    end)
end

local function validateNewsSets(value, path)
    local seenIds = {}
    return validateDenseArray(value, path, function(set, setPath)
        if type(set) ~= "table" then
            return nil, setPath .. " must be a table"
        end
        for key in pairs(set) do
            if key ~= "id" and key ~= "createdDate"
                and key ~= "joiningMembers" and key ~= "leavingMembers"
                and key ~= "rankChanges" then
                return nil, setPath .. " contains unexpected field " .. tostring(key)
            end
        end
        if type(set.id) ~= "string" or set.id == "" or seenIds[set.id] then
            return nil, setPath .. ".id must be unique and non-empty"
        end
        seenIds[set.id] = true
        if type(set.createdDate) ~= "string"
            or not string.match(set.createdDate, "^%d%d%d%d%-%d%d%-%d%d$") then
            return nil, setPath .. ".createdDate must use YYYY-MM-DD form"
        end
        local function validateName(name, namePath)
            if type(name) ~= "string" or name == "" then
                return nil, namePath .. " must be a non-empty string"
            end
            return true
        end
        local valid, validationError = validateDenseArray(
            set.joiningMembers,
            setPath .. ".joiningMembers",
            validateName
        )
        if not valid then return nil, validationError end
        valid, validationError = validateDenseArray(
            set.leavingMembers,
            setPath .. ".leavingMembers",
            validateName
        )
        if not valid then return nil, validationError end
        valid, validationError = validateDenseArray(
            set.rankChanges,
            setPath .. ".rankChanges",
            function(change, changePath)
                if type(change) ~= "table"
                    or type(change.name) ~= "string" or change.name == ""
                    or type(change.rankName) ~= "string" or change.rankName == "" then
                    return nil, changePath .. " is invalid"
                end
                for key in pairs(change) do
                    if key ~= "name" and key ~= "rankName" then
                        return nil, changePath .. " contains unexpected field " .. tostring(key)
                    end
                end
                return true
            end
        )
        if not valid then return nil, validationError end
        if #set.joiningMembers == 0 and #set.leavingMembers == 0
            and #set.rankChanges == 0 then
            return nil, setPath .. " must contain at least one change"
        end
        return true
    end)
end

local function newTags()
    return {
        definitions = { me = true },
        assignments = {},
    }
end

local function normalizeTagName(value)
    local trimmed = string.match(value, "^%s*(.-)%s*$") or ""
    return (string.gsub(trimmed, "[A-Z]", function(character)
        return string.char(string.byte(character) + 32)
    end))
end

local function validateTags(value, path)
    if type(value) ~= "table"
        or type(value.definitions) ~= "table"
        or type(value.assignments) ~= "table" then
        return nil, path .. " must contain definitions and assignments"
    end
    for key in pairs(value) do
        if key ~= "definitions" and key ~= "assignments" then
            return nil, path .. " contains unexpected field " .. tostring(key)
        end
    end
    if value.definitions.me ~= true then
        return nil, path .. ".definitions must contain me"
    end
    for name, present in pairs(value.definitions) do
        if type(name) ~= "string" or name == "" or present ~= true then
            return nil, path .. ".definitions must use non-empty string names"
        end
        if normalizeTagName(name) ~= name then
            return nil, path .. ".definitions names must be normalized"
        end
        if characterCount(name) > AccountData.MAX_TAG_NAME_LENGTH then
            return nil, path .. ".definitions names must not exceed "
                .. AccountData.MAX_TAG_NAME_LENGTH .. " characters"
        end
    end
    for identity, assigned in pairs(value.assignments) do
        if type(identity) ~= "string" or identity == ""
            or type(assigned) ~= "table" or next(assigned) == nil then
            return nil, path .. ".assignments must use non-empty character entries"
        end
        for name, present in pairs(assigned) do
            if present ~= true or value.definitions[name] ~= true then
                return nil, path .. ".assignments must reference saved definitions"
            end
        end
    end
    return true
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
            minimapPos = AccountData.DEFAULT_MINIMAP_POSITION,
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
        tags = newTags(),
        rosterObservation = nil,
        newsSets = {},
        provisions = {},
        nextProvisionId = 1,
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
        if key ~= "minimapPos" then
            return nil, "account data.settings contains unexpected field " .. tostring(key)
        end
    end
    local minimapPos = model.settings.minimapPos
    if type(minimapPos) ~= "number"
        or minimapPos ~= minimapPos
        or minimapPos == math.huge
        or minimapPos == -math.huge
        or minimapPos < 0
        or minimapPos >= 360 then
        return nil, "account data.settings.minimapPos must be at least 0 and less than 360"
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
            tags = true,
            rosterObservation = true,
            newsSets = true,
            provisions = true,
            nextProvisionId = true,
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
        valid, validationError = validateTags(
            guild.tags,
            "account data.guilds[" .. key .. "].tags"
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
        valid, validationError = validateRosterObservation(
            guild.rosterObservation,
            "account data.guilds[" .. key .. "].rosterObservation"
        )
        if not valid then
            return nil, validationError
        end
        valid, validationError = validateNewsSets(
            guild.newsSets,
            "account data.guilds[" .. key .. "].newsSets"
        )
        if not valid then
            return nil, validationError
        end
        valid, validationError = validateProvisions(
            guild.provisions,
            guild.nextProvisionId,
            "account data.guilds[" .. key .. "].provisions"
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
            minimapAngle = AccountData.DEFAULT_MINIMAP_POSITION,
        }
    end
    if working.schemaVersion == 2 then
        if type(working.settings) ~= "table" then
            return disabledState(
                "corrupt",
                "account data.settings must be a table",
                saved
            )
        end
        for key in pairs(working.settings) do
            if key ~= "minimapAngle" then
                return disabledState(
                    "corrupt",
                    "account data.settings contains unexpected field " .. tostring(key),
                    saved
                )
            end
        end
        local minimapAngle = working.settings.minimapAngle
        if type(minimapAngle) ~= "number"
            or minimapAngle ~= minimapAngle
            or minimapAngle == math.huge
            or minimapAngle == -math.huge
            or minimapAngle < 0
            or minimapAngle >= 360 then
            return disabledState(
                "corrupt",
                "account data.settings.minimapAngle must be at least 0 and less than 360",
                saved
            )
        end
        migratedFrom = migratedFrom or 2
        working.schemaVersion = 3
        working.settings = {
            minimapPos = minimapAngle,
        }
    end
    if working.schemaVersion == 3 then
        if type(working.guilds) ~= "table" then
            return disabledState(
                "corrupt",
                "account data.guilds must be a table",
                saved
            )
        end
        for _, guild in pairs(working.guilds) do
            if type(guild) ~= "table" then
                return disabledState(
                    "corrupt",
                    "account data guild partitions must be tables",
                    saved
                )
            end
            guild.tags = newTags()
        end
        migratedFrom = migratedFrom or 3
        working.schemaVersion = 4
    end
    if working.schemaVersion == 4 then
        if type(working.guilds) ~= "table" then
            return disabledState(
                "corrupt",
                "account data.guilds must be a table",
                saved
            )
        end
        for _, guild in pairs(working.guilds) do
            if type(guild) ~= "table" then
                return disabledState(
                    "corrupt",
                    "account data guild partitions must be tables",
                    saved
                )
            end
            guild.rosterObservation = nil
            guild.newsSets = {}
        end
        migratedFrom = migratedFrom or 4
        working.schemaVersion = 5
    end
    if working.schemaVersion == 5 then
        if type(working.guilds) ~= "table" then
            return disabledState(
                "corrupt",
                "account data.guilds must be a table",
                saved
            )
        end
        for _, guild in pairs(working.guilds) do
            if type(guild) ~= "table" then
                return disabledState(
                    "corrupt",
                    "account data guild partitions must be tables",
                    saved
                )
            end
            guild.provisions = {}
            guild.nextProvisionId = 1
        end
        migratedFrom = migratedFrom or 5
        working.schemaVersion = 6
    end
    if working.schemaVersion == 6 then
        if type(working.guilds) ~= "table" then
            return disabledState(
                "corrupt",
                "account data.guilds must be a table",
                saved
            )
        end
        for key, guild in pairs(working.guilds) do
            if type(guild) ~= "table" then
                return disabledState(
                    "corrupt",
                    "account data guild partitions must be tables",
                    saved
                )
            end
            if type(guild.provisions) ~= "table" then
                return disabledState(
                    "corrupt",
                    "account data guild provisions must be a table",
                    saved
                )
            end
            local provisionsValid, provisionsError = validateProvisions(
                guild.provisions,
                guild.nextProvisionId,
                "account data.guilds[" .. tostring(key) .. "].provisions"
            )
            if not provisionsValid then
                return disabledState("corrupt", provisionsError, saved)
            end
            table.sort(guild.provisions, function(left, right)
                local leftName = string.lower(left.name)
                local rightName = string.lower(right.name)
                if leftName ~= rightName then
                    return leftName < rightName
                end
                return left.id < right.id
            end)
        end
        migratedFrom = migratedFrom or 6
        working.schemaVersion = 7
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
    notes,
    tags
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
    if tags ~= nil then
        valid, validationError = validateTags(tags, "tags")
        if not valid then
            return nil, validationError
        end
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
    if tags ~= nil then
        guild.tags, copyError = deepCopy(tags)
        if not guild.tags then
            return nil, copyError
        end
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

function AccountData.replaceCharacterTags(model, identity, tags)
    local valid, validationError = AccountData.validate(model)
    if not valid then
        return nil, validationError
    end
    valid, validationError = validateTags(tags, "tags")
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
    guild.tags, copyError = deepCopy(tags)
    if not guild.tags then
        return nil, copyError
    end

    valid, validationError = AccountData.validate(replacement)
    if not valid then
        return nil, validationError
    end
    return replacement, guild, key
end

function AccountData.replaceRosterNews(model, identity, observation, newsSets)
    local valid, validationError = AccountData.validate(model)
    if not valid then
        return nil, validationError
    end
    valid, validationError = validateRosterObservation(observation, "rosterObservation")
    if not valid then
        return nil, validationError
    end
    valid, validationError = validateNewsSets(newsSets, "newsSets")
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
    guild.rosterObservation, copyError = deepCopy(observation)
    if observation ~= nil and not guild.rosterObservation then
        return nil, copyError
    end
    guild.newsSets, copyError = deepCopy(newsSets)
    if not guild.newsSets then
        return nil, copyError
    end

    valid, validationError = AccountData.validate(replacement)
    if not valid then
        return nil, validationError
    end
    return replacement, guild, key
end

function AccountData.replaceProvisions(model, identity, provisions, nextProvisionId)
    local valid, validationError = AccountData.validate(model)
    if not valid then
        return nil, validationError
    end
    valid, validationError = validateProvisions(
        provisions,
        nextProvisionId,
        "provisions"
    )
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
    guild.provisions, copyError = deepCopy(provisions)
    if not guild.provisions then
        return nil, copyError
    end
    guild.nextProvisionId = nextProvisionId

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
    guild.tags = newTags()
    guild.rosterObservation = nil
    guild.newsSets = {}
    guild.provisions = {}
    guild.nextProvisionId = 1

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
        tags = guild and guild.tags or newTags(),
        newsSets = guild and guild.newsSets or {},
        provisions = guild and guild.provisions or {},
        nextProvisionId = guild and guild.nextProvisionId or 1,
        ui = ui or {},
    }
end

if type(RGMS) == "table" then
    RGMS.AccountData = AccountData
end

return AccountData
