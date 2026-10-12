-- Realm normalization shared by saved-data migration, dataset ownership, and
-- roster capture. Retail can return a repeated realm suffix truncated partway
-- through its final repetition, so normalization detects the first complete
-- repeated prefix instead of requiring the entire value to be periodic.

local _, RGMS = ...

local Realm = {}

function Realm.normalize(value)
    local realm = tostring(value or "")
    local foldedRealm = string.lower(realm)
    local separator = string.find(realm, "-", 1, true)

    while separator do
        local candidate = string.sub(realm, 1, separator - 1)
        local repeatStart = separator + 1
        local repeatEnd = repeatStart + #candidate - 1
        local repeatedCandidate = string.sub(
            foldedRealm,
            repeatStart,
            repeatEnd
        )
        local hasBoundary = repeatEnd == #realm
            or string.sub(realm, repeatEnd + 1, repeatEnd + 1) == "-"

        if repeatedCandidate == string.lower(candidate) and hasBoundary then
            return candidate
        end

        separator = string.find(realm, "-", separator + 1, true)
    end

    return realm
end

function Realm.key(value)
    return string.lower(Realm.normalize(value))
end

if type(RGMS) == "table" then
    RGMS.Realm = Realm
end

return Realm
