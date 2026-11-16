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

    test.case("timer creation and scan release use the injected runtime seams", function()
        local previousCreateFrame = CreateFrame
        local previousTimer = C_Timer
        local timerDelay
        local timerCallback
        local timerHandle = { cancelled = false }
        local released = true
        local releasedOwner
        local scanLockStates = {}
        local releaseNotifications = 0

        CreateFrame = function()
            return {
                RegisterEvent = function() end,
                SetScript = function() end,
            }
        end
        C_Timer = {
            NewTimer = function(delay, callback)
                timerDelay = delay
                timerCallback = callback
                return timerHandle
            end,
        }

        local fakeRGMS = {
            Portal = {
                create = function()
                    return {
                        finishScan = function(_, owner)
                            releasedOwner = owner
                            return released
                        end,
                    }
                end,
            },
            UI = {
                SetGlobalScanLock = function(locked)
                    scanLockStates[#scanLockStates + 1] = locked
                end,
            },
            Roster = {
                OnGlobalScanLockReleased = function()
                    releaseNotifications = releaseNotifications + 1
                end,
            },
        }
        assert(loadfile("Core/Bootstrap.lua"))("RGMS", fakeRGMS)

        local callback = function() end
        local created = fakeRGMS.NewTimer(0.5, callback)
        test.assert_true(created == timerHandle)
        test.assert_equal(timerDelay, 0.5)
        test.assert_true(timerCallback == callback)

        test.assert_true(fakeRGMS.EndScan("bank"))
        test.assert_equal(releasedOwner, "bank")
        test.assert_equal(scanLockStates, { false })
        test.assert_equal(releaseNotifications, 1)

        released = false
        test.assert_false(fakeRGMS.EndScan("roster"))
        test.assert_equal(releasedOwner, "roster")
        test.assert_equal(scanLockStates, { false })
        test.assert_equal(releaseNotifications, 1)

        C_Timer = nil
        local missing, missingError = fakeRGMS.NewTimer(1, callback)
        test.assert_nil(missing)
        test.assert_equal(missingError, "timer service is unavailable")

        CreateFrame = previousCreateFrame
        C_Timer = previousTimer
    end),

    test.case("addon loading primes pending identity before the first roster refresh", function()
        local previousChatFrame = DEFAULT_CHAT_FRAME
        local previousCreateFrame = CreateFrame
        local previousCharacter = RGMSCharacterDB
        local previousAccount = RGMSAccountDB
        local eventCallback
        local pendingReason
        local steps = {}
        local frame = {
            RegisterEvent = function() end,
            SetScript = function(_, scriptName, callback)
                test.assert_equal(scriptName, "OnEvent")
                eventCallback = callback
            end,
            UnregisterEvent = function() end,
        }

        DEFAULT_CHAT_FRAME = { AddMessage = function() end }
        CreateFrame = function() return frame end
        RGMSCharacterDB = {}
        RGMSAccountDB = {}

        local characterModel = { ui = {} }
        local accountModel = { guilds = {} }
        local fakeRGMS = {
            SavedData = {
                CURRENT_SCHEMA_VERSION = 1,
                load = function()
                    return { enabled = true, model = characterModel }
                end,
            },
            AccountData = {
                load = function()
                    return { enabled = true, model = accountModel }
                end,
            },
            UI = {
                Initialize = function()
                    steps[#steps + 1] = "initialize"
                    return true
                end,
                SetDataState = function() end,
            },
            Roster = {
                PrimeGuildIdentityPending = function(reason)
                    pendingReason = reason
                    steps[#steps + 1] = "prime:" .. tostring(reason)
                end,
                RefreshStatus = function()
                    steps[#steps + 1] = "refresh:" .. tostring(pendingReason)
                end,
            },
        }
        assert(loadfile("Core/Bootstrap.lua"))("RGMS", fakeRGMS)
        fakeRGMS.ActivateCurrentGuild = function()
            return nil, false, "guild data is unavailable", "guild-identity-pending"
        end

        eventCallback(frame, "ADDON_LOADED", "RGMS")
        test.assert_equal(steps, {
            "prime:guild-identity-pending",
            "initialize",
            "refresh:guild-identity-pending",
        })

        DEFAULT_CHAT_FRAME = previousChatFrame
        CreateFrame = previousCreateFrame
        RGMSCharacterDB = previousCharacter
        RGMSAccountDB = previousAccount
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

    test.case("guild resolution distinguishes pending live inputs from hard errors", function()
        local previousCreateFrame = CreateFrame
        local previousIsInGuild = IsInGuild
        local previousGetGuildInfo = GetGuildInfo
        local previousGetNormalizedRealmName = GetNormalizedRealmName
        local previousGetRealmName = GetRealmName
        local previousGetCurrentRegion = GetCurrentRegion
        local previousClub = C_Club
        local flavor = clientFlavor.FOREVER
        local guildName = "Night Shift"

        CreateFrame = function()
            return {
                RegisterEvent = function() end,
                SetScript = function() end,
            }
        end
        IsInGuild = function() return true end
        GetGuildInfo = function() return guildName end
        GetCurrentRegion = function() return 0 end
        C_Club = { GetGuildClubId = function() return nil end }

        local fakeRGMS = {
            ClientFlavor = {
                RETAIL = clientFlavor.RETAIL,
                FOREVER = clientFlavor.FOREVER,
                getFlavor = function() return flavor end,
            },
            GuildIdentity = guildIdentity,
        }
        assert(loadfile("Core/Bootstrap.lua"))("RGMS", fakeRGMS)

        local identity, identityError, identityReason =
            fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_nil(identity)
        test.assert_equal(identityError, "guild region is unavailable")
        test.assert_equal(identityReason, "guild-identity-pending")

        GetCurrentRegion = function() return 6 end
        identity, identityError, identityReason =
            fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_nil(identity)
        test.assert_equal(identityError, "guild region is unsupported")
        test.assert_nil(identityReason)

        GetCurrentRegion = function() return 1 end
        identity, identityError, identityReason =
            fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_nil(identity)
        test.assert_equal(identityError, "Forever guild club ID is unavailable")
        test.assert_equal(identityReason, "guild-identity-pending")

        C_Club.GetGuildClubId = function() return -1 end
        identity, identityError, identityReason =
            fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_nil(identity)
        test.assert_equal(identityError, "Forever guild club ID is unavailable")
        test.assert_nil(identityReason)

        C_Club = {}
        identity, identityError, identityReason =
            fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_nil(identity)
        test.assert_equal(
            identityError,
            "Forever guild club ID service is unavailable"
        )
        test.assert_nil(identityReason)

        C_Club = { GetGuildClubId = function() return 123456 end }
        guildName = nil
        identity, identityError, identityReason =
            fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_nil(identity)
        test.assert_equal(identityError, "guild name is unavailable")
        test.assert_equal(identityReason, "guild-identity-pending")

        guildName = "Night Shift"
        flavor = clientFlavor.RETAIL
        GetNormalizedRealmName = function() return nil end
        GetRealmName = function() return nil end
        identity, identityError, identityReason =
            fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_nil(identity)
        test.assert_equal(
            identityError,
            "Retail guild realm requires a name and slug"
        )
        test.assert_equal(identityReason, "guild-identity-pending")

        flavor = clientFlavor.UNSUPPORTED
        identity, identityError, identityReason =
            fakeRGMS.ResolveCurrentGuildIdentity()
        test.assert_nil(identity)
        test.assert_equal(identityError, "guild flavor is unavailable")
        test.assert_nil(identityReason)

        CreateFrame = previousCreateFrame
        IsInGuild = previousIsInGuild
        GetGuildInfo = previousGetGuildInfo
        GetNormalizedRealmName = previousGetNormalizedRealmName
        GetRealmName = previousGetRealmName
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
            return nil, "guild region is unavailable", "guild-identity-pending"
        end

        local identity, initialized, activationError, activationReason =
            fakeRGMS.ActivateCurrentGuild()
        test.assert_nil(identity)
        test.assert_false(initialized)
        test.assert_equal(activationError, "guild region is unavailable")
        test.assert_equal(activationReason, "guild-identity-pending")
        test.assert_nil(fakeRGMS.ActiveGuildIdentity)
        test.assert_equal(fakeRGMS.DB.roster.members, {})
        test.assert_equal(fakeRGMS.DB.bank.slots, {})
        test.assert_true(fakeRGMS.AccountDataState.model == account)
        test.assert_equal(account.guilds, {})

        CreateFrame = previousCreateFrame
    end),
}
