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
| UI facade and cross-feature coordination | `UI/UI.lua` | `Tests/spec/ui_modules_spec.lua`, `Tests/spec/ui_spec.lua`, `docs/PORTAL_UI.md` |
| Root window, navigation, positioning, and scan overlay | `UI/Window.lua` | `Tests/spec/ui_modules_spec.lua`, `Tests/spec/ui_spec.lua` |
| Shared UI widgets and styling | `UI/Widgets.lua` | `Tests/spec/ui_modules_spec.lua`, `Tests/spec/ui_spec.lua` |
| Roster ByName, ByTenure, and tag popovers | `UI/Roster/ByName.lua`, `UI/Roster/ByTenure.lua`, `UI/Roster/TagPopovers.lua` | `Tests/spec/ui_modules_spec.lua`, `Tests/spec/ui_spec.lua` |
| Tags, bank, and provisions views | `UI/Tags.lua`, `UI/Bank.lua`, `UI/Provisions.lua`, `UI/ProvisionDrag.lua` | `Tests/spec/ui_modules_spec.lua`, `Tests/spec/ui_spec.lua` |
| Notes, News, tooltips, and toasts | `UI/Notes.lua`, `UI/News.lua`, `UI/Tooltip.lua`, `UI/Toast.lua` | `Tests/spec/ui_modules_spec.lua`, `Tests/spec/ui_spec.lua` |
| Pure window geometry | `UI/Layout.lua` | `Tests/spec/ui_layout_spec.lua` |
| Minimap button and placement | `Core/Minimap.lua` | `Tests/spec/minimap_spec.lua` |
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
smallest explicit test stub in an adapter test. UI-only frame APIs belong in
the component identified in `docs/PORTAL_UI.md`; the `UI/UI.lua` facade retains
only cross-feature coordination. Pure placement calculations remain in
`UI/Layout.lua`.

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

On Windows, run the full suite from Git Bash at the repository root:

```text
lua.exe Tests/run.lua
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

## Manual regression testing

Automated tests cannot reproduce Retail event timing, guild permissions,
SavedVariables flushing, or the default guild-bank UI. The project owner runs
live-client regression testing between tickets and may use
[`docs/MVP_SCENARIO_CHECKLIST.md`](docs/MVP_SCENARIO_CHECKLIST.md) as the test
reference. Record observations from the exact checkout or package under test,
never from memory, and remove private account and character identifiers from
any shared evidence. Large images or videos belong on the corresponding GitHub
issue or release rather than in the repository.

## Dependencies, assets, and attribution

RGMS bundles LibDBIcon-1.0 and its minimal runtime dependencies: LibStub,
CallbackHandler-1.0, and LibDataBroker-1.1. Their versions, source, license, and
included files are recorded in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
RGMS otherwise bundles no third-party code, fonts, icons, textures, audio, or
other assets. WoW Retail APIs are platform APIs, not bundled project
dependencies. The test runner and fixtures are project-owned source.

Before adding a dependency or asset:

- verify that its license permits redistribution in an MIT-licensed project;
- retain its required copyright and license notices;
- document its name, version or source revision, source URL, license, and use in
  this section or a dedicated `THIRD_PARTY_NOTICES.md`;
- ensure the distributable ZIP contains any notice the dependency requires;
- add only the files needed at runtime and update the explicit distribution
  allowlist in `scripts/build-release.ps1` deliberately.

Do not copy Blizzard or third-party artwork into the repository without clear
redistribution permission.

## Release-related changes

User-visible changes belong under `Unreleased` in [`CHANGELOG.md`](CHANGELOG.md).
Do not create or move release tags manually. The **Create Release** workflow
builds the verified package, creates the matching `v<version>` tag, and
publishes the GitHub release; exact `X.Y.Z` finals then submit the same verified
ZIP to CurseForge, while all SemVer prereleases remain GitHub-only. The version
and stored Retail build must match `RGMS.toc` and the promoted changelog
section. Maintainers should use the complete
[`docs/RELEASING.md`](docs/RELEASING.md) runbook, including its repository
secret setup and failed-job retry procedure.
