local accountData = require("Core.AccountData")
local clientFlavor = require("Core.ClientFlavor")
local fixtures = require("Tests.fixtures")
local guildIdentity = require("Core.GuildIdentity")
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

    test.case("guild resolution builds isolated Retail and Forever identities", function()
        local previousCreateFrame = CreateFrame
        local previousIsInGuild = IsInGuild
        local previousGetGuildInfo = GetGuildInfo
        local previousGetNormalizedRealmName = GetNormalizedRealmName
        local previousGetRealmName = GetRealmName
        local previousGetCurrentRegion = GetCurrentRegion
        local previousClub = C_Club
        local flavor = clientFlavor.RETAIL

        CreateFrame = function()
            return {
                RegisterEvent = function() end,
                SetScript = function() end,
            }
        end
        IsInGuild = function() return true end
        GetGuildInfo = function(unit)
            test.assert_equal(unit, "player")
            return "Night Shift"
        end
        GetNormalizedRealmName = function() return "Area-52-Area-52-Ar" end
        GetRealmName = function() return "Area 52-Area 52-Ar" end
        GetCurrentRegion = function() return 1 end
        C_Club = {
            GetGuildClubId = function()
                error("Retail resolution must not read a guild club ID")
            end,
        }

        local fakeRGMS = {
            ClientFlavor = {
                RETAIL = clientFlavor.RETAIL,
                FOREVER = clientFlavor.FOREVER,
                getFlavor = function() return flavor end,
            },
            GuildIdentity = guildIdentity,
        }
        assert(loadfile("Core/Bootstrap.lua"))("RGMS", fakeRGMS)

        local retail, retailError = fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_not_nil(retail, retailError)
        test.assert_true(guildIdentity.validate(retail))
        test.assert_equal(retail.flavor, clientFlavor.RETAIL)
        test.assert_equal(retail.key, "11:Night Shift:area-52")
        test.assert_equal(retail.realm, {
            name = "Area 52",
            slug = "Area-52",
        })

        flavor = clientFlavor.FOREVER
        GetNormalizedRealmName = function()
            error("Forever resolution must not read a normalized realm")
        end
        GetRealmName = function()
            error("Forever resolution must not read a display realm")
        end
        C_Club.GetGuildClubId = function() return 123456 end

        local forever, foreverError = fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_not_nil(forever, foreverError)
        test.assert_true(guildIdentity.validate(forever))
        test.assert_equal(forever.flavor, clientFlavor.FOREVER)
        test.assert_equal(
            forever.key,
            "RGMS:GUILD:FOREVER:1:2:US:6:123456"
        )
        test.assert_nil(forever.realm)
        test.assert_false(retail.key == forever.key)

        CreateFrame = previousCreateFrame
        IsInGuild = previousIsInGuild
        GetGuildInfo = previousGetGuildInfo
        GetNormalizedRealmName = previousGetNormalizedRealmName
        GetRealmName = previousGetRealmName
        GetCurrentRegion = previousGetCurrentRegion
        C_Club = previousClub
    end),

    test.case("guild resolution fails closed for malformed product inputs", function()
        local previousCreateFrame = CreateFrame
        local previousIsInGuild = IsInGuild
        local previousGetGuildInfo = GetGuildInfo
        local previousGetCurrentRegion = GetCurrentRegion
        local previousClub = C_Club

        CreateFrame = function()
            return {
                RegisterEvent = function() end,
                SetScript = function() end,
            }
        end
        IsInGuild = function() return true end
        GetGuildInfo = function() return "Night Shift" end
        GetCurrentRegion = function() return 0 end
        C_Club = { GetGuildClubId = function() return nil end }

        local fakeRGMS = {
            ClientFlavor = {
                RETAIL = clientFlavor.RETAIL,
                FOREVER = clientFlavor.FOREVER,
                getFlavor = function() return clientFlavor.FOREVER end,
            },
            GuildIdentity = guildIdentity,
        }
        assert(loadfile("Core/Bootstrap.lua"))("RGMS", fakeRGMS)

        local identity, identityError = fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_nil(identity)
        test.assert_equal(identityError, "guild region is unavailable")

        GetCurrentRegion = function() return 1 end
        identity, identityError = fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_nil(identity)
        test.assert_equal(identityError, "Forever guild club ID is unavailable")

        CreateFrame = previousCreateFrame
        IsInGuild = previousIsInGuild
        GetGuildInfo = previousGetGuildInfo
        GetCurrentRegion = previousGetCurrentRegion
        C_Club = previousClub
    end),

    test.case("activation exposes no partition when identity resolution fails", function()
        local previousCreateFrame = CreateFrame
        CreateFrame = function()
            return {
                RegisterEvent = function() end,
                SetScript = function() end,
            }
        end

        local account = accountData.newModel()
        local character = savedData.newModel()
        local fakeRGMS = {
            AccountData = accountData,
            AccountDataState = { enabled = true, model = account },
            SavedDataState = { enabled = true, model = character },
        }
        assert(loadfile("Core/Bootstrap.lua"))("RGMS", fakeRGMS)
        fakeRGMS.ActiveGuildIdentity = fixtures.guild_identity()
        fakeRGMS.ResolveCurrentGuildIdentity = function()
            return nil, "guild region is unavailable"
        end

        local identity, initialized, activationError =
            fakeRGMS.ActivateCurrentGuild()
        test.assert_nil(identity)
        test.assert_false(initialized)
        test.assert_equal(activationError, "guild region is unavailable")
        test.assert_nil(fakeRGMS.ActiveGuildIdentity)
        test.assert_equal(fakeRGMS.DB.roster.members, {})
        test.assert_equal(fakeRGMS.DB.bank.slots, {})

        CreateFrame = previousCreateFrame
    end),
}
