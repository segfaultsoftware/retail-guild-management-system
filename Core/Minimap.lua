local addonName, RGMS = ...

local MinimapButton = {}

local DEFAULT_ANGLE = 225
local RADIUS = 80

local function normalizeAngle(angle)
    angle = tonumber(angle) or DEFAULT_ANGLE
    angle = angle % 360
    if angle < 0 then
        angle = angle + 360
    end
    return angle
end

function MinimapButton.positionForAngle(angle, radius)
    local radians = math.rad(normalizeAngle(angle))
    radius = radius or RADIUS
    return math.cos(radians) * radius, math.sin(radians) * radius
end

function MinimapButton.angleForPoint(x, y)
    if x == 0 then
        if y < 0 then
            return 270
        end
        return 90
    end

    local angle = math.deg(math.atan(y / x))
    if x < 0 then
        angle = angle + 180
    elseif y < 0 then
        angle = angle + 360
    end
    return normalizeAngle(angle)
end

local function currentSettings()
    local state = RGMS.AccountDataState
    if type(state) ~= "table"
        or not state.enabled
        or type(state.model) ~= "table"
        or type(state.model.settings) ~= "table" then
        return nil
    end
    return state.model.settings
end

local function place(button, angle)
    angle = normalizeAngle(angle)
    local x, y = MinimapButton.positionForAngle(angle)
    button:ClearAllPoints()
    button:SetPoint("CENTER", _G.Minimap, "CENTER", x, y)
    button.angle = angle
end

local function placeAtCursor(button)
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local centerX, centerY = _G.Minimap:GetCenter()
    local angle = MinimapButton.angleForPoint(
        cursorX / scale - centerX,
        cursorY / scale - centerY
    )
    place(button, angle)
end

local function savePosition(button)
    local settings = currentSettings()
    if settings == nil then
        return
    end
    settings.minimapAngle = normalizeAngle(button.angle)
    RGMSAccountDB = RGMS.AccountDataState.model
end

function MinimapButton.Initialize()
    if MinimapButton.button ~= nil then
        return true
    end
    if type(_G.Minimap) ~= "table" then
        return nil, "the minimap is unavailable"
    end

    local button = CreateFrame("Button", nil, _G.Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(_G.Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetPoint("CENTER", 0, 1)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(23, 23)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\assets\\rgms-minimap-icon.png")
    -- Trim transparent margins from the full CurseForge artwork at render time.
    icon:SetTexCoord(0.03, 0.97, 0.12, 0.88)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton"
            and type(RGMS.UI) == "table"
            and type(RGMS.UI.Toggle) == "function" then
            RGMS.UI.Toggle("roster")
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Retail Guild Management System")
        GameTooltip:AddLine("Left-click to open or close RGMS.", 1, 1, 1)
        GameTooltip:AddLine("Drag to reposition this button.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", placeAtCursor)
        placeAtCursor(self)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        placeAtCursor(self)
        savePosition(self)
    end)

    local settings = currentSettings()
    place(button, settings and settings.minimapAngle or DEFAULT_ANGLE)
    MinimapButton.button = button
    return true
end

if type(RGMS) == "table" then
    RGMS.MinimapButton = MinimapButton
end

return MinimapButton
