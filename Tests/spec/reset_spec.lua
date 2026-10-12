local commands = require("Core.Commands")
local fixtures = require("Tests.fixtures")
local resetModule = require("Core.Reset")
local savedData = require("Core.SavedData")
local test = require("Tests.lib.runner")

local function newHarness(saved)
    local harness = {
        saved = saved,
        state = savedData.load(saved),
        messages = {},
    }
    if harness.state.enabled then
        harness.saved = harness.state.model
        harness.db = harness.state.model
    end

    harness.controller = resetModule.create({
        savedData = savedData,
        getSavedData = function()
            return harness.saved
        end,
        getState = function()
            return harness.state
        end,
        commit = function(model, state)
            harness.saved = model
            harness.db = model
            harness.state = state
        end,
        showConfirmation = function(request)
            harness.shownRequest = request
        end,
        print = function(message)
            harness.messages[#harness.messages + 1] = message
        end,
    })

    return harness
end

return {
    test.case("reset command opens confirmation without changing saved data", function()
        local harness = newHarness(fixtures.saved_model())
        local before = harness.saved
        local api = {
            Reset = harness.controller,
            Print = function(message)
                harness.messages[#harness.messages + 1] = message
            end,
        }

        commands.handle("  ReSeT  ", api)

        test.assert_not_nil(harness.shownRequest)
        test.assert_false(harness.shownRequest.recovery)
        test.assert_true(harness.saved == before)
        test.assert_equal(#harness.saved.roster.members, 1)
        test.assert_equal(#harness.saved.bank.slots, 1)
    end),

    test.case("confirm clears exact observation fields and preserves UI", function()
        local harness = newHarness(fixtures.saved_model())
        local originalPosition = harness.saved.ui.windowPosition
        local request = harness.controller:requestManual()

        local confirmed, resetError = harness.controller:confirm(request)

        test.assert_true(confirmed, resetError)
        test.assert_equal(harness.saved, {
            schemaVersion = 5,
            roster = {
                ranks = {},
                members = {},
            },
            bank = {
                tabs = {},
                slots = {},
            },
            ui = {
                windowPosition = fixtures.window_position(),
            },
        })
        test.assert_true(harness.saved == harness.db)
        test.assert_true(harness.state.enabled)
        test.assert_true(harness.saved.ui.windowPosition ~= originalPosition)
    end),

    test.case("cancel leaves every saved value and runtime state unchanged", function()
        local harness = newHarness(fixtures.saved_model())
        local originalSaved = harness.saved
        local originalState = harness.state
        local request = harness.controller:requestManual()

        harness.controller:cancel(request)

        test.assert_true(harness.saved == originalSaved)
        test.assert_true(harness.state == originalState)
        test.assert_equal(#harness.saved.roster.members, 1)
        test.assert_matches(harness.messages[#harness.messages], "no data was changed")
    end),

    test.case("accepting corrupt-data recovery creates a reloadable empty state", function()
        local corrupt = fixtures.saved_model()
        corrupt.roster.members[1].level = "eighty"
        local harness = newHarness(corrupt)
        local originalPosition = corrupt.ui.windowPosition

        test.assert_false(harness.state.enabled)
        test.assert_nil(harness.db)

        local request = harness.controller:requestRecovery(harness.state)
        test.assert_true(harness.saved == corrupt)
        test.assert_true(request.recovery)
        test.assert_true(harness.controller:confirm(request))

        test.assert_true(harness.state.enabled)
        test.assert_equal(harness.state.recoveredFrom, "corrupt")
        test.assert_equal(harness.saved.ui.windowPosition, originalPosition)
        test.assert_equal(harness.saved.roster.members, {})
        test.assert_equal(harness.saved.bank.slots, {})
        test.assert_true(savedData.load(harness.saved).enabled)
    end),

    test.case("declining recovery preserves data and blocks roster bank and reports", function()
        local corrupt = fixtures.saved_model()
        corrupt.bank.slots[1].quantity = "many"
        local harness = newHarness(corrupt)
        local originalState = harness.state
        local request = harness.controller:requestRecovery(harness.state)

        harness.controller:cancel(request)

        test.assert_true(harness.saved == corrupt)
        test.assert_true(harness.state == originalState)
        test.assert_false(harness.controller:canScan("the guild roster"))
        test.assert_false(harness.controller:canScan("the guild bank"))
        test.assert_false(harness.controller:canReport("the roster report"))
        test.assert_false(savedData.load(harness.saved).enabled)
        test.assert_matches(harness.messages[#harness.messages], "disabled until /rgms reset")
    end),

    test.case("unsupported-version recovery preserves a compatible window position", function()
        local future = {
            schemaVersion = 99,
            roster = { future = true },
            bank = { future = true },
            ui = {
                windowPosition = fixtures.window_position({ x = 333 }),
                futureSetting = true,
            },
        }
        local harness = newHarness(future)
        local request = harness.controller:requestRecovery(harness.state)

        test.assert_true(harness.controller:confirm(request))

        test.assert_equal(harness.state.recoveredFrom, "incompatible")
        test.assert_equal(harness.saved.ui.windowPosition.x, 333)
        test.assert_nil(harness.saved.ui.futureSetting)
        test.assert_true(savedData.load(harness.saved).enabled)
    end),

    test.case("reset remains scoped to its character store", function()
        local firstCharacter = newHarness(fixtures.saved_model())
        local secondCharacter = newHarness(fixtures.saved_model())
        secondCharacter.saved.roster.members[1].name = "Other Character Observation"

        local request = firstCharacter.controller:requestManual()
        test.assert_true(firstCharacter.controller:confirm(request))

        test.assert_equal(firstCharacter.saved.roster.members, {})
        test.assert_equal(
            secondCharacter.saved.roster.members[1].name,
            "Other Character Observation"
        )
    end),

    test.case("WoW popup callbacks route cancel and accept without errors", function()
        local previousDialogs = StaticPopupDialogs
        local previousAccept = ACCEPT
        local previousCancel = CANCEL
        local previousShow = StaticPopup_Show
        local previousSaved = RGMSCharacterDB

        StaticPopupDialogs = {}
        ACCEPT = "Accept"
        CANCEL = "Cancel"

        local shown
        StaticPopup_Show = function(key, message, _, request)
            shown = {
                key = key,
                message = message,
                request = request,
            }
            return {}
        end

        local loaded = savedData.load(fixtures.saved_model())
        RGMSCharacterDB = loaded.model
        local original = RGMSCharacterDB
        local fakeRGMS = {
            SavedData = savedData,
            SavedDataState = loaded,
            DB = loaded.model,
            Print = function() end,
        }

        local resetChunk = assert(loadfile("Core/Reset.lua"))
        resetChunk("RGMS", fakeRGMS)

        fakeRGMS.Reset:requestManual()
        test.assert_matches(shown.message, "Reset all RGMS roster")
        StaticPopupDialogs[shown.key].OnCancel(nil, shown.request)
        test.assert_true(RGMSCharacterDB == original)

        fakeRGMS.Reset:requestManual()
        StaticPopupDialogs[shown.key].OnAccept(nil, shown.request)
        test.assert_equal(RGMSCharacterDB.roster.members, {})
        test.assert_equal(RGMSCharacterDB.bank.slots, {})
        test.assert_true(fakeRGMS.SavedDataState.enabled)

        StaticPopupDialogs = previousDialogs
        ACCEPT = previousAccept
        CANCEL = previousCancel
        StaticPopup_Show = previousShow
        RGMSCharacterDB = previousSaved
    end),
}
