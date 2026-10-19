local test = require("Tests.lib.runner")

local function loadHarness(options)
    options = options or {}
    local previousLibStub = _G.LibStub
    local previousAccount = RGMSAccountDB
    local registrations = {}
    local dataObjects = {}
    local button = {}

    local dataBroker = {
        NewDataObject = function(_, name, object)
            dataObjects[#dataObjects + 1] = { name = name, object = object }
            return object
        end,
    }
    local dbIcon = {
        Register = function(_, name, object, settings)
            registrations[#registrations + 1] = {
                name = name,
                object = object,
                settings = settings,
            }
        end,
        GetMinimapButton = function()
            return button
        end,
    }
    local libraries = {
        ["LibDataBroker-1.1"] = dataBroker,
        ["LibDBIcon-1.0"] = dbIcon,
    }
    if options.withoutDataBroker then
        libraries["LibDataBroker-1.1"] = nil
    end
    if options.withoutDBIcon then
        libraries["LibDBIcon-1.0"] = nil
    end
    _G.LibStub = {
        GetLibrary = function(_, name)
            return libraries[name]
        end,
    }

    local accountModel = {
        settings = { minimapPos = 225 },
    }
    local toggles = {}
    local fakeRGMS = {
        AccountDataState = {
            enabled = true,
            model = accountModel,
        },
        UI = {
            Toggle = function(tabId)
                toggles[#toggles + 1] = tabId
            end,
        },
    }
    RGMSAccountDB = accountModel

    local chunk = assert(loadfile("Core/Minimap.lua"))
    local minimap = chunk("RGMS", fakeRGMS)

    return {
        accountModel = accountModel,
        button = button,
        dataObjects = dataObjects,
        minimap = minimap,
        registrations = registrations,
        restore = function()
            _G.LibStub = previousLibStub
            RGMSAccountDB = previousAccount
        end,
        toggles = toggles,
    }
end

return {
    test.case("LibDBIcon registration uses the account-wide settings table", function()
        local harness = loadHarness()

        test.assert_true(harness.minimap.Initialize())
        test.assert_true(harness.minimap.button == harness.button)
        test.assert_equal(#harness.dataObjects, 1)
        test.assert_equal(harness.dataObjects[1].name, "RGMS")

        local object = harness.dataObjects[1].object
        test.assert_equal(object.type, "launcher")
        test.assert_equal(object.text, "RGMS")
        test.assert_equal(object.label, "Retail Guild Management System")
        test.assert_equal(
            object.icon,
            "Interface\\AddOns\\RGMS\\assets\\rgms-minimap-icon.png"
        )
        test.assert_equal(object.iconCoords, { 0.03, 0.97, 0.12, 0.88 })

        test.assert_equal(#harness.registrations, 1)
        test.assert_equal(harness.registrations[1].name, "RGMS")
        test.assert_true(harness.registrations[1].object == object)
        test.assert_true(
            harness.registrations[1].settings == harness.accountModel.settings
        )

        harness.registrations[1].settings.minimapPos = 90
        test.assert_equal(harness.accountModel.settings.minimapPos, 90)
        test.assert_true(RGMSAccountDB == harness.accountModel)

        test.assert_true(harness.minimap.Initialize())
        test.assert_equal(#harness.registrations, 1)
        harness.restore()
    end),

    test.case("broker callbacks toggle RGMS and populate the tooltip", function()
        local harness = loadHarness()
        test.assert_true(harness.minimap.Initialize())
        local object = harness.dataObjects[1].object

        object.OnClick(nil, "LeftButton")
        object.OnClick(nil, "RightButton")
        test.assert_equal(harness.toggles, { "roster" })

        local lines = {}
        object.OnTooltipShow({
            AddLine = function(_, ...)
                lines[#lines + 1] = { ... }
            end,
        })
        test.assert_equal(lines[1][1], "Retail Guild Management System")
        test.assert_equal(lines[2][1], "Left-click to open or close RGMS.")
        test.assert_equal(lines[3][1], "Drag to reposition this button.")
        harness.restore()
    end),

    test.case("initialization reports unavailable broker libraries", function()
        local harness = loadHarness({ withoutDataBroker = true })
        local initialized, message = harness.minimap.Initialize()
        test.assert_nil(initialized)
        test.assert_matches(message, "LibDataBroker")
        harness.restore()

        harness = loadHarness({ withoutDBIcon = true })
        initialized, message = harness.minimap.Initialize()
        test.assert_nil(initialized)
        test.assert_matches(message, "LibDBIcon")
        harness.restore()
    end),
}
