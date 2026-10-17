-- Pure Mains/Alts projection. The saved roster is the only source of
-- characters; saved groups only determine which of those characters nest
-- beneath a main.

local _, RGMS = ...

local Report = {}
local Names = type(RGMS) == "table"
    and RGMS.RosterNames
    or require("Roster.Names")

local function characterComesBefore(left, right)
    local leftName = string.lower(left.name)
    local rightName = string.lower(right.name)
    if leftName ~= rightName then
        return leftName < rightName
    end

    local leftRealm = string.lower(left.realm)
    local rightRealm = string.lower(right.realm)
    if leftRealm ~= rightRealm then
        return leftRealm < rightRealm
    end
    return left.displayName < right.displayName
end

local function projectCharacter(member)
    local displayName = Names.displayName(member.name, member.realm)
    return {
        name = member.name,
        realm = member.realm,
        displayName = displayName,
        identity = Names.identity(member.name, member.realm),
        isMissing = member.isMissing == true,
    }
end

function Report.build(dataset, savedGroups)
    if type(dataset) ~= "table" or type(dataset.members) ~= "table" then
        return nil, "Mains/Alts roster dataset is invalid"
    end
    if savedGroups ~= nil and type(savedGroups) ~= "table" then
        return nil, "Mains/Alts groups must be a table"
    end

    local characters = {}
    local charactersByIdentity = {}
    for _, member in ipairs(dataset.members) do
        if type(member) ~= "table"
            or type(member.name) ~= "string"
            or member.name == ""
            or type(member.realm) ~= "string"
            or member.realm == "" then
            return nil, "Mains/Alts roster member is invalid"
        end

        local character = projectCharacter(member)
        if charactersByIdentity[character.identity] then
            return nil, "Mains/Alts roster contains a duplicate character"
        end
        characters[#characters + 1] = character
        charactersByIdentity[character.identity] = character
    end

    local groupDefinitions = {}
    for mainDisplayName, altDisplayNames in pairs(savedGroups or {}) do
        if type(mainDisplayName) ~= "string"
            or type(altDisplayNames) ~= "table" then
            return nil, "Mains/Alts group is invalid"
        end
        local mainName, mainRealm = Names.splitDisplayName(mainDisplayName)
        local main = charactersByIdentity[Names.identity(mainName, mainRealm)]
        if main then
            groupDefinitions[#groupDefinitions + 1] = {
                main = main,
                altDisplayNames = altDisplayNames,
            }
        end
    end
    table.sort(groupDefinitions, function(left, right)
        return characterComesBefore(left.main, right.main)
    end)

    local groupedIdentities = {}
    local rowsByIdentity = {}
    for _, definition in ipairs(groupDefinitions) do
        if not groupedIdentities[definition.main.identity] then
            local alts = {}
            local seenAlts = {}
            for _, altDisplayName in ipairs(definition.altDisplayNames) do
                if type(altDisplayName) ~= "string" then
                    return nil, "Mains/Alts group alt is invalid"
                end
                local altName, altRealm = Names.splitDisplayName(altDisplayName)
                local alt = charactersByIdentity[Names.identity(altName, altRealm)]
                if alt
                    and alt.identity ~= definition.main.identity
                    and not groupedIdentities[alt.identity]
                    and not seenAlts[alt.identity] then
                    alts[#alts + 1] = alt
                    seenAlts[alt.identity] = true
                end
            end

            if #alts > 0 then
                table.sort(alts, characterComesBefore)
                groupedIdentities[definition.main.identity] = true
                for _, alt in ipairs(alts) do
                    groupedIdentities[alt.identity] = true
                end
                rowsByIdentity[definition.main.identity] = {
                    name = definition.main.name,
                    realm = definition.main.realm,
                    displayName = definition.main.displayName,
                    identity = definition.main.identity,
                    isMissing = definition.main.isMissing,
                    altCount = #alts,
                    alts = alts,
                }
            end
        end
    end

    local rows = {}
    for _, character in ipairs(characters) do
        local groupRow = rowsByIdentity[character.identity]
        if groupRow then
            rows[#rows + 1] = groupRow
        elseif not groupedIdentities[character.identity] then
            rows[#rows + 1] = {
                name = character.name,
                realm = character.realm,
                displayName = character.displayName,
                identity = character.identity,
                isMissing = character.isMissing,
                altCount = 0,
                alts = {},
            }
        end
    end
    table.sort(rows, characterComesBefore)

    return { rows = rows }
end

if type(RGMS) == "table" then
    RGMS.MainsAltsReport = Report
end

return Report
