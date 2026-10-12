local fixtures = require("Tests.fixtures")
local savedData = require("Core.SavedData")
local test = require("Tests.lib.runner")

return {
    test.case("fresh load creates a valid empty model", function()
        local state = savedData.load(nil)

        test.assert_true(state.enabled)
        test.assert_true(state.initialized)
        test.assert_equal(state.status, "ready")
        test.assert_equal(state.model, {
            schemaVersion = 5,
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
        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.model, original)

        state.model.roster.members[1].name = "Changed After Load"
        state.model.ui.windowPosition.x = 999
        test.assert_equal(original.roster.members[1].name, "Aeloria")
        test.assert_equal(original.ui.windowPosition.x, 120)
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
        test.assert_equal(first.model.schemaVersion, 5)
        test.assert_equal(first.model.roster.guild, original.roster.guildIdentity)
        test.assert_equal(first.model.roster.scannedAt, original.roster.scanTimestamp)
        test.assert_equal(first.model.bank.guild, original.bank.guildIdentity)
        test.assert_equal(first.model.ui.windowPosition, original.windowPosition)
        test.assert_equal(original.schemaVersion, 0)
        test.assert_nil(original.roster.guild)
    end),

    test.case("schema version one backfills roster identity and rank names", function()
        local original = fixtures.saved_model_v1()
        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 1)
        test.assert_equal(state.model.schemaVersion, 5)
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
        test.assert_equal(state.model.schemaVersion, 5)
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
        test.assert_equal(state.model.schemaVersion, 5)
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
            fixtures.roster_member({
                name = "Nalla",
                realm = "Ner'zhul",
                displayName = "Nalla-Ner'zhul",
                isMissing = true,
            }),
            fixtures.roster_member({
                name = "Nalla",
                realm = corruptedRealm,
                displayName = "Nalla-" .. corruptedRealm,
                isMissing = false,
            }),
        }

        local state = savedData.load(original)

        test.assert_true(state.enabled)
        test.assert_equal(state.migratedFrom, 4)
        test.assert_equal(state.model.schemaVersion, 5)
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
}
