# Lua tests

RGMS uses a small dependency-free runner in `Tests/lib/runner.lua`. It targets
the Lua 5.1 language features available to addons in WoW Retail while running
entirely outside the game client. The runner is kept in the repository so a
clean checkout needs only a Lua interpreter and never needs a package download
or network connection to run tests.

Install Lua 5.1 (or a newer Lua version for a quick compatibility check), then
run the complete suite from the repository root with one command:

```text
lua Tests/run.lua
```

Some systems install the executable as `lua5.1`; in that case use that name in
the same command. A passing suite exits with status 0. Any failed assertion or
test-loading error exits non-zero. The CI workflow executes the suite on Lua
5.1 for every push and pull request.

## Add a fixture

Fixture builders live in `Tests/fixtures.lua`. Each builder returns a new table
with fixed defaults and accepts a table of overrides. Defaults must be
deterministic: use explicit UTC timestamps and IDs, and never read `os.time`,
`os.date`, WoW APIs, the filesystem, or the network.

For example:

```lua
function Fixtures.example(overrides)
    return withOverrides({
        id = "example-001",
        observedAt = Fixtures.timestamp(),
    }, overrides)
end
```

The provided builders cover guild identities, roster members and ranks, bank
tabs and slots, and UTC timestamps.

## Add a test

Create a file under `Tests/spec` that returns test cases:

```lua
local fixtures = require("Tests.fixtures")
local test = require("Tests.lib.runner")

return {
    test.case("example behavior", function()
        local guild = fixtures.guild_identity({ name = "My Guild" })
        test.assert_equal(guild.name, "My Guild")
    end),
}
```

Add the module name to `defaultSuites` in `Tests/run.lua`. Available assertions
are `assert_true`, `assert_false`, `assert_nil`, `assert_not_nil`,
`assert_equal` (including nested tables), and `assert_matches`.

Keep business state and date calculations in modules that accept their inputs
as arguments. Put calls to WoW globals in thin adapter modules. No WoW API stub
is needed by the initial suite because all code under test is pure Lua; add the
smallest explicit stub to a test only when a module boundary actually requires
one.

## Confirm failure behavior

The passing suite includes runner self-tests for both successful and failing
assertions. To verify the command-line exit status end to end, run the
deliberately failing example by itself:

```text
lua Tests/run.lua Tests/examples/failing_spec.lua
```

It should print one failure and exit non-zero. The example is not part of the
normal suite.

Tests, fixtures, examples, and generated coverage/results directories are not
listed in `RGMS.toc`. `.pkgmeta` excludes the entire test tree from addon
release packages, while `.gitignore` excludes local result and coverage files.
