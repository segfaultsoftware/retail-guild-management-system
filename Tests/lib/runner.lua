-- A deliberately small test runner that stays within WoW's Lua 5.1-era
-- language subset. It has no dependencies on WoW globals or third-party code.

local Runner = {}

local function render(value, seen)
    if type(value) ~= "table" then
        if type(value) == "string" then
            return string.format("%q", value)
        end

        return tostring(value)
    end

    seen = seen or {}
    if seen[value] then
        return "<recursive table>"
    end
    seen[value] = true

    local parts = {}
    for key, item in pairs(value) do
        parts[#parts + 1] = "[" .. render(key, seen) .. "]=" .. render(item, seen)
    end
    table.sort(parts)
    seen[value] = nil

    return "{" .. table.concat(parts, ", ") .. "}"
end

local function valuesAreEqual(actual, expected, visited)
    if actual == expected then
        return true
    end

    if type(actual) ~= "table" or type(expected) ~= "table" then
        return false
    end

    visited = visited or {}
    if visited[actual] == expected then
        return true
    end
    visited[actual] = expected

    for key, value in pairs(actual) do
        if not valuesAreEqual(value, expected[key], visited) then
            return false
        end
    end

    for key in pairs(expected) do
        if actual[key] == nil then
            return false
        end
    end

    return true
end

local function fail(message, level)
    error(message, (level or 1) + 1)
end

function Runner.case(name, testFunction)
    if type(name) ~= "string" or name == "" then
        error("test case name must be a non-empty string", 2)
    end
    if type(testFunction) ~= "function" then
        error("test case must provide a function", 2)
    end

    return {
        name = name,
        run = testFunction,
    }
end

function Runner.assert_true(value, message)
    if value ~= true then
        fail(message or ("expected true, got " .. render(value)), 2)
    end
end

function Runner.assert_false(value, message)
    if value ~= false then
        fail(message or ("expected false, got " .. render(value)), 2)
    end
end

function Runner.assert_nil(value, message)
    if value ~= nil then
        fail(message or ("expected nil, got " .. render(value)), 2)
    end
end

function Runner.assert_not_nil(value, message)
    if value == nil then
        fail(message or "expected a non-nil value", 2)
    end
end

function Runner.assert_equal(actual, expected, message)
    if not valuesAreEqual(actual, expected) then
        fail(message or ("expected " .. render(expected) .. ", got " .. render(actual)), 2)
    end
end

function Runner.assert_matches(value, pattern, message)
    if type(value) ~= "string" or not string.find(value, pattern) then
        fail(message or ("expected " .. render(value) .. " to match " .. render(pattern)), 2)
    end
end

function Runner.run(testCases, options)
    options = options or {}
    local write = options.write or print
    local result = {
        total = 0,
        passed = 0,
        failed = 0,
        failures = {},
    }

    for _, testCase in ipairs(testCases) do
        result.total = result.total + 1
        local succeeded, failureMessage = pcall(testCase.run)

        if succeeded then
            result.passed = result.passed + 1
            if not options.quiet then
                write("PASS " .. testCase.name)
            end
        else
            result.failed = result.failed + 1
            result.failures[#result.failures + 1] = {
                name = testCase.name,
                message = tostring(failureMessage),
            }
            if not options.quiet then
                write("FAIL " .. testCase.name)
                write("     " .. tostring(failureMessage))
            end
        end
    end

    return result
end


return Runner
