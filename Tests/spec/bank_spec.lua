local test = require("Tests.lib.runner")
local portal = require("UI.Portal")

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
            SetBankReport = function(report)
                actions[#actions + 1] = { action = "report", report = report }
            end,
            SetViewStatus = function(tabId, status)
                actions[#actions + 1] = {
                    action = "status",
                    tabId = tabId,
                    status = status,
                }
            end,
        },
        DB = options.database,
        BankReport = options.bankReport,
        DateTime = options.dateTime,
        Portal = portal,
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
    local bank = chunk("RGMS", fakeRGMS)

    return {
        actions = actions,
        eventFrame = eventFrame,
        guildBankFrame = guildBankFrame,
        bank = bank,
        restore = function()
            CreateFrame = previousCreateFrame
            GuildBankFrame = previousGuildBankFrame
            Enum = previousEnum
        end,
    }
end

return {
    test.case("status refresh renders the committed bank report and overall timestamp", function()
        local projected = { tabs = { { index = 1, rows = {} } } }
        local dataset = {
            scannedAt = { unixSeconds = 100 },
            tabs = {},
            slots = {},
        }
        local harness = newHarness({
            database = { bank = dataset },
            bankReport = {
                build = function(value)
                    test.assert_true(value == dataset)
                    return projected
                end,
            },
            dateTime = {
                formatPacificTimestamp = function(unixSeconds)
                    test.assert_equal(unixSeconds, 100)
                    return "2024-06-01 05:34 PT"
                end,
            },
        })

        harness.bank.RefreshStatus()

        test.assert_equal(harness.actions, {
            { action = "bank-open", value = true },
            { action = "report", report = projected },
            {
                action = "status",
                tabId = "bank",
                status = "Last scan: 2024-06-01 05:34 PT",
            },
        })
        harness.restore()
    end),

    test.case("bank status keeps its timestamp visible while scanning", function()
        local projected = { tabs = { { index = 1, rows = {} } } }
        local harness = newHarness({
            database = {
                bank = {
                    scannedAt = { unixSeconds = 100 },
                    tabs = {},
                    slots = {},
                },
            },
            bankReport = {
                build = function()
                    return projected
                end,
            },
            dateTime = {
                formatPacificTimestamp = function()
                    return "2024-06-01 05:34 PT"
                end,
            },
        })
        harness.bank.Scanner.inProgress = true

        harness.bank.RefreshStatus()

        test.assert_equal(harness.actions[#harness.actions], {
            action = "status",
            tabId = "bank",
            status = "Scanning... Last successful scan: 2024-06-01 05:34 PT",
        })
        harness.restore()
    end),

    test.case("fresh bank state stays distinct from a successful zero-tab scan", function()
        local builds = 0
        local harness = newHarness({
            guildBankShown = false,
            database = {
                bank = {
                    tabs = {},
                    slots = {},
                },
            },
            bankReport = {
                build = function()
                    builds = builds + 1
                    return { tabs = {} }
                end,
            },
            dateTime = {},
        })

        harness.bank.RefreshStatus()

        test.assert_equal(builds, 0)
        test.assert_equal(harness.actions, {
            { action = "bank-open", value = false },
            {
                action = "status",
                tabId = "bank",
                status = "Guild bank closed. No bank scan yet",
            },
        })
        harness.restore()
    end),

    test.case("closed bank status preserves prior timestamp and disables availability", function()
        local harness = newHarness({
            guildBankShown = false,
            database = {
                bank = {
                    scannedAt = { unixSeconds = 100 },
                    tabs = {},
                    slots = {},
                },
                ui = { selectedBankTabIndex = 1 },
            },
            bankReport = {
                build = function()
                    return { tabs = {
                        {
                            index = 1,
                            lastAccessibleText = "2024-05-31 23:45 PT",
                        },
                    } }
                end,
            },
            dateTime = {
                formatPacificTimestamp = function()
                    return "2024-06-01 05:34 PT"
                end,
            },
        })

        harness.bank.RefreshStatus()

        test.assert_equal(harness.actions[1], {
            action = "bank-open",
            value = false,
        })
        test.assert_equal(harness.actions[#harness.actions], {
            action = "status",
            tabId = "bank",
            status = "Guild bank closed. Last scan: 2024-06-01 05:34 PT\n"
                .. "Tab last accessible: 2024-05-31 23:45 PT",
        })
        harness.restore()
    end),

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
