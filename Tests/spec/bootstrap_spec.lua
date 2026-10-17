local accountData = require("Core.AccountData")
local fixtures = require("Tests.fixtures")
local realm = require("Core.Realm")
local rosterMigration = require("Core.RosterMigration")
local savedData = require("Core.SavedData")
local test = require("Tests.lib.runner")

return {
    test.case("debug logging is session-only, opt-in, and uses its own prefix", function()
        local previousChatFrame = DEFAULT_CHAT_FRAME
        local previousCreateFrame = CreateFrame
        local messages = {}

        DEFAULT_CHAT_FRAME = {
            AddMessage = function(_, message)
                messages[#messages + 1] = message
            end,
        }
        CreateFrame = function()
            return {
                RegisterEvent = function()
                end,
                SetScript = function()
                end,
            }
        end

        local fakeRGMS = {}
        local chunk = assert(loadfile("Core/Bootstrap.lua"))
        chunk("RGMS", fakeRGMS)

        test.assert_false(fakeRGMS.DebugEnabled)
        test.assert_false(fakeRGMS.Debug("hidden"))
        test.assert_equal(messages, {})

        test.assert_true(fakeRGMS.ToggleDebug())
        test.assert_true(fakeRGMS.Debug("tab 1=0"))
        test.assert_equal(messages, {
            "|cff33ff99RGMS|r [debug]: tab 1=0",
        })

        test.assert_false(fakeRGMS.ToggleDebug())
        test.assert_false(fakeRGMS.Debug("hidden again"))
        test.assert_equal(#messages, 1)

        DEFAULT_CHAT_FRAME = previousChatFrame
        CreateFrame = previousCreateFrame
    end),

    test.case("guild activation initializes roster migration before display", function()
        local previousCreateFrame = CreateFrame
        local previousAccount = RGMSAccountDB
        CreateFrame = function()
            return {
                RegisterEvent = function() end,
                SetScript = function() end,
            }
        end

        local character = fixtures.saved_model()
        character.ui.windowPosition.x = 456
        local identity = character.roster.guild
        local fakeRGMS = {
            AccountData = accountData,
            Realm = realm,
            RosterMigration = rosterMigration,
            SavedData = savedData,
            AccountDataState = {
                enabled = true,
                model = accountData.newModel(),
            },
            SavedDataState = {
                enabled = true,
                model = character,
            },
        }
        RGMSAccountDB = fakeRGMS.AccountDataState.model
        local chunk = assert(loadfile("Core/Bootstrap.lua"))
        chunk("RGMS", fakeRGMS)
        fakeRGMS.ResolveCurrentGuildIdentity = function()
            return identity
        end

        local activated, rosterInitialized = fakeRGMS.ActivateCurrentGuild()
        test.assert_equal(activated, identity)
        test.assert_true(rosterInitialized)
        local partition = accountData.findGuild(RGMSAccountDB, identity)
        test.assert_true(partition.rosterInitialized)
        test.assert_false(partition.bankInitialized)
        test.assert_equal(partition.roster.members[1].name, "Aeloria")
        test.assert_equal(fakeRGMS.DB.roster.members[1].name, "Aeloria")
        test.assert_equal(fakeRGMS.DB.ui.windowPosition.x, 456)
        test.assert_equal(character.roster.members[1].name, "Aeloria")

        CreateFrame = previousCreateFrame
        RGMSAccountDB = previousAccount
    end),
}
