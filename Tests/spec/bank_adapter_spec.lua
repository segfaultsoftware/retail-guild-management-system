local dateTime = require("Core.DateTime")
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

local function withRetailStubs(callback)
    local previous = {}
    for _, name in ipairs(GLOBAL_NAMES) do
        previous[name] = _G[name]
    end

    local requested = {}
    local messages = {}
    local itemLink = "|Hitem:191384::::::::80:::::|h[Refreshing Healing Potion]|h"
    local eventFrame = { events = {}, scripts = {} }
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
        return "Example Guild", nil, nil, "ExampleRealm"
    end
    GetNormalizedRealmName = function()
        return "ExampleRealm"
    end
    GetRealmName = function()
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
        if tabIndex == 1 and slotIndex == 5 then
            return 236873, 20, nil, false, 1
        end
        return nil, nil, nil, false, nil
    end
    GetGuildBankItemLink = function(tabIndex, slotIndex)
        if tabIndex == 1 and slotIndex == 5 then
            return itemLink
        end
        return nil
    end
    QueryGuildBankTab = function(tabIndex)
        requested[#requested + 1] = tabIndex
    end

    local rgms = {
        DateTime = dateTime,
        ProvisionModel = require("Provisions.Model"),
        Realm = require("Core.Realm"),
        Reset = {},
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

    local succeeded, callbackError = pcall(callback, {
        api = bank.CreateRetailApi(),
        bank = bank,
        rgms = rgms,
        messages = messages,
        requested = requested,
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

return {
    test.case("Retail adapter discovers and classifies purchased tabs in order", function()
        withRetailStubs(function(harness)
            local catalog = assert(harness.api:captureCatalog())

            test.assert_equal(catalog.guild.name, "Example Guild")
            test.assert_equal(catalog.guild.realm.slug, "ExampleRealm")
            test.assert_equal(#catalog.tabs, 2)
            test.assert_equal(catalog.tabs[1].index, 1)
            test.assert_equal(catalog.tabs[1].name, "Bank Tab 1")
            test.assert_equal(
                catalog.tabs[1].icon,
                "Interface\\Icons\\INV_Misc_QuestionMark"
            )
            test.assert_true(catalog.tabs[1].isViewable)
            test.assert_false(catalog.tabs[2].isViewable)

            harness.api:requestTab(1)
            test.assert_equal(harness.requested, { 1 })
        end)
    end),

    test.case("Retail adapter captures occupied slot display data and basic item ID", function()
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

            local model = savedData.newModel()
            model.bank = assert(bankState.reduce(model.bank, {
                guild = catalog.guild,
                scannedAt = scannedAt,
                tabs = catalog.tabs,
                slots = slots,
            }, dateTime))
            test.assert_true(savedData.validate(model))
        end)
    end),

    test.case("Retail adapter rejects an occupied slot until its item link arrives", function()
        withRetailStubs(function(harness)
            harness.setItemLink(nil)

            local slots, state, message = harness.api:captureTab(1)

            test.assert_nil(slots)
            test.assert_equal(state, "incomplete")
            test.assert_matches(message, "partial")
        end)
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
