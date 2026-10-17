local accountData = require("Core.AccountData")
local bankMigration = require("Core.BankMigration")
local datasetOwnership = require("Core.DatasetOwnership")
local fixtures = require("Tests.fixtures")
local savedData = require("Core.SavedData")
local test = require("Tests.lib.runner")

local function guild(name, realm)
    return fixtures.guild_identity({
        id = "guild-" .. realm,
        name = name,
        realm = { name = realm, slug = realm },
    })
end

local function legacyCharacter(identity, quantity, position)
    local character = fixtures.saved_model()
    character.bank.guild = identity
    character.bank.slots[1].quantity = quantity or 20
    character.ui.windowPosition = position or fixtures.window_position()
    return character
end

local function completedBank(identity, quantity)
    return legacyCharacter(identity, quantity).bank
end

return {
    test.case("eligible legacy bank seeds only the current guild", function()
        local currentGuild = guild("Night Shift", "area-52")
        local position = fixtures.window_position({ x = 444 })
        local character = legacyCharacter(currentGuild, 37, position)
        local account, initialized, imported = bankMigration.initialize(
            accountData.newModel(),
            character,
            currentGuild
        )

        test.assert_true(initialized)
        test.assert_true(imported)
        local partition = accountData.findGuild(account, currentGuild)
        test.assert_true(partition.bankInitialized)
        test.assert_false(partition.rosterInitialized)
        test.assert_equal(partition.bank.slots[1].quantity, 37)
        test.assert_equal(character.bank.slots[1].quantity, 37)
        test.assert_equal(character.ui.windowPosition, position)
    end),

    test.case("foreign legacy bank is ignored without creating its guild", function()
        local currentGuild = guild("Night Shift", "area-52")
        local formerGuild = guild("Former Guild", "illidan")
        local character = legacyCharacter(formerGuild, 11)
        local account, initialized, imported = bankMigration.initialize(
            accountData.newModel(),
            character,
            currentGuild
        )

        test.assert_true(initialized)
        test.assert_false(imported)
        local current = accountData.findGuild(account, currentGuild)
        test.assert_true(current.bankInitialized)
        test.assert_equal(current.bank, { tabs = {}, slots = {} })
        test.assert_nil(accountData.findGuild(account, formerGuild))
        test.assert_equal(character.bank.slots[1].quantity, 11)
    end),

    test.case("roster initialization does not suppress bank migration", function()
        local identity = guild("Night Shift", "area-52")
        local character = legacyCharacter(identity, 29)
        character.roster.guild = identity
        local account = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            character.roster
        ))
        local beforeRoster = accountData.findGuild(account, identity).roster
        account = assert(bankMigration.initialize(account, character, identity))

        local partition = accountData.findGuild(account, identity)
        test.assert_true(partition.rosterInitialized)
        test.assert_true(partition.bankInitialized)
        test.assert_equal(partition.roster, beforeRoster)
        test.assert_equal(partition.bank.slots[1].quantity, 29)
    end),

    test.case("initialized empty bank remains authoritative", function()
        local identity = guild("Night Shift", "area-52")
        local account = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "bank",
            savedData.newModel().bank
        ))
        local character = legacyCharacter(identity, 99)
        local result, initialized, imported = bankMigration.initialize(
            account,
            character,
            identity
        )

        test.assert_true(result == account)
        test.assert_false(initialized)
        test.assert_false(imported)
        test.assert_equal(
            accountData.findGuild(result, identity).bank,
            { tabs = {}, slots = {} }
        )
        test.assert_equal(character.bank.slots[1].quantity, 99)
    end),

    test.case("a later character cannot merge into an initialized bank", function()
        local identity = guild("Night Shift", "area-52")
        local account = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "bank",
            completedBank(identity, 41)
        ))
        local secondCharacter = legacyCharacter(identity, 88)
        local result = assert(bankMigration.initialize(
            account,
            secondCharacter,
            identity
        ))

        test.assert_equal(
            accountData.findGuild(result, identity).bank.slots[1].quantity,
            41
        )
        test.assert_equal(secondCharacter.bank.slots[1].quantity, 88)
    end),

    test.case("only a successful bank commit cleans the current character", function()
        local identity = guild("Night Shift", "area-52")
        local account = accountData.newModel()
        local position = fixtures.window_position({ x = 333, y = -222 })
        local character = legacyCharacter(identity, 20, position)
        local originalRoster = character.roster
        local otherCharacter = legacyCharacter(identity, 77)
        local cleanups = 0
        local controller = datasetOwnership.create({
            savedData = savedData,
            accountData = accountData,
            getSavedData = function() return account end,
            prepareCharacterCommit = function(datasetName)
                test.assert_equal(datasetName, "bank")
                cleanups = cleanups + 1
                return bankMigration.cleanup(character)
            end,
            commit = function(newAccount, _, newCharacter)
                account = newAccount
                character = newCharacter or character
            end,
            print = function() end,
        })

        local failed = assert(controller:begin("bank", identity))
        failed.dataset = completedBank(identity, 1)
        test.assert_false(controller:finish(failed, "failed"))
        local canceled = assert(controller:begin("bank", identity))
        canceled.dataset = completedBank(identity, 2)
        test.assert_false(controller:finish(canceled, "canceled"))
        test.assert_equal(cleanups, 0)
        test.assert_equal(character.bank.slots[1].quantity, 20)

        local successful = assert(controller:begin("bank", identity))
        successful.dataset = completedBank(identity, 55)
        test.assert_true(controller:finish(successful, "success"))

        test.assert_equal(cleanups, 1)
        test.assert_equal(
            accountData.findGuild(account, identity).bank.slots[1].quantity,
            55
        )
        test.assert_equal(character.bank, { tabs = {}, slots = {} })
        test.assert_equal(character.roster, originalRoster)
        test.assert_equal(character.ui.windowPosition, position)
        test.assert_equal(otherCharacter.bank.slots[1].quantity, 77)
    end),
}
