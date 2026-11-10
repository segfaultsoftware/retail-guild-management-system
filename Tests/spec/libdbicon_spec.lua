local test = require("Tests.lib.runner")

local GLOBAL_NAMES = {
    "AddonCompartmentFrame",
    "CreateFrame",
    "GetCursorPosition",
    "GetMinimapShape",
    "LibStub",
    "Minimap",
    "UIParent",
    "WOW_PROJECT_CAMELOT",
    "WOW_PROJECT_ID",
    "WOW_PROJECT_MAINLINE",
    "securecallfunction",
    "strmatch",
}

local function assertNear(actual, expected)
    test.assert_true(math.abs(actual - expected) < 0.001)
end

local function withLibraryHarness(options, callback)
    options = options or {}
    local previous = {}
    for _, name in ipairs(GLOBAL_NAMES) do
        previous[name] = _G[name]
    end

    local eventFrame
    local createdButtons = {}
    local tooltip
    local minimapWidth = 200
    local minimapHeight = 120
    local minimapShape = "ROUND"
    local minimapCenterX = 500
    local minimapCenterY = 500
    local cursorX = 500
    local cursorY = 600

    local function newTexture(parent)
        local texture = {
            parent = parent,
            shown = true,
        }
        function texture:ClearAllPoints()
            self.point = nil
        end
        function texture:GetParent()
            return self.parent
        end
        function texture:GetVertexColor()
            return 1, 1, 1
        end
        function texture:Hide()
            self.shown = false
        end
        function texture:SetPoint(...)
            self.point = { ... }
        end
        function texture:SetSize(width, height)
            self.width = width
            self.height = height
        end
        function texture:SetTexCoord(...)
            self.texCoord = { ... }
        end
        function texture:SetTexture(value)
            self.texture = value
        end
        function texture:SetVertexColor(...)
            self.vertexColor = { ... }
        end
        function texture:Show()
            self.shown = true
        end
        return texture
    end

    local function newFrame(frameType, name, parent)
        local frame = {
            frameType = frameType,
            lines = {},
            name = name,
            parent = parent,
            scripts = {},
        }
        function frame:AddLine(...)
            self.lines[#self.lines + 1] = { ... }
        end
        function frame:CreateAnimationGroup()
            return {
                CreateAnimation = function()
                    return {
                        SetDuration = function() end,
                        SetFromAlpha = function() end,
                        SetOrder = function() end,
                        SetStartDelay = function() end,
                        SetToAlpha = function() end,
                    }
                end,
                Play = function() end,
                SetToFinalAlpha = function() end,
                Stop = function() end,
            }
        end
        function frame:CreateTexture()
            return newTexture(self)
        end
        function frame:GetCenter()
            return self.centerX or 960, self.centerY or 540
        end
        function frame:GetName()
            return self.name
        end
        function frame:GetOwner()
            return self.owner
        end
        function frame:Hide()
            self.shown = false
        end
        function frame:IsShown()
            return self.shown == true
        end
        function frame:LockHighlight()
            self.highlightLocked = true
        end
        function frame:RegisterEvent(event)
            self.registeredEvent = event
        end
        function frame:RegisterForClicks(...)
            self.registeredClicks = { ... }
        end
        function frame:RegisterForDrag(...)
            self.registeredDrag = { ... }
        end
        function frame:SetAlpha(value)
            self.alpha = value
        end
        function frame:SetFixedFrameLevel(value)
            self.fixedFrameLevel = value
        end
        function frame:SetFixedFrameStrata(value)
            self.fixedFrameStrata = value
        end
        function frame:SetFrameLevel(value)
            self.frameLevel = value
        end
        function frame:SetFrameStrata(value)
            self.frameStrata = value
        end
        function frame:SetHighlightTexture(value)
            self.highlightTexture = value
        end
        function frame:SetOwner(owner, anchor)
            self.owner = owner
            self.ownerAnchor = anchor
        end
        function frame:SetPoint(...)
            self.point = { ... }
        end
        function frame:SetScript(event, handler)
            self.scripts[event] = handler
        end
        function frame:SetSize(width, height)
            self.width = width
            self.height = height
        end
        function frame:Show()
            self.shown = true
        end
        function frame:UnlockHighlight()
            self.highlightLocked = false
        end
        return frame
    end

    _G.AddonCompartmentFrame = nil
    if options.addonCompartmentAvailable ~= false then
        _G.AddonCompartmentFrame = {
            registeredAddons = {},
            RegisterAddon = function(self, entry)
                self.registeredAddons[#self.registeredAddons + 1] = entry
            end,
            UpdateDisplay = function() end,
        }
    end
    _G.LibStub = nil
    _G.securecallfunction = function(func, ...)
        return func(...)
    end
    _G.strmatch = string.match
    _G.WOW_PROJECT_ID = options.projectId or 1
    _G.WOW_PROJECT_MAINLINE = 1
    _G.WOW_PROJECT_CAMELOT = 18
    _G.GetCursorPosition = function()
        return cursorX, cursorY
    end
    _G.GetMinimapShape = function()
        return minimapShape
    end
    _G.UIParent = {
        GetHeight = function() return 1080 end,
        GetWidth = function() return 1920 end,
    }
    _G.Minimap = {
        GetCenter = function() return minimapCenterX, minimapCenterY end,
        GetEffectiveScale = function() return 1 end,
        GetHeight = function() return minimapHeight end,
        GetWidth = function() return minimapWidth end,
        HookScript = function() end,
    }
    _G.CreateFrame = function(frameType, name, parent)
        local frame = newFrame(frameType, name, parent)
        if frameType == "Button" then
            createdButtons[#createdButtons + 1] = frame
        elseif frameType == "GameTooltip" then
            tooltip = frame
        elseif frameType == "Frame" then
            eventFrame = frame
        end
        return frame
    end

    local ok, message = pcall(function()
        assert(loadfile("Libs/LibStub/LibStub.lua"))()
        assert(loadfile("Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua"))()
        assert(loadfile("Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua"))()
        assert(loadfile("Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua"))()

        callback({
            createdButtons = createdButtons,
            eventFrame = eventFrame,
            moveCursor = function(x, y)
                cursorX = x
                cursorY = y
            end,
            resizeMinimap = function(width, height)
                minimapWidth = width
                minimapHeight = height
            end,
            setMinimapShape = function(shape)
                minimapShape = shape
            end,
            tooltip = tooltip,
        })
    end)

    for _, name in ipairs(GLOBAL_NAMES) do
        _G[name] = previous[name]
    end
    if not ok then
        error(message, 0)
    end
end

return {
    test.case("vendored LibDBIcon supports Retail and both Forever UI surfaces", function()
        local scenarios = {
            {
                projectId = 1,
                addonCompartmentAvailable = true,
                borderSize = 50,
                backgroundSize = 24,
                backgroundPoint = { "CENTER", 0, 0 },
                iconSize = 18,
                iconPoint = { "CENTER" },
            },
            {
                projectId = 18,
                addonCompartmentAvailable = true,
                borderSize = 50,
                backgroundSize = 24,
                backgroundPoint = { "CENTER", 0, 0 },
                iconSize = 18,
                iconPoint = { "CENTER" },
            },
            {
                projectId = 18,
                addonCompartmentAvailable = false,
                borderSize = 53,
                backgroundSize = 20,
                backgroundPoint = { "TOPLEFT", 7, -5 },
                iconSize = 17,
                iconPoint = { "TOPLEFT", 7, -6 },
            },
        }

        for _, scenario in ipairs(scenarios) do
            withLibraryHarness(scenario, function(harness)
                local dataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
                local dbIcon = LibStub:GetLibrary("LibDBIcon-1.0")
                local object = dataBroker:NewDataObject("RGMS", {
                    type = "launcher",
                    icon = "rgms-icon",
                })

                dbIcon:Register("RGMS", object, { minimapPos = 225 })
                test.assert_equal(#harness.createdButtons, 1)
                local button = harness.createdButtons[1]
                test.assert_equal(button:GetName(), "LibDBIcon10_RGMS")
                test.assert_true(button.parent == Minimap)
                test.assert_equal(button.registeredDrag, { "LeftButton" })
                test.assert_true(type(button.scripts.OnDragStart) == "function")
                test.assert_true(type(button.scripts.OnDragStop) == "function")

                test.assert_equal(button.border.width, scenario.borderSize)
                test.assert_equal(button.border.height, scenario.borderSize)
                test.assert_equal(button.background.width, scenario.backgroundSize)
                test.assert_equal(button.background.height, scenario.backgroundSize)
                test.assert_equal(button.background.point, scenario.backgroundPoint)
                test.assert_equal(button.icon.width, scenario.iconSize)
                test.assert_equal(button.icon.height, scenario.iconSize)
                test.assert_equal(button.icon.point, scenario.iconPoint)
            end)
        end
    end),

    test.case("vendored LibDBIcon follows dimensions and shape for both projects", function()
        for _, projectId in ipairs({ 1, 18 }) do
            withLibraryHarness({
                projectId = projectId,
                addonCompartmentAvailable = true,
            }, function(harness)
                local dataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
                local dbIcon = LibStub:GetLibrary("LibDBIcon-1.0")
                local object = dataBroker:NewDataObject("RGMS", {
                    type = "launcher",
                    icon = "rgms-icon",
                })
                local settings = { minimapPos = 0 }

                dbIcon:Register("RGMS", object, settings)
                local button = harness.createdButtons[1]
                harness.eventFrame.scripts.OnEvent(harness.eventFrame)
                test.assert_equal(button.point[1], "CENTER")
                test.assert_true(button.point[2] == Minimap)
                assertNear(button.point[4], 105)
                assertNear(button.point[5], 0)

                harness.resizeMinimap(300, 160)
                settings.minimapPos = 90
                dbIcon:Refresh("RGMS")
                assertNear(button.point[4], 0)
                assertNear(button.point[5], 85)

                harness.setMinimapShape("SQUARE")
                settings.minimapPos = 45
                dbIcon:Refresh("RGMS")
                local xRadius = math.sqrt(2 * 155 * 155) - 10
                local yRadius = math.sqrt(2 * 85 * 85) - 10
                assertNear(button.point[4], math.cos(math.rad(45)) * xRadius)
                assertNear(button.point[5], math.sin(math.rad(45)) * yRadius)
            end)
        end
    end),

    test.case("vendored LibDBIcon drag persists the Forever minimap position", function()
        withLibraryHarness({
            projectId = 18,
            addonCompartmentAvailable = false,
        }, function(harness)
            local dataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
            local dbIcon = LibStub:GetLibrary("LibDBIcon-1.0")
            local object = dataBroker:NewDataObject("RGMS", {
                type = "launcher",
                icon = "rgms-icon",
            })
            local settings = { minimapPos = 225 }

            dbIcon:Register("RGMS", object, settings)
            local button = harness.createdButtons[1]
            harness.moveCursor(500, 600)
            button.scripts.OnDragStart(button)
            test.assert_true(button.highlightLocked)
            test.assert_true(type(button.scripts.OnUpdate) == "function")

            button.scripts.OnUpdate(button)
            assertNear(settings.minimapPos, 90)
            assertNear(button.point[4], 0)
            assertNear(button.point[5], 65)

            button.scripts.OnDragStop(button)
            test.assert_nil(button.scripts.OnUpdate)
            test.assert_false(button.highlightLocked)
        end)
    end),

    test.case("vendored LibDBIcon places tooltips for Retail and Forever", function()
        for _, projectId in ipairs({ 1, 18 }) do
            withLibraryHarness({
                projectId = projectId,
                addonCompartmentAvailable = projectId == 1,
            }, function(harness)
                local dataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
                local dbIcon = LibStub:GetLibrary("LibDBIcon-1.0")
                local object = dataBroker:NewDataObject("RGMS", {
                    type = "launcher",
                    icon = "rgms-icon",
                    OnTooltipShow = function(activeTooltip)
                        activeTooltip:AddLine("RGMS")
                    end,
                })

                dbIcon:Register("RGMS", object, { minimapPos = 0 })
                local button = harness.createdButtons[1]
                button.centerX = 960
                button.centerY = 1000
                button.scripts.OnEnter(button)

                test.assert_true(harness.tooltip.owner == button)
                test.assert_equal(harness.tooltip.ownerAnchor, "ANCHOR_NONE")
                test.assert_equal(harness.tooltip.point[1], "TOP")
                test.assert_true(harness.tooltip.point[2] == button)
                test.assert_equal(harness.tooltip.point[3], "BOTTOM")
                test.assert_equal(harness.tooltip.lines, { { "RGMS" } })
                test.assert_true(harness.tooltip:IsShown())

                button.scripts.OnLeave(button)
                test.assert_false(harness.tooltip:IsShown())
            end)
        end
    end),
}
