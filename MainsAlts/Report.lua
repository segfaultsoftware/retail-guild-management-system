-- Pure Roster ByName projection. The saved roster is the only source of
-- characters; saved groups only determine which of those characters nest
-- beneath a main.

local _, RGMS = ...

local Report = {}
local Tags = type(RGMS) == "table"
    and RGMS.MainsAltsTags
    or require("MainsAlts.Tags")

local function lower(value)
    return string.lower(value or "")
end

local function characterComesBefore(left, right)
    local leftName = lower(left.name)
    local rightName = lower(right.name)
    if leftName ~= rightName then
        return leftName < rightName
    end

    local leftRealm = lower(left.realm)
    local rightRealm = lower(right.realm)
    if leftRealm ~= rightRealm then
        return leftRealm < rightRealm
    end
    local leftDisplayName = lower(left.displayName)
    local rightDisplayName = lower(right.displayName)
    if leftDisplayName ~= rightDisplayName then
        return leftDisplayName < rightDisplayName
    end
    return left.displayName < right.displayName
end

local function projectCharacter(member, savedNotes, savedTags)
    local note = savedNotes[member.identity]
    return {
        name = member.name,
        realm = member.realm,
        displayName = member.displayName,
        identity = member.identity,
        classFileName = member.classFileName,
        leadershipRole = member.leadershipRole,
        isMissing = member.isMissing == true,
        note = type(note) == "string" and note or "",
        hasNote = type(note) == "string" and string.find(note, "%S") ~= nil,
        tags = Tags.assignedTo(savedTags, member.identity),
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
    for identity in pairs(savedNotes) do
        if type(identity) ~= "string" or identity == "" then
            return nil, "ByName character note identity is invalid"
        end
    end
    local validTags, tagsError = Tags.validate(savedTags)
    if not validTags then
        return nil, tagsError
    end

    local characters = {}
    local charactersByIdentity = {}
    for _, member in ipairs(dataset.members) do
        if type(member) ~= "table"
            or type(member.identity) ~= "string"
            or member.identity == ""
            or type(member.name) ~= "string"
            or member.name == ""
            or (member.realm ~= nil
                and (type(member.realm) ~= "string" or member.realm == ""))
            or type(member.displayName) ~= "string"
            or member.displayName == "" then
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
    for mainIdentity, altIdentities in pairs(savedGroups or {}) do
        if type(mainIdentity) ~= "string" or mainIdentity == ""
            or type(altIdentities) ~= "table" then
            return nil, "ByName group is invalid"
        end
        local altCount = 0
        for index in pairs(altIdentities) do
            if type(index) ~= "number" or index < 1
                or index ~= math.floor(index) then
                return nil, "ByName group alts must be a dense array"
            end
            altCount = altCount + 1
        end
        if altCount ~= #altIdentities then
            return nil, "ByName group alts must be a dense array"
        end
        for _, altIdentity in ipairs(altIdentities) do
            if type(altIdentity) ~= "string" or altIdentity == "" then
                return nil, "ByName group alt is invalid"
            end
        end
        local main = charactersByIdentity[mainIdentity]
        if main then
            groupDefinitions[#groupDefinitions + 1] = {
                main = main,
                altIdentities = altIdentities,
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
            for _, altIdentity in ipairs(definition.altIdentities) do
                local alt = charactersByIdentity[altIdentity]
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
