local portal = require("UI.Portal")
local test = require("Tests.lib.runner")

return {
    test.case("dropdown selection uses numeric identity and deterministic fallback", function()
        local ranks = {
            { index = 4, name = "Officer" },
            { index = 7, name = "Officer" },
        }
        test.assert_true(portal.resolveSelection(ranks, 7) == ranks[2])
        test.assert_true(portal.resolveSelection(ranks, 99) == ranks[1])

        local tabs = {
            { index = 5, name = "Fifth" },
            { index = 2, name = "Second" },
        }
        test.assert_true(portal.resolveSelection(tabs, 99, true) == tabs[2])
        local empty = portal.dropdown({}, nil, "No bank tabs", true)
        test.assert_true(empty.disabled)
        test.assert_equal(empty.label, "No bank tabs")
    end),

    test.case("context controls are view-specific", function()
        test.assert_equal(portal.contextControls("roster"), {
            primary = "Group Toons", search = "character",
            tags = "Tags...", byRank = false, close = true,
        })
        test.assert_equal(portal.contextControls("roster", "ByTenure"), {
            dropdown = "rank", byRank = true, primary = "Refresh", close = true,
        })
        test.assert_equal(portal.contextControls("bank"), {
            dropdown = "bankTab", primary = "Refresh", close = true,
        })
        test.assert_equal(portal.contextControls("provisions"), {
            secondary = "New Provision", primary = "Refresh", close = true,
        })
        test.assert_equal(portal.contextControls("tags"), { close = true })
    end),

    test.case("every open selects roster and every close resets session scrolling", function()
        local state = portal.create()
        state:openWindow()
        test.assert_true(state:selectView("bank"))
        test.assert_equal(state:setScroll("bank", 91), 91)
        test.assert_true(state:selectView("roster"))
        test.assert_equal(state:setScroll("roster", 42, "ByName"), 42)
        test.assert_true(state:selectRosterMode("ByTenure"))
        test.assert_equal(state:setScroll("roster", 17), 17)
        test.assert_true(state:selectView("bank"))
        test.assert_equal(state.scroll.bank, 91)

        state:closeWindow()
        test.assert_equal(state:openWindow(), "roster")
        test.assert_equal(state.rosterMode, "ByName")
        test.assert_equal(state.scroll, {
            roster = { ByName = 0, ByTenure = 0 },
            bank = 0,
            provisions = 0,
            tags = 0,
        })
    end),

    test.case("option changes reset only the affected table", function()
        local state = portal.create()
        state.scroll.roster.ByName = 12
        state.scroll.roster.ByTenure = 56
        state.scroll.bank = 34
        test.assert_true(state:selectionChanged("bank"))
        test.assert_equal(state.scroll, {
            roster = { ByName = 12, ByTenure = 56 },
            bank = 0,
            provisions = 0,
            tags = 0,
        })
        test.assert_true(state:selectionChanged("roster"))
        test.assert_equal(state.scroll.roster, { ByName = 12, ByTenure = 0 })
    end),

    test.case("global scan lock rejects mutation and discards a note draft", function()
        local state = portal.create()
        test.assert_true(state:openNote("unsaved"))
        test.assert_true(state:beginScan("roster"))
        test.assert_false(state.modalOpen)
        test.assert_nil(state.noteDraft)
        test.assert_false(state:commandAllowed("reset"))
        test.assert_false(state:commandAllowed("scanroster"))
        test.assert_true(state:commandAllowed("help"))
        test.assert_true(state:commandAllowed("debug"))
        test.assert_true(state:commandAllowed(""))
        test.assert_nil(state:beginScan("bank"))
        test.assert_false(state:finishScan("bank"))
        test.assert_true(state:finishScan("roster"))
        test.assert_false(state:isLocked())
    end),

    test.case("dragging is allowed throughout the window while unlocked", function()
        local state = portal.create()
        test.assert_true(state:canDrag())
        test.assert_true(state:canDrag("header", true))
        test.assert_true(state:canDrag("table", false))
        state:beginScan("bank")
        test.assert_false(state:canDrag())
    end),

    test.case("operational status takes priority over the last bank scan", function()
        local timestamp = portal.bankTimestamp("Monday", "Sunday")
        test.assert_equal(timestamp, "Last scan: Monday")
        test.assert_nil(portal.bankTimestamp(nil, "Sunday"))
        test.assert_equal(portal.status("Scanning...", timestamp), "Scanning...")
        test.assert_equal(portal.status(nil, timestamp), timestamp)
    end),
}
