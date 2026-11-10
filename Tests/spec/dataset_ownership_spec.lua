local accountData = require("Core.AccountData")
local clientFlavor = require("Core.ClientFlavor")
local datasetOwnership = require("Core.DatasetOwnership")
local fixtures = require("Tests.fixtures")
local guildIdentity = require("Core.GuildIdentity")
local savedData = require("Core.SavedData")
local test = require("Tests.lib.runner")

local function guild(name, realmSlug, overrides)
    local input = {
        flavor = clientFlavor.RETAIL,
        region = "US",
        name = name,
        realm = {
            name = realmSlug,
            slug = realmSlug,
        },
    }
    for key, value in pairs(overrides or {}) do
        input[key] = value
    end
    return assert(guildIdentity.create(input))
end

local function foreverGuild(region, clubId, name)
    return assert(guildIdentity.create({
        flavor = clientFlavor.FOREVER,
        region = region,
        name = name or "Night Shift",
        clubId = clubId,
    }))
end

local function laterTimestamp()
    return fixtures.timestamp({
        unixSeconds = 1717245356,
        iso8601 = "2024-06-01T12:35:56Z",
    })
end

local function newHarness(model)
    local current = model or savedData.newModel()
    local messages = {}
    local commits = 0
    local controller = datasetOwnership.create({
        savedData = savedData,
        getSavedData = function()
            return current
        end,
        commit = function(replacement)
            current = replacement
            commits = commits + 1
        end,
        print = function(message)
            messages[#messages + 1] = message
        end,
    })

    return {
        controller = controller,
        current = function()
            return current
        end,
        messages = messages,
        commits = function()
            return commits
        end,
    }
end

local function completeRoster(transaction, memberName)
    memberName = memberName or "Aeloria"
    transaction.dataset.scannedAt = laterTimestamp()
    transaction.dataset.ranks = { fixtures.roster_rank() }
    transaction.dataset.members = {
        fixtures.roster_member({
            name = memberName,
            displayName = memberName .. "-Example Realm",
        }),
    }
end

local function completeBank(transaction, quantity)
    transaction.dataset.scannedAt = laterTimestamp()
    transaction.dataset.tabs = { fixtures.bank_tab() }
    transaction.dataset.slots = {
        fixtures.bank_slot({ quantity = quantity or 20 }),
    }
end

return {
    test.case("guild ownership delegates to the shared identity contract", function()
        local original = guild("Night Shift", "area-52")
        local metadataChanged = guild("Night Shift", "area-52", {
            region = "EU",
            realm = {
                name = "Different Display Name",
                slug = "area-52",
            },
        })

        test.assert_true(datasetOwnership.sameGuild(original, metadataChanged))
        test.assert_true(datasetOwnership.sameGuild(
            original,
            guild("Night Shift", "AREA-52-area-52-ar")
        ))
        test.assert_false(datasetOwnership.sameGuild(original, guild("Night shift", "area-52")))
        test.assert_false(datasetOwnership.sameGuild(original, guild("Night Shift", "illidan")))
    end),

    test.case("Forever ownership is isolated from Retail club and region peers", function()
        local original = foreverGuild("US", "Club-001", "Night Shift")
        local renamed = foreverGuild("US", "Club-001", "Renamed Guild")
        local european = foreverGuild("EU", "Club-001", "Night Shift")
        local otherClub = foreverGuild("US", "Club-002", "Night Shift")
        local retail = guild("Night Shift", "Club-001")

        test.assert_true(datasetOwnership.sameGuild(original, renamed))
        test.assert_false(datasetOwnership.sameGuild(original, european))
        test.assert_false(datasetOwnership.sameGuild(original, otherClub))
        test.assert_false(datasetOwnership.sameGuild(original, retail))

        local same, sameError = datasetOwnership.sameGuild(
            { flavor = clientFlavor.FOREVER },
            original
        )
        test.assert_nil(same)
        test.assert_matches(sameError, "left guild identity is invalid")
    end),

    test.case("first successful scan binds only its dataset", function()
        local harness = newHarness()
        local identity = guild("Night Shift", "area-52")
        local transaction = harness.controller:begin("roster", identity)

        test.assert_nil(harness.current().roster.guild)
        test.assert_nil(harness.current().bank.guild)
        completeRoster(transaction)
        local committed, model = harness.controller:finish(transaction, "success")

        test.assert_true(committed)
        test.assert_equal(model.roster.guild, identity)
        test.assert_equal(model.roster.members[1].name, "Aeloria")
        test.assert_nil(model.bank.guild)
        test.assert_equal(harness.messages, {})
    end),

    test.case("same-guild rescans retain the existing dataset baseline", function()
        local model = fixtures.saved_model()
        local harness = newHarness(model)
        local transaction = harness.controller:begin("roster", model.roster.guild)

        test.assert_equal(transaction.dataset.members, model.roster.members)
        transaction.dataset.members[1].isOnline = true
        transaction.dataset.members[1].lastOnline = nil
        transaction.dataset.scannedAt = laterTimestamp()
        local committed = harness.controller:finish(transaction, "success")

        test.assert_true(committed)
        test.assert_true(harness.current().roster.members[1].isOnline)
        test.assert_false(model.roster.members[1].isOnline)
        test.assert_equal(harness.messages, {})
    end),

    test.case("unguilded periods and leave-rejoin preserve ownership", function()
        local model = fixtures.saved_model()
        local harness = newHarness(model)
        local transaction, beginError = harness.controller:begin("roster", nil)

        test.assert_nil(transaction)
        test.assert_matches(beginError, "unavailable")
        test.assert_equal(harness.current(), model)
        test.assert_equal(harness.commits(), 0)

        local rejoined = harness.controller:begin("roster", model.roster.guild)
        test.assert_equal(rejoined.dataset.members, model.roster.members)
        rejoined.dataset.scannedAt = laterTimestamp()
        test.assert_true(harness.controller:finish(rejoined, "success"))
        test.assert_equal(harness.current().roster.members, model.roster.members)
        test.assert_equal(harness.messages, {})
    end),

    test.case("failed and canceled scans discard detached work", function()
        local original = fixtures.saved_model()
        local harness = newHarness(original)
        local newGuild = guild("Example Guild", "different-realm")

        local failed = harness.controller:begin("roster", newGuild)
        completeRoster(failed, "FailedWork")
        local committed, status = harness.controller:finish(failed, "failed")
        test.assert_false(committed)
        test.assert_equal(status, "failed")

        local canceled = harness.controller:begin("bank", newGuild)
        completeBank(canceled, 1)
        committed, status = harness.controller:finish(canceled, "canceled")
        test.assert_false(committed)
        test.assert_equal(status, "canceled")

        test.assert_equal(harness.current(), original)
        test.assert_equal(harness.commits(), 0)
        test.assert_equal(harness.messages, {})
    end),

    test.case("successful realm change replaces roster only after commit", function()
        local original = fixtures.saved_model()
        local harness = newHarness(original)
        local newGuild = guild(original.roster.guild.name, "different-realm")
        local transaction = harness.controller:begin("roster", newGuild)

        test.assert_equal(transaction.dataset.ranks, {})
        test.assert_equal(transaction.dataset.members, {})
        test.assert_equal(harness.current(), original)
        completeRoster(transaction, "NewRealmMember")
        test.assert_true(harness.controller:finish(transaction, "success"))

        test.assert_equal(harness.current().roster.guild, newGuild)
        test.assert_equal(harness.current().roster.members[1].name, "NewRealmMember")
        test.assert_equal(harness.current().bank, original.bank)
        test.assert_equal(harness.current().ui, original.ui)
        test.assert_equal(
            harness.messages,
            { "Detected guild change; resetting roster data" }
        )
    end),

    test.case("roster and bank ownership can diverge independently", function()
        local original = fixtures.saved_model()
        local bankGuild = guild("Bank Guild", "bank-realm")
        original.bank.guild = bankGuild
        local harness = newHarness(original)
        local rosterGuild = guild("Roster Guild", "roster-realm")
        local rosterTransaction = harness.controller:begin("roster", rosterGuild)
        completeRoster(rosterTransaction, "RosterMember")
        test.assert_true(harness.controller:finish(rosterTransaction, "success"))

        test.assert_equal(harness.current().roster.guild, rosterGuild)
        test.assert_equal(harness.current().bank.guild, bankGuild)
        test.assert_equal(harness.current().bank.slots, original.bank.slots)

        local nextBankGuild = guild("Next Bank Guild", "next-bank-realm")
        local bankTransaction = harness.controller:begin("bank", nextBankGuild)
        completeBank(bankTransaction, 7)
        test.assert_true(harness.controller:finish(bankTransaction, "success"))

        test.assert_equal(harness.current().roster.guild, rosterGuild)
        test.assert_equal(harness.current().bank.guild, nextBankGuild)
        test.assert_equal(harness.current().bank.slots[1].quantity, 7)
        test.assert_equal(harness.current().ui.windowPosition, original.ui.windowPosition)
        test.assert_equal(harness.messages, {
            "Detected guild change; resetting roster data",
            "Detected guild change; resetting bank data",
        })
    end),

    test.case("invalid successful work cannot alter saved data", function()
        local original = fixtures.saved_model()
        local harness = newHarness(original)
        local transaction = harness.controller:begin("roster", original.roster.guild)
        transaction.dataset.scannedAt = laterTimestamp()
        transaction.dataset.members[1].level = "eighty"

        local committed, commitError = harness.controller:finish(transaction, "success")

        test.assert_nil(committed)
        test.assert_matches(commitError, "level must be an integer")
        test.assert_equal(harness.current(), original)
        test.assert_equal(harness.commits(), 0)
        test.assert_equal(harness.messages, {})
    end),

    test.case("account commit rejects a scan after product or region changes", function()
        local captured = foreverGuild("US", "Club-001")
        local currentIdentity = captured
        local current = accountData.newModel()
        local original = current
        local commits = 0
        local reconciles = 0
        local cleanups = 0
        local controller = datasetOwnership.create({
            savedData = savedData,
            accountData = accountData,
            getSavedData = function() return current end,
            getCurrentGuildIdentity = function()
                return currentIdentity
            end,
            reconcileRosterFeatures = function()
                reconciles = reconciles + 1
                return {}, {}
            end,
            prepareCharacterCommit = function()
                cleanups = cleanups + 1
                return savedData.newModel()
            end,
            commit = function(model)
                current = model
                commits = commits + 1
            end,
            print = function() end,
        })

        local transaction = assert(controller:begin("roster", captured))
        completeRoster(transaction, "CapturedMember")
        currentIdentity = foreverGuild("EU", "Club-001")

        local committed, commitError = controller:finish(transaction, "success")
        test.assert_nil(committed)
        test.assert_equal(commitError, "current guild changed during dataset transaction")
        test.assert_true(current == original)
        test.assert_equal(commits, 0)
        test.assert_equal(reconciles, 0)
        test.assert_equal(cleanups, 0)
        test.assert_nil(accountData.findGuild(current, captured))

        currentIdentity = guild("Night Shift", "area-52")
        committed, commitError = controller:finish(transaction, "success")
        test.assert_nil(committed)
        test.assert_equal(commitError, "current guild changed during dataset transaction")
        test.assert_equal(commits, 0)
    end),
}
