# Retail Guild Management System

RGMS is a World of Warcraft Retail addon for guild officers who need a local,
read-only view of guild-roster and guild-bank observations. The current MVP
runs entirely inside the game client and stores its latest complete observations
in account-wide, per-guild SavedVariables. Window placement and deprecated
migration sources remain per character. It does not send data anywhere.

## What the MVP does

- Scans the guild roster once after login and on demand, then groups members by
  configured guild rank.
- Shows and manages roster-backed main/alt groups in a dedicated tab, including
  retained missing members, with expandable groups and no separate scan. Every
  roster character can also keep an account-wide, per-guild note.
- Tracks how long a member has remained at the same numeric rank and retains a
  recently missing member with a warning for up to 21 Pacific calendar days.
- Preserves joins, departures, and numeric rank changes as independently
  acknowledged per-scan News Sets in a right-side drawer.
- Scans every purchased guild-bank tab that the character can access when the
  default guild-bank window opens or Bank **Refresh** is selected.
- Shows bank contents by tab and tracks how long an item ID and stack count have
  remained in the same slot.
- Commits roster and bank scans transactionally. A partial, failed, timed-out,
  or canceled scan leaves the previous successful observation unchanged.
- Shares each guild's roster and bank observations between characters on the
  account while isolating identically named guilds on different realms.
- Validates account-wide guild storage and versioned per-character migration
  sources. Corrupt or newer, incompatible data is preserved until the user
  accepts `/rgms reset`.
- Saves the RGMS window position independently for each character.
- Adds a draggable minimap button using the RGMS logo. Left-clicking it toggles
  the Roster window, and its position is shared account-wide.

RGMS is **Retail only**. The supported interface is declared in
[`RGMS.toc`](RGMS.toc) and is updated during release preparation only after the
addon has been tested on that live Retail client build.

## Commands

| Command | Behavior |
| --- | --- |
| `/rgms` | Toggle the main window, selecting Roster when it opens. |
| `/rgms help` | Print the supported command list. |
| `/rgms debug` | Toggle verbose session-only diagnostic logging. |
| `/rgms scanroster` | Start the same roster transaction as Roster **Refresh**. |
| `/rgms reset` | Open a confirmation before clearing the current guild's roster, bank, groups, notes, and news; preserve the character's window position. |

Bank scans are started from the default guild-bank window and the Bank
**Refresh** button. There is no bank scan slash command.

## Install for development

1. Install the current live World of Warcraft Retail client.
2. Clone this repository.
3. Link the checkout into Retail's `Interface/AddOns` directory:
   - Windows: `powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1`
   - macOS: `sh ./scripts/link-addon.sh`
   - To safely remove the Windows junction later, rerun the command with
     `-Unlink`.
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

The project owner also performs live-client regression testing between tickets.
The [`MVP scenario checklist`](docs/MVP_SCENARIO_CHECKLIST.md) remains available
as a testing reference; it is not a separate release gate.

## Build a local test package

From Git Bash, build and verify a ZIP using the version in `RGMS.toc`:

```text
./scripts/build-local-release.sh
```

The package is written to a timestamped `.release/local-*/RGMS-<version>.zip`
directory. This is intended for local installation and testing; public release
artifacts come from GitHub Actions.

## Prepare and create a release

On a clean `main` branch, use the Git Bash preparation entry point with values
from the tested Retail client:

```text
bash ./scripts/prepare-release.sh \
  --version 1.1.0 \
  --retail-version "12.1.5" \
  --interface 120100
```

The command stores the complete tested Retail version in `RGMS.toc`, updates
the addon version and interface, and promotes the `CHANGELOG.md` Unreleased
section to the target version. After committing and pushing those changes,
dispatch **Create Release** from `main` with the version and full main-tip SHA.
The workflow tests and retains one canonical ZIP, publishes and verifies it on
GitHub, and automatically submits exact final releases to CurseForge.
Prereleases remain GitHub-only. See [`docs/RELEASING.md`](docs/RELEASING.md)
for one-time token setup, the complete procedure, retry behavior, and the
manual fallback.

## Current exclusions

The MVP has no Classic support, localization, settings panel,
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
  packaging, automated GitHub and CurseForge releases, and recovery steps.

## License

RGMS is available under the [MIT License](LICENSE). Copyright is held by
`segfaultsoftware`. The bundled minimap libraries and their licenses are
documented in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md); dependency and
attribution rules are documented in
[`CONTRIBUTING.md`](CONTRIBUTING.md#dependencies-assets-and-attribution).
