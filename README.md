# Retail Guild Management System

RGMS is a World of Warcraft addon for guild officers on Retail and Blizzard's
official Forever client who need a local, read-only view of guild-roster and
guild-bank observations. The current MVP runs entirely inside the game client
and stores its latest complete observations in account-wide, per-guild
SavedVariables. Window placement and deprecated migration sources remain per
character. It does not send data anywhere.

## What the MVP does

- Scans the guild roster once after login and on demand, then groups members by
  configured guild rank.
- Opens Roster in its grouped character presentation, where officers can manage
  main/alt groups, search characters, filter tags, and keep account-wide,
  per-guild notes. **By rank** switches the same tab to rank-and-tenure cohorts;
  both presentations share the roster scan and exclude retained missing records.
- Tracks how long a member has remained at the same numeric rank and retains a
  recently missing member with a warning for up to 21 Pacific calendar days.
- Preserves joins, departures, and numeric rank changes as independently
  acknowledged per-scan News Sets in a right-side drawer.
- Scans every purchased guild-bank tab that the character can access when the
  default guild-bank window opens or Bank **Refresh** is selected.
- Shows bank contents by tab and tracks how long an item ID and stack count have
  remained in the same slot.
- Tracks unlimited per-guild Provisions targets by localized item name and,
  on Retail, Midnight crafting quality. Progress comes from the latest complete
  guild-bank snapshot, including retained inaccessible-tab contents, and users
  can drag rows into one persistent account-wide order per guild.
- Commits roster and bank scans transactionally. A partial, failed, timed-out,
  or canceled scan leaves the previous successful observation unchanged.
- Shares each guild's roster, bank observations, and Provisions between
  characters on the account while isolating product-, region-, and
  realm-specific guild identities.
- Validates account-wide guild storage and versioned per-character migration
  sources. Corrupt or newer, incompatible data is preserved until the user
  accepts `/rgms reset`.
- Saves the RGMS window position independently for each character.
- Adds a draggable minimap button using the RGMS logo. Left-clicking it toggles
  the Roster window, and its position is shared account-wide.

RGMS supports current live **Retail** and **Forever** from the same
[`RGMS.toc`](RGMS.toc), source load graph, and release artifact. The manifest's
Retail and Forever interfaces and version/build metadata are set from values
captured immediately before that exact artifact is built and tested in both
clients.

## Commands

| Command | Behavior |
| --- | --- |
| `/rgms` | Toggle the main window, selecting Roster when it opens. |
| `/rgms help` | Print the supported command list. |
| `/rgms debug` | Toggle verbose session-only diagnostic logging. |
| `/rgms scanroster` | Start the same roster transaction as Roster **Refresh**. |
| `/rgms dumpbanktab N` | Print the active guild's stored tab and slot records for guild-bank tab `N`. |
| `/rgms reset` | Open a confirmation before clearing the current guild's roster, bank, provisions, groups, notes, and news; preserve the character's window position. |

Bank scans are started from the default guild-bank window and the Bank
**Refresh** button. There is no bank scan slash command.

## Install for development

1. Install the current live Retail or Forever client. Install both when
   validating shared-client support.
2. Clone this repository.
3. Link the checkout into the client's `Interface/AddOns` directory:
   - Windows Retail: `powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Retail`
   - Windows Forever: `powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Forever`
   - To safely remove a Windows junction later, rerun the same command with
     `-Unlink` while retaining its required product switch.
4. Enable **Retail Guild Management System (RGMS)** at character selection and
   log in.
5. Confirm that the RGMS development load message appears, then run
   `/rgms help`.

Exactly one product switch is required for linking and unlinking: `-Retail`
selects `_retail_`, and `-Forever` selects `_forever_`. Both links use the same
checkout and shared manifest.

The complete setup, edit/reload/debug loop, SavedVariables locations, manifest
notes, and troubleshooting steps are in
[`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

## Test

On Windows, run the complete dependency-free suite from Git Bash at the
repository root:

```text
lua.exe Tests/run.lua
```

A passing run exits with status `0` and reports zero failures. CI runs the same
suite with Lua 5.1 for every push and pull request. See
[`Tests/README.md`](Tests/README.md) for fixture and test conventions.

The project owner also performs live-client regression testing in both
supported products between tickets. The
[`staged core-beta checklist`](docs/MVP_SCENARIO_CHECKLIST.md) is the durable
Retail and Forever validation procedure. Its completed evidence gates a staged
dual-client beta but is not an automatic input to the release workflow.

## Build a local test package

From Git Bash, build and verify a ZIP using the version in `RGMS.toc`:

```text
./scripts/build-local-release.sh
```

The package is written to a timestamped `.release/local-*/RGMS-<version>.zip`
directory. The builder validates comma-delimited interface metadata and, when
the shared manifest uses `standard` or `camelot` inline load directives,
includes every shared and conditional runtime file exactly once without
rewriting the manifest. It still produces one package rather than generated or
product-specific TOCs and archives. This is intended for local installation
and testing; public release artifacts come from GitHub Actions.

## Prepare and create a release

On each tested client, Retail and Forever, collect the version/build and numeric
interface values in chat:

```text
/dump GetBuildInfo()
/dump select(4, GetBuildInfo())
```

Then, on a clean `main` branch, pass the exact observed values to the Git Bash
preparation entry point. Replace the representative values below with the
values from the clients being released:

```text
bash ./scripts/prepare-release.sh \
  --version 1.1.0 \
  --retail-version "12.1.6 (build 22222)" \
  --retail-interface 120106 \
  --forever-version "1.60.2 (build 33333)" \
  --forever-interface 16002
```

The command stores both complete tested version/build values in `RGMS.toc`,
writes the interfaces in deterministic Retail-then-Forever order, updates the
addon version, and promotes the `CHANGELOG.md` Unreleased section in the same
rollback-protected operation. After committing and pushing those changes,
dispatch **Create Release** from `main` with the version. The workflow pins the
dispatch SHA, tests and retains one canonical ZIP, and publishes and verifies
it on GitHub. Exact final releases upload that same checksum-verified ZIP once
to CurseForge with the exact Retail and Forever targets; prereleases remain
GitHub-only. See [`docs/RELEASING.md`](docs/RELEASING.md) for one-time token
setup, the complete procedure, retry behavior, and the manual fallback.

## Current exclusions

The MVP does not support Classic products other than Forever, localization, a
settings panel, multi-client synchronization, a hosted service, website
integration, or data export. The addon does not upload observations or
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
