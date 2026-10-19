local addonName, RGMS = ...

local MinimapButton = {}

local DEFAULT_POSITION = 225
local DISPLAY_NAME = "Retail Guild Management System"

local function currentSettings()
    local state = type(RGMS) == "table" and RGMS.AccountDataState or nil
    if type(state) ~= "table"
        or not state.enabled
        or type(state.model) ~= "table"
        or type(state.model.settings) ~= "table" then
        return nil
    end
    return state.model.settings
end

local function getLibrary(name)
    if type(_G.LibStub) ~= "table"
        or type(_G.LibStub.GetLibrary) ~= "function" then
        return nil
    end
    return _G.LibStub:GetLibrary(name, true)
end

local function toggleRGMS(_, mouseButton)
    if mouseButton == "LeftButton"
        and type(RGMS) == "table"
        and type(RGMS.UI) == "table"
        and type(RGMS.UI.Toggle) == "function" then
        RGMS.UI.Toggle("roster")
    end
end

local function showTooltip(tooltip)
    if type(tooltip) ~= "table" or type(tooltip.AddLine) ~= "function" then
        return
    end
    tooltip:AddLine(DISPLAY_NAME)
    tooltip:AddLine("Left-click to open or close RGMS.", 1, 1, 1)
    tooltip:AddLine("Drag to reposition this button.", 0.7, 0.7, 0.7)
end

function MinimapButton.Initialize()
    if MinimapButton.button ~= nil then
        return true
    end

    local dataBroker = getLibrary("LibDataBroker-1.1")
    if dataBroker == nil then
        return nil, "LibDataBroker-1.1 is unavailable"
    end
    local dbIcon = getLibrary("LibDBIcon-1.0")
    if dbIcon == nil then
        return nil, "LibDBIcon-1.0 is unavailable"
    end

    local dataObject = dataBroker:NewDataObject(addonName, {
        type = "launcher",
        text = addonName,
        label = DISPLAY_NAME,
        icon = "Interface\\AddOns\\" .. addonName .. "\\assets\\rgms-minimap-icon.png",
        iconCoords = { 0.03, 0.97, 0.12, 0.88 },
        OnClick = toggleRGMS,
        OnTooltipShow = showTooltip,
    })
    if dataObject == nil then
        return nil, "the RGMS data broker object could not be registered"
    end

    local settings = currentSettings() or { minimapPos = DEFAULT_POSITION }
    dbIcon:Register(addonName, dataObject, settings)

    local button = dbIcon:GetMinimapButton(addonName)
    if button == nil then
        return nil, "LibDBIcon-1.0 did not create the RGMS button"
    end

    MinimapButton.dataObject = dataObject
    MinimapButton.button = button
    return true
end

if type(RGMS) == "table" then
    RGMS.MinimapButton = MinimapButton
end

return MinimapButton
