-- Pure main/alt grouping rules. Saved groups are copied before changes so a
-- rejected action cannot partially modify account data.

local _, RGMS = ...

local Groups = {}
local Names = type(RGMS) == "table"
    and RGMS.RosterNames
    or require("Roster.Names")

local function copyGroups(savedGroups)
    if type(savedGroups) ~= "table" then
        return nil, "ByName groups must be a table"
    end

    local copy = {}
    local memberships = {}
    local mainsByIdentity = {}
    for mainDisplayName, altDisplayNames in pairs(savedGroups) do
        if type(mainDisplayName) ~= "string" or mainDisplayName == ""
            or type(altDisplayNames) ~= "table" then
            return nil, "ByName group is invalid"
        end

        local mainName, mainRealm = Names.splitDisplayName(mainDisplayName)
        local mainIdentity = Names.identity(mainName, mainRealm)
        if memberships[mainIdentity] then
            return nil, "a character cannot belong to more than one group"
        end
        memberships[mainIdentity] = true
        mainsByIdentity[mainIdentity] = mainDisplayName

        local alts = {}
        copy[mainDisplayName] = alts
        for index, altDisplayName in ipairs(altDisplayNames) do
            if type(altDisplayName) ~= "string" or altDisplayName == "" then
                return nil, "ByName group alt is invalid"
            end
            local altName, altRealm = Names.splitDisplayName(altDisplayName)
            local altIdentity = Names.identity(altName, altRealm)
            if memberships[altIdentity] then
                return nil, "a character cannot belong to more than one group"
            end
            memberships[altIdentity] = true
            alts[index] = altDisplayName
        end
    end
    return copy, memberships, mainsByIdentity
end

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

local function sortDisplayNames(displayNames)
    table.sort(displayNames, function(left, right)
        local leftName, leftRealm = Names.splitDisplayName(left)
        local rightName, rightRealm = Names.splitDisplayName(right)
        return characterComesBefore(
            { name = leftName, realm = leftRealm, displayName = left },
            { name = rightName, realm = rightRealm, displayName = right }
        )
    end)
end

local function findAlt(groups, altIdentity)
    for mainDisplayName, altDisplayNames in pairs(groups) do
        for index, altDisplayName in ipairs(altDisplayNames) do
            local altName, altRealm = Names.splitDisplayName(altDisplayName)
            if Names.identity(altName, altRealm) == altIdentity then
                return mainDisplayName, altDisplayNames, index, altDisplayName
            end
        end
    end
    return nil
end

local function buildRosterCharacters(dataset)
    if type(dataset) ~= "table" or type(dataset.members) ~= "table" then
        return nil, "ByName roster dataset is invalid"
    end

    local byIdentity = {}
    for _, member in ipairs(dataset.members) do
        if type(member) ~= "table"
            or type(member.name) ~= "string" or member.name == ""
            or type(member.realm) ~= "string" or member.realm == "" then
            return nil, "ByName roster member is invalid"
        end
        local identity = Names.identity(member.name, member.realm)
        if byIdentity[identity] then
            return nil, "ByName roster contains a duplicate character"
        end
        byIdentity[identity] = {
            identity = identity,
            name = member.name,
            realm = member.realm,
            displayName = Names.displayName(member.name, member.realm),
        }
    end
    return byIdentity
end

function Groups.apply(dataset, savedGroups, selectedIdentities)
    if type(selectedIdentities) ~= "table" then
        return nil, "selected characters must be a table"
    end

    local charactersByIdentity, rosterError = buildRosterCharacters(dataset)
    if not charactersByIdentity then
        return nil, rosterError
    end
    local replacement, memberships, mainsByIdentity = copyGroups(savedGroups)
    if not replacement then
        return nil, memberships
    end

    local selected = {}
    local seenSelections = {}
    local selectedMainDisplayName
    local selectedMainIdentity
    local selectedMainCount = 0
    for _, identity in ipairs(selectedIdentities) do
        if type(identity) ~= "string" or seenSelections[identity]
            or not charactersByIdentity[identity] then
            return nil, "selection contains an unavailable character"
        end
        seenSelections[identity] = true
        local character = charactersByIdentity[identity]
        selected[#selected + 1] = character

        local mainDisplayName = mainsByIdentity[identity]
        if mainDisplayName and #replacement[mainDisplayName] > 0 then
            selectedMainCount = selectedMainCount + 1
            selectedMainDisplayName = mainDisplayName
            selectedMainIdentity = identity
        elseif memberships[identity] then
            return nil, "selection contains a character that is already grouped"
        end
    end

    if #selected < 2 then
        return nil, "select at least two characters"
    end
    if selectedMainCount > 1 then
        return nil, "existing groups cannot be combined"
    end

    table.sort(selected, characterComesBefore)
    local mainDisplayName = selectedMainDisplayName
    if not mainDisplayName then
        mainDisplayName = selected[1].displayName
        selectedMainIdentity = selected[1].identity
        replacement[mainDisplayName] = {}
    end

    local alts = replacement[mainDisplayName]
    for _, character in ipairs(selected) do
        if character.identity ~= selectedMainIdentity then
            alts[#alts + 1] = character.displayName
        end
    end

    sortDisplayNames(alts)

    return replacement, selectedMainIdentity
end

function Groups.promote(savedGroups, altIdentity)
    if type(altIdentity) ~= "string" or altIdentity == "" then
        return nil, "the alt identity is required"
    end

    local replacement, copyError = copyGroups(savedGroups)
    if not replacement then
        return nil, copyError
    end

    local mainDisplayName, alts, altIndex, altDisplayName = findAlt(
        replacement,
        altIdentity
    )
    if not mainDisplayName then
        return nil, "the character is not an alt in an existing group"
    end

    table.remove(alts, altIndex)
    alts[#alts + 1] = mainDisplayName
    sortDisplayNames(alts)
    replacement[mainDisplayName] = nil
    replacement[altDisplayName] = alts
    return replacement, altIdentity
end

function Groups.remove(savedGroups, altIdentity)
    if type(altIdentity) ~= "string" or altIdentity == "" then
        return nil, "the alt identity is required"
    end

    local replacement, copyError = copyGroups(savedGroups)
    if not replacement then
        return nil, copyError
    end

    local mainDisplayName, alts, altIndex = findAlt(replacement, altIdentity)
    if not mainDisplayName then
        return nil, "the character is not an alt in an existing group"
    end

    table.remove(alts, altIndex)
    local mainName, mainRealm = Names.splitDisplayName(mainDisplayName)
    local mainIdentity = Names.identity(mainName, mainRealm)
    if #alts == 0 then
        replacement[mainDisplayName] = nil
        return replacement, mainIdentity, false
    end

    sortDisplayNames(alts)
    return replacement, mainIdentity, true
end

function Groups.reconcile(dataset, savedGroups, savedNotes)
    local charactersByIdentity, rosterError = buildRosterCharacters(dataset)
    if not charactersByIdentity then
        return nil, rosterError
    end
    local copiedGroups, copyError = copyGroups(savedGroups)
    if not copiedGroups then
        return nil, copyError
    end
    if type(savedNotes) ~= "table" then
        return nil, "character notes must be a table"
    end

    local groups = {}
    for mainDisplayName, altDisplayNames in pairs(copiedGroups) do
        local mainName, mainRealm = Names.splitDisplayName(mainDisplayName)
        local mainIdentity = Names.identity(mainName, mainRealm)
        local mainRemains = charactersByIdentity[mainIdentity] ~= nil
        local remaining = {}

        if mainRemains then
            remaining[#remaining + 1] = mainDisplayName
        end
        for _, altDisplayName in ipairs(altDisplayNames) do
            local altName, altRealm = Names.splitDisplayName(altDisplayName)
            if charactersByIdentity[Names.identity(altName, altRealm)] then
                remaining[#remaining + 1] = altDisplayName
            end
        end

        if #remaining >= 2 then
            if not mainRemains then
                sortDisplayNames(remaining)
                mainDisplayName = table.remove(remaining, 1)
            else
                table.remove(remaining, 1)
                sortDisplayNames(remaining)
            end
            groups[mainDisplayName] = remaining
        end
    end

    local notes = {}
    for identity, note in pairs(savedNotes) do
        if charactersByIdentity[identity] then
            notes[identity] = note
        end
    end
    return groups, notes
end

if type(RGMS) == "table" then
    RGMS.MainsAltsGroups = Groups
end

return Groups
