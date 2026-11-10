-- Pure product-aware guild identity construction. Retail preserves the
-- established account partition key exactly, while Forever ownership uses
-- only the approved stable club ID scoped by product and region. Generated
-- keys are opaque; callers use the separate display fields instead.

local _, RGMS = ...

local GuildIdentity = {}
local ClientFlavor = type(RGMS) == "table"
    and RGMS.ClientFlavor
    or require("Core.ClientFlavor")
local Realm = type(RGMS) == "table"
    and RGMS.Realm
    or require("Core.Realm")

local FOREVER_KEY_PREFIX = "RGMS:GUILD:FOREVER:1:"
local VALID_REGIONS = {
    US = true,
    KR = true,
    EU = true,
    TW = true,
    CN = true,
}

local CANONICAL_SCALAR_FIELDS = {
    "key",
    "flavor",
    "region",
    "name",
    "displayName",
    "clubId",
}

local function normalizeFlavor(value)
    if value == nil
        or value == ""
        or value == ClientFlavor.UNSUPPORTED then
        return nil, "guild flavor is unavailable"
    end
    if value ~= ClientFlavor.RETAIL and value ~= ClientFlavor.FOREVER then
        return nil, "guild flavor is unsupported"
    end
    return value
end

local function normalizeRegion(value)
    if type(value) ~= "string" or value == "" then
        return nil, "guild region is unavailable"
    end

    local region = string.upper(value)
    if not VALID_REGIONS[region] then
        return nil, "guild region is unsupported"
    end
    return region
end

local function validateName(value)
    if type(value) ~= "string" or value == "" then
        return nil, "guild name is unavailable"
    end
    return value
end

local function normalizeRetailRealm(value)
    if type(value) ~= "table" then
        return nil, "Retail guild realm is unavailable"
    end
    if type(value.name) ~= "string" or value.name == ""
        or type(value.slug) ~= "string" or value.slug == "" then
        return nil, "Retail guild realm requires a name and slug"
    end

    local name = Realm.normalize(value.name)
    local slug = Realm.normalize(value.slug)
    if name == "" or slug == "" then
        return nil, "Retail guild realm requires a name and slug"
    end
    return {
        name = name,
        slug = slug,
    }
end

local function normalizeClubId(value)
    if type(value) == "string" then
        if value == "" then
            return nil, "Forever guild club ID is unavailable"
        end
        return value
    end
    if type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value > 0
        and value == math.floor(value) then
        return tostring(value)
    end
    return nil, "Forever guild club ID is unavailable"
end

local function retailKey(name, realmSlug)
    return tostring(#name) .. ":" .. name .. ":" .. Realm.key(realmSlug)
end

local function foreverKey(region, clubId)
    return FOREVER_KEY_PREFIX
        .. tostring(#region) .. ":" .. region
        .. ":" .. tostring(#clubId) .. ":" .. clubId
end

function GuildIdentity.create(input)
    if type(input) ~= "table" then
        return nil, "guild identity input must be a table"
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

    local realm
    local clubId
    local key
    if flavor == ClientFlavor.RETAIL then
        if input.clubId ~= nil then
            return nil, "Retail guild club ID must be unavailable"
        end
        local realmError
        realm, realmError = normalizeRetailRealm(input.realm)
        if not realm then
            return nil, realmError
        end
        key = retailKey(name, realm.slug)
    else
        if input.realm ~= nil then
            return nil, "Forever guild realm must be unavailable"
        end
        local clubIdError
        clubId, clubIdError = normalizeClubId(input.clubId)
        if not clubId then
            return nil, clubIdError
        end
        key = foreverKey(region, clubId)
    end

    return {
        key = key,
        flavor = flavor,
        region = region,
        name = name,
        realm = realm,
        displayName = name,
        clubId = clubId,
    }
end

function GuildIdentity.validate(identity)
    if type(identity) ~= "table" then
        return nil, "guild identity must be a table"
    end

    local canonical, canonicalError = GuildIdentity.create(identity)
    if not canonical then
        return nil, canonicalError
    end

    for _, field in ipairs(CANONICAL_SCALAR_FIELDS) do
        if identity[field] ~= canonical[field] then
            return nil, "guild identity " .. field .. " is not canonical"
        end
    end

    if (identity.realm == nil) ~= (canonical.realm == nil) then
        return nil, "guild identity realm is not canonical"
    end
    if canonical.realm ~= nil then
        for _, field in ipairs({ "name", "slug" }) do
            if identity.realm[field] ~= canonical.realm[field] then
                return nil, "guild identity realm." .. field
                    .. " is not canonical"
            end
        end
    end
    return true
end

local function validateOperand(value, label)
    local valid, validationError = GuildIdentity.validate(value)
    if not valid then
        return nil, label .. " guild identity is invalid: "
            .. validationError
    end
    return true
end

-- Equality deliberately ignores display metadata and compares only the
-- canonical opaque ownership key.
function GuildIdentity.same(left, right)
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

if type(RGMS) == "table" then
    RGMS.GuildIdentity = GuildIdentity
end

return GuildIdentity
