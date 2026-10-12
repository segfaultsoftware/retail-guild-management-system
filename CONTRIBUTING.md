# Contributing to RGMS

This guide explains where RGMS behavior lives and how to change it without
crossing the project's architecture boundaries. It applies to the live World
of Warcraft **Retail** client only.

## Start here

1. Follow [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) to link the checkout into
   Retail and enable Lua error dialogs.
2. Install Lua 5.1, or use a newer Lua only as an additional compatibility
   check.
3. Run `lua Tests/run.lua` from the repository root before changing code.
4. Read [`docs/SAVED_DATA.md`](docs/SAVED_DATA.md) before changing any persisted
   field, scan commit, reset, or migration behavior.

No package manager, generated source, or application build is required during
normal development. `RGMS.toc` is the runtime manifest and defines the exact
Lua load order.

## Project map

| Area | Runtime code | Primary tests and documentation |
| --- | --- | --- |
| Startup and addon namespace | `Core/Bootstrap.lua`, `RGMS.toc` | `Tests/spec/mvp_integration_spec.lua`, `docs/DEVELOPMENT.md` |
| Slash commands | `Core/Commands.lua` | `Tests/spec/commands_spec.lua` |
| Saved-data schema, validation, and migrations | `Core/SavedData.lua` | `Tests/spec/saved_data_spec.lua`, `Tests/spec/fixtures_spec.lua`, `docs/SAVED_DATA.md` |
| Reset and recovery | `Core/Reset.lua` | `Tests/spec/reset_spec.lua`, `docs/SAVED_DATA.md` |
| Guild identity and transactional ownership | `Core/Realm.lua`, `Core/DatasetOwnership.lua` | `Tests/spec/dataset_ownership_spec.lua`, `Tests/spec/roster_names_spec.lua` |
| Pacific dates and timestamps | `Core/DateTime.lua` | `Tests/spec/date_time_spec.lua`, `Tests/date_fixtures.lua` |
| Roster Retail adapter and event wiring | `Roster/Roster.lua` | `Tests/spec/roster_adapter_spec.lua`, `Tests/spec/roster_spec.lua` |
| Roster scan coordinator | `Roster/Scanner.lua` | `Tests/spec/roster_scanner_spec.lua` |
| Roster identity, tenure, missing-member rules, and report model | `Roster/Names.lua`, `Roster/Tenure.lua`, `Roster/Report.lua` | `Tests/spec/roster_names_spec.lua`, `Tests/spec/roster_tenure_spec.lua`, `Tests/spec/roster_report_spec.lua` |
| Bank Retail adapter and event wiring | `Bank/Bank.lua` | `Tests/spec/bank_adapter_spec.lua`, `Tests/spec/bank_spec.lua` |
| Bank scan coordinator | `Bank/Scanner.lua` | `Tests/spec/bank_scanner_spec.lua` |
| Bank slot stability and report model | `Bank/State.lua`, `Bank/Report.lua` | `Tests/spec/bank_state_spec.lua`, `Tests/spec/bank_report_spec.lua` |
| Window rendering and interaction | `UI/UI.lua` | `Tests/spec/ui_spec.lua` |
| Pure window geometry | `UI/Layout.lua` | `Tests/spec/ui_layout_spec.lua` |
| Cross-subsystem MVP scenarios | all layers | `Tests/spec/mvp_integration_spec.lua`, `Tests/mvp_fixtures.lua`, `docs/MVP_SCENARIO_CHECKLIST.md` |
| Test runner and reusable fixtures | `Tests/lib/runner.lua`, `Tests/fixtures.lua`, `Tests/run.lua` | `Tests/spec/runner_spec.lua`, `Tests/README.md` |

## Architecture boundaries

### Addon namespace and load order

WoW passes every manifest-loaded file the same private `RGMS` table. Runtime
modules publish their narrow public surface on that table. Do not create new
globals; `RGMSCharacterDB` and WoW's slash-command registration globals are the
intentional exceptions.

When adding or moving a runtime file, update `RGMS.toc` so dependencies load
before consumers. Test files, development scripts, and documentation must not
be added to the manifest.

### Retail API adapters

Calls to roster globals and `C_Club`/`C_GuildInfo` belong in
`Roster/Roster.lua`. Calls to guild-bank globals belong in `Bank/Bank.lua`.
Those two modules translate potentially partial client state into complete
plain-Lua snapshots and wire Retail events to the scan coordinators.

Do not move WoW globals into reducers, report builders, or scanners. A new WoW
API dependency should be wrapped by the relevant adapter and represented by the
smallest explicit test stub in an adapter test. UI-only frame APIs remain in
`UI/UI.lua`; pure placement calculations remain in `UI/Layout.lua`.

### Transactions and pure state

`Roster/Scanner.lua` and `Bank/Scanner.lua` coordinate requests, timeouts,
cancellation, and completion through injected dependencies. They must not
publish partial observations.

`Core/DatasetOwnership.lua` creates a detached working dataset and commits only
a complete success through `Core/SavedData.lua`. Failure and cancellation must
leave the previously committed dataset unchanged. Roster tenure and bank slot
stability rules live in their pure reducers, not in event handlers or UI code.

Reports convert committed datasets into view models. The UI renders those
models and owns interaction state; it does not decide persistence or scan
semantics.

### Saved data

`RGMSCharacterDB` is declared with `SavedVariablesPerCharacter`. Any persisted
shape change requires all of the following:

1. Increment `SavedData.CURRENT_SCHEMA_VERSION`.
2. Add a deterministic migration from the immediately previous version.
3. Keep loading copy-on-write so invalid data remains untouched.
4. Update validation, fixtures, migration tests, and `docs/SAVED_DATA.md`.
5. Verify reset/recovery and cross-character isolation in the live checklist.

Never silently discard unknown or malformed data during load. A reset must
remain user-confirmed and preserve only the explicitly valid UI subtree.

## Coding conventions

- Use Lua 5.1-compatible syntax and the runtime APIs available in live Retail.
- Prefer `local` values and small module tables. Share runtime state only
  through the private `RGMS` namespace.
- Keep operating-system, filesystem, network, and normal Lua package-library
  calls out of addon runtime code; WoW does not expose them.
- Pass dates, clocks, adapters, and side effects into pure modules so tests stay
  deterministic.
- Treat a Retail collection as incomplete until every required identity,
  member, rank, tab, or slot field is available. Do not commit best-effort
  fragments.
- Store UTC timestamps and derive user-facing Pacific dates through
  `Core/DateTime.lua`; do not read the workstation timezone.
- Preserve existing public messages and UI state unless the change explicitly
  updates their tested behavior.
- Add a focused regression test for every observable bug fix and tests for each
  new acceptance criterion.
- Keep source and documentation as plain UTF-8 text. Avoid unrelated formatting
  changes.

## Edit, reload, and debug

With the checkout linked into `_retail_/Interface/AddOns/RGMS`:

1. Enable error dialogs with `/console scriptErrors 1`, then `/reload`.
2. Edit a Lua or manifest file in the checkout and save it.
3. Enter `/reload` to reload every addon file. Restart or return to character
   selection after adding or moving the addon directory itself.
4. Reproduce with only RGMS enabled when investigating an interaction.
5. Capture the first Lua error, including file, line, Retail build from
   `/dump GetBuildInfo()`, and exact reproduction steps.
6. Use `/reload` or log out to flush SavedVariables, then fully close Retail
   before inspecting `RGMS.lua`. Do not share account or character identifiers.

The exact installation and SavedVariables paths are in
[`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

## Automated tests

Run the full suite from the repository root:

```text
lua Tests/run.lua
```

Expected result: exit status `0` and a summary with zero failed tests. CI runs
`lua5.1 Tests/run.lua` on every push and pull request.

To verify that the runner propagates failures:

```text
lua Tests/run.lua Tests/examples/failing_spec.lua
```

Expected result: one intentional failure and a non-zero exit status. Do not add
that example to the default suites. See [`Tests/README.md`](Tests/README.md) for
fixture patterns, assertions, and suite registration.

## Manual QA and recorded evidence

Automated tests cannot reproduce Retail event timing, guild permissions,
SavedVariables flushing, or the default guild-bank UI. For a release candidate:

1. Copy `docs/MVP_SCENARIO_CHECKLIST.md` to
   `docs/qa/<version>-<tester>.md`, for example
   `docs/qa/0.1.0-rc.1-segfaultsoftware.md`.
2. Fill every Test record field and every Observed result/evidence line while
   executing the checklist. Do not check an item from memory.
3. Record `PASS`, `FAIL`, or `BLOCKED`, with an owner for each blocker.
4. Remove private account and character identifiers from evidence.
5. Commit the completed record with the release-candidate work. Large images or
   videos should be attached to the corresponding GitHub issue or release and
   linked from the record instead of committed.

A second person must follow the contributor setup and dry-run the release
runbook through creation and inspection of an unpublished package before the
first public release. Record that person's result the same way.

## Dependencies, assets, and attribution

RGMS currently bundles no third-party libraries, code, fonts, icons, textures,
audio, or other assets. WoW Retail APIs are platform APIs, not bundled project
dependencies. The test runner and fixtures are project-owned source.

Before adding a dependency or asset:

- verify that its license permits redistribution in an MIT-licensed project;
- retain its required copyright and license notices;
- document its name, version or source revision, source URL, license, and use in
  this section or a dedicated `THIRD_PARTY_NOTICES.md`;
- ensure the distributable ZIP contains any notice the dependency requires;
- add only the files needed at runtime and update `.pkgmeta` deliberately.

Do not copy Blizzard or third-party artwork into the repository without clear
redistribution permission.

## Release-related changes

User-visible changes belong under `Unreleased` in [`CHANGELOG.md`](CHANGELOG.md).
Do not create or move release tags casually: the packaging tool derives the
version and changelog range from Git tags. Maintainers should use the complete
[`docs/RELEASING.md`](docs/RELEASING.md) runbook.
