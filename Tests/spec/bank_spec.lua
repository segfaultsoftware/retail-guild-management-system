local test = require("Tests.lib.runner")

local function newHarness(options)
    options = options or {}
    local actions = {}
    local eventFrame = {
        events = {},
        scripts = {},
    }

    function eventFrame:RegisterEvent(event)
        self.events[event] = true
    end

    function eventFrame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    local guildBankFrame = {
        shown = options.guildBankShown ~= false,
    }
    function guildBankFrame:IsShown()
        return self.shown
    end

    local rgmsShown = options.rgmsShown == true
    local fakeRGMS = {
        Reset = {
            canScan = function()
                return true
            end,
            canReport = function()
                return true
            end,
        },
        UI = {
            Show = function(tabId)
                actions[#actions + 1] = { action = "show", tabId = tabId }
                rgmsShown = true
                return true
            end,
            IsShown = function()
                return rgmsShown
            end,
            AlignToRightOf = function(frame)
                actions[#actions + 1] = { action = "align", frame = frame }
                return true
            end,
        },
    }

    local previousCreateFrame = CreateFrame
    local previousGuildBankFrame = GuildBankFrame
    local previousEnum = Enum
    CreateFrame = function()
        return eventFrame
    end
    GuildBankFrame = guildBankFrame
    Enum = {
        PlayerInteractionType = {
            GuildBanker = 10,
        },
    }

    local chunk = assert(loadfile("Bank/Bank.lua"))
    chunk("RGMS", fakeRGMS)

    return {
        actions = actions,
        eventFrame = eventFrame,
        guildBankFrame = guildBankFrame,
        restore = function()
            CreateFrame = previousCreateFrame
            GuildBankFrame = previousGuildBankFrame
            Enum = previousEnum
        end,
    }
end

return {
    test.case("opening the default guild bank opens RGMS on the Bank view", function()
        local harness = newHarness()

        test.assert_true(
            harness.eventFrame.events.PLAYER_INTERACTION_MANAGER_FRAME_SHOW
        )
        test.assert_false(harness.eventFrame.events.GUILDBANKFRAME_CLOSED == true)
        harness.eventFrame.scripts.OnEvent(
            nil,
            "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
            10
        )

        test.assert_equal(harness.actions, {
            { action = "show", tabId = "bank" },
            { action = "align", frame = harness.guildBankFrame },
        })
        harness.restore()
    end),

    test.case("unrelated interaction windows do not affect RGMS", function()
        local harness = newHarness()

        harness.eventFrame.scripts.OnEvent(
            nil,
            "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
            99
        )

        test.assert_equal(harness.actions, {})
        harness.restore()
    end),

    test.case("display changes realign an open RGMS while the guild bank is visible", function()
        local harness = newHarness({ rgmsShown = true })

        harness.eventFrame.scripts.OnEvent(nil, "UI_SCALE_CHANGED")
        harness.eventFrame.scripts.OnEvent(nil, "DISPLAY_SIZE_CHANGED")

        test.assert_equal(harness.actions, {
            { action = "align", frame = harness.guildBankFrame },
            { action = "align", frame = harness.guildBankFrame },
        })
        harness.restore()
    end),

    test.case("closed windows remain independent", function()
        local harness = newHarness({ rgmsShown = true, guildBankShown = false })

        harness.eventFrame.scripts.OnEvent(nil, "GUILDBANKFRAME_CLOSED")
        harness.eventFrame.scripts.OnEvent(nil, "UI_SCALE_CHANGED")

        test.assert_equal(harness.actions, {})
        harness.restore()
    end),
}
