# Saved data model

RGMS persists one global named `RGMSCharacterDB`. `RGMS.toc` declares it with
`SavedVariablesPerCharacter`, so World of Warcraft stores a separate value for
each `CharacterName-Realm`. RGMS does not add an account-level character map;
observations from two characters therefore cannot be combined accidentally.

## Current schema: version 1

The complete persisted shape is:

```text
{
  schemaVersion = 1,
  roster = {
    guild = GuildIdentity | nil,
    scannedAt = Timestamp | nil,
    ranks = { RosterRank, ... },
    members = { RosterMember, ... },
  },
  bank = {
    guild = GuildIdentity | nil,
    scannedAt = Timestamp | nil,
    tabs = { BankTab, ... },
    slots = { BankSlot, ... },
  },
  ui = {
    windowPosition = WindowPosition | nil,
  },
}
```

Lua does not serialize keys whose value is `nil`, so a fresh model contains
empty `ranks`, `members`, `tabs`, and `slots` arrays while the nullable fields
are absent. `guild` and `scannedAt` must either both be present or both be
absent. Observations are invalid without both. Each roster and bank dataset has
its own guild identity so scans made while the character changes guild cannot
be mistaken for one another.

`Timestamp` contains an integer `unixSeconds` and its UTC
`YYYY-MM-DDTHH:MM:SSZ` rendering in `iso8601`. `GuildIdentity` contains the
guild `id`, `name`, `region`, and a `realm` with `name` and `slug`. Collection
records use the shapes built in `Tests/fixtures.lua` and checked by
`Core/SavedData.lua`.

`WindowPosition` contains `point`, `relativePoint`, `x`, and `y`. It lives
under the separate `ui` subtree. Resetting observations creates empty roster
and bank datasets but deep-copies this subtree, allowing data resets and future
migrations to preserve the user's window placement.

Only the latest complete roster and bank observations are retained. Daily
snapshots, scan histories, and unknown fields are rejected rather than carried
forward silently.

## Loading, validation, and recovery

All existing values are copied before migration and validation. RGMS replaces
`RGMSCharacterDB` only after the copy reaches schema version 1 and passes full
validation. A fresh character receives a valid empty version 1 model.

Unsupported future versions enter the `incompatible` state. Malformed values,
unknown unversioned values, and failed migrations enter the `corrupt` state.
In either state, `RGMS.DB` remains unavailable so scans and reports cannot use
unsafe data, and the original `RGMSCharacterDB` value remains untouched. The
chat message on load reports the disabled state and reason.

To recover manually, log out or exit so WoW flushes SavedVariables, make a
backup of that character's `SavedVariables/RGMS.lua`, and inspect or replace it
while the client is closed. Deleting that one character's file makes the next
load initialize an empty model. Keep the backup when diagnosing a migration or
validation bug; do not share account or character names from its path.

## Supported migrations

- Schema version 0 used `guildIdentity` and `scanTimestamp` within each
  dataset and stored `windowPosition` at the top level. Migration renames those
  fields, moves the window position under `ui`, and then validates version 1.
- The pre-schema development placeholder contained only `loadCount` and/or
  `lastLoadedAt`. Those diagnostic values did not contain observations and are
  migrated to a fresh empty version 1 model. Any other unversioned shape is
  preserved and classified as corrupt.

Every migration is deterministic and operates on a deep copy. There is no
best-effort migration that discards fields it does not recognize.
