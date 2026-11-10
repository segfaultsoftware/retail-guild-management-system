local clientFlavor = require("Core.ClientFlavor")
local dateTime = require("Core.DateTime")
local guildIdentity = require("Core.GuildIdentity")
local savedData = require("Core.SavedData")
local bankState = require("Bank.State")
local test = require("Tests.lib.runner")

local GLOBAL_NAMES = {
    "C_Club",
    "C_TradeSkillUI",
    "CreateFrame",
    "Enum",
    "GetCurrentRegion",
    "GetGuildBankItemInfo",
    "GetGuildBankItemLink",
    "GetGuildBankMoney",
    "GetGuildBankTabInfo",
    "GetGuildInfo",
    "GetNormalizedRealmName",
    "GetNumGuildBankTabs",
    "GetRealmName",
    "GetServerTime",
    "GUILDBANK_TAB_NUMBER",
    "GuildBankFrame",
    "QueryGuildBankTab",
}

local function expectedGuild(flavor)
    if flavor == clientFlavor.FOREVER then
        return assert(guildIdentity.create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Example Guild",
            clubId = 42,
        }))
    end
    return assert(guildIdentity.create({
        flavor = clientFlavor.RETAIL,
        region = "US",
        name = "Example Guild",
        realm = {
            name = "Example Realm",
            slug = "ExampleRealm",
        },
    }))
end

local function withModernStubs(options, callback)
    options = options or {}
    local previous = {}
    for _, name in ipairs(GLOBAL_NAMES) do
        previous[name] = _G[name]
    end

    local flavor = options.flavor or clientFlavor.RETAIL
    local requested = {}
    local messages = {}
    local itemLink = "|Hitem:191384::::::::80:::::|h[Refreshing Healing Potion]|h"
    local eventFrame = { events = {}, scripts = {} }
    local guildIdentityResolutions = 0
    local qualityApiCalls = 0
    local realmApiCalls = 0
    local slotInfoCalls = 0
    local slotLinkCalls = 0
    function eventFrame:RegisterEvent(event)
        self.events[event] = true
    end
    function eventFrame:SetScript(scriptName, handler)
        self.scripts[scriptName] = handler
    end

    C_Club = {
        GetGuildClubId = function()
            return 42
        end,
        GetClubInfo = function()
            return { name = "Example Guild" }
        end,
    }
    C_TradeSkillUI = {
        GetItemReagentQualityByItemInfo = function(itemInfo)
            qualityApiCalls = qualityApiCalls + 1
            if itemInfo == 191384 then
                return 2
            end
        end,
    }
    CreateFrame = function()
        return eventFrame
    end
    Enum = {
        PlayerInteractionType = {
            GuildBanker = 10,
        },
    }
    GuildBankFrame = {
        IsShown = function()
            return true
        end,
    }
    GetGuildInfo = function()
        realmApiCalls = realmApiCalls + 1
        if flavor == clientFlavor.FOREVER then
            error("Forever bank capture must obtain guild identity from the resolver")
        end
        return "Example Guild", nil, nil, "ExampleRealm"
    end
    GetNormalizedRealmName = function()
        realmApiCalls = realmApiCalls + 1
        if flavor == clientFlavor.FOREVER then
            error("Forever bank capture must not read a normalized realm")
        end
        return "ExampleRealm"
    end
    GetRealmName = function()
        realmApiCalls = realmApiCalls + 1
        if flavor == clientFlavor.FOREVER then
            error("Forever bank capture must not read a display realm")
        end
        return "Example Realm"
    end
    GetCurrentRegion = function()
        return 1
    end
    GetServerTime = function()
        return 1717245296
    end
    GetNumGuildBankTabs = function()
        return 2
    end
    GUILDBANK_TAB_NUMBER = "Bank Tab %d"
    GetGuildBankTabInfo = function(index)
        if index == 1 then
            return "", "Interface\\Icons\\INV_Misc_QuestionMark", true, true, -1
        end
        return "Restricted", 134400, nil, nil, 0
    end
    GetGuildBankItemInfo = function(tabIndex, slotIndex)
        slotInfoCalls = slotInfoCalls + 1
        if tabIndex == 1 and slotIndex == 5 then
            return 236873, 20, nil, false, 1
        end
        return nil, nil, nil, false, nil
    end
    GetGuildBankItemLink = function(tabIndex, slotIndex)
        slotLinkCalls = slotLinkCalls + 1
        if tabIndex == 1 and slotIndex == 5 then
            return itemLink
        end
        return nil
    end
    GetGuildBankMoney = function()
        return 1233452412
    end
    QueryGuildBankTab = function(tabIndex)
        requested[#requested + 1] = tabIndex
    end

    local resolvedGuild = options.guildIdentity or expectedGuild(flavor)
    local rgms = {
        ClientFlavor = {
            RETAIL = clientFlavor.RETAIL,
            FOREVER = clientFlavor.FOREVER,
            getFlavor = function()
                return flavor
            end,
            supportsCraftingQuality = function()
                return flavor == clientFlavor.RETAIL
            end,
        },
        DateTime = dateTime,
        GuildIdentity = guildIdentity,
        ProvisionModel = require("Provisions.Model"),
        Reset = {},
        ResolveCurrentGuildIdentity = function()
            guildIdentityResolutions = guildIdentityResolutions + 1
            return resolvedGuild
        end,
        UI = {
            IsShown = function()
                return false
            end,
        },
        Print = function(message)
            messages[#messages + 1] = message
        end,
    }
    local chunk = assert(loadfile("Bank/Bank.lua"))
    local bank = chunk("RGMS", rgms)
    local createApi = bank.CreateModernApi or bank.CreateRetailApi

    local succeeded, callbackError = pcall(callback, {
        api = createApi(),
        bank = bank,
        rgms = rgms,
        messages = messages,
        requested = requested,
        guildIdentityResolutions = function()
            return guildIdentityResolutions
        end,
        qualityApiCalls = function()
            return qualityApiCalls
        end,
        realmApiCalls = function()
            return realmApiCalls
        end,
        slotInfoCalls = function()
            return slotInfoCalls
        end,
        slotLinkCalls = function()
            return slotLinkCalls
        end,
        setItemLink = function(value)
            itemLink = value
        end,
    })

    for _, name in ipairs(GLOBAL_NAMES) do
        _G[name] = previous[name]
    end
    if not succeeded then
        error(callbackError, 0)
    end
end

local function withRetailStubs(callback)
    return withModernStubs({ flavor = clientFlavor.RETAIL }, callback)
end

return {
    test.case("shared adapter captures Retail and Forever tab catalogs in order", function()
        for _, flavor in ipairs({ clientFlavor.RETAIL, clientFlavor.FOREVER }) do
            withModernStubs({ flavor = flavor }, function(harness)
                local catalog = assert(harness.api:captureCatalog())

                test.assert_true(guildIdentity.validate(catalog.guild))
                test.assert_equal(catalog.guild, expectedGuild(flavor))
                test.assert_equal(harness.guildIdentityResolutions(), 1)
                test.assert_equal(harness.realmApiCalls(), 0)
                if flavor == clientFlavor.FOREVER then
                    test.assert_nil(catalog.guild.realm)
                    test.assert_equal(catalog.guild.clubId, "42")
                else
                    test.assert_equal(catalog.guild.realm.slug, "ExampleRealm")
                    test.assert_nil(catalog.guild.clubId)
                end
                test.assert_equal(#catalog.tabs, 2)
                test.assert_equal(catalog.tabs[1].index, 1)
                test.assert_equal(catalog.tabs[1].name, "Bank Tab 1")
                test.assert_equal(
                    catalog.tabs[1].icon,
                    "Interface\\Icons\\INV_Misc_QuestionMark"
                )
                test.assert_true(catalog.tabs[1].isViewable)
                test.assert_false(catalog.tabs[2].isViewable)
                test.assert_equal(harness.api:captureMoney(), 1233452412)

                harness.api:requestTab(1)
                test.assert_equal(harness.requested, { 1 })
            end)
        end
    end),

    test.case("Retail adapter preserves semantic crafting-quality capture", function()
        withRetailStubs(function(harness)
            local catalog = assert(harness.api:captureCatalog())
            local slots = assert(harness.api:captureTab(1))
            local scannedAt = assert(harness.api:captureTimestamp())
            slots[1].observedAt = scannedAt

            test.assert_equal(#slots, 1)
            test.assert_equal(slots[1].tabIndex, 1)
            test.assert_equal(slots[1].slotIndex, 5)
            test.assert_equal(slots[1].itemId, 191384)
            test.assert_equal(slots[1].icon, 236873)
            test.assert_equal(slots[1].quantity, 20)
            test.assert_false(slots[1].isLocked)
            test.assert_equal(slots[1].craftingQuality, 2)
            test.assert_matches(slots[1].itemLink, "Refreshing Healing Potion")
            test.assert_equal(harness.slotInfoCalls(), 98)
            test.assert_equal(harness.slotLinkCalls(), 98)
            test.assert_equal(harness.qualityApiCalls(), 1)

            local model = savedData.newModel()
            model.bank = assert(bankState.reduce(model.bank, {
                guild = catalog.guild,
                scannedAt = scannedAt,
                money = assert(harness.api:captureMoney()),
                tabs = catalog.tabs,
                slots = slots,
            }, dateTime))
            test.assert_true(savedData.validate(model))
        end)
    end),

    test.case("Forever adapter omits crafting quality despite an available API", function()
        withModernStubs({ flavor = clientFlavor.FOREVER }, function(harness)
            local catalog = assert(harness.api:captureCatalog())
            local slots = assert(harness.api:captureTab(1))
            local scannedAt = assert(harness.api:captureTimestamp())
            slots[1].observedAt = scannedAt

            test.assert_equal(#slots, 1)
            test.assert_equal(slots[1].tabIndex, 1)
            test.assert_equal(slots[1].slotIndex, 5)
            test.assert_equal(slots[1].itemId, 191384)
            test.assert_equal(slots[1].icon, 236873)
            test.assert_equal(slots[1].quantity, 20)
            test.assert_false(slots[1].isLocked)
            test.assert_nil(slots[1].craftingQuality)
            test.assert_matches(slots[1].itemLink, "Refreshing Healing Potion")
            test.assert_equal(harness.slotInfoCalls(), 98)
            test.assert_equal(harness.slotLinkCalls(), 98)
            test.assert_equal(harness.qualityApiCalls(), 0)
            test.assert_equal(harness.realmApiCalls(), 0)

            local model = savedData.newModel()
            model.bank = assert(bankState.reduce(model.bank, {
                guild = catalog.guild,
                scannedAt = scannedAt,
                money = assert(harness.api:captureMoney()),
                tabs = catalog.tabs,
                slots = slots,
            }, dateTime))
            test.assert_true(savedData.validate(model))
        end)
    end),

    test.case("shared adapter rejects an occupied slot until its link arrives", function()
        for _, flavor in ipairs({ clientFlavor.RETAIL, clientFlavor.FOREVER }) do
            withModernStubs({ flavor = flavor }, function(harness)
                harness.setItemLink(nil)

                local slots, state, message = harness.api:captureTab(1)

                test.assert_nil(slots)
                test.assert_equal(state, "incomplete")
                test.assert_matches(message, "partial")
                test.assert_equal(harness.qualityApiCalls(), 0)
            end)
        end
    end),

    test.case("bank tab dump prints the stored tab and raw quality-bearing slots", function()
        withRetailStubs(function(harness)
            harness.rgms.DB = {
                bank = {
                    tabs = {
                        {
                            index = 1,
                            name = "Consumables",
                            icon = 134400,
                            isViewable = true,
                            canDeposit = true,
                            withdrawalsPerDay = -1,
                            lastAccessibleAt = { iso8601 = "2024-06-01T12:34:56Z" },
                        },
                    },
                    slots = {
                        {
                            tabIndex = 1,
                            slotIndex = 5,
                            itemId = 191384,
                            itemLink = "|Hitem:191384|h[Refreshing Healing Potion |A:Professions-Icon-Quality-12-Tier2:20:20|a]|h",
                            quantity = 20,
                            craftingQuality = 2,
                            isLocked = false,
                            observedAt = { iso8601 = "2024-06-01T12:34:56Z" },
                            stableSinceDate = "2024-06-01",
                        },
                    },
                },
            }

            local dumped, count = harness.bank.DumpTab(1)

            test.assert_true(dumped)
            test.assert_equal(count, 1)
            test.assert_matches(harness.messages[1], "tab 1")
            test.assert_matches(harness.messages[2], 'name="Consumables"')
            test.assert_matches(harness.messages[3], "rawName=.*Quality%-12%-Tier2")
            test.assert_matches(harness.messages[3], 'matchName="Refreshing Healing Potion"')
            test.assert_matches(harness.messages[3], "craftingQuality=2")
            test.assert_equal(harness.messages[4], "Stored slot records: 1")
        end)
    end),
}
