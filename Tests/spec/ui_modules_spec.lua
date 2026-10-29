local test = require("Tests.lib.runner")

local MODULES = {
    { path = "UI/Widgets.lua", name = "Widgets", exports = {} },
    {
        path = "UI/Provisions.lua",
        name = "Provisions",
        exports = {
            "SelectProvisionRow",
            "SetProvisionsReport",
            "SetGuildBankBalance",
            "SetProvisionsMoney",
            "SetProvisionsEditor",
        },
    },
    {
        path = "UI/ProvisionDrag.lua",
        name = "ProvisionDrag",
        exports = { "CancelProvisionDrag" },
    },
    {
        path = "UI/Tooltip.lua",
        name = "Tooltip",
        exports = { "ShowTooltip", "HideTooltip" },
    },
    {
        path = "UI/Toast.lua",
        name = "Toast",
        exports = { "ShowToast", "ClearToasts" },
    },
    {
        path = "UI/Roster/ByName.lua",
        name = "RosterByName",
        exports = {
            "SetMainsAltsReport",
            "CompleteRosterScan",
            "CompleteMainsAltsGrouping",
            "CompleteMainsAltsChange",
            "ToggleMainsAltsGroup",
            "CollapseMainsAltsGroups",
        },
    },
    {
        path = "UI/Roster/ByTenure.lua",
        name = "RosterByTenure",
        exports = { "SelectRosterRank", "SetRosterReport" },
    },
    {
        path = "UI/Roster/TagPopovers.lua",
        name = "RosterTagPopovers",
        exports = {
            "OpenMainsAltsTagEditor",
            "ToggleMainsAltsTagFilter",
            "ShowMainsAltsTagPreview",
            "HideMainsAltsTagPreview",
        },
    },
    {
        path = "UI/Tags.lua",
        name = "Tags",
        exports = { "SetTagsReport", "RequestTagDeletion" },
    },
    {
        path = "UI/Bank.lua",
        name = "Bank",
        exports = { "SelectBankTab", "SetBankReport" },
    },
    {
        path = "UI/Notes.lua",
        name = "Notes",
        exports = {
            "OpenCharacterNote",
            "CloseCharacterNoteEditor",
            "SetCharacterNoteState",
        },
    },
    {
        path = "UI/News.lua",
        name = "News",
        exports = { "SetNewsSets", "OpenNews", "CloseNews" },
    },
    {
        path = "UI/Window.lua",
        name = "Window",
        exports = {
            "Initialize",
            "ClampToScreen",
            "HasSavedPosition",
            "AlignToRightOf",
            "Show",
            "Hide",
            "Toggle",
            "IsShown",
        },
    },
}

local rgms = {}
for _, module in ipairs(MODULES) do
    assert(loadfile(module.path))("RGMS", rgms)
end

local cases = {
    test.case("UI components register in dependency order without constructing frames", function()
        test.assert_nil(rgms.UI)
        test.assert_equal(#rgms.UIRuntime.Registrations, #MODULES)
        for index, expected in ipairs(MODULES) do
            test.assert_equal(rgms.UIRuntime.Registrations[index].name, expected.name)
        end
    end),
}

for index, expected in ipairs(MODULES) do
    cases[#cases + 1] = test.case(
        expected.name .. " exposes only its declared facade interface",
        function()
            local registration = rgms.UIRuntime.Registrations[index]
            test.assert_equal(registration.name, expected.name)
            test.assert_equal(registration.exports, expected.exports)
            test.assert_equal(type(registration.installer), "function")
        end
    )
end

return cases
