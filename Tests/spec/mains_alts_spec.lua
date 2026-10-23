local test = require("Tests.lib.runner")
local tags = require("MainsAlts.Tags")

local function newHarness(options)
    options = options or {}
    local calls = {}
    local rgms
    rgms = {
        DB = {
            roster = { members = options.members or {} },
            mainAltGroups = options.groups or {},
            characterNotes = options.notes or {},
            tags = options.tags or tags.newState(),
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
        IsScanLocked = function()
            return options.scanLocked == true
        end,
        MainsAltsReport = {
            build = function()
                if options.reportError then
                    return nil, options.reportError
                end
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
        MainsAltsTags = tags,
        LiveGuildNotes = options.liveNotes,
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
            replaceCharacterTags = function(model, identity, replacementTags)
                calls.tagReplaces = calls.tagReplaces or {}
                calls.tagReplaces[#calls.tagReplaces + 1] = {
                    model = model,
                    identity = identity,
                    tags = replacementTags,
                }
                if options.tagReplaceError then
                    return nil, options.tagReplaceError
                end
                calls.pendingTags = replacementTags
                return { publishedTags = true }, { tags = replacementTags }
            end,
        },
        ActivateCurrentGuild = function()
            calls.activated = true
            if calls.pendingTags then
                rgms.DB.tags = calls.pendingTags
            end
        end,
        UI = {
            SetMainsAltsAvailable = function(value)
                calls.available = value
            end,
            SetMainsAltsReport = function(value)
                calls.report = value
            end,
            SetTagsReport = function(value)
                calls.tagsReport = value
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

    test.case("Mains/Alts status disables controls for a corrupt report", function()
        local controller, calls = newHarness({ reportError = "corrupt roster" })

        controller.RefreshStatus()

        test.assert_false(calls.available)
        test.assert_nil(calls.report)
        test.assert_matches(calls.status.value, "corrupt roster")
    end),

    test.case("live visible guild notes participate in row note indicators", function()
        local controller, calls = newHarness({
            members = { { name = "Main", realm = "Area52" } },
            rows = {
                {
                    identity = "main-area52",
                    note = "",
                    hasNote = false,
                    alts = {},
                },
            },
            liveNotes = {
                HasActiveNote = function(_, identity, privateNote)
                    return identity == "main-area52" and privateNote == ""
                end,
            },
        })

        controller.RefreshStatus()

        test.assert_true(calls.report.rows[1].hasNote)
    end),

    test.case("successful roster scans can refresh the live guild-note cache", function()
        local refreshed = 0
        local controller = newHarness({
            liveNotes = {
                OnRosterUpdated = function()
                    refreshed = refreshed + 1
                    return true
                end,
            },
        })

        test.assert_true(controller.RefreshGuildNotes())
        test.assert_equal(refreshed, 1)
    end),

    test.case("UI note requests ensure a cache without forcing a refresh", function()
        local ensured = 0
        local controller = newHarness({
            liveNotes = {
                EnsureLoaded = function()
                    ensured = ensured + 1
                    return true, "cached"
                end,
            },
        })

        local loaded, reason = controller.RequestGuildNotes()
        test.assert_true(loaded)
        test.assert_equal(reason, "cached")
        test.assert_equal(ensured, 1)
    end),

    test.case("incomplete scan note data requests a follow-up roster load", function()
        local requests = 0
        local controller = newHarness({
            liveNotes = {
                OnRosterUpdated = function()
                    return false, "incomplete"
                end,
                RequestLoad = function()
                    requests = requests + 1
                    return true
                end,
            },
        })

        local refreshed, reason = controller.RefreshGuildNotes()
        test.assert_false(refreshed)
        test.assert_equal(reason, "incomplete")
        test.assert_equal(requests, 1)
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

    test.case("character note changes reject scans unknown characters and oversized text", function()
        local scanningController, scanningCalls = newHarness({
            scanning = true,
            members = { { name = "Main", realm = "Area52" } },
        })
        local saved, saveError = scanningController.SaveCharacterNote(
            "main-area52",
            "note"
        )
        test.assert_nil(saved)
        test.assert_matches(saveError, "disabled")
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

    test.case("character tags normalize deduplicate toggle and refresh immediately", function()
        local controller, calls, rgms = newHarness({
            members = { { name = "Main", realm = "Area52" } },
        })

        local assigned, resolved = controller.CreateOrAssignTag(
            "main-area52",
            "  Raid  Lead  "
        )
        test.assert_true(assigned)
        test.assert_equal(resolved, "raid  lead")
        test.assert_true(calls.tagReplaces[1].tags.definitions["raid  lead"])
        test.assert_true(
            calls.tagReplaces[1].tags.assignments["main-area52"]["raid  lead"]
        )
        test.assert_equal(rgms.AccountDataState.model, { publishedTags = true })
        test.assert_not_nil(calls.report)

        rgms.DB.tags = calls.tagReplaces[1].tags
        test.assert_true(controller.CreateOrAssignTag("main-area52", "RAID  LEAD"))
        test.assert_equal(
            tags.sortedDefinitions(calls.tagReplaces[2].tags),
            { "me", "raid  lead" }
        )

        rgms.DB.tags = calls.tagReplaces[2].tags
        local toggled, nowAssigned = controller.ToggleCharacterTag(
            "main-area52",
            "raid  lead"
        )
        test.assert_true(toggled)
        test.assert_false(nowAssigned)
        test.assert_nil(calls.tagReplaces[3].tags.assignments["main-area52"])
        test.assert_true(calls.tagReplaces[3].tags.definitions["raid  lead"])
    end),

    test.case("character tag mutations reject scans unknown characters and long names", function()
        local scanning, scanningCalls = newHarness({
            scanning = true,
            members = { { name = "Main", realm = "Area52" } },
        })
        local changed, scanError = scanning.CreateOrAssignTag(
            "main-area52",
            "raid"
        )
        test.assert_nil(changed)
        test.assert_matches(scanError, "disabled")
        test.assert_nil(scanningCalls.tagReplaces)

        local controller, calls = newHarness({
            members = { { name = "Main", realm = "Area52" } },
        })
        local unknown, unknownError = controller.ToggleCharacterTag(
            "other-area52",
            "me"
        )
        test.assert_nil(unknown)
        test.assert_matches(unknownError, "unavailable")
        local long, longError = controller.CreateOrAssignTag(
            "main-area52",
            string.rep("x", 33)
        )
        test.assert_nil(long)
        test.assert_matches(longError, "32")
        test.assert_nil(calls.tagReplaces)
    end),

    test.case("tag deletion publishes full cleanup and refreshes both tag consumers", function()
        local controller, calls, rgms = newHarness({
            members = { { name = "Visible", realm = "Area52" } },
            tags = {
                definitions = { me = true, raid = true },
                assignments = {
                    ["visible-area52"] = { me = true, raid = true },
                    ["retained-area52"] = { raid = true },
                },
            },
        })

        local deleted, deleteError = controller.DeleteTag("raid")

        test.assert_true(deleted, deleteError)
        test.assert_nil(calls.tagReplaces[1].tags.definitions.raid)
        test.assert_nil(calls.tagReplaces[1].tags.assignments["visible-area52"].raid)
        test.assert_nil(calls.tagReplaces[1].tags.assignments["retained-area52"])
        test.assert_not_nil(calls.report)
        test.assert_not_nil(calls.tagsReport)
        test.assert_equal(#calls.tagsReport.rows, 1)
        test.assert_equal(calls.tagsReport.rows[1].name, "me")
        test.assert_equal(rgms.AccountDataState.model, { publishedTags = true })
    end),

    test.case("tag deletion is scan-locked and storage failures remain atomic", function()
        local locked, lockedCalls = newHarness({
            scanLocked = true,
            tags = {
                definitions = { me = true, raid = true },
                assignments = { ["main-area52"] = { raid = true } },
            },
        })
        local deleted, lockedError = locked.DeleteTag("raid")
        test.assert_nil(deleted)
        test.assert_matches(lockedError, "disabled")
        test.assert_nil(lockedCalls.tagReplaces)

        local originalTags = {
            definitions = { me = true, raid = true },
            assignments = { ["retained-area52"] = { raid = true } },
        }
        local controller, calls, rgms = newHarness({
            tags = originalTags,
            tagReplaceError = "write rejected",
        })
        local originalModel = rgms.AccountDataState.model
        local failed, failure = controller.DeleteTag("raid")
        test.assert_nil(failed)
        test.assert_equal(failure, "write rejected")
        test.assert_true(rgms.DB.tags.definitions.raid)
        test.assert_true(rgms.DB.tags.assignments["retained-area52"].raid)
        test.assert_true(rgms.AccountDataState.model == originalModel)
        test.assert_nil(calls.report)
        test.assert_nil(calls.tagsReport)
    end),
}
