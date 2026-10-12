# Retail Guild Management System

RGMS is a World of Warcraft Retail addon for guild officers who need a local,
read-only view of guild-roster and guild-bank observations. The current MVP
runs entirely inside the game client and stores its latest complete observations
in per-character SavedVariables. It does not send data anywhere.

## What the MVP does

- Scans the guild roster once after login and on demand, then groups members by
  configured guild rank.
- Tracks how long a member has remained at the same numeric rank and retains a
  recently missing member with a warning for up to 21 Pacific calendar days.
- Scans every purchased guild-bank tab that the character can access when the
  default guild-bank window opens or Bank **Refresh** is selected.
- Shows bank contents by tab and tracks how long an item ID and stack count have
  remained in the same slot.
- Commits roster and bank scans transactionally. A partial, failed, timed-out,
  or canceled scan leaves the previous successful observation unchanged.
- Detects a guild change independently for roster and bank data and replaces
  only the affected dataset after a successful scan.
- Validates and migrates versioned per-character saved data. Corrupt or newer,
  incompatible data is preserved until the user accepts `/rgms reset`.
- Saves the RGMS window position independently for each character.

RGMS is **Retail only**. The manifest currently declares interface `120100` in
[`RGMS.toc`](RGMS.toc). A release supports only the live Retail build recorded
in that release's completed QA record; an interface value is updated only after
the addon has been tested on that client build.

## Commands

| Command | Behavior |
| --- | --- |
| `/rgms` | Toggle the main window, selecting Roster when it opens. |
| `/rgms help` | Print the supported command list. |
| `/rgms scanroster` | Start the same roster transaction as Roster **Refresh**. |
| `/rgms reset` | Open a confirmation before clearing roster and bank observations; preserve a valid window position. |

Bank scans are started from the default guild-bank window and the Bank
**Refresh** button. There is no bank scan slash command.

## Install for development

1. Install the current live World of Warcraft Retail client.
2. Clone this repository.
3. Link the checkout into Retail's `Interface/AddOns` directory:
   - Windows: `powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1`
   - macOS: `sh ./scripts/link-addon.sh`
4. Enable **Retail Guild Management System (RGMS)** at character selection and
   log in.
5. Confirm that the RGMS development load message appears, then run
   `/rgms help`.

The complete setup, edit/reload/debug loop, SavedVariables locations, manifest
notes, and troubleshooting steps are in
[`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

## Test

With Lua installed, run the complete dependency-free suite from the repository
root:

```text
lua Tests/run.lua
```

A passing run exits with status `0` and reports zero failures. CI runs the same
suite with Lua 5.1 for every push and pull request. See
[`Tests/README.md`](Tests/README.md) for fixture and test conventions.

Release candidates must also complete the live-client
[`MVP scenario checklist`](docs/MVP_SCENARIO_CHECKLIST.md). Store a completed
copy as described in [`docs/qa/README.md`](docs/qa/README.md); automated tests
do not replace Retail client verification.

## Build a release package

After setting `## Version` in `RGMS.toc`, run the repository-owned release
builder from the repository root:

```text
pwsh ./scripts/build-release.ps1 -Version 0.1.0-rc.1
```

The command runs the complete Lua suite, validates the manifest and runtime
files, builds the archive twice to prove deterministic output, and writes the
verified `RGMS-<version>.zip` under `.release`. It refuses to overwrite an
existing artifact. See [`docs/RELEASING.md`](docs/RELEASING.md) for tagging,
live-client verification, automated draft releases, and manual CurseForge
upload.

## Current exclusions

The MVP has no Classic support, localization, minimap icon, settings panel,
cross-character data sharing, multi-client synchronization, hosted service,
website integration, or data export. The addon does not upload observations or
integrate with an external RGMS application. These are exclusions, not hidden
or partially supported features.

## Contributing and releasing

- [`CONTRIBUTING.md`](CONTRIBUTING.md) maps each subsystem to its code and tests
  and documents architecture and coding conventions.
- [`docs/SAVED_DATA.md`](docs/SAVED_DATA.md) defines the current persisted
  schema, migrations, validation, and recovery behavior.
- [`CHANGELOG.md`](CHANGELOG.md) records user-visible changes.
- [`docs/RELEASING.md`](docs/RELEASING.md) covers versioning, deterministic
  packaging, automated draft GitHub releases, and manual CurseForge uploads.

## License

RGMS is available under the [MIT License](LICENSE). Copyright is held by
`segfaultsoftware`. The project currently bundles no third-party libraries or
assets; dependency and attribution rules are documented in
[`CONTRIBUTING.md`](CONTRIBUTING.md#dependencies-assets-and-attribution).
