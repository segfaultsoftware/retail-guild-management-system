local test = require("Tests.lib.runner")

local function newHarness(options)
    options = options or {}
    local calls = {}
    local rgms = {
        DB = {
            roster = { members = options.members or {} },
            mainAltGroups = options.groups or {},
        },
        Roster = {
            IsAvailable = function() return options.available ~= false end,
            IsScanInProgress = function() return options.scanning == true end,
        },
        MainsAltsReport = {
            build = function()
                return { rows = options.rows or {} }
            end,
        },
        UI = {
            SetMainsAltsAvailable = function(value)
                calls.available = value
            end,
            SetMainsAltsReport = function(value)
                calls.report = value
            end,
            SetViewContent = function(tabId, value)
                calls.content = { tabId = tabId, value = value }
            end,
            SetViewStatus = function(tabId, value)
                calls.status = { tabId = tabId, value = value }
            end,
        },
    }
    local chunk = assert(loadfile("MainsAlts/MainsAlts.lua"))
    return chunk("RGMS", rgms), calls
end

return {
    test.case("Mains/Alts status renders the roster projection while guilded", function()
        local controller, calls = newHarness({
            members = { {}, {} },
            rows = { { displayName = "Main-Area52" } },
        })

        controller.RefreshStatus()

        test.assert_true(calls.available)
        test.assert_not_nil(calls.report)
        test.assert_equal(calls.status, {
            tabId = "mainsalts",
            value = "2 roster characters",
        })
    end),

    test.case("Mains/Alts status is empty and disabled while guildless", function()
        local controller, calls = newHarness({ available = false })

        controller.RefreshStatus()

        test.assert_false(calls.available)
        test.assert_nil(calls.report)
        test.assert_equal(calls.content, {
            tabId = "mainsalts",
            value = "Not in a guild",
        })
        test.assert_equal(calls.status.value, "Not in a guild")
    end),

    test.case("Mains/Alts status identifies an active roster scan", function()
        local controller, calls = newHarness({ scanning = true })

        controller.RefreshStatus()

        test.assert_equal(calls.status.value, "Roster scan in progress")
    end),
}
