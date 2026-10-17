local accountData = require("Core.AccountData")
local datasetOwnership = require("Core.DatasetOwnership")
local fixtures = require("Tests.fixtures")
local reset = require("Core.Reset")
local savedData = require("Core.SavedData")
local test = require("Tests.lib.runner")

local function guild(name, realm)
    return fixtures.guild_identity({
        id = "guild-" .. realm,
        name = name,
        realm = { name = realm, slug = realm },
    })
end

local function completedRoster(identity, memberName)
    return {
        guild = identity,
        scannedAt = fixtures.timestamp(),
        ranks = { fixtures.roster_rank() },
        members = {
            fixtures.roster_member({
                name = memberName,
                realm = identity.realm.slug,
                displayName = memberName .. "-" .. identity.realm.slug,
            }),
        },
    }
end

return {
    test.case("account data starts without guild partitions", function()
        local state = accountData.load(nil)

        test.assert_true(state.enabled)
        test.assert_true(state.initialized)
        test.assert_equal(state.model, {
            schemaVersion = 1,
            guilds = {},
        })
    end),

    test.case("same account guild identity resolves one shared partition", function()
        local identity = guild("Night Shift", "Area-52")
        local model = accountData.newModel()
        model = assert(accountData.replaceDataset(
            model,
            identity,
            "roster",
            completedRoster(identity, "First")
        ))

        local metadataVariant = guild("Night Shift", "area-52")
        metadataVariant.id = "different-id"
        metadataVariant.region = "EU"
        local first = accountData.findGuild(model, identity)
        local second = accountData.findGuild(model, metadataVariant)

        test.assert_true(first == second)
        test.assert_true(first.rosterInitialized)
        test.assert_equal(first.roster.members[1].name, "First")
    end),

    test.case("guild name and normalized realm jointly partition account data", function()
        local model = accountData.newModel()
        local firstIdentity = guild("Night Shift", "area-52")
        local secondIdentity = guild("Night Shift", "illidan")
        local thirdIdentity = guild("Day Shift", "area-52")

        model = assert(accountData.replaceDataset(
            model,
            firstIdentity,
            "roster",
            completedRoster(firstIdentity, "First")
        ))
        model = assert(accountData.replaceDataset(
            model,
            secondIdentity,
            "roster",
            completedRoster(secondIdentity, "Second")
        ))
        model = assert(accountData.replaceDataset(
            model,
            thirdIdentity,
            "roster",
            completedRoster(thirdIdentity, "Third")
        ))

        test.assert_equal(accountData.findGuild(model, firstIdentity).roster.members[1].name, "First")
        test.assert_equal(accountData.findGuild(model, secondIdentity).roster.members[1].name, "Second")
        test.assert_equal(accountData.findGuild(model, thirdIdentity).roster.members[1].name, "Third")
    end),

    test.case("guildless views are empty and never mutate saved partitions", function()
        local identity = guild("Night Shift", "area-52")
        local model = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Saved")
        ))
        local before = accountData.load(model).model
        local ui = { windowPosition = fixtures.window_position() }
        local view = accountData.view(model, nil, ui)

        test.assert_equal(view.roster.members, {})
        test.assert_equal(view.bank.slots, {})
        test.assert_true(view.ui == ui)
        test.assert_equal(model, before)
    end),

    test.case("window positions remain independently owned by each character", function()
        local identity = guild("Night Shift", "area-52")
        local model = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Shared")
        ))
        local firstUi = { windowPosition = fixtures.window_position({ x = 100 }) }
        local secondUi = { windowPosition = fixtures.window_position({ x = 500 }) }
        local first = accountData.view(model, identity, firstUi)
        local second = accountData.view(model, identity, secondUi)

        test.assert_true(first.roster == second.roster)
        test.assert_equal(first.ui.windowPosition.x, 100)
        test.assert_equal(second.ui.windowPosition.x, 500)
    end),

    test.case("roster and bank initialization are independent and survive empty reset", function()
        local identity = guild("Night Shift", "area-52")
        local model = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Saved")
        ))
        local partition = accountData.findGuild(model, identity)
        test.assert_true(partition.rosterInitialized)
        test.assert_false(partition.bankInitialized)

        local reset = assert(accountData.resetGuild(model, identity))
        partition = accountData.findGuild(reset, identity)
        test.assert_true(partition.rosterInitialized)
        test.assert_true(partition.bankInitialized)
        test.assert_equal(partition.roster, { ranks = {}, members = {} })
        test.assert_equal(partition.bank, { tabs = {}, slots = {} })
        test.assert_equal(partition.mainAltGroups, {})
        test.assert_equal(partition.characterNotes, {})
    end),

    test.case("replacing groups preserves roster bank and character notes", function()
        local identity = guild("Night Shift", "area-52")
        local model = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        local partition = accountData.findGuild(model, identity)
        partition.characterNotes["Main-area-52"] = "Keep this note"
        local originalRoster = partition.roster

        local replacement = assert(accountData.replaceMainAltGroups(
            model,
            identity,
            { ["Main-area-52"] = { "Alt-area-52" } }
        ))
        local updated = accountData.findGuild(replacement, identity)

        test.assert_equal(updated.mainAltGroups, {
            ["Main-area-52"] = { "Alt-area-52" },
        })
        test.assert_equal(updated.characterNotes, {
            ["Main-area-52"] = "Keep this note",
        })
        test.assert_equal(updated.roster, originalRoster)
        test.assert_equal(partition.mainAltGroups, {})
    end),

    test.case("account transactions publish complete datasets atomically", function()
        local current = accountData.newModel()
        local identity = guild("Night Shift", "area-52")
        local commits = 0
        local controller = datasetOwnership.create({
            savedData = savedData,
            accountData = accountData,
            getSavedData = function() return current end,
            commit = function(model) current = model; commits = commits + 1 end,
            print = function() end,
        })

        local failed = assert(controller:begin("roster", identity))
        failed.dataset.scannedAt = fixtures.timestamp()
        failed.dataset.ranks = { fixtures.roster_rank() }
        failed.dataset.members = { fixtures.roster_member() }
        test.assert_false(controller:finish(failed, "failed"))
        test.assert_equal(commits, 0)
        test.assert_nil(accountData.findGuild(current, identity))

        local successful = assert(controller:begin("roster", identity))
        successful.dataset.scannedAt = fixtures.timestamp()
        successful.dataset.ranks = { fixtures.roster_rank() }
        successful.dataset.members = { fixtures.roster_member() }
        test.assert_true(controller:finish(successful, "success"))
        test.assert_equal(commits, 1)
        test.assert_true(accountData.findGuild(current, identity).rosterInitialized)
    end),

    test.case("reset controller clears only the active account guild", function()
        local active = guild("Night Shift", "area-52")
        local other = guild("Night Shift", "illidan")
        local account = accountData.newModel()
        account = assert(accountData.replaceDataset(
            account,
            active,
            "roster",
            completedRoster(active, "Active")
        ))
        account = assert(accountData.replaceDataset(
            account,
            other,
            "roster",
            completedRoster(other, "Other")
        ))
        local character = fixtures.saved_model()
        local originalPosition = character.ui.windowPosition
        local controller = reset.create({
            savedData = savedData,
            accountData = accountData,
            getSavedData = function() return character end,
            getAccountData = function() return account end,
            getGuildIdentity = function() return active end,
            getState = function() return { enabled = true } end,
            commitAccount = function(newAccount, newCharacter)
                account = newAccount
                character = newCharacter
            end,
            showConfirmation = function() end,
            print = function() end,
        })

        test.assert_true(controller:confirm(controller:requestManual()))
        test.assert_equal(accountData.findGuild(account, active).roster.members, {})
        test.assert_true(accountData.findGuild(account, active).rosterInitialized)
        test.assert_equal(
            accountData.findGuild(account, other).roster.members[1].name,
            "Other"
        )
        test.assert_true(character.ui.windowPosition == originalPosition)
        test.assert_equal(character.roster.members[1].name, "Aeloria")
    end),

    test.case("guildless reset leaves account data unchanged", function()
        local identity = guild("Night Shift", "area-52")
        local account = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Saved")
        ))
        local before = accountData.load(account).model
        local commits = 0
        local controller = reset.create({
            savedData = savedData,
            accountData = accountData,
            getSavedData = function() return fixtures.saved_model() end,
            getAccountData = function() return account end,
            getGuildIdentity = function() return nil end,
            getState = function() return { enabled = true } end,
            commitAccount = function() commits = commits + 1 end,
            showConfirmation = function() end,
            print = function() end,
        })

        local confirmed, confirmError = controller:confirm(controller:requestManual())
        test.assert_nil(confirmed)
        test.assert_matches(confirmError, "unavailable")
        test.assert_equal(commits, 0)
        test.assert_equal(account, before)
    end),
}
