local accountData = require("Core.AccountData")
local dateTime = require("Core.DateTime")
local chartModel = require("Charts.Model")
local datasetOwnership = require("Core.DatasetOwnership")
local fixtures = require("Tests.fixtures")
local guildIdentity = require("Core.GuildIdentity")
local groups = require("MainsAlts.Groups")
local tags = require("MainsAlts.Tags")
local reset = require("Core.Reset")
local rosterNews = require("Roster.News")
local savedData = require("Core.SavedData")
local test = require("Tests.lib.runner")

local function guild(name, realm, region)
    return assert(guildIdentity.create({
        flavor = "retail",
        region = region or "US",
        name = name,
        realm = { name = realm, slug = realm },
    }))
end

local function foreverGuild(name, region, clubId)
    return assert(guildIdentity.create({
        flavor = "forever",
        region = region,
        name = name,
        clubId = clubId,
    }))
end

local function legacyIdentity(identity)
    return fixtures.legacy_guild_identity({
        id = "legacy-" .. identity.key,
        name = identity.name,
        realm = {
            name = identity.realm.name,
            slug = identity.realm.slug,
        },
        region = identity.region,
    })
end

local function downgradeRosterRecords(model)
    for _, partition in pairs(model.guilds) do
        for _, member in ipairs(partition.roster.members) do
            member.identity = nil
        end
        if partition.rosterObservation ~= nil then
            for _, member in ipairs(partition.rosterObservation.members) do
                member.name = member.displayName
                member.displayName = nil
            end
        end
    end
    return model
end

local function downgradeGuildIdentities(model)
    for _, partition in pairs(model.guilds) do
        partition.identity = legacyIdentity(partition.identity)
        for _, datasetName in ipairs({ "roster", "bank" }) do
            if partition[datasetName].guild ~= nil then
                partition[datasetName].guild = legacyIdentity(
                    partition[datasetName].guild
                )
            end
        end
    end
    return downgradeRosterRecords(model)
end

local function downgradeRosterIdentityPersistence(model)
    model.schemaVersion = 11
    return downgradeRosterRecords(model)
end

local function completedRoster(identity, memberName)
    return {
        guild = identity,
        scannedAt = fixtures.timestamp(),
        ranks = { fixtures.roster_rank() },
        members = {
            fixtures.roster_member({
                identity = string.lower(memberName .. "-" .. identity.realm.slug),
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
            schemaVersion = 13,
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
            schemaVersion = 13,
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
            schemaVersion = 13,
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
        downgradeGuildIdentities(original)
        accountData.findGuild(original, identity).tags = nil

        local state = accountData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 3)
        test.assert_equal(state.model.schemaVersion, 13)
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
        downgradeGuildIdentities(original)
        local originalGuild = accountData.findGuild(original, identity)
        originalGuild.rosterObservation = nil
        originalGuild.newsSets = nil

        local state = accountData.load(original)
        local migratedGuild = accountData.findGuild(state.model, identity)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 4)
        test.assert_equal(state.model.schemaVersion, 13)
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
        downgradeGuildIdentities(original)
        local originalGuild = accountData.findGuild(original, identity)
        originalGuild.provisions = nil
        originalGuild.nextProvisionId = nil

        local state = accountData.load(original)
        local migratedGuild = accountData.findGuild(state.model, identity)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 5)
        test.assert_equal(state.model.schemaVersion, 13)
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
        downgradeGuildIdentities(original)

        local state = accountData.load(original)
        local migratedGuild = accountData.findGuild(state.model, identity)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 6)
        test.assert_equal(state.model.schemaVersion, 13)
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
        downgradeGuildIdentities(original)

        local state = accountData.load(original)
        local migratedBank = accountData.findGuild(state.model, identity).bank

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 7)
        test.assert_equal(state.model.schemaVersion, 13)
        test.assert_nil(migratedBank.money)
        test.assert_equal(original.schemaVersion, 7)
    end),

    test.case("version 8 creates empty chart histories without snapshot backfill", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "bank",
            {
                guild = identity,
                scannedAt = fixtures.timestamp(),
                money = 12345,
                tabs = {},
                slots = {},
            }
        ))
        original.schemaVersion = 8
        downgradeGuildIdentities(original)
        accountData.findGuild(original, identity).chartHistory = nil

        local state = accountData.load(original, "2024-06-01")
        local migratedGuild = accountData.findGuild(state.model, identity)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 8)
        test.assert_equal(state.model.schemaVersion, 13)
        test.assert_equal(migratedGuild.chartHistory, {
            gold = {}, members = {},
        })
        test.assert_nil(accountData.findGuild(original, identity).chartHistory)
    end),

    test.case("version 9 discards item chart history copy-on-write", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceChartHistory(
            accountData.newModel(),
            identity,
            {
                gold = { { date = "2024-06-01", value = 500 } },
                members = {
                    {
                        rankIndex = 2,
                        name = "Officer",
                        points = { { date = "2024-06-01", value = 3 } },
                    },
                },
            }
        ))
        original.schemaVersion = 9
        downgradeGuildIdentities(original)
        local originalHistory = accountData.findGuild(original, identity).chartHistory
        originalHistory.items = {
            {
                itemId = 10,
                name = "Obsolete",
                icon = 10,
                points = { { date = "2024-06-01", value = 2 } },
            },
        }

        local state = accountData.load(original, "2024-06-01")
        local migratedHistory = accountData.findGuild(state.model, identity).chartHistory

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 9)
        test.assert_equal(state.model.schemaVersion, 13)
        test.assert_equal(migratedHistory, {
            gold = { { date = "2024-06-01", value = 500 } },
            members = {
                {
                    rankIndex = 2,
                    name = "Officer",
                    points = { { date = "2024-06-01", value = 3 } },
                },
            },
        })
        test.assert_equal(originalHistory.items[1].name, "Obsolete")
    end),

    test.case("version 10 infers Retail identities without changing partition keys", function()
        local identity = guild("Night Shift", "Area-52")
        local original = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        original = assert(accountData.replaceDataset(
            original,
            identity,
            "bank",
            {
                guild = identity,
                scannedAt = fixtures.timestamp(),
                tabs = { fixtures.bank_tab() },
                slots = { fixtures.bank_slot() },
            }
        ))
        original.schemaVersion = 10
        downgradeGuildIdentities(original)
        local expectedKey = identity.key
        local originalIdentity = original.guilds[expectedKey].identity

        local state = accountData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 10)
        test.assert_equal(state.model.schemaVersion, 13)
        test.assert_equal(state.model.guilds[expectedKey].identity, identity)
        test.assert_equal(
            state.model.guilds[expectedKey].roster.guild,
            identity
        )
        test.assert_equal(
            state.model.guilds[expectedKey].bank.guild,
            identity
        )
        test.assert_nil(state.model.guilds[identity.key .. "-migrated"])
        test.assert_equal(original.schemaVersion, 10)
        test.assert_true(original.guilds[expectedKey].identity == originalIdentity)
        test.assert_equal(original.guilds[expectedKey].identity.id, "legacy-" .. identity.key)
    end),

    test.case("failed identity migration preserves the complete account store", function()
        local validIdentity = guild("Night Shift", "area-52")
        local malformedIdentity = guild("Day Shift", "illidan")
        local original = assert(accountData.replaceProvisions(
            accountData.newModel(),
            validIdentity,
            {},
            1
        ))
        original = assert(accountData.replaceProvisions(
            original,
            malformedIdentity,
            {},
            1
        ))
        original.schemaVersion = 10
        downgradeGuildIdentities(original)
        local malformedKey = malformedIdentity.key
        original.guilds[malformedKey].identity.region = "Unknown"
        local originalValidIdentity = original.guilds[validIdentity.key].identity

        local state = accountData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_true(state.original == original)
        test.assert_true(original.guilds[validIdentity.key].identity == originalValidIdentity)
        test.assert_equal(original.schemaVersion, 10)
        test.assert_equal(original.guilds[malformedKey].identity.region, "Unknown")
    end),

    test.case("version 11 persists Retail roster and observation identities copy-on-write", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        local originalPartition = accountData.findGuild(original, identity)
        originalPartition.rosterObservation = {
            scannedAt = fixtures.timestamp(),
            members = {
                {
                    identity = "main-area-52",
                    displayName = "Main-Area-52",
                    rankIndex = 7,
                    rankName = "Veteran",
                },
            },
        }
        downgradeRosterIdentityPersistence(original)

        local state = accountData.load(original)
        local migrated = accountData.findGuild(state.model, identity)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 11)
        test.assert_equal(state.model.schemaVersion, 13)
        test.assert_equal(migrated.roster.members[1].identity, "main-area-52")
        test.assert_equal(migrated.rosterObservation, {
            scannedAt = fixtures.timestamp(),
            members = {
                {
                    identity = "main-area-52",
                    displayName = "Main-Area-52",
                    rankIndex = 7,
                    rankName = "Veteran",
                },
            },
        })
        test.assert_equal(original.schemaVersion, 11)
        test.assert_nil(originalPartition.roster.members[1].identity)
        test.assert_equal(originalPartition.rosterObservation.members[1].name, "Main-Area-52")
        test.assert_nil(originalPartition.rosterObservation.members[1].displayName)
    end),

    test.case("version 11 preserves note and tag identities with unrelated guild data", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        original = assert(accountData.replaceDataset(
            original,
            identity,
            "bank",
            {
                guild = identity,
                scannedAt = fixtures.timestamp(),
                money = 12345,
                tabs = { fixtures.bank_tab() },
                slots = { fixtures.bank_slot() },
            }
        ))
        local originalPartition = accountData.findGuild(original, identity)
        originalPartition.mainAltGroups = {
            ["Main-Area-52"] = { "Alt-Area-52" },
        }
        originalPartition.characterNotes = {
            ["main-area-52"] = "Preserved note",
        }
        originalPartition.tags = {
            definitions = { me = true, raid = true },
            assignments = { ["main-area-52"] = { raid = true } },
        }
        originalPartition.newsSets = {
            {
                id = "historical-labels",
                createdDate = "2024-06-01",
                joiningMembers = { "Original Join Label" },
                leavingMembers = { "Original Leave Label" },
                rankChanges = {
                    { name = "Original Rank Label", rankName = "Veteran" },
                },
            },
        }
        originalPartition.provisions = {
            { id = 1, name = "Guild Feast", quality = "either", target = 20 },
        }
        originalPartition.nextProvisionId = 2
        originalPartition.chartHistory.gold = {
            { date = "2024-06-01", value = 12345 },
        }
        downgradeRosterIdentityPersistence(original)

        local state = accountData.load(original, "2024-06-01")
        local migrated = accountData.findGuild(state.model, identity)

        test.assert_true(state.enabled)
        test.assert_equal(migrated.bank, originalPartition.bank)
        test.assert_equal(migrated.mainAltGroups, {
            ["main-area-52"] = { "alt-area-52" },
        })
        test.assert_equal(migrated.characterNotes, originalPartition.characterNotes)
        test.assert_equal(migrated.tags, originalPartition.tags)
        test.assert_equal(migrated.newsSets, originalPartition.newsSets)
        test.assert_equal(migrated.provisions, originalPartition.provisions)
        test.assert_equal(migrated.nextProvisionId, originalPartition.nextProvisionId)
        test.assert_equal(migrated.chartHistory, originalPartition.chartHistory)
    end),

    test.case("version 11 rejects duplicate observation identities", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceProvisions(
            accountData.newModel(),
            identity,
            {},
            1
        ))
        original.schemaVersion = 11
        local partition = accountData.findGuild(original, identity)
        partition.rosterObservation = {
            scannedAt = fixtures.timestamp(),
            members = {
                {
                    identity = "same-area-52",
                    name = "First Label",
                    rankIndex = 2,
                    rankName = "Member",
                },
                {
                    identity = "same-area-52",
                    name = "Second Label",
                    rankIndex = 3,
                    rankName = "Initiate",
                },
            },
        }

        local state = accountData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "identity must be unique")
        test.assert_true(state.original == original)
        test.assert_equal(original.schemaVersion, 11)
        test.assert_equal(partition.rosterObservation.members[2].name, "Second Label")
    end),

    test.case("late version 11 failure preserves the supplied account store", function()
        local identity = guild("Night Shift", "area-52")
        local original = assert(accountData.replaceDataset(
            accountData.newModel(),
            identity,
            "roster",
            completedRoster(identity, "Main")
        ))
        local partition = accountData.findGuild(original, identity)
        partition.rosterObservation = {
            scannedAt = fixtures.timestamp(),
            members = {
                {
                    identity = "NOT-LOWERCASE",
                    displayName = "Unmigratable Label",
                    rankIndex = 2,
                    rankName = "Member",
                },
            },
        }
        downgradeRosterIdentityPersistence(original)

        local state = accountData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "rosterObservation.members%[1%] is invalid")
        test.assert_true(state.original == original)
        test.assert_equal(original.schemaVersion, 11)
        test.assert_nil(partition.roster.members[1].identity)
        test.assert_equal(partition.rosterObservation.members[1].name, "Unmigratable Label")
        test.assert_nil(partition.rosterObservation.members[1].displayName)
    end),

    test.case("version 12 migrates only group labels to opaque Retail identities", function()
        local identity = guild("Night Shift", "Area-52")
        local original = assert(accountData.replaceProvisions(
            accountData.newModel(),
            identity,
            {},
            1
        ))
        original.schemaVersion = 12
        local originalPartition = accountData.findGuild(original, identity)
        originalPartition.mainAltGroups = {
            ["Main-Area-52"] = { "Alt-Area-52", "Other-Illidan" },
        }
        originalPartition.characterNotes = {
            ["main-area-52"] = "Preserve this key and note",
        }
        originalPartition.tags = {
            definitions = { me = true, raid = true },
            assignments = {
                ["alt-area-52"] = { raid = true },
            },
        }

        local state = accountData.load(original)
        local migrated = accountData.findGuild(state.model, identity)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 12)
        test.assert_equal(state.model.schemaVersion, 13)
        test.assert_equal(migrated.mainAltGroups, {
            ["main-area-52"] = { "alt-area-52", "other-illidan" },
        })
        test.assert_equal(migrated.characterNotes, originalPartition.characterNotes)
        test.assert_equal(migrated.tags, originalPartition.tags)
        test.assert_equal(original.schemaVersion, 12)
        test.assert_equal(originalPartition.mainAltGroups, {
            ["Main-Area-52"] = { "Alt-Area-52", "Other-Illidan" },
        })
    end),

    test.case("version 12 rejects colliding Retail group labels atomically", function()
        local identity = guild("Night Shift", "Area-52")
        local original = assert(accountData.replaceProvisions(
            accountData.newModel(),
            identity,
            {},
            1
        ))
        original.schemaVersion = 12
        local partition = accountData.findGuild(original, identity)
        partition.mainAltGroups = {
            ["Main-Area-52"] = { "First-Area-52" },
            ["main-area-52"] = { "Second-Area-52" },
        }

        local state = accountData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "colliding")
        test.assert_true(state.original == original)
        test.assert_equal(original.schemaVersion, 12)
        test.assert_equal(partition.mainAltGroups["Main-Area-52"], {
            "First-Area-52",
        })
        test.assert_equal(partition.mainAltGroups["main-area-52"], {
            "Second-Area-52",
        })
    end),

    test.case("version 12 rejects duplicate canonical group membership atomically", function()
        local identity = guild("Night Shift", "Area-52")
        local original = assert(accountData.replaceProvisions(
            accountData.newModel(),
            identity,
            {},
            1
        ))
        original.schemaVersion = 12
        local partition = accountData.findGuild(original, identity)
        partition.mainAltGroups = {
            ["First-Area-52"] = { "Shared-Area-52" },
            ["Second-Area-52"] = { "shared-area-52" },
        }

        local state = accountData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "duplicate or colliding")
        test.assert_true(state.original == original)
        test.assert_equal(original.schemaVersion, 12)
        test.assert_equal(partition.mainAltGroups["First-Area-52"], {
            "Shared-Area-52",
        })
    end),

    test.case("malformed version 12 group migration leaves the source recoverable", function()
        local identity = guild("Night Shift", "Area-52")
        local original = assert(accountData.replaceProvisions(
            accountData.newModel(),
            identity,
            {},
            1
        ))
        original.schemaVersion = 12
        local partition = accountData.findGuild(original, identity)
        partition.mainAltGroups = {
            ["MissingRealm"] = { "Alt-Area-52" },
        }

        local state = accountData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "cannot be migrated")
        test.assert_true(state.original == original)
        test.assert_equal(original.schemaVersion, 12)
        test.assert_equal(partition.mainAltGroups, {
            ["MissingRealm"] = { "Alt-Area-52" },
        })
    end),

    test.case("current feature identity keys are validated without parsing", function()
        local identity = foreverGuild("Night Shift", "US", 4242)
        local model = assert(accountData.replaceProvisions(
            accountData.newModel(),
            identity,
            {},
            1
        ))
        local partition = accountData.findGuild(model, identity)
        local mainIdentity = "RGMS:CHARACTER:FOREVER:1:2:US:9:Ash Birch"
        local altIdentity = "opaque alt identity with [brackets]"
        partition.mainAltGroups = {
            [mainIdentity] = { altIdentity },
        }
        partition.characterNotes = {
            [mainIdentity] = "Private note",
        }
        partition.tags = {
            definitions = { me = true, raid = true },
            assignments = {
                [altIdentity] = { raid = true },
            },
        }

        test.assert_true(accountData.validate(model))
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

    test.case("chart history remains account-wide inside only its guild partition", function()
        local active = guild("Night Shift", "area-52")
        local other = guild("Night Shift", "illidan")
        local model = assert(accountData.replaceChartHistory(
            accountData.newModel(),
            active,
            {
                gold = { { date = "2024-06-01", value = 500 } },
                members = {},
            }
        ))
        model = assert(accountData.replaceChartHistory(
            model,
            other,
            chartModel.newHistory()
        ))

        test.assert_equal(accountData.view(model, active, {}).chartHistory.gold, {
            { date = "2024-06-01", value = 500 },
        })
        test.assert_equal(accountData.view(model, other, {}).chartHistory.gold, {})
        test.assert_equal(accountData.view(model, nil, {}).chartHistory.gold, {})
    end),

    test.case("account load prunes chart points and final empty member series", function()
        local identity = guild("Night Shift", "area-52")
        local model = assert(accountData.replaceChartHistory(
            accountData.newModel(),
            identity,
            {
                gold = {
                    { date = "2024-01-01", value = 1 },
                    { date = "2024-01-03", value = 2 },
                },
                members = {
                    {
                        rankIndex = 2, name = "Expired",
                        points = { { date = "2024-01-01", value = 1 } },
                    },
                },
            }
        ))

        local state = accountData.load(model, "2024-06-30")
        local history = accountData.findGuild(state.model, identity).chartHistory
        test.assert_true(state.enabled)
        test.assert_equal(history.gold, { { date = "2024-01-03", value = 2 } })
        test.assert_equal(history.members, {})
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

        local metadataVariant = guild("Night Shift", "area-52", "EU")
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

    test.case("Forever partitions cannot collide with Retail or another region", function()
        local retail = guild("Night Shift", "area-52", "US")
        local foreverUS = foreverGuild("Night Shift", "US", 4242)
        local foreverEU = foreverGuild("Night Shift", "EU", 4242)
        local model = accountData.newModel()

        model = assert(accountData.replaceProvisions(model, retail, {
            { id = 1, name = "Retail Supply", quality = "either", target = 1 },
        }, 2))
        model = assert(accountData.replaceProvisions(model, foreverUS, {
            { id = 1, name = "US Supply", quality = "either", target = 1 },
        }, 2))
        model = assert(accountData.replaceProvisions(model, foreverEU, {
            { id = 1, name = "EU Supply", quality = "either", target = 1 },
        }, 2))

        test.assert_false(retail.key == foreverUS.key)
        test.assert_false(foreverUS.key == foreverEU.key)
        test.assert_equal(
            accountData.findGuild(model, retail).provisions[1].name,
            "Retail Supply"
        )
        test.assert_equal(
            accountData.findGuild(model, foreverUS).provisions[1].name,
            "US Supply"
        )
        test.assert_equal(
            accountData.findGuild(model, foreverEU).provisions[1].name,
            "EU Supply"
        )
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
                    identity = "RGMS:CHARACTER:FOREVER:1:2:US:21:First-048 Surname-042",
                    displayName = "Active Display Label",
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
        test.assert_equal(
            accountData.findGuild(replacement, active).rosterObservation,
            observation
        )
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
        local function applyCharts(model, guildIdentity, datasetName, snapshot)
            local partition = accountData.findGuild(model, guildIdentity)
            local history = assert(chartModel.recordRoster(
                partition.chartHistory,
                snapshot
            ))
            return accountData.replaceChartHistory(model, guildIdentity, history)
        end
        local controller = datasetOwnership.create({
            savedData = savedData,
            accountData = accountData,
            getSavedData = function() return current end,
            commit = function(model) current = model end,
            reconcileRosterFeatures = groups.reconcile,
            reconcileCharacterTags = tags.reconcile,
            applyRosterNews = applyNews,
            applyChartHistory = applyCharts,
            print = function() end,
        })
        local firstSnapshot = completedRoster(identity, "Alpha")
        firstSnapshot.ranks[1].index = 2
        firstSnapshot.ranks[1].name = "Member"
        firstSnapshot.members[1].rankIndex = 2
        firstSnapshot.members[1].rankName = "Member"
        local first = assert(controller:begin("roster", identity))
        first.dataset = firstSnapshot
        first.snapshot = firstSnapshot
        local committed, _, created = controller:finish(first, "success")
        test.assert_true(committed)
        test.assert_false(created)
        test.assert_equal(accountData.findGuild(current, identity).newsSets, {})
        test.assert_equal(
            accountData.findGuild(current, identity).chartHistory.members[1].points,
            { { date = "2024-06-01", value = 1 } }
        )

        local secondSnapshot = completedRoster(identity, "Bravo")
        secondSnapshot.ranks[1].index = 2
        secondSnapshot.ranks[1].name = "Member"
        secondSnapshot.members[1].rankIndex = 2
        secondSnapshot.members[1].rankName = "Member"
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
        test.assert_equal(
            #accountData.findGuild(current, identity).chartHistory.members[1].points,
            1
        )

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
        test.assert_equal(#partition.chartHistory.members[1].points, 2)
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
                    displayName = "Active-area-52",
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
        activePartition.chartHistory.gold = {
            { date = "2024-06-01", value = 12345 },
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
            accountData.findGuild(account, active).chartHistory,
            chartModel.newHistory()
        )
        test.assert_equal(
            accountData.findGuild(account, other).roster.members[1].name,
            "Other"
        )
        test.assert_true(character.ui.windowPosition == originalPosition)
        test.assert_nil(character.ui.selectedRosterRankIndex)
        test.assert_nil(character.ui.selectedBankTabIndex)
        test.assert_equal(character.roster.members[1].name, "Aeloria")
    end),

    test.case("reset keeps same-named product and region partitions isolated", function()
        local retail = guild("Night Shift", "area-52", "US")
        local foreverUS = foreverGuild("Night Shift", "US", 4242)
        local foreverEU = foreverGuild("Night Shift", "EU", 4242)
        local account = accountData.newModel()
        for _, entry in ipairs({
            { identity = retail, name = "Retail Supply" },
            { identity = foreverUS, name = "US Supply" },
            { identity = foreverEU, name = "EU Supply" },
        }) do
            account = assert(accountData.replaceProvisions(account, entry.identity, {
                { id = 1, name = entry.name, quality = "either", target = 1 },
            }, 2))
        end
        local character = fixtures.saved_model()
        local controller = reset.create({
            savedData = savedData,
            accountData = accountData,
            getSavedData = function() return character end,
            getAccountData = function() return account end,
            getGuildIdentity = function() return foreverUS end,
            getState = function() return { enabled = true } end,
            commitAccount = function(newAccount, newCharacter)
                account = newAccount
                character = newCharacter
            end,
            showConfirmation = function() end,
            print = function() end,
        })

        test.assert_true(controller:confirm(controller:requestManual()))

        test.assert_equal(accountData.findGuild(account, foreverUS).provisions, {})
        test.assert_equal(
            accountData.findGuild(account, retail).provisions[1].name,
            "Retail Supply"
        )
        test.assert_equal(
            accountData.findGuild(account, foreverEU).provisions[1].name,
            "EU Supply"
        )
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
