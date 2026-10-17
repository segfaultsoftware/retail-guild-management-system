local test = require("Tests.lib.runner")

local function newHarness(options)
    options = options or {}
    local calls = {}
    local rgms = {
        DB = {
            roster = { members = options.members or {} },
            mainAltGroups = options.groups or {},
            characterNotes = options.notes or {},
        },
        RosterNames = {
            identity = function(name, realm)
                return string.lower(name .. "-" .. realm)
            end,
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
                if options.groupError then
                    return nil, options.groupError
                end
                return options.groupResult or {
                    ["Main-Area52"] = { "Alt-Area52" },
                }, options.mainIdentity or "main-area52"
            end,
            promote = function(groups, altIdentity)
                calls.promote = { groups = groups, altIdentity = altIdentity }
                if options.promoteError then
                    return nil, options.promoteError
                end
                return options.promoteResult or {
                    ["Alt-Area52"] = { "Main-Area52" },
                }, options.promoteMainIdentity or "alt-area52"
            end,
            remove = function(groups, altIdentity)
                calls.remove = { groups = groups, altIdentity = altIdentity }
                if options.removeError then
                    return nil, options.removeError
                end
                local result = options.removeResult or {}
                local groupRemains = options.removeGroupRemains
                if groupRemains == nil then
                    groupRemains = next(result) ~= nil
                end
                return result,
                    options.removeMainIdentity or "main-area52",
                    groupRemains
            end,
        },
        AccountDataState = { model = { original = true } },
        ActiveGuildIdentity = { name = "Guild" },
        AccountData = {
            MAX_CHARACTER_NOTE_LENGTH = 5500,
            replaceMainAltGroups = function(model, identity, groups)
                calls.replace = { model = model, identity = identity, groups = groups }
                return { published = true }, { mainAltGroups = groups }
            end,
            replaceCharacterNote = function(model, identity, characterIdentity, note)
                calls.noteReplaces = calls.noteReplaces or {}
                calls.noteReplaces[#calls.noteReplaces + 1] = {
                    model = model,
                    identity = identity,
                    characterIdentity = characterIdentity,
                    note = note,
                }
                return { publishedNote = true }, {
                    characterNotes = note and { [characterIdentity] = note } or {},
                }
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
            CompleteMainsAltsChange = function(value, expandGroup)
                calls.completedChange = value or false
                calls.completedChangeExpands = expandGroup
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

    test.case("extending a group targets its existing main after publication", function()
        local controller, calls = newHarness({
            groups = { ["Existing-Area52"] = { "OldAlt-Area52" } },
            groupResult = {
                ["Existing-Area52"] = { "NewAlt-Area52", "OldAlt-Area52" },
            },
            mainIdentity = "existing-area52",
        })

        local grouped, mainIdentity = controller.GroupSelected({
            "existing-area52",
            "newalt-area52",
        })

        test.assert_true(grouped)
        test.assert_equal(mainIdentity, "existing-area52")
        test.assert_equal(calls.completedMain, "existing-area52")
        test.assert_not_nil(calls.report)
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
        test.assert_equal(mainIdentity, "main-area52")
        test.assert_equal(calls.remove.altIdentity, "alt-area52")
        test.assert_equal(calls.replace.groups, {})
        test.assert_equal(calls.completedChange, "main-area52")
        test.assert_false(calls.completedChangeExpands)
        test.assert_not_nil(calls.report)
    end),

    test.case("removal from a surviving group targets and expands its existing main", function()
        local controller, calls = newHarness({
            groups = {
                ["Main-Area52"] = { "Removed-Area52", "Stayed-Area52" },
            },
            removeResult = {
                ["Main-Area52"] = { "Stayed-Area52" },
            },
            removeMainIdentity = "main-area52",
            removeGroupRemains = true,
        })

        local removed, mainIdentity = controller.RemoveAlt("removed-area52")

        test.assert_true(removed)
        test.assert_equal(mainIdentity, "main-area52")
        test.assert_equal(calls.completedChange, "main-area52")
        test.assert_true(calls.completedChangeExpands)
        test.assert_not_nil(calls.report)
    end),

    test.case("failed group mutations do not complete UI state or refresh the report", function()
        local grouping, groupingCalls = newHarness({ groupError = "rejected" })
        local promotion, promotionCalls = newHarness({ promoteError = "rejected" })
        local removal, removalCalls = newHarness({ removeError = "rejected" })

        local grouped = grouping.GroupSelected({ "one", "two" })
        local promoted = promotion.PromoteAlt("alt-area52")
        local removed = removal.RemoveAlt("alt-area52")

        test.assert_nil(grouped)
        test.assert_nil(promoted)
        test.assert_nil(removed)
        test.assert_nil(groupingCalls.completedMain)
        test.assert_nil(promotionCalls.completedChange)
        test.assert_nil(removalCalls.completedChange)
        test.assert_nil(groupingCalls.report)
        test.assert_nil(promotionCalls.report)
        test.assert_nil(removalCalls.report)
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

    test.case("character notes save trimmed text and remove whitespace-only values", function()
        local controller, calls, rgms = newHarness({
            members = { { name = "Main", realm = "Area52" } },
        })

        test.assert_true(controller.SaveCharacterNote(
            "main-area52",
            "  first line\nsecond line  "
        ))
        test.assert_equal(calls.noteReplaces[1].characterIdentity, "main-area52")
        test.assert_equal(calls.noteReplaces[1].note, "first line\nsecond line")
        test.assert_equal(rgms.AccountDataState.model, { publishedNote = true })
        test.assert_not_nil(calls.report)

        test.assert_true(controller.SaveCharacterNote("main-area52", " \n\t "))
        test.assert_nil(calls.noteReplaces[2].note)
    end),

    test.case("character note deletion changes only the note entry", function()
        local controller, calls = newHarness({
            members = { { name = "Main", realm = "Area52" } },
            groups = { ["Main-Area52"] = { "Alt-Area52" } },
        })

        test.assert_true(controller.DeleteCharacterNote("main-area52"))

        test.assert_nil(calls.noteReplaces[1].note)
        test.assert_nil(calls.replace)
        test.assert_nil(calls.groupApply)
    end),

    test.case("character note changes reject scans unknown characters and oversized text", function()
        local scanningController, scanningCalls = newHarness({
            scanning = true,
            members = { { name = "Main", realm = "Area52" } },
        })
        local saved, saveError = scanningController.SaveCharacterNote(
            "main-area52",
            "note"
        )
        local deleted, deleteError = scanningController.DeleteCharacterNote(
            "main-area52"
        )
        test.assert_nil(saved)
        test.assert_matches(saveError, "disabled")
        test.assert_nil(deleted)
        test.assert_matches(deleteError, "disabled")
        test.assert_nil(scanningCalls.noteReplaces)

        local controller, calls = newHarness({
            members = { { name = "Main", realm = "Area52" } },
        })
        local unknown, unknownError = controller.SaveCharacterNote(
            "other-area52",
            "note"
        )
        local oversized, oversizedError = controller.SaveCharacterNote(
            "main-area52",
            string.rep("x", 5501)
        )
        test.assert_nil(unknown)
        test.assert_matches(unknownError, "unavailable")
        test.assert_nil(oversized)
        test.assert_matches(oversizedError, "5500")
        test.assert_nil(calls.noteReplaces)
    end),
}
