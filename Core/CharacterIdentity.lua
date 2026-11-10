-- Pure product-aware character identity construction. Retail delegates to the
-- established RosterNames contract so existing Name-Realm keys stay exact.
-- Forever names remain indivisible, case-preserving values namespaced by
-- product and region. Identity keys are opaque; callers use the accompanying
-- displayName and sortName fields instead of parsing them.

local _, RGMS = ...

local CharacterIdentity = {}
local ClientFlavor = type(RGMS) == "table"
    and RGMS.ClientFlavor
    or require("Core.ClientFlavor")
local Names = type(RGMS) == "table"
    and RGMS.RosterNames
    or require("Roster.Names")

local FOREVER_KEY_PREFIX = "RGMS:CHARACTER:FOREVER:1:"
local VALID_REGIONS = {
    US = true,
    KR = true,
    EU = true,
    TW = true,
    CN = true,
}

local CANONICAL_FIELDS = {
    "key",
    "flavor",
    "region",
    "name",
    "realm",
    "displayName",
    "sortName",
    "guid",
}

local function asciiFold(value)
    return (string.gsub(value, "[A-Z]", function(character)
        return string.char(string.byte(character) + 32)
    end))
end

local function normalizeFlavor(value)
    if value == nil
        or value == ""
        or value == ClientFlavor.UNSUPPORTED then
        return nil, "character flavor is unavailable"
    end
    if value ~= ClientFlavor.RETAIL and value ~= ClientFlavor.FOREVER then
        return nil, "character flavor is unsupported"
    end
    return value
end

local function normalizeRegion(value)
    if type(value) ~= "string" or value == "" then
        return nil, "character region is unavailable"
    end

    local region = string.upper(value)
    if not VALID_REGIONS[region] then
        return nil, "character region is unsupported"
    end
    return region
end

local function validateName(value)
    if type(value) ~= "string" or value == "" then
        return nil, "character name is unavailable"
    end
    return value
end

local function validateForeverName(value)
    -- The approved client contract is exactly two non-empty components joined
    -- by one or more ordinary spaces. Check only that outer structure: retain
    -- every byte and never expose or interpret the second component as realm.
    if not string.match(value, "^%S+ +%S+$") then
        return nil, "Forever character name must be a complete two-part value"
    end
    return value
end

local function validateGuid(value)
    if value ~= nil and (type(value) ~= "string" or value == "") then
        return nil, "character GUID must be a non-empty string when provided"
    end
    return value
end

local function foreverKey(region, completeName)
    return FOREVER_KEY_PREFIX
        .. tostring(#region) .. ":" .. region
        .. ":" .. tostring(#completeName) .. ":" .. completeName
end

function CharacterIdentity.create(input)
    if type(input) ~= "table" then
        return nil, "character identity input must be a table"
    end

    local flavor, flavorError = normalizeFlavor(input.flavor)
    if not flavor then
        return nil, flavorError
    end

    local region, regionError = normalizeRegion(input.region)
    if not region then
        return nil, regionError
    end

    local name, nameError = validateName(input.name)
    if not name then
        return nil, nameError
    end

    local guid, guidError = validateGuid(input.guid)
    if guidError then
        return nil, guidError
    end

    local realm
    local displayName
    local key
    if flavor == ClientFlavor.RETAIL then
        if type(input.realm) ~= "string" or input.realm == "" then
            return nil, "Retail character realm is unavailable"
        end
        realm = Names.collapseRepeatedRealm(input.realm)
        if realm == "" then
            return nil, "Retail character realm is unavailable"
        end
        displayName = Names.displayName(name, realm)
        key = Names.identity(name, realm)
    else
        if input.realm ~= nil then
            return nil, "Forever character realm must be unavailable"
        end
        local completeName, completeNameError = validateForeverName(name)
        if not completeName then
            return nil, completeNameError
        end
        name = completeName
        displayName = name
        key = foreverKey(region, name)
    end

    local sortName = flavor == ClientFlavor.RETAIL
        and key
        or asciiFold(displayName)

    local result = {
        key = key,
        flavor = flavor,
        region = region,
        name = name,
        realm = realm,
        displayName = displayName,
        sortName = sortName,
    }
    if guid ~= nil then
        result.guid = guid
    end
    return result
end

function CharacterIdentity.validate(identity)
    if type(identity) ~= "table" then
        return nil, "character identity must be a table"
    end

    local canonical, canonicalError = CharacterIdentity.create(identity)
    if not canonical then
        return nil, canonicalError
    end

    for _, field in ipairs(CANONICAL_FIELDS) do
        if identity[field] ~= canonical[field] then
            return nil, "character identity " .. field .. " is not canonical"
        end
    end
    return true
end

local function validateOperand(value, label)
    local valid, validationError = CharacterIdentity.validate(value)
    if not valid then
        return nil, label .. " character identity is invalid: "
            .. validationError
    end
    return true
end

-- Equality deliberately ignores correlation metadata and presentation fields.
function CharacterIdentity.same(left, right)
    local leftValid, leftError = validateOperand(left, "left")
    if not leftValid then
        return nil, leftError
    end
    local rightValid, rightError = validateOperand(right, "right")
    if not rightValid then
        return nil, rightError
    end
    return left.key == right.key
end

-- Returns -1, 0, or 1. Equal opaque keys compare equally even when a Retail
-- label uses different casing. Distinct identities use the separate sort
-- input and then the opaque key as deterministic tie-breakers.
function CharacterIdentity.compare(left, right)
    local leftValid, leftError = validateOperand(left, "left")
    if not leftValid then
        return nil, leftError
    end
    local rightValid, rightError = validateOperand(right, "right")
    if not rightValid then
        return nil, rightError
    end

    if left.key == right.key then
        return 0
    end

    for _, field in ipairs({ "sortName", "key" }) do
        if left[field] < right[field] then
            return -1
        end
        if left[field] > right[field] then
            return 1
        end
    end
    return 0
end

if type(RGMS) == "table" then
    RGMS.CharacterIdentity = CharacterIdentity
end

return CharacterIdentity
