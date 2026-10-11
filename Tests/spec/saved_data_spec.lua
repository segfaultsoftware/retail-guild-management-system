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
            schemaVersion = 1,
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
        test.assert_equal(first.model.schemaVersion, 1)
        test.assert_equal(first.model.roster.guild, original.roster.guildIdentity)
        test.assert_equal(first.model.roster.scannedAt, original.roster.scanTimestamp)
        test.assert_equal(first.model.bank.guild, original.bank.guildIdentity)
        test.assert_equal(first.model.ui.windowPosition, original.windowPosition)
        test.assert_equal(original.schemaVersion, 0)
        test.assert_nil(original.roster.guild)
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

    test.case("inconsistent scan timestamps fail validation", function()
        local original = fixtures.saved_model()
        original.bank.scannedAt.iso8601 = "2024-06-01T12:34:57Z"
        local state = savedData.load(original)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "must represent the same time")
        test.assert_equal(original.bank.scannedAt.iso8601, "2024-06-01T12:34:57Z")
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

    test.case("snapshot history and unknown fields fail validation", function()
        local model = fixtures.saved_model()
        model.roster.dailySnapshots = {}
        local state = savedData.load(model)

        test.assert_false(state.enabled)
        test.assert_equal(state.status, "corrupt")
        test.assert_matches(state.error, "unexpected field dailySnapshots")
    end),
}
