local moduleName = ...

local Exporter = {}

local function loadFixtures(scriptPath)
    scriptPath = tostring(scriptPath or ""):gsub("\\", "/")
    local repositoryPath = scriptPath:match("^(.*)/scripts/[^/]+$") or "."
    package.path = repositoryPath .. "/?.lua;" .. package.path

    local loaded, fixturesOrError = pcall(
        require,
        "Tests.runtime_contract_fixtures"
    )
    if not loaded then
        return nil,
            "could not load the runtime-contract schema: "
                .. tostring(fixturesOrError)
    end
    return fixturesOrError
end

function Exporter.run(arguments, options)
    arguments = arguments or {}
    options = options or {}
    if #arguments ~= 2 then
        return nil,
            "Usage: lua scripts/export-runtime-probe.lua <SavedVariables.lua> <output.lua>",
            2
    end

    local fixtures = options.fixtures
    local fixturesError
    if not fixtures then
        fixtures, fixturesError = loadFixtures(
            options.scriptPath or arguments[0]
        )
    end
    if not fixtures then
        return nil, fixturesError, 1
    end

    local inputPath = arguments[1]
    local outputPath = arguments[2]
    if inputPath == outputPath then
        return nil, "input and output paths must differ", 1
    end
    local existingOutput = io.open(outputPath, "rb")
    if existingOutput then
        existingOutput:close()
        return nil,
            "refusing to overwrite an existing output path: " .. outputPath,
            1
    end

    local export, loadError = fixtures.loadSavedVariables(inputPath)
    if not export then
        return nil, loadError, 1
    end
    if export.complete ~= true then
        return nil,
            "RGMSRuntimeProbeExport is not finalized; run /rgmsprobe stop and export in the client",
            1
    end
    if export.truncated == true then
        return nil,
            "RGMSRuntimeProbeExport is truncated and cannot be used as evidence",
            1
    end

    local source, formatError = fixtures.format(export)
    if not source then
        return nil, formatError, 1
    end

    local output, openError = io.open(outputPath, "wb")
    if not output then
        return nil,
            "could not open " .. outputPath .. " for writing: "
                .. tostring(openError),
            1
    end
    local wrote, writeError = output:write(source)
    local closed, closeError = output:close()
    if not wrote or not closed then
        os.remove(outputPath)
        return nil,
            "could not write " .. outputPath .. ": "
                .. tostring(writeError or closeError),
            1
    end

    return true,
        "Wrote sanitized runtime probe export to " .. outputPath,
        0
end

if moduleName == "scripts.export-runtime-probe" then
    return Exporter
end

local succeeded, message, exitCode = Exporter.run(arg, {
    scriptPath = arg and arg[0],
})
if not succeeded then
    io.stderr:write("export-runtime-probe: " .. tostring(message) .. "\n")
    os.exit(exitCode or 1)
end
io.stdout:write(message .. "\n")
