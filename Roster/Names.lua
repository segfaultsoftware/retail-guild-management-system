-- Canonical roster-member name handling shared by capture, reconciliation,
-- and reporting. The game normally supplies Name-Realm, but persisted realm
-- suffixes are normalized defensively so a malformed repeated suffix cannot
-- compound or create a duplicate retained member.

local _, RGMS = ...

local Names = {}

function Names.collapseRepeatedRealm(value)
    local realm = tostring(value or "")
    local separator = string.find(realm, "-", 1, true)
    while separator do
        local candidate = string.sub(realm, 1, separator - 1)
        local repeated = candidate
        while #repeated < #realm do
            repeated = repeated .. "-" .. candidate
        end
        if repeated == realm then
            return candidate
        end
        separator = string.find(realm, "-", separator + 1, true)
    end
    return realm
end

function Names.displayName(name, realm)
    local normalizedName = tostring(name or "")
    local normalizedRealm = Names.collapseRepeatedRealm(realm)
    return normalizedName .. "-" .. normalizedRealm
end

function Names.splitDisplayName(value, defaultRealm)
    local supplied = tostring(value or "")
    local name, realm = string.match(supplied, "^([^%-]+)%-(.+)$")
    if not name then
        name = supplied
        realm = defaultRealm
    end
    realm = Names.collapseRepeatedRealm(realm)
    return name, realm, Names.displayName(name, realm)
end

if type(RGMS) == "table" then
    RGMS.RosterNames = Names
end

return Names
