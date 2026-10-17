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
        MainsAltsGroups = {
            apply = function(roster, groups, selected)
                calls.groupApply = {
                    roster = roster,
                    groups = groups,
                    selected = selected,
                }
                return options.groupResult or {
                    ["Main-Area52"] = { "Alt-Area52" },
                }, options.mainIdentity or "main-area52"
            end,
            promote = function(groups, altIdentity)
                calls.promote = { groups = groups, altIdentity = altIdentity }
                return options.promoteResult or {
                    ["Alt-Area52"] = { "Main-Area52" },
                }, options.promoteMainIdentity or "alt-area52"
            end,
            remove = function(groups, altIdentity)
                calls.remove = { groups = groups, altIdentity = altIdentity }
                return options.removeResult or {}, options.removeMainIdentity
            end,
        },
        AccountDataState = { model = { original = true } },
        ActiveGuildIdentity = { name = "Guild" },
        AccountData = {
            replaceMainAltGroups = function(model, identity, groups)
                calls.replace = { model = model, identity = identity, groups = groups }
                return { published = true }, { mainAltGroups = groups }
            end,
        },
        ActivateCurrentGuild = function()
            calls.activated = true
        end,
        UI = {
            SetMainsAltsAvailable = function(value)
                calls.available = value
            end,
            SetMainsAltsReport = function(value)
                calls.report = value
            end,
            CompleteMainsAltsGrouping = function(value)
                calls.completedMain = value
            end,
            CompleteMainsAltsChange = function(value)
                calls.completedChange = value or false
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
    return chunk("RGMS", rgms), calls, rgms
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

    test.case("grouping publishes only the replacement groups and completes the UI state", function()
        local controller, calls, rgms = newHarness({
            members = { { name = "Main" }, { name = "Alt" } },
            groups = {},
        })

        local grouped, mainIdentity = controller.GroupSelected({
            "main-area52",
            "alt-area52",
        })

        test.assert_true(grouped)
        test.assert_equal(mainIdentity, "main-area52")
        test.assert_equal(calls.groupApply.selected, {
            "main-area52",
            "alt-area52",
        })
        test.assert_equal(calls.replace.groups, {
            ["Main-Area52"] = { "Alt-Area52" },
        })
        test.assert_true(calls.activated)
        test.assert_equal(calls.completedMain, "main-area52")
        test.assert_equal(rgms.AccountDataState.model, { published = true })
    end),

    test.case("grouping is rejected while a roster scan is active", function()
        local controller, calls = newHarness({ scanning = true })

        local grouped, message = controller.GroupSelected({ "one", "two" })

        test.assert_nil(grouped)
        test.assert_matches(message, "disabled")
        test.assert_nil(calls.groupApply)
        test.assert_nil(calls.replace)
    end),

    test.case("promotion publishes the swapped group and expands the new main", function()
        local controller, calls, rgms = newHarness({
            groups = { ["Main-Area52"] = { "Alt-Area52" } },
        })

        local promoted, mainIdentity = controller.PromoteAlt("alt-area52")

        test.assert_true(promoted)
        test.assert_equal(mainIdentity, "alt-area52")
        test.assert_equal(calls.promote.altIdentity, "alt-area52")
        test.assert_equal(calls.replace.groups, {
            ["Alt-Area52"] = { "Main-Area52" },
        })
        test.assert_equal(calls.completedChange, "alt-area52")
        test.assert_not_nil(calls.report)
        test.assert_equal(rgms.AccountDataState.model, { published = true })
    end),

    test.case("removal publishes dissolved groups and clears expansion", function()
        local controller, calls = newHarness({
            groups = { ["Main-Area52"] = { "Alt-Area52" } },
        })

        local removed, mainIdentity = controller.RemoveAlt("alt-area52")

        test.assert_true(removed)
        test.assert_nil(mainIdentity)
        test.assert_equal(calls.remove.altIdentity, "alt-area52")
        test.assert_equal(calls.replace.groups, {})
        test.assert_false(calls.completedChange)
        test.assert_not_nil(calls.report)
    end),

    test.case("promotion and removal are rejected during a roster scan", function()
        local controller, calls = newHarness({ scanning = true })

        local promoted, promoteError = controller.PromoteAlt("alt-area52")
        local removed, removeError = controller.RemoveAlt("alt-area52")

        test.assert_nil(promoted)
        test.assert_matches(promoteError, "disabled")
        test.assert_nil(removed)
        test.assert_matches(removeError, "disabled")
        test.assert_nil(calls.promote)
        test.assert_nil(calls.remove)
        test.assert_nil(calls.replace)
    end),
}
