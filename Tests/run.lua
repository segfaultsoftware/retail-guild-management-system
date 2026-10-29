-- Run from the repository root with: lua Tests/run.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local test = require("Tests.lib.runner")
local defaultSuites = {
    "Tests.spec.runner_spec",
    "Tests.spec.fixtures_spec",
    "Tests.spec.date_time_spec",
    "Tests.spec.saved_data_spec",
    "Tests.spec.account_data_spec",
    "Tests.spec.roster_migration_spec",
    "Tests.spec.bank_migration_spec",
    "Tests.spec.bootstrap_spec",
    "Tests.spec.reset_spec",
    "Tests.spec.dataset_ownership_spec",
    "Tests.spec.commands_spec",
    "Tests.spec.minimap_spec",
    "Tests.spec.libdbicon_spec",
    "Tests.spec.roster_names_spec",
    "Tests.spec.roster_news_spec",
    "Tests.spec.roster_adapter_spec",
    "Tests.spec.roster_tenure_spec",
    "Tests.spec.roster_report_spec",
    "Tests.spec.mains_alts_groups_spec",
    "Tests.spec.mains_alts_tags_spec",
    "Tests.spec.mains_alts_report_spec",
    "Tests.spec.mains_alts_search_spec",
    "Tests.spec.mains_alts_notes_spec",
    "Tests.spec.mains_alts_notes_adapter_spec",
    "Tests.spec.mains_alts_spec",
    "Tests.spec.provisions_model_spec",
    "Tests.spec.auctionator_spec",
    "Tests.spec.provisions_spec",
    "Tests.spec.roster_scanner_spec",
    "Tests.spec.roster_spec",
    "Tests.spec.ui_layout_spec",
    "Tests.spec.portal_spec",
    "Tests.spec.ui_modules_spec",
    "Tests.spec.ui_spec",
    "Tests.spec.bank_adapter_spec",
    "Tests.spec.bank_state_spec",
    "Tests.spec.bank_report_spec",
    "Tests.spec.bank_scanner_spec",
    "Tests.spec.bank_spec",
    "Tests.spec.mvp_integration_spec",
}

local function appendCases(destination, cases, source)
    if type(cases) ~= "table" then
        error(source .. " must return a table of test cases")
    end

    for _, testCase in ipairs(cases) do
        destination[#destination + 1] = testCase
    end
end

local function loadRequestedFile(path)
    local chunk, loadError = loadfile(path)
    if not chunk then
        error(loadError)
    end

    return chunk()
end

local cases = {}
if #arg == 0 then
    for _, moduleName in ipairs(defaultSuites) do
        appendCases(cases, require(moduleName), moduleName)
    end
else
    for _, path in ipairs(arg) do
        appendCases(cases, loadRequestedFile(path), path)
    end
end

local result = test.run(cases)
print(string.format(
    "\n%d tests: %d passed, %d failed",
    result.total,
    result.passed,
    result.failed
))

if result.failed > 0 then
    os.exit(1)
end

os.exit(0)
