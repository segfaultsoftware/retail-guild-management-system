local test = require("Tests.lib.runner")

local PRODUCT_CASES = {
    { name = "Retail", projectId = 1 },
    { name = "Forever", projectId = 18 },
}

local function loadHarness(options)
    options = options or {}
    local previousGlobals = {
        LibStub = { _G.LibStub },
        WOW_PROJECT_CAMELOT = { _G.WOW_PROJECT_CAMELOT },
        WOW_PROJECT_ID = { _G.WOW_PROJECT_ID },
        WOW_PROJECT_MAINLINE = { _G.WOW_PROJECT_MAINLINE },
    }
    local previousAccount = RGMSAccountDB
    local registrations = {}
    local dataObjects = {}
    local button = {}

    local dataBroker = {
        NewDataObject = function(_, name, object)
            if options.withoutDataObject then
                return nil
            end
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
            if options.withoutButton then
                return nil
            end
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
    _G.WOW_PROJECT_MAINLINE = 1
    _G.WOW_PROJECT_CAMELOT = 18
    _G.WOW_PROJECT_ID = options.projectId or _G.WOW_PROJECT_MAINLINE

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
            for name, value in pairs(previousGlobals) do
                _G[name] = value[1]
            end
            RGMSAccountDB = previousAccount
        end,
        toggles = toggles,
    }
end

return {
    test.case("LibDBIcon registration is product-agnostic and account-wide", function()
        for _, product in ipairs(PRODUCT_CASES) do
            local harness = loadHarness({ projectId = product.projectId })

            test.assert_equal(WOW_PROJECT_ID, product.projectId)
            test.assert_equal(WOW_PROJECT_MAINLINE, 1)
            test.assert_equal(WOW_PROJECT_CAMELOT, 18)
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
            test.assert_equal(#harness.dataObjects, 1)
            test.assert_equal(#harness.registrations, 1)
            harness.restore()
        end
    end),

    test.case("broker callbacks toggle RGMS and populate the standard tooltip", function()
        for _, product in ipairs(PRODUCT_CASES) do
            local harness = loadHarness({ projectId = product.projectId })
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
            test.assert_equal(#lines, 1)
            test.assert_equal(lines[1][1], "RGMS")
            harness.restore()
        end
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

    test.case("initialization reports an unavailable broker data object", function()
        local harness = loadHarness({ withoutDataObject = true })
        local initialized, message = harness.minimap.Initialize()

        test.assert_nil(initialized)
        test.assert_matches(message, "data broker object")
        test.assert_equal(#harness.dataObjects, 0)
        test.assert_equal(#harness.registrations, 0)
        harness.restore()
    end),

    test.case("initialization reports a missing registered minimap button", function()
        local harness = loadHarness({ withoutButton = true })
        local initialized, message = harness.minimap.Initialize()

        test.assert_nil(initialized)
        test.assert_matches(message, "did not create")
        test.assert_equal(#harness.dataObjects, 1)
        test.assert_equal(#harness.registrations, 1)
        harness.restore()
    end),
}
