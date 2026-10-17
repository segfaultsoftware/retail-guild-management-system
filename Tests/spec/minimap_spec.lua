local minimap = require("Core.Minimap")
local test = require("Tests.lib.runner")

local function assertNear(actual, expected)
    test.assert_true(math.abs(actual - expected) < 0.001)
end

local function newRegion()
    local region = {}
    for _, method in ipairs({ "SetSize", "SetPoint", "SetTexture", "SetTexCoord" }) do
        region[method] = function(self, ...)
            self[method] = { ... }
        end
    end
    return region
end

return {
    test.case("minimap geometry converts angles and cursor points", function()
        local x, y = minimap.positionForAngle(0, 80)
        assertNear(x, 80)
        assertNear(y, 0)

        x, y = minimap.positionForAngle(270, 80)
        assertNear(x, 0)
        assertNear(y, -80)

        test.assert_equal(minimap.angleForPoint(0, 10), 90)
        test.assert_equal(minimap.angleForPoint(-10, 0), 180)
        test.assert_equal(minimap.angleForPoint(0, -10), 270)
        assertNear(minimap.angleForPoint(10, -10), 315)
    end),

    test.case("button toggles RGMS and saves its dragged account-wide angle", function()
        local previousCreateFrame = CreateFrame
        local previousMinimap = _G.Minimap
        local previousUIParent = UIParent
        local previousCursor = GetCursorPosition
        local previousTooltip = GameTooltip
        local previousAccount = RGMSAccountDB
        local button
        local toggles = {}
        local textures = {}

        _G.Minimap = {
            GetFrameLevel = function() return 2 end,
            GetCenter = function() return 100, 100 end,
        }
        UIParent = {
            GetEffectiveScale = function() return 2 end,
        }
        GetCursorPosition = function() return 200, 360 end
        GameTooltip = {
            SetOwner = function() end,
            AddLine = function() end,
            Show = function() end,
            Hide = function() end,
        }
        CreateFrame = function()
            button = {
                scripts = {},
                textures = {},
                SetSize = function() end,
                SetFrameStrata = function() end,
                SetFrameLevel = function() end,
                RegisterForClicks = function() end,
                RegisterForDrag = function() end,
                SetHighlightTexture = function() end,
                ClearAllPoints = function() end,
                SetPoint = function(self, ...)
                    self.point = { ... }
                end,
                SetScript = function(self, event, handler)
                    self.scripts[event] = handler
                end,
                CreateTexture = function(self)
                    local texture = newRegion()
                    self.textures[#self.textures + 1] = texture
                    textures[#textures + 1] = texture
                    return texture
                end,
            }
            return button
        end

        local accountModel = {
            settings = { minimapAngle = 225 },
        }
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
        local chunk = assert(loadfile("Core/Minimap.lua"))
        local loaded = chunk("RGMS", fakeRGMS)

        test.assert_true(loaded.Initialize())
        test.assert_equal(button.point[1], "CENTER")
        test.assert_equal(button.point[2], _G.Minimap)
        assertNear(button.point[4], -56.568542)
        assertNear(button.point[5], -56.568542)
        test.assert_equal(
            textures[2].SetTexture[1],
            "Interface\\AddOns\\RGMS\\assets\\rgms-minimap-icon.png"
        )

        button.scripts.OnClick(button, "LeftButton")
        button.scripts.OnClick(button, "RightButton")
        test.assert_equal(toggles, { "roster" })

        button.scripts.OnDragStart(button)
        test.assert_equal(button.angle, 90)
        button.scripts.OnDragStop(button)
        test.assert_equal(accountModel.settings.minimapAngle, 90)
        test.assert_true(RGMSAccountDB == accountModel)

        CreateFrame = previousCreateFrame
        _G.Minimap = previousMinimap
        UIParent = previousUIParent
        GetCursorPosition = previousCursor
        GameTooltip = previousTooltip
        RGMSAccountDB = previousAccount
    end),
}
