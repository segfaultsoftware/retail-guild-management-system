-- Authoritative runtime product and semantic-capability detection. This small
-- policy module is project-owned because available addon libraries expose raw
-- build checks but do not provide RGMS's fail-closed capability contract.

local _, RGMS = ...

local ClientFlavor = {}

ClientFlavor.RETAIL = "retail"
ClientFlavor.FOREVER = "forever"
ClientFlavor.UNSUPPORTED = "unsupported"

local function isProjectId(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value > 0
        and value == math.floor(value)
end

local function profile(flavor, supported, mainlineFamily, craftingQuality)
    return {
        flavor = flavor,
        supported = supported,
        mainlineFamily = mainlineFamily,
        craftingQuality = craftingQuality,
    }
end

local function unsupportedProfile()
    return profile(ClientFlavor.UNSUPPORTED, false, false, false)
end

-- Evaluates injected values so Lua 5.1 tests and future callers can exercise
-- the product contract without reading or replacing live client globals.
function ClientFlavor.evaluate(runtime)
    if type(runtime) ~= "table" then
        return unsupportedProfile()
    end

    local projectId = runtime.projectId
    local mainlineProjectId = runtime.mainlineProjectId
    local camelotProjectId = runtime.camelotProjectId
    if not isProjectId(projectId)
        or not isProjectId(mainlineProjectId)
        or not isProjectId(camelotProjectId)
        or mainlineProjectId == camelotProjectId then
        return unsupportedProfile()
    end

    if projectId == mainlineProjectId then
        return profile(ClientFlavor.RETAIL, true, true, true)
    end
    if projectId == camelotProjectId then
        return profile(ClientFlavor.FOREVER, true, true, false)
    end

    return unsupportedProfile()
end

-- These are the only production reads of the raw project globals. Feature
-- modules consume product identity and semantic capabilities through the
-- stable queries below instead of inspecting project IDs themselves.
local globals = type(_G) == "table" and _G or {}
local currentProfile = ClientFlavor.evaluate({
    projectId = globals.WOW_PROJECT_ID,
    mainlineProjectId = globals.WOW_PROJECT_MAINLINE,
    camelotProjectId = globals.WOW_PROJECT_CAMELOT,
})

function ClientFlavor.getFlavor()
    return currentProfile.flavor
end

function ClientFlavor.isSupported()
    return currentProfile.supported
end

function ClientFlavor.isMainlineFamily()
    return currentProfile.mainlineFamily
end

function ClientFlavor.supportsCraftingQuality()
    return currentProfile.craftingQuality
end

if type(RGMS) == "table" then
    RGMS.ClientFlavor = ClientFlavor
end

return ClientFlavor
