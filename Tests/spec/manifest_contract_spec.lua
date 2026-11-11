local test = require("Tests.lib.runner")

local MANIFEST_PATH = "RGMS.toc"
local SUPPORTED_GAME_TYPES = {
    standard = true,
    camelot = true,
}
local SUPPORTED_DIRECTIVES = {
    AllowLoadGameType = true,
    ExcludeLoadGameType = true,
}

local function trim(value)
    return string.match(value or "", "^%s*(.-)%s*$") or ""
end

local function splitCommaDelimited(value)
    local values = {}
    local offset = 1
    while true do
        local comma = string.find(value, ",", offset, true)
        local item = trim(string.sub(value, offset, comma and comma - 1 or nil))
        if item == "" then
            error("comma-delimited manifest values must not contain empty items", 0)
        end
        values[#values + 1] = item
        if not comma then
            break
        end
        offset = comma + 1
    end
    return values
end

local function parseDirectives(text, line)
    local directives = {}
    local seen = {}
    local offset = 1
    while offset <= #text do
        local remaining = string.sub(text, offset)
        local whitespace = string.match(remaining, "^(%s*)") or ""
        offset = offset + #whitespace
        if offset > #text then
            break
        end

        remaining = string.sub(text, offset)
        local complete, name, values = string.match(
            remaining,
            "^(%[([%a]+)%s+([%a%s,]+)%])"
        )
        if not complete or not SUPPORTED_DIRECTIVES[name] or seen[name] then
            error("unsupported or malformed manifest directive: " .. line, 0)
        end
        seen[name] = true

        local gameTypes = splitCommaDelimited(values)
        local gameTypeSet = {}
        for _, gameType in ipairs(gameTypes) do
            if not SUPPORTED_GAME_TYPES[gameType] or gameTypeSet[gameType] then
                error("unsupported or repeated manifest game type: " .. line, 0)
            end
            gameTypeSet[gameType] = true
        end
        directives[#directives + 1] = {
            name = name,
            gameTypes = gameTypeSet,
        }
        offset = offset + #complete
    end

    if #directives == 2 then
        for gameType in pairs(SUPPORTED_GAME_TYPES) do
            if directives[1].gameTypes[gameType]
                and directives[2].gameTypes[gameType] then
                error("conflicting manifest directives: " .. line, 0)
            end
        end
    end
    return directives
end

local function parseManifest()
    local handle = assert(io.open(MANIFEST_PATH, "rb"))
    local metadata = {}
    local entries = {}
    for rawLine in handle:lines() do
        local line = string.gsub(rawLine, "\r$", "")
        local name, value = string.match(
            line,
            "^##%s+([%w%-]+):%s*(.-)%s*$"
        )
        if name then
            metadata[name] = metadata[name] or {}
            metadata[name][#metadata[name] + 1] = value
        elseif trim(line) ~= "" and string.sub(trim(line), 1, 1) ~= "#" then
            local source, directiveText = string.match(line, "^(.-)%s+(%[.*)$")
            source = trim(source or line)
            if source == "" then
                error("manifest runtime entry must have a source path", 0)
            end
            entries[#entries + 1] = {
                source = source,
                directives = directiveText
                    and parseDirectives(directiveText, line)
                    or {},
            }
        end
    end
    handle:close()
    return metadata, entries
end

local metadata, entries = parseManifest()

local function singleMetadata(name)
    local values = metadata[name]
    test.assert_not_nil(values, "manifest is missing " .. name)
    test.assert_equal(#values, 1, "manifest must declare " .. name .. " once")
    test.assert_true(values[1] ~= "", "manifest " .. name .. " must not be empty")
    return values[1]
end

local function normalizedPath(path)
    return string.lower(string.gsub(path, "\\", "/"))
end

local function entryIndexes()
    local indexes = {}
    for index, entry in ipairs(entries) do
        indexes[normalizedPath(entry.source)] = index
    end
    return indexes
end

local function appliesTo(entry, gameType)
    local allowed = true
    for _, directive in ipairs(entry.directives) do
        if directive.name == "AllowLoadGameType" then
            allowed = directive.gameTypes[gameType] == true
        elseif directive.name == "ExcludeLoadGameType"
            and directive.gameTypes[gameType] then
            allowed = false
        end
    end
    return allowed
end

local function productVersion(name)
    local value = singleMetadata(name)
    local major, minor, patch, suffix = string.match(
        value,
        "^(%d+)%.(%d+)%.(%d+)(.*)$"
    )
    test.assert_not_nil(major, name .. " must begin with X.Y.Z")
    for _, component in ipairs({ major, minor, patch }) do
        test.assert_true(
            component == "0" or string.sub(component, 1, 1) ~= "0",
            name .. " must use canonical numeric version components"
        )
    end
    test.assert_true(
        suffix == "" or string.match(suffix, "^%s+%S") ~= nil,
        name .. " build text must be separated from X.Y.Z by whitespace"
    )
    return value
end

return {
    test.case("shared manifest declares validated Retail and Forever products", function()
        local interfaces = splitCommaDelimited(singleMetadata("Interface"))
        productVersion("X-RGMS-Retail-Version")
        productVersion("X-RGMS-Forever-Version")

        test.assert_equal(#interfaces, 2)
        test.assert_matches(interfaces[1], "^%d+$")
        test.assert_matches(interfaces[2], "^%d+$")
        test.assert_false(interfaces[1] == interfaces[2])
        test.assert_equal(
            splitCommaDelimited(singleMetadata("AllowLoadGameType")),
            { "standard", "camelot" }
        )
    end),

    test.case("manifest preserves RGMS branding and saved-variable contracts", function()
        test.assert_equal(
            singleMetadata("Title"),
            "Retail Guild Management System (RGMS)"
        )
        test.assert_equal(singleMetadata("SavedVariables"), "RGMSAccountDB")
        test.assert_equal(
            singleMetadata("SavedVariablesPerCharacter"),
            "RGMSCharacterDB"
        )
        test.assert_equal(singleMetadata("X-Curse-Project-ID"), "1741733")
        test.assert_equal(singleMetadata("OptionalDeps"), "Auctionator")
    end),

    test.case("runtime entries are unique shared files with valid directives", function()
        local seen = {}
        local conditionalFiles = {}
        for _, entry in ipairs(entries) do
            local path = normalizedPath(entry.source)
            test.assert_nil(seen[path], "runtime file is listed more than once: " .. path)
            seen[path] = true

            local file = io.open(string.gsub(entry.source, "\\", "/"), "rb")
            test.assert_not_nil(file, "manifest runtime file is missing: " .. entry.source)
            file:close()

            local standard = appliesTo(entry, "standard")
            local camelot = appliesTo(entry, "camelot")
            test.assert_true(
                standard or camelot,
                "runtime entry is excluded from every supported product: "
                    .. entry.source
            )
            if #entry.directives > 0 then
                conditionalFiles[#conditionalFiles + 1] = path
                test.assert_false(
                    standard and camelot,
                    "conditional runtime entry must not execute on both products: "
                        .. entry.source
                )
            end
        end

        -- Every current runtime module is intentionally shared. A future
        -- product-specific implementation must add its expected path here.
        test.assert_equal(conditionalFiles, {})
    end),

    test.case("shared startup surfaces load in both supported products", function()
        local required = {
            "Core/ClientFlavor.lua",
            "Core/SavedData.lua",
            "Core/AccountData.lua",
            "Core/Minimap.lua",
            "Core/Bootstrap.lua",
            "Core/Commands.lua",
            "Roster/Roster.lua",
            "Bank/Bank.lua",
            "UI/Window.lua",
            "UI/UI.lua",
        }
        local byPath = {}
        for _, entry in ipairs(entries) do
            byPath[normalizedPath(entry.source)] = entry
        end
        for _, source in ipairs(required) do
            local entry = byPath[normalizedPath(source)]
            test.assert_not_nil(entry, "manifest is missing " .. source)
            test.assert_true(appliesTo(entry, "standard"), source .. " must load on Retail")
            test.assert_true(appliesTo(entry, "camelot"), source .. " must load on Forever")
        end
    end),

    test.case("client detection precedes identity persistence adapters and UI", function()
        local indexes = entryIndexes()
        local clientIndex = indexes[normalizedPath("Core/ClientFlavor.lua")]
        test.assert_not_nil(clientIndex)

        local consumers = {
            "Core/CharacterIdentity.lua",
            "Core/GuildIdentity.lua",
            "Core/SavedData.lua",
            "Core/AccountData.lua",
            "Core/RosterMigration.lua",
            "Core/BankMigration.lua",
            "Roster/Roster.lua",
            "Bank/Bank.lua",
            "MainsAlts/NotesRetail.lua",
            "Core/Minimap.lua",
            "Core/Bootstrap.lua",
            "UI/Window.lua",
            "UI/UI.lua",
        }
        for _, source in ipairs(consumers) do
            local consumerIndex = indexes[normalizedPath(source)]
            test.assert_not_nil(consumerIndex, "manifest is missing " .. source)
            test.assert_true(
                clientIndex < consumerIndex,
                "client detection must load before " .. source
            )
        end
    end),
}
