# Saved data model

RGMS persists one global named `RGMSCharacterDB`. `RGMS.toc` declares it with
`SavedVariablesPerCharacter`, so World of Warcraft stores a separate value for
each `CharacterName-Realm`. RGMS does not add an account-level character map;
observations from two characters therefore cannot be combined accidentally.

## Current schema: version 2

The complete persisted shape is:

```text
{
  schemaVersion = 2,
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
guild `id`, `name`, `region`, and a `realm` with `name` and `slug`. The `slug`
stores the normalized realm value supplied by the Retail API. Dataset ownership
compares the exact guild name and this normalized realm value; the other fields
are metadata.

Each `RosterRank` stores its one-based guild-order `index`, displayed `name`,
and the subset of rank permissions already represented by RGMS. Every
configured rank is retained, including Guild Master and ranks with no current
members. Each `RosterMember` stores the character and realm components plus a
canonical `displayName` in `Name-Realm` form, the current displayed `rankName`
and one-based `rankIndex`, basic character metadata, online state, and the scan
timestamp in `observedAt`. An offline member may include the game's approximate
`lastOnline` components (`years`, `months`, `days`, and `hours`); an absent
value does not invent precision the client did not provide. Collection records
use the shapes built in `Tests/fixtures.lua` and checked by
`Core/SavedData.lua`.

`WindowPosition` contains `point`, `relativePoint`, `x`, and `y`. It lives
under the separate `ui` subtree. Resetting observations creates empty roster
and bank datasets but deep-copies this subtree, allowing data resets and future
migrations to preserve the user's window placement. Replacing one dataset after
a detected guild change likewise deep-copies the complete valid model before
clearing that dataset, so it cannot move the window or alter the other dataset.

Only the latest complete roster and bank observations are retained. Daily
snapshots, scan histories, and unknown fields are rejected rather than carried
forward silently.

## Transactional dataset ownership

Roster and Bank create independent working transactions. A transaction for the
same guild receives a detached copy of that dataset as its baseline. A first
binding or different guild receives an empty baseline, but the saved model is
not changed at that point. Only a complete, valid success replaces the relevant
dataset. Failure, cancellation, and an unavailable guild identity discard the
working data without changing saved observations or ownership.

A different guild is recognized only when a previously bound dataset's exact
guild name or normalized realm value differs. Its successful commit prints the
dataset-specific reset message. The replacement deep-copies the other dataset
and UI state, so roster and bank may refer to different guilds and window
position survives every automatic replacement.

## Loading, validation, and recovery

All existing values are copied before migration and validation. RGMS replaces
`RGMSCharacterDB` only after the copy reaches schema version 2 and passes full
validation. A fresh character receives a valid empty version 2 model.

Unsupported future versions enter the `incompatible` state. Malformed values,
unknown unversioned values, and failed migrations enter the `corrupt` state.
In either state, `RGMS.DB` remains unavailable so scans and reports cannot use
unsafe data, and the original `RGMSCharacterDB` value remains untouched. The
chat message on load reports the disabled state and reason, and RGMS opens its
reset confirmation. Declining keeps the original value unchanged and leaves
scans and reports disabled. Accepting replaces it with a valid empty model and
immediately re-enables RGMS. A later UI reload therefore retains either the
disabled original or the accepted empty replacement.

`/rgms reset` opens the same confirmation without changing data immediately.
Accepting clears both datasets' collections, guild identities, and scan
timestamps for the current character only. Canceling changes nothing. A valid
saved window position is deep-copied into the replacement, including during
recovery from an otherwise corrupt or unsupported-version model. An invalid
window position cannot be put into the valid replacement and is discarded.

For diagnosis, log out or exit so WoW flushes SavedVariables, make a backup of
that character's `SavedVariables/RGMS.lua`, and inspect it while the client is
closed. Keep the backup when investigating a migration or validation bug; do
not share account or character names from its path.

## Supported migrations

- Schema version 0 used `guildIdentity` and `scanTimestamp` within each
  dataset and stored `windowPosition` at the top level. Migration renames those
  fields, moves the window position under `ui`, and continues through the
  version 1 migration.
- Schema version 1 roster members did not store canonical display names,
  displayed rank names, or approximate last-online components. Migration
  derives `displayName` and `rankName` from the existing member, realm, and
  configured-rank data; prior last-online precision remains unknown.
- The pre-schema development placeholder contained only `loadCount` and/or
  `lastLoadedAt`. Those diagnostic values did not contain observations and are
  migrated to a fresh empty version 2 model. Any other unversioned shape is
  preserved and classified as corrupt.

Every migration is deterministic and operates on a deep copy. There is no
best-effort migration that discards fields it does not recognize.
