local test = require("Tests.lib.runner")

local GLOBAL_NAMES = {
    "CreateFrame",
    "GetMinimapShape",
    "LibStub",
    "Minimap",
    "UIParent",
    "WOW_PROJECT_ID",
    "WOW_PROJECT_MAINLINE",
    "securecallfunction",
    "strmatch",
}

local function withLibraryHarness(callback)
    local previous = {}
    for _, name in ipairs(GLOBAL_NAMES) do
        previous[name] = _G[name]
    end

    local eventFrame
    local createdButtons = {}
    local minimapWidth = 200
    local minimapHeight = 120

    local function newTexture(parent)
        return {
            ClearAllPoints = function() end,
            GetParent = function() return parent end,
            GetVertexColor = function() return 1, 1, 1 end,
            Hide = function() end,
            SetPoint = function() end,
            SetSize = function() end,
            SetTexCoord = function() end,
            SetTexture = function() end,
            SetVertexColor = function() end,
            Show = function() end,
        }
    end

    local function newFrame(frameType, name, parent)
        local frame = {
            frameType = frameType,
            name = name,
            parent = parent,
            scripts = {},
        }
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
        function frame:RegisterEvent(event)
            self.registeredEvent = event
        end
        function frame:RegisterForClicks() end
        function frame:RegisterForDrag() end
        function frame:SetAlpha() end
        function frame:SetFixedFrameLevel() end
        function frame:SetFixedFrameStrata() end
        function frame:SetFrameLevel() end
        function frame:SetFrameStrata() end
        function frame:SetHighlightTexture() end
        function frame:SetOwner(owner)
            self.owner = owner
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
        return frame
    end

    _G.LibStub = nil
    _G.securecallfunction = function(func, ...)
        return func(...)
    end
    _G.strmatch = string.match
    _G.WOW_PROJECT_ID = 1
    _G.WOW_PROJECT_MAINLINE = 1
    _G.GetMinimapShape = function() return "ROUND" end
    _G.UIParent = {
        GetHeight = function() return 1080 end,
        GetWidth = function() return 1920 end,
    }
    _G.Minimap = {
        GetCenter = function() return 500, 500 end,
        GetEffectiveScale = function() return 1 end,
        GetHeight = function() return minimapHeight end,
        GetWidth = function() return minimapWidth end,
        HookScript = function() end,
    }
    _G.CreateFrame = function(frameType, name, parent)
        local frame = newFrame(frameType, name, parent)
        if frameType == "Button" then
            createdButtons[#createdButtons + 1] = frame
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
            resizeMinimap = function(width, height)
                minimapWidth = width
                minimapHeight = height
            end,
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
    test.case("vendored LibDBIcon follows the current minimap size", function()
        withLibraryHarness(function(harness)
            local dataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
            local dbIcon = LibStub:GetLibrary("LibDBIcon-1.0")
            local object = dataBroker:NewDataObject("RGMS", {
                type = "launcher",
                icon = "rgms-icon",
            })

            dbIcon:Register("RGMS", object, { minimapPos = 0 })
            test.assert_equal(#harness.createdButtons, 1)
            local button = harness.createdButtons[1]
            test.assert_equal(button:GetName(), "LibDBIcon10_RGMS")
            test.assert_true(button.parent == Minimap)

            harness.eventFrame.scripts.OnEvent(harness.eventFrame)
            test.assert_equal(button.point[1], "CENTER")
            test.assert_true(button.point[2] == Minimap)
            test.assert_equal(button.point[4], 105)
            test.assert_equal(button.point[5], 0)

            harness.resizeMinimap(300, 160)
            dbIcon:Refresh("RGMS")
            test.assert_equal(button.point[4], 155)
            test.assert_equal(button.point[5], 0)
        end)
    end),
}
