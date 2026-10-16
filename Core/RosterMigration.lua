-- Conservative migration of the logged-in character's deprecated roster into
-- the current guild's account-wide partition. Bank migration is intentionally
-- independent and remains owned by its dedicated migration path.

local _, RGMS = ...

local RosterMigration = {}
local AccountData = type(RGMS) == "table"
    and RGMS.AccountData
    or require("Core.AccountData")
local SavedData = type(RGMS) == "table"
    and RGMS.SavedData
    or require("Core.SavedData")

local function sameGuild(left, right)
    if left == nil or right == nil then
        return false
    end
    local leftKey = AccountData.guildKey(left)
    local rightKey = AccountData.guildKey(right)
    return leftKey ~= nil and rightKey ~= nil and leftKey == rightKey
end

function RosterMigration.initialize(accountModel, characterModel, guildIdentity)
    local accountState = AccountData.load(accountModel)
    if not accountState.enabled then
        return nil, accountState.error
    end
    local characterState = SavedData.load(characterModel)
    if not characterState.enabled then
        return nil, characterState.error
    end

    local guildKey, guildKeyError = AccountData.guildKey(guildIdentity)
    if not guildKey then
        return nil, guildKeyError
    end
    local guild = accountState.model.guilds[guildKey]
    if guild and guild.rosterInitialized then
        return accountModel, false, false
    end

    local legacyRoster = characterState.model.roster
    local imported = sameGuild(legacyRoster.guild, guildIdentity)
    local seed = imported and legacyRoster or SavedData.newModel().roster
    local replacement, replaceError = AccountData.replaceDataset(
        accountState.model,
        guildIdentity,
        "roster",
        seed
    )
    if not replacement then
        return nil, replaceError
    end
    return replacement, true, imported
end

function RosterMigration.cleanup(characterModel)
    return SavedData.resetDatasetObservations(characterModel, "roster")
end

if type(RGMS) == "table" then
    RGMS.RosterMigration = RosterMigration
end

return RosterMigration
