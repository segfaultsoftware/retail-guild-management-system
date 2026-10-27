local accountData = require("Core.AccountData")
local dateTime = require("Core.DateTime")
local datasetOwnership = require("Core.DatasetOwnership")
local fixtures = require("Tests.fixtures")
local groups = require("MainsAlts.Groups")
local tags = require("MainsAlts.Tags")
local reset = require("Core.Reset")
local rosterNews = require("Roster.News")
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
            schemaVersion = 8,
            settings = {
                minimapPos = 225,
            },
            guilds = {},
        })
    end),

    test.case("version 1 account data gains default minimap settings copy-on-write", function()
        local original = {
            schemaVersion = 1,
            guilds = {},
        }

        local state = accountData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 1)
        test.assert_equal(state.model, {
            schemaVersion = 8,
            settings = {
                minimapPos = 225,
            },
            guilds = {},
        })
        test.assert_equal(original, {
            schemaVersion = 1,
            guilds = {},
        })
    end),

    test.case("version 2 account data preserves its minimap position copy-on-write", function()
        local original = {
            schemaVersion = 2,
            settings = { minimapAngle = 42 },
            guilds = {},
        }

        local state = accountData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 2)
        test.assert_equal(state.model, {
            schemaVersion = 8,
            settings = { minimapPos = 42 },
            guilds = {},
        })
        test.assert_equal(original, {
            schemaVersion = 2,
            settings = { minimapAngle = 42 },
            guilds = {},
        })
    end),

    test.case("version 3 account data gains the seeded tag catalog copy-on-write", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        original.schemaVersion = 3
        accountData.findGuild(original, identity).tags = nil

        local state = accountData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 3)
        test.assert_equal(state.model.schemaVersion, 8)
        test.assert_equal(accountData.findGuild(state.model, identity).tags, {
            definitions = { me = true },
            assignments = {},
        })
        test.assert_nil(accountData.findGuild(original, identity).tags)
    end),

    test.case("version 4 account data gains empty roster news state copy-on-write", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        original.schemaVersion = 4
        local originalGuild = accountData.findGuild(original, identity)
        originalGuild.rosterObservation = nil
        originalGuild.newsSets = nil

        local state = accountData.load(original)
        local migratedGuild = accountData.findGuild(state.model, identity)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 4)
        test.assert_equal(state.model.schemaVersion, 8)
        test.assert_nil(migratedGuild.rosterObservation)
        test.assert_equal(migratedGuild.newsSets, {})
        test.assert_nil(originalGuild.newsSets)
    end),

    test.case("version 5 account data initializes empty per-guild provisions copy-on-write", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        original.schemaVersion = 5
        local originalGuild = accountData.findGuild(original, identity)
        originalGuild.provisions = nil
        originalGuild.nextProvisionId = nil

        local state = accountData.load(original)
        local migratedGuild = accountData.findGuild(state.model, identity)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 5)
        test.assert_equal(state.model.schemaVersion, 8)
        test.assert_equal(migratedGuild.provisions, {})
        test.assert_equal(migratedGuild.nextProvisionId, 1)
        test.assert_nil(originalGuild.provisions)
    end),

    test.case("version 6 account data converts the visible provision order copy-on-write", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceProvisions(
            accountData.newModel(),
            identity,
            {
                { id = 4, name = "zeta", quality = "either", target = 1 },
                { id = 3, name = "Alpha", quality = "silver", target = 2 },
                { id = 1, name = "alpha", quality = "gold", target = 3 },
            },
            5
        ))
        original.schemaVersion = 6

        local state = accountData.load(original)
        local migratedGuild = accountData.findGuild(state.model, identity)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 6)
        test.assert_equal(state.model.schemaVersion, 8)
        test.assert_equal(migratedGuild.provisions[1].id, 1)
        test.assert_equal(migratedGuild.provisions[2].id, 3)
        test.assert_equal(migratedGuild.provisions[3].id, 4)
        test.assert_equal(accountData.findGuild(original, identity).provisions[1].id, 4)
        test.assert_equal(migratedGuild.nextProvisionId, 5)
    end),

    test.case("version 7 account data keeps older bank scans without invented money", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "bank",
            {
                guild = identity,
                scannedAt = fixtures.timestamp(),
                tabs = {},
                slots = {},
            }
        ))
        original.schemaVersion = 7

        local state = accountData.load(original)
        local migratedBank = accountData.findGuild(state.model, identity).bank

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 7)
        test.assert_equal(state.model.schemaVersion, 8)
        test.assert_nil(migratedBank.money)
        test.assert_equal(original.schemaVersion, 7)
    end),

    test.case("bank money round trips within only its guild partition", function()
        local identity = guild("Night Shift", "area-52")
        local model = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "bank",
            {
                guild = identity,
                scannedAt = fixtures.timestamp(),
                money = 1233452412,
                tabs = {},
                slots = {},
            }
        ))

        local reloaded = accountData.load(model)

        test.assert_true(reloaded.enabled)
        test.assert_equal(
            accountData.view(reloaded.model, identity, {}).bank.money,
            1233452412
        )
        test.assert_nil(accountData.view(reloaded.model, nil, {}).bank.money)
    end),

    test.case("account data validates the saved LibDBIcon position", function()
        local model = accountData.newModel()
        model.settings.minimapPos = 359.5
        test.assert_true(accountData.validate(model))

        for _, angle in ipairs({ -1, 360, math.huge }) do
            model.settings.minimapPos = angle
            local valid, message = accountData.validate(model)
            test.assert_nil(valid)
            test.assert_matches(message, "minimapPos")
        end
    end),

    test.case("version 2 rejects an invalid minimap angle without changing input", function()
        local original = {
            schemaVersion = 2,
            settings = { minimapAngle = 360 },
            guilds = {},
        }

        local state = accountData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "minimapAngle")
        test.assert_true(state.original == original)
        test.assert_equal(original.settings.minimapAngle, 360)
    end),

    test.case("version 1 migration rejects unknown settings without changing input", function()
        local original = {
            schemaVersion = 1,
            settings = { minimapAngle = 42 },
            guilds = {},
        }

        local state = accountData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "unexpected field settings")
        test.assert_true(state.original == original)
        test.assert_equal(original.settings.minimapAngle, 42)
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

    test.case("roster news persists account-wide inside only its guild partition", function()
        local active = guild("Night Shift", "area-52")
        local other = guild("Night Shift", "illidan")
        local model = accountData.newModel()
        model = assert(accountData.replaceDataset(
            model,
            active,
            "roster",
            completedRoster(active, "Active")
        ))
        model = assert(accountData.replaceDataset(
            model,
            other,
            "roster",
            completedRoster(other, "Other")
        ))
        local observation = {
            scannedAt = fixtures.timestamp(),
            members = {
                {
                    identity = "active-area-52",
                    name = "Active-Area-52",
                    rankIndex = 2,
                    rankName = "Member",
                },
            },
        }
        local newsSets = {
            {
                id = "news-1",
                createdDate = "2024-06-01",
                joiningMembers = { "Active-Area-52" },
                leavingMembers = {},
                rankChanges = {},
            },
        }

        local replacement = assert(accountData.replaceRosterNews(
            model,
            active,
            observation,
            newsSets
        ))

        test.assert_equal(accountData.findGuild(replacement, active).newsSets, newsSets)
        test.assert_equal(accountData.findGuild(replacement, other).newsSets, {})
        test.assert_equal(accountData.view(replacement, active, {}).newsSets, newsSets)
        test.assert_equal(accountData.findGuild(model, active).newsSets, {})
    end),

    test.case("successful roster ownership commits baseline and news atomically", function()
        local identity = guild("Night Shift", "area-52")
        local current = accountData.newModel()
        local function applyNews(model, guildIdentity, snapshot)
            local partition = accountData.findGuild(model, guildIdentity)
            local result = assert(rosterNews.process(
                partition.rosterObservation,
                partition.newsSets,
                snapshot,
                dateTime
            ))
            return accountData.replaceRosterNews(
                model,
                guildIdentity,
                result.observation,
                result.newsSets
            ), result.created
        end
        local controller = datasetOwnership.create({
            savedData = savedData,
            accountData = accountData,
            getSavedData = function() return current end,
            commit = function(model) current = model end,
            reconcileRosterFeatures = groups.reconcile,
            reconcileCharacterTags = tags.reconcile,
            applyRosterNews = applyNews,
            print = function() end,
        })
        local firstSnapshot = completedRoster(identity, "Alpha")
        local first = assert(controller:begin("roster", identity))
        first.dataset = firstSnapshot
        first.snapshot = firstSnapshot
        local committed, _, created = controller:finish(first, "success")
        test.assert_true(committed)
        test.assert_false(created)
        test.assert_equal(accountData.findGuild(current, identity).newsSets, {})

        local secondSnapshot = completedRoster(identity, "Bravo")
        secondSnapshot.scannedAt = assert(dateTime.utcTimestamp(
            firstSnapshot.scannedAt.unixSeconds + 24 * 60 * 60
        ))
        secondSnapshot.members[1].observedAt = secondSnapshot.scannedAt
        secondSnapshot.members[1].lastSeenDate = assert(
            dateTime.currentPacificDate(secondSnapshot.scannedAt.unixSeconds)
        )
        local beforeFailure = current
        local failed = assert(controller:begin("roster", identity))
        failed.dataset = secondSnapshot
        failed.snapshot = secondSnapshot
        local failedCommit, failedStatus = controller:finish(failed, "failed")
        test.assert_false(failedCommit)
        test.assert_equal(failedStatus, "failed")
        test.assert_true(current == beforeFailure)
        test.assert_equal(accountData.findGuild(current, identity).newsSets, {})

        local second = assert(controller:begin("roster", identity))
        second.dataset = secondSnapshot
        second.snapshot = secondSnapshot
        local commitResult
        committed, commitResult, created = controller:finish(second, "success")
        if not committed then
            error(tostring(commitResult))
        end

        local partition = accountData.findGuild(current, identity)
        test.assert_true(committed)
        test.assert_true(created)
        test.assert_equal(partition.newsSets[1].joiningMembers, { "Bravo-area-52" })
        test.assert_equal(partition.newsSets[1].leavingMembers, { "Alpha-area-52" })
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
        test.assert_equal(partition.tags, {
            definitions = { me = true },
            assignments = {},
        })
        test.assert_equal(partition.provisions, {})
        test.assert_equal(partition.nextProvisionId, 1)
    end),

    test.case("provisions persist atomically within only their guild partition", function()
        local firstGuild = guild("Night Shift", "area-52")
        local secondGuild = guild("Day Shift", "illidan")
        local model = accountData.newModel()
        local replacement = assert(accountData.replaceProvisions(
            model,
            firstGuild,
            {
                { id = 1, name = "Feast", quality = "either", target = 20 },
                { id = 2, name = "Feast", quality = "either", target = 20 },
            },
            3
        ))

        test.assert_equal(accountData.view(replacement, firstGuild).provisions, {
            { id = 1, name = "Feast", quality = "either", target = 20 },
            { id = 2, name = "Feast", quality = "either", target = 20 },
        })
        test.assert_equal(accountData.view(replacement, firstGuild).nextProvisionId, 3)
        test.assert_equal(accountData.view(replacement, secondGuild).provisions, {})
        test.assert_equal(accountData.view(model, firstGuild).provisions, {})

        local invalid, message = accountData.replaceProvisions(
            replacement,
            firstGuild,
            { { id = 2, name = "x", quality = "either", target = 20 } },
            3
        )
        test.assert_nil(invalid)
        test.assert_matches(message, "3 through 100")
        test.assert_equal(#accountData.view(replacement, firstGuild).provisions, 2)
    end),

    test.case("replacing groups preserves roster bank notes and tags", function()
        local identity = guild("Night Shift", "area-52")
        local model = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        local partition = accountData.findGuild(model, identity)
        partition.characterNotes["Main-area-52"] = "Keep this note"
        partition.tags.definitions.raid = true
        partition.tags.assignments["main-area-52"] = { raid = true }
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
        test.assert_equal(updated.tags, partition.tags)
        test.assert_equal(partition.mainAltGroups, {})
    end),

    test.case("replacing character tags is atomic and preserves guild data", function()
        local identity = guild("Night Shift", "area-52")
        local model = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        local partition = accountData.findGuild(model, identity)
        partition.mainAltGroups = { ["Main-area-52"] = { "Alt-area-52" } }
        partition.characterNotes = { ["main-area-52"] = "Keep this note" }
        local replacementTags = {
            definitions = { me = true, raid = true },
            assignments = { ["main-area-52"] = { raid = true } },
        }

        local replacement = assert(accountData.replaceCharacterTags(
            model,
            identity,
            replacementTags
        ))
        local updated = accountData.findGuild(replacement, identity)

        test.assert_equal(updated.tags, replacementTags)
        test.assert_equal(updated.roster, partition.roster)
        test.assert_equal(updated.mainAltGroups, partition.mainAltGroups)
        test.assert_equal(updated.characterNotes, partition.characterNotes)
        test.assert_equal(partition.tags, {
            definitions = { me = true },
            assignments = {},
        })
        replacementTags.definitions.changedAfterPublish = true
        test.assert_nil(updated.tags.definitions.changedAfterPublish)

        local invalid, invalidError = accountData.replaceCharacterTags(
            model,
            identity,
            { definitions = { raid = true }, assignments = {} }
        )
        test.assert_nil(invalid)
        test.assert_matches(invalidError, "me")
    end),

    test.case("replacing one character note is atomic and preserves guild data", function()
        local identity = guild("Night Shift", "area-52")
        local model = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        local partition = accountData.findGuild(model, identity)
        partition.mainAltGroups = { ["Main-area-52"] = { "Alt-area-52" } }
        partition.characterNotes = {
            ["other-area-52"] = "Keep this note",
        }

        local replacement = assert(accountData.replaceCharacterNote(
            model,
            identity,
            "main-area-52",
            "New note"
        ))
        local updated = accountData.findGuild(replacement, identity)

        test.assert_equal(updated.characterNotes, {
            ["main-area-52"] = "New note",
            ["other-area-52"] = "Keep this note",
        })
        test.assert_equal(updated.mainAltGroups, partition.mainAltGroups)
        test.assert_equal(updated.roster, partition.roster)
        test.assert_nil(partition.characterNotes["main-area-52"])

        replacement = assert(accountData.replaceCharacterNote(
            replacement,
            identity,
            "main-area-52",
            nil
        ))
        updated = accountData.findGuild(replacement, identity)
        test.assert_nil(updated.characterNotes["main-area-52"])
        test.assert_equal(updated.characterNotes["other-area-52"], "Keep this note")
    end),

    test.case("character note replacement validates identity value and length", function()
        local identity = guild("Night Shift", "area-52")
        local model = accountData.newModel()

        local replacement, message = accountData.replaceCharacterNote(
            model,
            identity,
            "",
            "Note"
        )
        test.assert_nil(replacement)
        test.assert_matches(message, "identity")

        replacement, message = accountData.replaceCharacterNote(
            model,
            identity,
            "main-area-52",
            string.rep("x", 5501)
        )
        test.assert_nil(replacement)
        test.assert_matches(message, "5500")
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

    test.case("successful account roster commits reconcile groups notes and tags atomically", function()
        local identity = guild("Night Shift", "Area-52")
        local current = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            {
                guild = identity,
                scannedAt = fixtures.timestamp(),
                ranks = { fixtures.roster_rank() },
                members = {
                    fixtures.roster_member({
                        name = "Main",
                        realm = "Area-52",
                        displayName = "Main-Area-52",
                    }),
                    fixtures.roster_member({
                        name = "Alt",
                        realm = "Area-52",
                        displayName = "Alt-Area-52",
                    }),
                },
            }
        ))
        local partition = accountData.findGuild(current, identity)
        partition.mainAltGroups = {
            ["Main-Area-52"] = { "Alt-Area-52" },
        }
        partition.characterNotes = {
            ["main-area-52"] = "Delete this note",
            ["alt-area-52"] = "Keep this note",
        }
        partition.tags = {
            definitions = { me = true, raid = true },
            assignments = {
                ["main-area-52"] = { raid = true },
                ["alt-area-52"] = { me = true },
            },
        }
        local commits = 0
        local controller = datasetOwnership.create({
            savedData = savedData,
            accountData = accountData,
            getSavedData = function() return current end,
            commit = function(model) current = model; commits = commits + 1 end,
            reconcileRosterFeatures = groups.reconcile,
            reconcileCharacterTags = tags.reconcile,
            print = function() end,
        })
        local transaction = assert(controller:begin("roster", identity))
        transaction.dataset.members = {
            fixtures.roster_member({
                name = "Alt",
                realm = "Area-52",
                displayName = "Alt-Area-52",
            }),
        }

        test.assert_true(controller:finish(transaction, "success"))

        partition = accountData.findGuild(current, identity)
        test.assert_equal(commits, 1)
        test.assert_equal(partition.mainAltGroups, {})
        test.assert_equal(partition.characterNotes, {
            ["alt-area-52"] = "Keep this note",
        })
        test.assert_equal(partition.tags, {
            definitions = { me = true, raid = true },
            assignments = { ["alt-area-52"] = { me = true } },
        })
        test.assert_equal(partition.roster.members[1].name, "Alt")
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
        local activePartition = accountData.findGuild(account, active)
        activePartition.tags.definitions.raid = true
        activePartition.tags.assignments["active-area-52"] = { raid = true }
        activePartition.rosterObservation = {
            scannedAt = fixtures.timestamp(),
            members = {
                {
                    identity = "active-area-52",
                    name = "Active-area-52",
                    rankIndex = 1,
                    rankName = "Guild Master",
                },
            },
        }
        activePartition.newsSets = {
            {
                id = "reset-news",
                createdDate = "2024-06-01",
                joiningMembers = { "Active-area-52" },
                leavingMembers = {},
                rankChanges = {},
            },
        }
        account = assert(accountData.replaceDataset(
            account,
            other,
            "roster",
            completedRoster(other, "Other")
        ))
        local character = fixtures.saved_model()
        character.ui.selectedRosterRankIndex = 3
        character.ui.selectedBankTabIndex = 2
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
        test.assert_equal(accountData.findGuild(account, active).tags, {
            definitions = { me = true },
            assignments = {},
        })
        test.assert_nil(accountData.findGuild(account, active).rosterObservation)
        test.assert_equal(accountData.findGuild(account, active).newsSets, {})
        test.assert_equal(
            accountData.findGuild(account, other).roster.members[1].name,
            "Other"
        )
        test.assert_true(character.ui.windowPosition == originalPosition)
        test.assert_nil(character.ui.selectedRosterRankIndex)
        test.assert_nil(character.ui.selectedBankTabIndex)
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
