-- Conservative migration of the logged-in character's deprecated bank into
-- the current guild's account-wide partition. Initialization is invoked only
-- by the bank scanner after the guild bank is open.

local _, RGMS = ...

local BankMigration = {}
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

function BankMigration.initialize(accountModel, characterModel, guildIdentity)
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
    if guild and guild.bankInitialized then
        return accountModel, false, false
    end

    local legacyBank = characterState.model.bank
    local imported = sameGuild(legacyBank.guild, guildIdentity)
    local seed = imported and legacyBank or SavedData.newModel().bank
    local replacement, replaceError = AccountData.replaceDataset(
        accountState.model,
        guildIdentity,
        "bank",
        seed
    )
    if not replacement then
        return nil, replaceError
    end
    return replacement, true, imported
end

function BankMigration.cleanup(characterModel)
    return SavedData.resetDatasetObservations(characterModel, "bank")
end

if type(RGMS) == "table" then
    RGMS.BankMigration = BankMigration
end

return BankMigration
