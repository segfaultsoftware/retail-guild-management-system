local clientFlavor = require("Core.ClientFlavor")
local test = require("Tests.lib.runner")

local function validRuntime()
    return {
        projectId = 1,
        mainlineProjectId = 1,
        camelotProjectId = 18,
    }
end

local function assertUnsupported(actual)
    test.assert_equal(actual, {
        flavor = clientFlavor.UNSUPPORTED,
        supported = false,
        mainlineFamily = false,
        craftingQuality = false,
    })
end

local function withProjectGlobals(values, callback)
    local names = {
        "WOW_PROJECT_ID",
        "WOW_PROJECT_MAINLINE",
        "WOW_PROJECT_CAMELOT",
    }
    local previous = {}
    for _, name in ipairs(names) do
        previous[name] = _G[name]
        _G[name] = values[name]
    end

    local succeeded, message = pcall(callback)
    for _, name in ipairs(names) do
        _G[name] = previous[name]
    end
    if not succeeded then
        error(message, 0)
    end
end

local function readAll(path)
    local handle, openError = io.open(path, "rb")
    if not handle then
        error(openError, 0)
    end
    local contents = handle:read("*a")
    handle:close()
    return contents
end

return {
    test.case("flavor values remain stable for callers", function()
        test.assert_equal(clientFlavor.RETAIL, "retail")
        test.assert_equal(clientFlavor.FOREVER, "forever")
        test.assert_equal(clientFlavor.UNSUPPORTED, "unsupported")
    end),

    test.case("Retail exposes Mainline and crafting-quality semantics", function()
        test.assert_equal(clientFlavor.evaluate(validRuntime()), {
            flavor = clientFlavor.RETAIL,
            supported = true,
            mainlineFamily = true,
            craftingQuality = true,
        })
    end),

    test.case("Forever shares Mainline without Retail crafting quality", function()
        local runtime = validRuntime()
        runtime.projectId = runtime.camelotProjectId

        test.assert_equal(clientFlavor.evaluate(runtime), {
            flavor = clientFlavor.FOREVER,
            supported = true,
            mainlineFamily = true,
            craftingQuality = false,
        })
    end),

    test.case("unknown project IDs fail closed", function()
        local runtime = validRuntime()
        runtime.projectId = 99

        assertUnsupported(clientFlavor.evaluate(runtime))
    end),

    test.case("missing project values fail closed", function()
        local fields = {
            "projectId",
            "mainlineProjectId",
            "camelotProjectId",
        }
        for _, field in ipairs(fields) do
            local runtime = validRuntime()
            runtime[field] = nil
            assertUnsupported(clientFlavor.evaluate(runtime))
        end
        assertUnsupported(clientFlavor.evaluate(nil))
    end),

    test.case("malformed and contradictory project values fail closed", function()
        local malformed = {
            {
                projectId = "1",
                mainlineProjectId = 1,
                camelotProjectId = 18,
            },
            {
                projectId = 1,
                mainlineProjectId = true,
                camelotProjectId = 18,
            },
            {
                projectId = 1,
                mainlineProjectId = 1,
                camelotProjectId = 18.5,
            },
            {
                projectId = math.huge,
                mainlineProjectId = 1,
                camelotProjectId = 18,
            },
            {
                projectId = 1,
                mainlineProjectId = 1,
                camelotProjectId = 1,
            },
        }
        for _, runtime in ipairs(malformed) do
            assertUnsupported(clientFlavor.evaluate(runtime))
        end
    end),

    test.case("addon loading exposes the live Retail service", function()
        withProjectGlobals({
            WOW_PROJECT_ID = 1,
            WOW_PROJECT_MAINLINE = 1,
            WOW_PROJECT_CAMELOT = 18,
        }, function()
            local addon = {}
            local loaded = assert(loadfile("Core/ClientFlavor.lua"))(
                "RGMS",
                addon
            )

            test.assert_equal(addon.ClientFlavor, loaded)
            test.assert_equal(loaded.getFlavor(), loaded.RETAIL)
            test.assert_true(loaded.isSupported())
            test.assert_true(loaded.isMainlineFamily())
            test.assert_true(loaded.supportsCraftingQuality())
        end)
    end),

    test.case("addon loading exposes the live Forever service", function()
        withProjectGlobals({
            WOW_PROJECT_ID = 18,
            WOW_PROJECT_MAINLINE = 1,
            WOW_PROJECT_CAMELOT = 18,
        }, function()
            local addon = {}
            local loaded = assert(loadfile("Core/ClientFlavor.lua"))(
                "RGMS",
                addon
            )

            test.assert_equal(addon.ClientFlavor, loaded)
            test.assert_equal(loaded.getFlavor(), loaded.FOREVER)
            test.assert_true(loaded.isSupported())
            test.assert_true(loaded.isMainlineFamily())
            test.assert_false(loaded.supportsCraftingQuality())
        end)
    end),

    test.case("manifest loads flavor detection before application modules", function()
        local manifest = readAll("RGMS.toc")
        local firstApplicationFile
        for line in string.gmatch(manifest, "[^\r\n]+") do
            if string.sub(line, 1, 2) ~= "##"
                and string.sub(line, 1, 5) ~= "Libs\\" then
                firstApplicationFile = line
                break
            end
        end

        test.assert_equal(firstApplicationFile, "Core\\ClientFlavor.lua")
    end),
}
