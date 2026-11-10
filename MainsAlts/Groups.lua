-- Pure main/alt grouping rules. Saved groups are copied before changes so a
-- rejected action cannot partially modify account data. Group keys are opaque
-- roster identities; presentation and ordering always come from roster rows.

local _, RGMS = ...

local Groups = {}

local function validIdentity(value)
    return type(value) == "string" and value ~= ""
end

local function copyGroups(savedGroups)
    if type(savedGroups) ~= "table" then
        return nil, "ByName groups must be a table"
    end

    local copy = {}
    local memberships = {}
    local mains = {}
    for mainIdentity, altIdentities in pairs(savedGroups) do
        if not validIdentity(mainIdentity) or type(altIdentities) ~= "table" then
            return nil, "ByName group is invalid"
        end
        if memberships[mainIdentity] then
            return nil, "a character cannot belong to more than one group"
        end

        local count = 0
        for index in pairs(altIdentities) do
            if type(index) ~= "number" or index < 1
                or index ~= math.floor(index) then
                return nil, "ByName group alts must be a dense array"
            end
            count = count + 1
        end
        if count ~= #altIdentities then
            return nil, "ByName group alts must be a dense array"
        end

        memberships[mainIdentity] = true
        mains[mainIdentity] = true
        local alts = {}
        copy[mainIdentity] = alts
        for index, altIdentity in ipairs(altIdentities) do
            if not validIdentity(altIdentity) then
                return nil, "ByName group alt is invalid"
            end
            if memberships[altIdentity] then
                return nil, "a character cannot belong to more than one group"
            end
            memberships[altIdentity] = true
            alts[index] = altIdentity
        end
    end
    return copy, memberships, mains
end

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

local function sortIdentities(identities, charactersByIdentity)
    local decorated = {}
    for index, identity in ipairs(identities) do
        decorated[index] = {
            character = charactersByIdentity[identity],
            identity = identity,
            originalIndex = index,
        }
    end
    table.sort(decorated, function(left, right)
        if left.character and right.character then
            if characterComesBefore(left.character, right.character) then
                return true
            end
            if characterComesBefore(right.character, left.character) then
                return false
            end
        elseif left.character then
            return true
        elseif right.character then
            return false
        end
        return left.originalIndex < right.originalIndex
    end)
    for index, item in ipairs(decorated) do
        identities[index] = item.identity
    end
end

local function findAlt(groups, altIdentity)
    for mainIdentity, altIdentities in pairs(groups) do
        for index, candidateIdentity in ipairs(altIdentities) do
            if candidateIdentity == altIdentity then
                return mainIdentity, altIdentities, index
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
            or not validIdentity(member.identity)
            or type(member.name) ~= "string" or member.name == ""
            or (member.realm ~= nil
                and (type(member.realm) ~= "string" or member.realm == ""))
            or type(member.displayName) ~= "string"
            or member.displayName == "" then
            return nil, "ByName roster member is invalid"
        end
        if byIdentity[member.identity] then
            return nil, "ByName roster contains a duplicate character"
        end
        byIdentity[member.identity] = {
            identity = member.identity,
            name = member.name,
            realm = member.realm,
            displayName = member.displayName,
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
    local replacement, memberships, mains = copyGroups(savedGroups)
    if not replacement then
        return nil, memberships
    end

    local selected = {}
    local seenSelections = {}
    local selectedMainIdentity
    local selectedMainCount = 0
    for _, identity in ipairs(selectedIdentities) do
        if not validIdentity(identity) or seenSelections[identity]
            or not charactersByIdentity[identity] then
            return nil, "selection contains an unavailable character"
        end
        seenSelections[identity] = true
        local character = charactersByIdentity[identity]
        selected[#selected + 1] = character

        if mains[identity] and #replacement[identity] > 0 then
            selectedMainCount = selectedMainCount + 1
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
    if not selectedMainIdentity then
        selectedMainIdentity = selected[1].identity
        replacement[selectedMainIdentity] = {}
    end

    local alts = replacement[selectedMainIdentity]
    for _, character in ipairs(selected) do
        if character.identity ~= selectedMainIdentity then
            alts[#alts + 1] = character.identity
        end
    end
    sortIdentities(alts, charactersByIdentity)

    return replacement, selectedMainIdentity
end

function Groups.promote(dataset, savedGroups, altIdentity)
    if not validIdentity(altIdentity) then
        return nil, "the alt identity is required"
    end

    local charactersByIdentity, rosterError = buildRosterCharacters(dataset)
    if not charactersByIdentity then
        return nil, rosterError
    end
    local replacement, copyError = copyGroups(savedGroups)
    if not replacement then
        return nil, copyError
    end

    local mainIdentity, alts, altIndex = findAlt(replacement, altIdentity)
    if not mainIdentity then
        return nil, "the character is not an alt in an existing group"
    end

    table.remove(alts, altIndex)
    alts[#alts + 1] = mainIdentity
    sortIdentities(alts, charactersByIdentity)
    replacement[mainIdentity] = nil
    replacement[altIdentity] = alts
    return replacement, altIdentity
end

function Groups.remove(dataset, savedGroups, altIdentity)
    if not validIdentity(altIdentity) then
        return nil, "the alt identity is required"
    end

    local charactersByIdentity, rosterError = buildRosterCharacters(dataset)
    if not charactersByIdentity then
        return nil, rosterError
    end
    local replacement, copyError = copyGroups(savedGroups)
    if not replacement then
        return nil, copyError
    end

    local mainIdentity, alts, altIndex = findAlt(replacement, altIdentity)
    if not mainIdentity then
        return nil, "the character is not an alt in an existing group"
    end

    table.remove(alts, altIndex)
    if #alts == 0 then
        replacement[mainIdentity] = nil
        return replacement, mainIdentity, false
    end

    sortIdentities(alts, charactersByIdentity)
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
    for mainIdentity, altIdentities in pairs(copiedGroups) do
        local mainRemains = charactersByIdentity[mainIdentity] ~= nil
        local remaining = {}

        if mainRemains then
            remaining[#remaining + 1] = mainIdentity
        end
        for _, altIdentity in ipairs(altIdentities) do
            if charactersByIdentity[altIdentity] then
                remaining[#remaining + 1] = altIdentity
            end
        end

        if #remaining >= 2 then
            if not mainRemains then
                sortIdentities(remaining, charactersByIdentity)
                mainIdentity = table.remove(remaining, 1)
            else
                table.remove(remaining, 1)
                sortIdentities(remaining, charactersByIdentity)
            end
            groups[mainIdentity] = remaining
        end
    end

    local notes = {}
    for identity, note in pairs(savedNotes) do
        if not validIdentity(identity) then
            return nil, "character note identity is invalid"
        end
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
