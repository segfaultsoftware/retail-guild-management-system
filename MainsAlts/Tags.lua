-- Pure character-tag rules. Tag definitions are guild-wide while assignments
-- remain attached to one roster identity through every group mutation.

local _, RGMS = ...

local Tags = {}
local Names = type(RGMS) == "table"
    and RGMS.RosterNames
    or require("Roster.Names")

Tags.DEFAULT_TAG = "me"
Tags.MAX_NAME_LENGTH = 32

local function copyMap(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function copyState(state)
    local result = {
        definitions = copyMap(state.definitions),
        assignments = {},
    }
    for identity, assigned in pairs(state.assignments) do
        result.assignments[identity] = copyMap(assigned)
    end
    return result
end

local function asciiLower(value)
    return (string.gsub(value, "[A-Z]", function(character)
        return string.char(string.byte(character) + 32)
    end))
end

function Tags.newState()
    return {
        definitions = { [Tags.DEFAULT_TAG] = true },
        assignments = {},
    }
end

function Tags.normalize(value)
    if type(value) ~= "string" then
        return ""
    end
    local trimmed = string.match(value, "^%s*(.-)%s*$") or ""
    return asciiLower(trimmed)
end

function Tags.validate(state)
    if type(state) ~= "table"
        or type(state.definitions) ~= "table"
        or type(state.assignments) ~= "table" then
        return nil, "character tags require definitions and assignments"
    end
    if state.definitions[Tags.DEFAULT_TAG] ~= true then
        return nil, "character tags must contain the immutable me definition"
    end
    for name, present in pairs(state.definitions) do
        if type(name) ~= "string" or name == "" or present ~= true then
            return nil, "tag definitions must use non-empty string names"
        end
        if Tags.normalize(name) ~= name then
            return nil, "tag definitions must contain normalized names"
        end
    end
    for identity, assigned in pairs(state.assignments) do
        if type(identity) ~= "string" or identity == ""
            or type(assigned) ~= "table" then
            return nil, "tag assignments must use character identities"
        end
        if next(assigned) == nil then
            return nil, "empty character tag assignments must be omitted"
        end
        for name, present in pairs(assigned) do
            if present ~= true or state.definitions[name] ~= true then
                return nil, "tag assignments must reference saved definitions"
            end
        end
    end
    return true
end

function Tags.sortedDefinitions(state)
    local names = {}
    for name in pairs(state and state.definitions or {}) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function Tags.assignedTo(state, identity)
    local names = {}
    local assigned = type(state) == "table"
        and type(state.assignments) == "table"
        and state.assignments[identity]
        or nil
    for name in pairs(assigned or {}) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function Tags.buildCatalog(state, roster)
    local valid, validationError = Tags.validate(state)
    if not valid then
        return nil, validationError
    end
    if type(roster) ~= "table" or type(roster.members) ~= "table" then
        return nil, "tag catalog roster is invalid"
    end

    local visibleCharacters = {}
    for _, member in ipairs(roster.members) do
        if type(member) ~= "table"
            or type(member.name) ~= "string" or member.name == ""
            or type(member.realm) ~= "string" or member.realm == "" then
            return nil, "tag catalog roster member is invalid"
        end
        if member.isMissing ~= true then
            visibleCharacters[Names.identity(member.name, member.realm)] =
                Names.displayName(member.name, member.realm)
        end
    end

    local charactersByTag = {}
    for identity, assigned in pairs(state.assignments) do
        local displayName = visibleCharacters[identity]
        if displayName then
            for name in pairs(assigned) do
                local characters = charactersByTag[name] or {}
                characters[#characters + 1] = displayName
                charactersByTag[name] = characters
            end
        end
    end

    local rows = {}
    for _, name in ipairs(Tags.sortedDefinitions(state)) do
        local characters = charactersByTag[name] or {}
        table.sort(characters)
        rows[#rows + 1] = {
            name = name,
            characters = characters,
            characterCount = #characters,
            characterPreview = table.concat(characters, ", "),
            immutable = name == Tags.DEFAULT_TAG,
        }
    end
    return { rows = rows }
end

function Tags.deleteDefinition(state, name)
    local valid, validationError = Tags.validate(state)
    if not valid then
        return nil, validationError
    end
    if name == Tags.DEFAULT_TAG then
        return nil, "the me tag is immutable"
    end
    if type(name) ~= "string" or state.definitions[name] ~= true then
        return nil, "tag definition is unavailable"
    end

    local replacement = copyState(state)
    replacement.definitions[name] = nil
    for identity, assigned in pairs(replacement.assignments) do
        assigned[name] = nil
        if next(assigned) == nil then
            replacement.assignments[identity] = nil
        end
    end
    return replacement
end

function Tags.resolveAndAssign(state, identity, input)
    local valid, validationError = Tags.validate(state)
    if not valid then
        return nil, validationError
    end
    if type(identity) ~= "string" or identity == "" then
        return nil, "tag assignment identity must be a non-empty string"
    end

    local name = Tags.normalize(input)
    if name == "" then
        return state, false, name
    end

    local replacement = copyState(state)
    local created = replacement.definitions[name] ~= true
    replacement.definitions[name] = true
    replacement.assignments[identity] = replacement.assignments[identity] or {}
    replacement.assignments[identity][name] = true
    return replacement, created, name
end

function Tags.toggle(state, identity, name)
    local valid, validationError = Tags.validate(state)
    if not valid then
        return nil, validationError
    end
    if type(identity) ~= "string" or identity == "" then
        return nil, "tag assignment identity must be a non-empty string"
    end
    if type(name) ~= "string" or state.definitions[name] ~= true then
        return nil, "tag definition is unavailable"
    end

    local replacement = copyState(state)
    local assigned = replacement.assignments[identity]
    if assigned and assigned[name] then
        assigned[name] = nil
        if next(assigned) == nil then
            replacement.assignments[identity] = nil
        end
        return replacement, false
    end

    assigned = assigned or {}
    replacement.assignments[identity] = assigned
    assigned[name] = true
    return replacement, true
end

function Tags.reconcile(dataset, state)
    if type(dataset) ~= "table" or type(dataset.members) ~= "table" then
        return nil, "ByName roster dataset is invalid"
    end
    local valid, validationError = Tags.validate(state)
    if not valid then
        return nil, validationError
    end

    local available = {}
    for _, member in ipairs(dataset.members) do
        if type(member) ~= "table"
            or type(member.name) ~= "string" or member.name == ""
            or type(member.realm) ~= "string" or member.realm == "" then
            return nil, "ByName roster member is invalid"
        end
        available[Names.identity(member.name, member.realm)] = true
    end

    local replacement = copyState(state)
    for identity in pairs(replacement.assignments) do
        if not available[identity] then
            replacement.assignments[identity] = nil
        end
    end
    return replacement
end

if type(RGMS) == "table" then
    RGMS.MainsAltsTags = Tags
end

return Tags
