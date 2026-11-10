local accountData = require("Core.AccountData")
local clientFlavor = require("Core.ClientFlavor")
local datasetOwnership = require("Core.DatasetOwnership")
local fixtures = require("Tests.fixtures")
local guildIdentity = require("Core.GuildIdentity")
local rosterMigration = require("Core.RosterMigration")
local savedData = require("Core.SavedData")
local test = require("Tests.lib.runner")

local function guild(name, realm, region)
    return assert(guildIdentity.create({
        flavor = clientFlavor.RETAIL,
        region = region or "US",
        name = name,
        realm = { name = realm, slug = realm },
    }))
end

local function foreverGuild(name, region, clubId)
    return assert(guildIdentity.create({
        flavor = clientFlavor.FOREVER,
        region = region,
        name = name,
        clubId = clubId,
    }))
end

local function legacyCharacter(identity, memberName, position)
    local character = savedData.newModel()
    local memberRealm = identity.realm and identity.realm.slug or "Forever"
    character.roster = {
        guild = identity,
        scannedAt = fixtures.timestamp(),
        ranks = { fixtures.roster_rank() },
        members = {
            fixtures.roster_member({
                name = memberName,
                realm = memberRealm,
                displayName = memberName .. "-" .. memberRealm,
            }),
        },
    }
    character.bank = fixtures.saved_model().bank
    character.bank.guild = identity
    character.ui.windowPosition = position or fixtures.window_position()
    return character
end

local function completedRoster(identity, memberName)
    local model = legacyCharacter(identity, memberName)
    return model.roster
end

return {
    test.case("eligible legacy roster seeds only the current guild", function()
        local currentGuild = guild("Night Shift", "area-52")
        local position = fixtures.window_position({ x = 444 })
        local character = legacyCharacter(currentGuild, "Legacy", position)
        local account, initialized, imported = rosterMigration.initialize(
            accountData.newModel(),
            character,
            currentGuild
        )

        test.assert_true(initialized)
        test.assert_true(imported)
        local partition = accountData.findGuild(account, currentGuild)
        test.assert_true(partition.rosterInitialized)
        test.assert_false(partition.bankInitialized)
        test.assert_equal(partition.roster.members[1].name, "Legacy")
        test.assert_equal(character.roster.members[1].name, "Legacy")
        test.assert_equal(character.ui.windowPosition, position)
    end),

    test.case("foreign legacy roster is ignored without creating its guild", function()
        local currentGuild = guild("Night Shift", "area-52")
        local formerGuild = guild("Former Guild", "illidan")
        local character = legacyCharacter(formerGuild, "Former", nil)
        local account, initialized, imported = rosterMigration.initialize(
            accountData.newModel(),
            character,
            currentGuild
        )

        test.assert_true(initialized)
        test.assert_false(imported)
        local current = accountData.findGuild(account, currentGuild)
        test.assert_true(current.rosterInitialized)
        test.assert_equal(current.roster, { ranks = {}, members = {} })
        test.assert_nil(accountData.findGuild(account, formerGuild))
        test.assert_equal(character.roster.members[1].name, "Former")
    end),

    test.case("Retail legacy roster cannot seed a same-named Forever partition", function()
        local retail = guild("Night Shift", "area-52")
        local forever = foreverGuild("Night Shift", "US", "guild-area-52")
        local character = legacyCharacter(retail, "RetailOnly", nil)
        local account, initialized, imported = rosterMigration.initialize(
            accountData.newModel(),
            character,
            forever
        )

        test.assert_true(initialized)
        test.assert_false(imported)
        test.assert_equal(
            accountData.findGuild(account, forever).roster,
            { ranks = {}, members = {} }
        )
        test.assert_nil(accountData.findGuild(account, retail))
        test.assert_equal(character.roster.members[1].name, "RetailOnly")
    end),

    test.case("Forever roster migration keeps regions isolated", function()
        local us = foreverGuild("Night Shift", "US", "Club-001")
        local eu = foreverGuild("Night Shift", "EU", "Club-001")
        local character = legacyCharacter(us, "USOnly", nil)
        local account, initialized, imported = rosterMigration.initialize(
            accountData.newModel(),
            character,
            eu
        )

        test.assert_true(initialized)
        test.assert_false(imported)
        test.assert_equal(
            accountData.findGuild(account, eu).roster,
            { ranks = {}, members = {} }
        )
        test.assert_nil(accountData.findGuild(account, us))
    end),

    test.case("bank initialization does not suppress roster migration", function()
        local identity = guild("Night Shift", "area-52")
        local character = legacyCharacter(identity, "Legacy", nil)
        local account = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "bank",
            character.bank
        ))
        local beforeBank = accountData.findGuild(account, identity).bank
        account = assert(rosterMigration.initialize(account, character, identity))

        local partition = accountData.findGuild(account, identity)
        test.assert_true(partition.rosterInitialized)
        test.assert_true(partition.bankInitialized)
        test.assert_equal(partition.roster.members[1].name, "Legacy")
        test.assert_equal(partition.bank, beforeBank)
    end),

    test.case("initialized empty roster remains authoritative", function()
        local identity = guild("Night Shift", "area-52")
        local account = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            savedData.newModel().roster
        ))
        local character = legacyCharacter(identity, "MustNotReturn", nil)
        local result, initialized, imported = rosterMigration.initialize(
            account,
            character,
            identity
        )

        test.assert_true(result == account)
        test.assert_false(initialized)
        test.assert_false(imported)
        test.assert_equal(
            accountData.findGuild(result, identity).roster,
            { ranks = {}, members = {} }
        )
        test.assert_equal(character.roster.members[1].name, "MustNotReturn")
    end),

    test.case("a later character cannot merge into an initialized roster", function()
        local identity = guild("Night Shift", "area-52")
        local account = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Authoritative")
        ))
        local secondCharacter = legacyCharacter(identity, "Second", nil)
        local result = assert(rosterMigration.initialize(
            account,
            secondCharacter,
            identity
        ))

        local members = accountData.findGuild(result, identity).roster.members
        test.assert_equal(#members, 1)
        test.assert_equal(members[1].name, "Authoritative")
        test.assert_equal(secondCharacter.roster.members[1].name, "Second")
    end),

    test.case("only a successful roster commit cleans the current character", function()
        local identity = guild("Night Shift", "area-52")
        local account = accountData.newModel()
        local position = fixtures.window_position({ x = 333, y = -222 })
        local character = legacyCharacter(identity, "Legacy", position)
        local otherCharacter = legacyCharacter(identity, "Other", nil)
        local cleanups = 0
        local controller = datasetOwnership.create({
            savedData = savedData,
            accountData = accountData,
            getSavedData = function() return account end,
            prepareCharacterCommit = function()
                cleanups = cleanups + 1
                return rosterMigration.cleanup(character)
            end,
            commit = function(newAccount, _, newCharacter)
                account = newAccount
                character = newCharacter or character
            end,
            print = function() end,
        })

        local failed = assert(controller:begin("roster", identity))
        failed.dataset = completedRoster(identity, "Failed")
        test.assert_false(controller:finish(failed, "failed"))
        test.assert_equal(cleanups, 0)
        test.assert_equal(character.roster.members[1].name, "Legacy")

        local successful = assert(controller:begin("roster", identity))
        successful.dataset = completedRoster(identity, "Fresh")
        test.assert_true(controller:finish(successful, "success"))

        test.assert_equal(cleanups, 1)
        test.assert_equal(
            accountData.findGuild(account, identity).roster.members[1].name,
            "Fresh"
        )
        test.assert_equal(character.roster, { ranks = {}, members = {} })
        test.assert_equal(character.bank.slots[1].itemId, 191384)
        test.assert_equal(character.ui.windowPosition, position)
        test.assert_equal(otherCharacter.roster.members[1].name, "Other")
    end),
}
