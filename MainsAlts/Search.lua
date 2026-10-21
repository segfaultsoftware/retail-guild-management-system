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

function Search.filter(report, query)
    if type(report) ~= "table" or type(report.rows) ~= "table" then
        return nil, nil, "Mains/Alts search requires report rows"
    end

    local normalized = Search.normalize(query)
    if normalized == "" then
        return { rows = report.rows }, {}, normalized
    end

    local rows = {}
    local expanded = {}
    for _, row in ipairs(report.rows) do
        local matches = Search.matches(row.name, normalized)
        if not matches then
            for _, alt in ipairs(row.alts or {}) do
                if Search.matches(alt.name, normalized) then
                    matches = true
                    break
                end
            end
        end

        if matches then
            rows[#rows + 1] = row
            if (row.altCount or 0) > 0 then
                expanded[row.identity] = true
            end
        end
    end

    return { rows = rows }, expanded, normalized
end

if type(RGMS) == "table" then
    RGMS.MainsAltsSearch = Search
end

return Search
