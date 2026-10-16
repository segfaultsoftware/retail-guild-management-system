local commands = require("Core.Commands")
local test = require("Tests.lib.runner")

local function newCommandHarness()
    local harness = {
        actions = {},
        messages = {},
        debugEnabled = false,
    }

    harness.api = {
        Print = function(message)
            harness.messages[#harness.messages + 1] = message
        end,
        ToggleDebug = function()
            harness.debugEnabled = not harness.debugEnabled
            return harness.debugEnabled
        end,
        UI = {
            Toggle = function(tabId)
                harness.actions[#harness.actions + 1] = {
                    action = "toggle",
                    tabId = tabId,
                }
            end,
        },
        Roster = {
            RequestManualScan = function()
                harness.actions[#harness.actions + 1] = {
                    action = "scanroster",
                }
            end,
        },
        Reset = {
            requestManual = function()
                harness.actions[#harness.actions + 1] = {
                    action = "reset",
                }
            end,
        },
    }

    return harness
end

local function loadRosterHarness(options)
    options = options or {}

    local messages = {}
    local scanRequests = {}
    local fakeRGMS = {
        Print = function(message)
            messages[#messages + 1] = message
        end,
        Reset = {
            canScan = function()
                return options.canScan ~= false
            end,
            canReport = function()
                return true
            end,
        },
    }

    if options.withScanner ~= false then
        fakeRGMS.Roster = {
            Scanner = {
                inProgress = options.inProgress == true,
                Request = function(_, source)
                    scanRequests[#scanRequests + 1] = source
                    return true
                end,
            },
        }
    end

    local previousIsInGuild = IsInGuild
    IsInGuild = function()
        return options.inGuild ~= false
    end

    local chunk = assert(loadfile("Roster/Roster.lua"))
    chunk("RGMS", fakeRGMS)

    return {
        messages = messages,
        requests = scanRequests,
        roster = fakeRGMS.Roster,
        restore = function()
            IsInGuild = previousIsInGuild
        end,
    }
end

return {
    test.case("bare command toggles the roster view exactly once", function()
        local harness = newCommandHarness()

        commands.handle(" \t\n ", harness.api)

        test.assert_equal(harness.actions, {
            { action = "toggle", tabId = "roster" },
        })
        test.assert_equal(harness.messages, {})
    end),

    test.case("supported commands ignore casing and surrounding whitespace", function()
        local harness = newCommandHarness()

        commands.handle("  ScAnRoStEr\t", harness.api)
        commands.handle("\n ReSeT  ", harness.api)

        test.assert_equal(harness.actions, {
            { action = "scanroster" },
            { action = "reset" },
        })
        test.assert_equal(harness.messages, {})
    end),

    test.case("debug command toggles session logging and reports its state", function()
        local harness = newCommandHarness()

        commands.handle("  DeBuG  ", harness.api)
        test.assert_true(harness.debugEnabled)
        test.assert_equal(harness.messages, { "Debug logging enabled." })

        commands.handle("debug", harness.api)
        test.assert_false(harness.debugEnabled)
        test.assert_equal(harness.messages, {
            "Debug logging enabled.",
            "Debug logging disabled.",
        })
    end),

    test.case("help and unknown arguments print equivalent complete listings", function()
        local helpHarness = newCommandHarness()
        local unknownHarness = newCommandHarness()

        commands.handle("HELP", helpHarness.api)
        commands.handle("scanbank", unknownHarness.api)

        test.assert_equal(helpHarness.actions, {})
        test.assert_equal(unknownHarness.actions, {})
        test.assert_equal(unknownHarness.messages, helpHarness.messages)
        test.assert_equal(helpHarness.messages, commands.HELP_LINES)

        local helpText = table.concat(helpHarness.messages, "\n"):lower()
        for _, excluded in ipairs({ "settings", "export", "sync", "classic", "scanbank" }) do
            test.assert_nil(string.find(helpText, excluded, 1, true))
        end
    end),

    test.case("extra arguments do not partially match a supported command", function()
        local harness = newCommandHarness()

        commands.handle("reset now", harness.api)

        test.assert_equal(harness.actions, {})
        test.assert_equal(harness.messages, commands.HELP_LINES)
    end),

    test.case("slash registration is restored when the command file reloads", function()
        local previousSlashCmdList = SlashCmdList
        local previousSlashName = SLASH_RGMS1
        SlashCmdList = {}

        local firstHarness = newCommandHarness()
        local chunk = assert(loadfile("Core/Commands.lua"))
        chunk("RGMS", firstHarness.api)
        local firstHandler = SlashCmdList.RGMS

        local secondHarness = newCommandHarness()
        chunk = assert(loadfile("Core/Commands.lua"))
        chunk("RGMS", secondHarness.api)

        test.assert_equal(SLASH_RGMS1, "/rgms")
        test.assert_true(type(firstHandler) == "function")
        test.assert_true(type(SlashCmdList.RGMS) == "function")
        test.assert_true(SlashCmdList.RGMS ~= firstHandler)

        SlashCmdList.RGMS("  HELP ")
        test.assert_equal(secondHarness.messages, commands.HELP_LINES)

        SlashCmdList = previousSlashCmdList
        SLASH_RGMS1 = previousSlashName
    end),

    test.case("manual roster scan reaches the transactional scanner once", function()
        local harness = loadRosterHarness()
        local started, reason = harness.roster.RequestManualScan()

        test.assert_true(started, reason)
        test.assert_equal(harness.requests, { "manual" })
        test.assert_equal(harness.messages, {})
        harness.restore()
    end),
}
