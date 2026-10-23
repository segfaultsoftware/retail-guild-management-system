-- Pure ordered-subsequence filtering for the Mains/Alts report. fzy-lua
-- primarily adds scoring and ranking, while lua-bk-tree adds edit-distance
-- lookup. Search here deliberately needs neither, so a small linear matcher
-- keeps the required report order without adding a third-party dependency.

local _, RGMS = ...

local Search = {}

function Search.normalize(query)
    if type(query) ~= "string" then
        return ""
    end
    return string.lower((string.gsub(query, " ", "")))
end

function Search.matches(name, query)
    if type(name) ~= "string" then
        return false
    end

    local needle = Search.normalize(query)
    if needle == "" then
        return true
    end

    local candidate = string.lower(name)
    local candidateIndex = 1
    for queryIndex = 1, #needle do
        local character = string.sub(needle, queryIndex, queryIndex)
        local matchIndex = string.find(
            candidate,
            character,
            candidateIndex,
            true
        )
        if not matchIndex then
            return false
        end
        candidateIndex = matchIndex + 1
    end
    return true
end

local function matchesTags(character, selectedTags)
    if type(selectedTags) ~= "table" then
        return true
    end
    local assigned = {}
    for _, name in ipairs(character.tags or {}) do
        assigned[name] = true
    end
    for name, selected in pairs(selectedTags) do
        if selected == true and assigned[name] ~= true then
            return false
        end
    end
    return true
end

local function hasSelectedTags(selectedTags)
    for _, selected in pairs(selectedTags or {}) do
        if selected == true then
            return true
        end
    end
    return false
end

function Search.characterMatches(character, query, selectedTags)
    return character.isMissing ~= true
        and Search.matches(character.name, query)
        and matchesTags(character, selectedTags)
end

function Search.filter(report, query, selectedTags)
    if type(report) ~= "table" or type(report.rows) ~= "table" then
        return nil, nil, "Mains/Alts search requires report rows"
    end

    local normalized = Search.normalize(query)
    selectedTags = type(selectedTags) == "table" and selectedTags or {}
    if normalized == "" and not hasSelectedTags(selectedTags) then
        local visibleRows = {}
        for _, row in ipairs(report.rows) do
            if row.isMissing ~= true then
                visibleRows[#visibleRows + 1] = row
            end
        end
        return { rows = visibleRows }, {}, normalized, {}
    end

    local rows = {}
    local expanded = {}
    local matchingCharacters = {}
    for _, row in ipairs(report.rows) do
        local groupMatches = Search.characterMatches(
            row,
            normalized,
            selectedTags
        )
        if groupMatches then
            matchingCharacters[row.identity] = true
        end
        for _, alt in ipairs(row.alts or {}) do
            if Search.characterMatches(alt, normalized, selectedTags) then
                groupMatches = true
                matchingCharacters[alt.identity] = true
            end
        end

        if groupMatches and row.isMissing ~= true then
            rows[#rows + 1] = row
            if (row.altCount or 0) > 0 then
                expanded[row.identity] = true
            end
        end
    end

    return { rows = rows }, expanded, normalized, matchingCharacters
end

if type(RGMS) == "table" then
    RGMS.MainsAltsSearch = Search
end

return Search
