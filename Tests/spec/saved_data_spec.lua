local clientFlavor = require("Core.ClientFlavor")
local characterIdentity = require("Core.CharacterIdentity")
local fixtures = require("Tests.fixtures")
local guildIdentity = require("Core.GuildIdentity")
local savedData = require("Core.SavedData")
local test = require("Tests.lib.runner")

local function legacyRosterMember(overrides)
    local member = fixtures.roster_member(overrides)
    member.identity = nil
    return member
end

return {
    test.case("fresh load creates a valid empty model", function()
        local state = savedData.load(nil)

        test.assert_true(state.enabled)
        test.assert_true(state.initialized)
        test.assert_equal(state.status, "ready")
        test.assert_equal(state.model, {
            schemaVersion = 10,
            roster = {
                ranks = {},
                members = {},
            },
            bank = {
                tabs = {},
                slots = {},
            },
            ui = {},
        })
        test.assert_true(savedData.validate(state.model))
    end),

    test.case("round-trip-shaped current data is restored without aliasing input", function()
        local original = fixtures.saved_model()
        original.roster.members[1].leadershipRole = "officer"
        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.model, original)

        state.model.roster.members[1].name = "Changed After Load"
        state.model.ui.windowPosition.x = 999
        test.assert_equal(original.roster.members[1].name, "Aeloria")
        test.assert_equal(original.ui.windowPosition.x, 120)
    end),

    test.case("roster leadership roles accept only supported Retail roles", function()
        local guildMaster = fixtures.saved_model()
        guildMaster.roster.members[1].leadershipRole = "guild-master"
        test.assert_true(savedData.validate(guildMaster))

        local officer = fixtures.saved_model()
        officer.roster.members[1].leadershipRole = "officer"
        test.assert_true(savedData.validate(officer))

        local invalid = fixtures.saved_model()
        invalid.roster.members[1].leadershipRole = "member"
        local valid, validationError = savedData.validate(invalid)
        test.assert_nil(valid)
        test.assert_matches(validationError, "leadershipRole")
    end),

    test.case("schema version seven adds optional per-character dropdown selections", function()
        local original = fixtures.saved_model_v7()

        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 7)
        test.assert_equal(state.model.schemaVersion, 10)
        test.assert_nil(state.model.ui.selectedRosterRankIndex)
        test.assert_nil(state.model.ui.selectedBankTabIndex)
        state.model.ui.selectedRosterRankIndex = 0
        state.model.ui.selectedBankTabIndex = 3
        test.assert_true(savedData.validate(state.model))
        state.model.ui.selectedBankTabIndex = 0
        test.assert_nil(savedData.validate(state.model))
    end),

    test.case("schema version eight infers Retail identities copy-on-write", function()
        local original = fixtures.saved_model_v8()
        original.ui.selectedRosterRankIndex = 0
        original.ui.selectedBankTabIndex = 2

        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 8)
        test.assert_equal(state.model.schemaVersion, 10)
        for _, datasetName in ipairs({ "roster", "bank" }) do
            local identity = state.model[datasetName].guild
            test.assert_equal(identity.flavor, clientFlavor.RETAIL)
            test.assert_equal(identity.region, "US")
            test.assert_equal(identity.name, "Example Guild")
            test.assert_equal(identity.displayName, "Example Guild")
            test.assert_equal(identity.key, "13:Example Guild:example-realm")
            test.assert_equal(identity.realm, {
                name = "Example Realm",
                slug = "example-realm",
            })
            test.assert_nil(identity.clubId)
            test.assert_nil(identity.id)
        end
        test.assert_equal(state.model.ui.selectedRosterRankIndex, 0)
        test.assert_equal(state.model.ui.selectedBankTabIndex, 2)
        test.assert_equal(original.schemaVersion, 8)
        test.assert_not_nil(original.roster.guild.id)
        test.assert_nil(original.roster.guild.flavor)
        test.assert_not_nil(original.bank.guild.id)
        test.assert_nil(original.bank.guild.flavor)
    end),

    test.case("late schema version eight failure preserves the supplied store", function()
        local original = fixtures.saved_model_v8()
        original.bank.guild.region = "UNKNOWN"
        local before = fixtures.saved_model_v8()
        before.bank.guild.region = "UNKNOWN"

        local state = savedData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "guild region is unsupported")
        test.assert_true(state.original == original)
        test.assert_equal(original, before)
        test.assert_nil(original.roster.guild.flavor)
        test.assert_not_nil(original.roster.guild.id)
    end),

    test.case("schema version nine adds exact Retail member identities copy-on-write", function()
        local original = fixtures.saved_model_v9()
        original.ui.selectedRosterRankIndex = 1
        original.ui.selectedBankTabIndex = 2
        local member = original.roster.members[1]
        local expected = assert(characterIdentity.create({
            flavor = clientFlavor.RETAIL,
            region = original.roster.guild.region,
            name = member.name,
            realm = member.realm,
            guid = member.guid,
        }))

        local state = savedData.load(original)
        local migrated = state.model.roster.members[1]

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 9)
        test.assert_equal(state.model.schemaVersion, 10)
        test.assert_equal(migrated.identity, expected.key)
        test.assert_equal(migrated.displayName, member.displayName)
        test.assert_equal(migrated.guid, member.guid)
        test.assert_equal(migrated.rankTenureStartDate, member.rankTenureStartDate)
        test.assert_equal(migrated.lastSeenDate, member.lastSeenDate)
        test.assert_equal(state.model.bank, original.bank)
        test.assert_equal(state.model.ui, original.ui)
        test.assert_equal(original.schemaVersion, 9)
        test.assert_nil(original.roster.members[1].identity)
    end),

    test.case("schema version nine resolves duplicate identities deterministically", function()
        local original = fixtures.saved_model_v9()
        local later = fixtures.timestamp({
            unixSeconds = 1717245326,
            iso8601 = "2024-06-01T12:35:26Z",
        })
        original.roster.members = {
            legacyRosterMember({
                guid = "Player-0000-ALPHA-MISSING",
                name = "Alpha",
                realm = "Example Realm",
                displayName = "Alpha-Example Realm",
                observedAt = later,
                isMissing = true,
            }),
            legacyRosterMember({
                guid = "Player-0000-ALPHA-PRESENT",
                name = "alpha",
                realm = "example realm",
                displayName = "alpha-example realm",
                isMissing = false,
            }),
            legacyRosterMember({
                guid = "Player-0000-BRAVO-OLDER",
                name = "Bravo",
                realm = "Example Realm",
                displayName = "Bravo-Example Realm",
            }),
            legacyRosterMember({
                guid = "Player-0000-BRAVO-NEWER",
                name = "bravo",
                realm = "example realm",
                displayName = "bravo-example realm",
                observedAt = later,
            }),
            legacyRosterMember({
                guid = "Player-0000-CHARLIE-FIRST",
                name = "Charlie",
                realm = "Example Realm",
                displayName = "Charlie-Example Realm",
            }),
            legacyRosterMember({
                guid = "Player-0000-CHARLIE-SECOND",
                name = "charlie",
                realm = "example realm",
                displayName = "charlie-example realm",
            }),
        }

        local state = savedData.load(original)
        local members = state.model.roster.members

        test.assert_true(state.enabled)
        test.assert_equal(#members, 3)
        test.assert_equal(members[1].guid, "Player-0000-ALPHA-PRESENT")
        test.assert_equal(members[1].identity, "alpha-example realm")
        test.assert_equal(members[2].guid, "Player-0000-BRAVO-NEWER")
        test.assert_equal(members[2].identity, "bravo-example realm")
        test.assert_equal(members[3].guid, "Player-0000-CHARLIE-FIRST")
        test.assert_equal(members[3].identity, "charlie-example realm")
        test.assert_equal(#original.roster.members, 6)
        test.assert_nil(original.roster.members[1].identity)
    end),

    test.case("late schema version nine failure rolls back identity migration", function()
        local original = fixtures.saved_model_v9()
        original.bank.tabs[1].lastAccessibleAt = fixtures.timestamp({
            unixSeconds = original.bank.scannedAt.unixSeconds + 1,
            iso8601 = "2024-06-01T12:34:57Z",
        })
        local before = fixtures.saved_model_v9()
        before.bank.tabs[1].lastAccessibleAt = fixtures.timestamp({
            unixSeconds = before.bank.scannedAt.unixSeconds + 1,
            iso8601 = "2024-06-01T12:34:57Z",
        })

        local state = savedData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "lastAccessibleAt must not follow scannedAt")
        test.assert_true(state.original == original)
        test.assert_equal(original, before)
        test.assert_nil(original.roster.members[1].identity)
    end),

    test.case("current Retail and Forever identities use exact canonical shapes", function()
        local retail = fixtures.saved_model()
        test.assert_true(savedData.validate(retail))

        local forever = assert(guildIdentity.create({
            flavor = clientFlavor.FOREVER,
            region = "EU",
            name = "Example Guild",
            clubId = "Club-001",
        }))
        local foreverModel = fixtures.saved_model()
        foreverModel.roster.guild = forever
        foreverModel.bank.guild = forever
        test.assert_true(savedData.validate(foreverModel))

        local unexpected = fixtures.saved_model()
        unexpected.roster.guild.id = "legacy-id"
        local valid, validationError = savedData.validate(unexpected)
        test.assert_nil(valid)
        test.assert_matches(validationError, "unexpected field id")

        local unexpectedRealm = fixtures.saved_model()
        unexpectedRealm.bank.guild.realm.label = "metadata"
        valid, validationError = savedData.validate(unexpectedRealm)
        test.assert_nil(valid)
        test.assert_matches(validationError, "unexpected field label")
    end),

    test.case("current roster display fields are independent of opaque identity", function()
        local retail = fixtures.saved_model()
        retail.roster.members[1].displayName = "Aeloria the Mage"
        test.assert_true(savedData.validate(retail))

        local foreverGuild = assert(guildIdentity.create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Example Guild",
            clubId = "Club-001",
        }))
        local foreverIdentity = assert(characterIdentity.create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Avery Ash",
            guid = "Player-0000-FOREVER-0001",
        }))
        local forever = fixtures.saved_model()
        local member = forever.roster.members[1]
        forever.roster.guild = foreverGuild
        member.identity = foreverIdentity.key
        member.guid = foreverIdentity.guid
        member.name = foreverIdentity.name
        member.realm = nil
        member.displayName = "Avery (Ash)"

        test.assert_true(savedData.validate(forever))

        member.identity = ""
        local valid, validationError = savedData.validate(forever)
        test.assert_nil(valid)
        test.assert_matches(validationError, "identity must be a non%-empty string")
    end),

    test.case("current roster identities must be unique", function()
        local model = fixtures.saved_model()
        model.roster.members[2] = fixtures.roster_member({
            guid = "Player-0000-00000002",
            name = "aeloria",
            realm = "example realm",
            displayName = "AELORIA (duplicate label)",
        })

        local valid, validationError = savedData.validate(model)

        test.assert_nil(valid)
        test.assert_matches(validationError, "identity must be unique")
    end),

    test.case("copying canonical guild identities does not alias callers", function()
        local original = fixtures.guild_identity()
        local copied = assert(savedData.copyGuildIdentity(original))

        test.assert_equal(copied, original)
        test.assert_false(copied == original)
        test.assert_false(copied.realm == original.realm)
        copied.realm.name = "Changed Realm"
        test.assert_equal(original.realm.name, "Example Realm")
    end),

    test.case("separate character loads never share nested state", function()
        local firstCharacter = savedData.load(nil).model
        local secondCharacter = savedData.load(nil).model

        firstCharacter.roster.ranks[1] = fixtures.roster_rank()
        firstCharacter.ui.windowPosition = fixtures.window_position()

        test.assert_equal(#secondCharacter.roster.ranks, 0)
        test.assert_nil(secondCharacter.ui.windowPosition)
    end),

    test.case("schema version zero migrates deterministically", function()
        local original = fixtures.saved_model_v0()
        local first = savedData.load(original)
        local second = savedData.load(original)

        test.assert_true(first.enabled)
        test.assert_equal(first.migratedFrom, 0)
        test.assert_equal(first.model, second.model)
        test.assert_equal(first.model.schemaVersion, 10)
        test.assert_equal(
            first.model.roster.guild,
            assert(savedData.migrateLegacyGuildIdentity(original.roster.guildIdentity))
        )
        test.assert_equal(first.model.roster.scannedAt, original.roster.scanTimestamp)
        test.assert_equal(
            first.model.bank.guild,
            assert(savedData.migrateLegacyGuildIdentity(original.bank.guildIdentity))
        )
        test.assert_equal(first.model.ui.windowPosition, original.windowPosition)
        test.assert_equal(original.schemaVersion, 0)
        test.assert_nil(original.roster.guild)
    end),

    test.case("schema version one backfills roster identity and rank names", function()
        local original = fixtures.saved_model_v1()
        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 1)
        test.assert_equal(state.model.schemaVersion, 10)
        test.assert_equal(
            state.model.roster.members[1].displayName,
            "Aeloria-Example Realm"
        )
        test.assert_equal(state.model.roster.members[1].rankName, "Officer")
        test.assert_nil(state.model.roster.members[1].lastOnline)
        test.assert_equal(
            state.model.roster.members[1].rankTenureStartDate,
            "2024-06-01"
        )
        test.assert_equal(state.model.roster.members[1].lastSeenDate, "2024-06-01")
        test.assert_false(state.model.roster.members[1].isMissing)
        test.assert_equal(original.schemaVersion, 1)
        test.assert_nil(original.roster.members[1].displayName)
    end),

    test.case("schema version two backfills rank tenure from the observation date", function()
        local original = fixtures.saved_model_v2()
        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 2)
        test.assert_equal(state.model.schemaVersion, 10)
        test.assert_equal(
            state.model.roster.members[1].rankTenureStartDate,
            "2024-06-01"
        )
        test.assert_equal(original.schemaVersion, 2)
        test.assert_nil(original.roster.members[1].rankTenureStartDate)
    end),

    test.case("schema version three backfills missing-member state", function()
        local original = fixtures.saved_model_v3()
        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 3)
        test.assert_equal(state.model.schemaVersion, 10)
        test.assert_equal(state.model.roster.members[1].lastSeenDate, "2024-06-01")
        test.assert_false(state.model.roster.members[1].isMissing)
        test.assert_equal(original.schemaVersion, 3)
        test.assert_nil(original.roster.members[1].lastSeenDate)
        test.assert_nil(original.roster.members[1].isMissing)
    end),

    test.case("schema version four repairs repeated realms and duplicate members", function()
        local corruptedRealm = "Ner'zhul-Ner'zhul-Ner'zhul-Ner'zh"
        local original = fixtures.saved_model_v4()
        original.roster.guild.realm.name = corruptedRealm
        original.roster.guild.realm.slug = corruptedRealm
        original.bank.guild.realm.name = "Deep-Rock-deep-rock-De"
        original.bank.guild.realm.slug = "deep-rock-Deep-Rock-de"
        original.roster.members = {
            legacyRosterMember({
                name = "Nalla",
                realm = "Ner'zhul",
                displayName = "Nalla-Ner'zhul",
                isMissing = true,
            }),
            legacyRosterMember({
                name = "Nalla",
                realm = corruptedRealm,
                displayName = "Nalla-" .. corruptedRealm,
                isMissing = false,
            }),
        }

        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 4)
        test.assert_equal(state.model.schemaVersion, 10)
        test.assert_equal(state.model.roster.guild.realm.name, "Ner'zhul")
        test.assert_equal(state.model.roster.guild.realm.slug, "Ner'zhul")
        test.assert_equal(state.model.bank.guild.realm.name, "Deep-Rock")
        test.assert_equal(state.model.bank.guild.realm.slug, "deep-rock")
        test.assert_equal(#state.model.roster.members, 1)
        test.assert_equal(state.model.roster.members[1].realm, "Ner'zhul")
        test.assert_equal(
            state.model.roster.members[1].displayName,
            "Nalla-Ner'zhul"
        )
        test.assert_false(state.model.roster.members[1].isMissing)
        test.assert_equal(original.schemaVersion, 4)
        test.assert_equal(#original.roster.members, 2)
        test.assert_equal(original.roster.members[2].realm, corruptedRealm)
    end),

    test.case("schema version five backfills bank stable-since dates", function()
        local original = fixtures.saved_model_v5()
        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 5)
        test.assert_equal(state.model.schemaVersion, 10)
        test.assert_equal(
            state.model.bank.slots[1].stableSinceDate,
            "2024-06-01"
        )
        test.assert_nil(original.bank.slots[1].stableSinceDate)
        test.assert_equal(original.schemaVersion, 5)
    end),

    test.case("schema version six backfills per-tab accessible timestamps", function()
        local original = fixtures.saved_model_v6()
        local earlier = fixtures.timestamp({
            unixSeconds = 1717158896,
            iso8601 = "2024-05-31T12:34:56Z",
        })
        original.bank.tabs = {
            fixtures.bank_tab({ index = 1, isViewable = true }),
            fixtures.bank_tab({ index = 2, isViewable = false }),
            fixtures.bank_tab({ index = 3, isViewable = false }),
        }
        for _, tab in ipairs(original.bank.tabs) do
            tab.lastAccessibleAt = nil
        end
        original.bank.slots = {
            fixtures.bank_slot({
                tabIndex = 2,
                observedAt = earlier,
                stableSinceDate = "2024-05-31",
            }),
        }
        original.bank.slots[1].icon = nil

        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 6)
        test.assert_equal(state.model.schemaVersion, 10)
        test.assert_equal(
            state.model.bank.tabs[1].lastAccessibleAt,
            original.bank.scannedAt
        )
        test.assert_equal(state.model.bank.tabs[2].lastAccessibleAt, earlier)
        test.assert_nil(state.model.bank.tabs[3].lastAccessibleAt)
        test.assert_nil(original.bank.tabs[1].lastAccessibleAt)
        test.assert_equal(original.schemaVersion, 6)
    end),

    test.case("the previous development placeholder migrates to an empty model", function()
        local original = {
            loadCount = 4,
            lastLoadedAt = "2026-10-11 09:00 PT",
        }
        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, "development-placeholder")
        test.assert_equal(state.model, savedData.newModel())
        test.assert_equal(original.loadCount, 4)
    end),

    test.case("corrupt data disables use and preserves the original", function()
        local original = fixtures.saved_model()
        original.roster.members[1].level = "eighty"
        local before = fixtures.saved_model()
        before.roster.members[1].level = "eighty"

        local state = savedData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "level must be an integer")
        test.assert_equal(state.original, original)
        test.assert_equal(original, before)
        test.assert_nil(state.model)
    end),

    test.case("current saved data rejects noncanonical realms", function()
        local original = fixtures.saved_model()
        local corruptedRealm = "Area52-Area52-Area"
        original.roster.members[1].realm = corruptedRealm
        original.roster.members[1].displayName = "Aeloria-" .. corruptedRealm

        local state = savedData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "realm must be canonical")
        test.assert_equal(original.roster.members[1].realm, corruptedRealm)
    end),

    test.case("inconsistent scan timestamps fail validation", function()
        local original = fixtures.saved_model()
        original.bank.scannedAt.iso8601 = "2024-06-01T12:34:57Z"
        local state = savedData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "must represent the same time")
        test.assert_equal(original.bank.scannedAt.iso8601, "2024-06-01T12:34:57Z")
    end),

    test.case("rank tenure start dates cannot follow their observations", function()
        local original = fixtures.saved_model()
        original.roster.members[1].rankTenureStartDate = "2024-06-02"
        local state = savedData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "must not follow observedAt")
    end),

    test.case("bank stable-since dates cannot follow their observations", function()
        local original = fixtures.saved_model()
        original.bank.slots[1].stableSinceDate = "2024-06-02"
        local state = savedData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "stableSinceDate must not follow observedAt")
    end),

    test.case("bank last-access timestamps cannot follow the overall scan", function()
        local model = fixtures.saved_model()
        model.bank.tabs[1].lastAccessibleAt = fixtures.timestamp({
            unixSeconds = model.bank.scannedAt.unixSeconds + 1,
            iso8601 = "2024-06-01T12:34:57Z",
        })

        local state = savedData.load(model)

        test.assert_false(state.enabled)
        test.assert_matches(state.error, "lastAccessibleAt must not follow scannedAt")
    end),

    test.case("missing state must match the member's last observation", function()
        local invalidDate = fixtures.saved_model()
        invalidDate.roster.members[1].lastSeenDate = "2024-05-31"
        local dateState = savedData.load(invalidDate)

        test.assert_false(dateState.enabled)
        test.assert_matches(dateState.error, "must match observedAt")

        local invalidOnline = fixtures.saved_model()
        invalidOnline.roster.members[1].isMissing = true
        invalidOnline.roster.members[1].isOnline = true
        invalidOnline.roster.members[1].lastOnline = nil
        local onlineState = savedData.load(invalidOnline)

        test.assert_false(onlineState.enabled)
        test.assert_matches(onlineState.error, "must be false while the member is missing")
    end),

    test.case("unsupported versions disable use and preserve the original", function()
        local original = {
            schemaVersion = 99,
            futureData = { doNotDiscard = true },
        }
        local state = savedData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "incompatible")
        test.assert_matches(state.error, "unsupported schema version 99")
        test.assert_equal(state.original, original)
        test.assert_true(original.futureData.doNotDiscard)
        test.assert_nil(state.model)
    end),

    test.case("unversioned unknown data is corrupt rather than silently erased", function()
        local original = {
            unknownObservations = { "keep me" },
        }
        local state = savedData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_equal(state.original, original)
        test.assert_equal(original.unknownObservations[1], "keep me")
    end),

    test.case("observation reset preserves valid window position", function()
        local model = fixtures.saved_model()
        local reset = savedData.resetObservations(model)

        test.assert_equal(reset.roster.ranks, {})
        test.assert_equal(reset.roster.members, {})
        test.assert_equal(reset.bank.tabs, {})
        test.assert_equal(reset.bank.slots, {})
        test.assert_nil(reset.roster.guild)
        test.assert_nil(reset.bank.guild)
        test.assert_equal(reset.ui.windowPosition, model.ui.windowPosition)

        reset.ui.windowPosition.x = 700
        test.assert_equal(model.ui.windowPosition.x, 120)
    end),

    test.case("recovery reset keeps only a valid window position from corrupt data", function()
        local model = fixtures.saved_model()
        model.roster.members[1].level = "eighty"
        model.ui.futureSetting = "discard me"

        local reset = savedData.resetObservations(model)

        test.assert_true(savedData.validate(reset))
        test.assert_equal(reset.ui.windowPosition, fixtures.window_position())
        test.assert_nil(reset.ui.futureSetting)
        test.assert_equal(reset.roster.ranks, {})
        test.assert_equal(reset.roster.members, {})
        test.assert_equal(reset.bank.tabs, {})
        test.assert_equal(reset.bank.slots, {})
        test.assert_nil(reset.roster.guild)
        test.assert_nil(reset.roster.scannedAt)
        test.assert_nil(reset.bank.guild)
        test.assert_nil(reset.bank.scannedAt)
    end),

    test.case("recovery reset handles invalid positions and version-zero positions", function()
        local invalid = fixtures.saved_model()
        invalid.ui.windowPosition.x = "far away"
        local invalidReset = savedData.resetObservations(invalid)
        test.assert_true(savedData.validate(invalidReset))
        test.assert_nil(invalidReset.ui.windowPosition)

        local previous = fixtures.saved_model_v0()
        previous.roster.members[1].level = "eighty"
        local previousReset = savedData.resetObservations(previous)
        test.assert_equal(previousReset.ui.windowPosition, previous.windowPosition)
        test.assert_true(savedData.validate(previousReset))
    end),

    test.case("single-dataset replacement preserves the other dataset and UI", function()
        local model = fixtures.saved_model()
        local reset = savedData.resetDatasetObservations(model, "roster")

        test.assert_equal(reset.roster, {
            ranks = {},
            members = {},
        })
        test.assert_equal(reset.bank, model.bank)
        test.assert_equal(reset.ui.windowPosition, model.ui.windowPosition)

        reset.bank.slots[1].quantity = 1
        reset.ui.windowPosition.x = 700
        test.assert_equal(model.bank.slots[1].quantity, 20)
        test.assert_equal(model.ui.windowPosition.x, 120)
    end),

    test.case("snapshot history and unknown fields fail validation", function()
        local model = fixtures.saved_model()
        model.roster.dailySnapshots = {}
        local state = savedData.load(model)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "unexpected field dailySnapshots")
    end),

    test.case("bank money is optional but must be non-negative whole copper", function()
        local model = fixtures.saved_model()
        test.assert_true(savedData.validate(model))

        model.bank.money = 1233452412
        test.assert_true(savedData.validate(model))

        for _, money in ipairs({ -1, 1.5, "100" }) do
            model.bank.money = money
            local valid, message = savedData.validate(model)
            test.assert_nil(valid)
            test.assert_matches(message, "money")
        end

        local empty = savedData.newModel()
        empty.bank.money = 0
        local valid, message = savedData.validate(empty)
        test.assert_nil(valid)
        test.assert_matches(message, "observations require guild identity")
    end),
}
