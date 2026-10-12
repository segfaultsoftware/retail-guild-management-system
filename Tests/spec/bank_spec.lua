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
    local scanner = {
        inProgress = false,
    }
    function scanner:IsInProgress()
        return self.inProgress
    end
    function scanner:Request(source)
        actions[#actions + 1] = { action = "scan", source = source }
        self.inProgress = true
        return true
    end
    function scanner:Cancel()
        actions[#actions + 1] = { action = "cancel" }
        self.inProgress = false
        return true
    end
    function scanner:OnSlotsChanged()
        actions[#actions + 1] = { action = "slots-changed" }
    end
    function scanner:Update(elapsed)
        actions[#actions + 1] = { action = "update", elapsed = elapsed }
    end
    local fakeRGMS = {
        Bank = {
            Scanner = scanner,
        },
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
            SetGuildBankOpen = function(isOpen)
                actions[#actions + 1] = { action = "bank-open", value = isOpen }
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
        test.assert_true(harness.eventFrame.events.GUILDBANKFRAME_CLOSED)
        test.assert_true(harness.eventFrame.events.GUILDBANKBAGSLOTS_CHANGED)
        harness.eventFrame.scripts.OnEvent(
            nil,
            "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
            10
        )

        test.assert_equal(harness.actions, {
            { action = "bank-open", value = true },
            { action = "show", tabId = "bank" },
            { action = "align", frame = harness.guildBankFrame },
            { action = "scan", source = "automatic" },
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

    test.case("closing the guild bank cancels collection but keeps RGMS open", function()
        local harness = newHarness({ rgmsShown = true, guildBankShown = false })

        harness.eventFrame.scripts.OnEvent(nil, "GUILDBANKFRAME_CLOSED")
        harness.eventFrame.scripts.OnEvent(nil, "UI_SCALE_CHANGED")

        test.assert_equal(harness.actions, {
            { action = "bank-open", value = false },
            { action = "cancel" },
        })
        harness.restore()
    end),

    test.case("slot events and frame updates are routed to the scanner", function()
        local harness = newHarness()

        harness.eventFrame.scripts.OnEvent(nil, "GUILDBANKBAGSLOTS_CHANGED")
        harness.eventFrame.scripts.OnUpdate(nil, 0.25)

        test.assert_equal(harness.actions, {
            { action = "slots-changed" },
            { action = "update", elapsed = 0.25 },
        })
        harness.restore()
    end),
}
