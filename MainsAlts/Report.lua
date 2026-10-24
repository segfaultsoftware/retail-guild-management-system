-- Pure Roster ByName projection. The saved roster is the only source of
-- characters; saved groups only determine which of those characters nest
-- beneath a main.

local _, RGMS = ...

local Report = {}
local Names = type(RGMS) == "table"
    and RGMS.RosterNames
    or require("Roster.Names")
local Tags = type(RGMS) == "table"
    and RGMS.MainsAltsTags
    or require("MainsAlts.Tags")

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

local function projectCharacter(member, savedNotes, savedTags)
    local displayName = Names.displayName(member.name, member.realm)
    local identity = Names.identity(member.name, member.realm)
    local note = savedNotes[identity]
    return {
        name = member.name,
        realm = member.realm,
        displayName = displayName,
        identity = identity,
        classFileName = member.classFileName,
        leadershipRole = member.leadershipRole,
        isMissing = member.isMissing == true,
        note = type(note) == "string" and note or "",
        hasNote = type(note) == "string" and string.find(note, "%S") ~= nil,
        tags = Tags.assignedTo(savedTags, identity),
    }
end

function Report.build(dataset, savedGroups, savedNotes, savedTags)
    if type(dataset) ~= "table" or type(dataset.members) ~= "table" then
        return nil, "ByName roster dataset is invalid"
    end
    if savedGroups ~= nil and type(savedGroups) ~= "table" then
        return nil, "ByName groups must be a table"
    end
    if savedNotes ~= nil and type(savedNotes) ~= "table" then
        return nil, "ByName character notes must be a table"
    end
    savedNotes = savedNotes or {}
    savedTags = savedTags or Tags.newState()
    local validTags, tagsError = Tags.validate(savedTags)
    if not validTags then
        return nil, tagsError
    end

    local characters = {}
    local charactersByIdentity = {}
    for _, member in ipairs(dataset.members) do
        if type(member) ~= "table"
            or type(member.name) ~= "string"
            or member.name == ""
            or type(member.realm) ~= "string"
            or member.realm == "" then
            return nil, "ByName roster member is invalid"
        end

        if member.isMissing ~= true then
            local character = projectCharacter(member, savedNotes, savedTags)
            if charactersByIdentity[character.identity] then
                return nil, "ByName roster contains a duplicate character"
            end
            characters[#characters + 1] = character
            charactersByIdentity[character.identity] = character
        end
    end

    local groupDefinitions = {}
    for mainDisplayName, altDisplayNames in pairs(savedGroups or {}) do
        if type(mainDisplayName) ~= "string"
            or type(altDisplayNames) ~= "table" then
            return nil, "ByName group is invalid"
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
                    return nil, "ByName group alt is invalid"
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
                    classFileName = definition.main.classFileName,
                    leadershipRole = definition.main.leadershipRole,
                    isMissing = definition.main.isMissing,
                    note = definition.main.note,
                    hasNote = definition.main.hasNote,
                    tags = definition.main.tags,
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
                classFileName = character.classFileName,
                leadershipRole = character.leadershipRole,
                isMissing = character.isMissing,
                note = character.note,
                hasNote = character.hasNote,
                tags = character.tags,
                altCount = 0,
                alts = {},
            }
        end
    end
    table.sort(rows, characterComesBefore)

    return {
        rows = rows,
        tagCatalog = Tags.sortedDefinitions(savedTags),
    }
end

if type(RGMS) == "table" then
    RGMS.MainsAltsReport = Report
end

return Report
