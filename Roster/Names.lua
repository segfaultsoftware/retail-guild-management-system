-- Canonical roster-member name handling shared by capture, reconciliation,
-- and reporting. The game normally supplies Name-Realm, but persisted realm
-- suffixes are normalized defensively so a malformed repeated suffix cannot
-- compound or create a duplicate retained member.

local _, RGMS = ...

local Names = {}
local Realm = type(RGMS) == "table"
    and RGMS.Realm
    or require("Core.Realm")

function Names.collapseRepeatedRealm(value)
    return Realm.normalize(value)
end

function Names.displayName(name, realm)
    local normalizedName = tostring(name or "")
    local normalizedRealm = Names.collapseRepeatedRealm(realm)
    return normalizedName .. "-" .. normalizedRealm
end

function Names.identity(name, realm)
    return string.lower(Names.displayName(name, realm))
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
