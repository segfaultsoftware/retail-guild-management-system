# Saved data model

RGMS persists one global named `RGMSCharacterDB`. `RGMS.toc` declares it with
`SavedVariablesPerCharacter`, so World of Warcraft stores a separate value for
each `CharacterName-Realm`. RGMS does not add an account-level character map;
observations from two characters therefore cannot be combined accidentally.

## Current schema: version 7

The complete persisted shape is:

```text
{
  schemaVersion = 7,
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
compares the exact guild name and a case-insensitive canonical realm value; the
other fields are metadata. Repeated realm suffixes, including values truncated
partway through a final repetition, are collapsed before persistence.

Each `RosterRank` stores its one-based guild-order `index`, displayed `name`,
and the subset of rank permissions already represented by RGMS. Every
configured rank is retained, including Guild Master and ranks with no current
members. Each `RosterMember` stores the character and realm components plus a
canonical `displayName` in `Name-Realm` form, the current displayed `rankName`
and one-based `rankIndex`, basic character metadata, online state, and the scan
timestamp in `observedAt`. `rankTenureStartDate` stores the Pacific
`YYYY-MM-DD` date on which that `Name-Realm` was first successfully observed at
its current numeric rank index. Rank-name changes preserve it; a different
rank index resets it. Tenure days are derived from this date rather than stored.
`lastSeenDate` stores the Pacific `YYYY-MM-DD` date of the member's most recent
appearance in a successful roster scan, and `isMissing` identifies records
retained after an absence. Missing records keep their last observation and
rank-tenure start date, remain under the current rank at their former numeric
index, and carry their stored last-online age forward between successful scans.
They are retained through 21 missing calendar days and removed on a later
successful scan after that threshold. Reappearance clears `isMissing` and
restarts rank tenure even when the numeric rank is unchanged.
An offline member may include the game's approximate `lastOnline` components
(`years`, `months`, `days`, and `hours`); an absent value does not invent
precision the client did not provide. Collection records use the shapes built
in `Tests/fixtures.lua` and checked by `Core/SavedData.lua`.

Each `BankTab` is identified by its one-based numeric position and stores the
latest name, icon, access metadata, and optional `lastAccessibleAt` timestamp.
Every successful accessible observation updates that timestamp, including for
empty tabs; inaccessible observations preserve it, while a never-accessible tab
has no timestamp. Each occupied `BankSlot` is identified independently by
numeric tab and numeric slot. It stores the basic item ID, stack count, item
link, optional cached icon, last accessible observation timestamp, and a
Pacific `YYYY-MM-DD` `stableSinceDate`. A matching item ID and count at the
same location preserve that date; replacement, count changes, movement into a
new slot, and refilling an emptied slot reset it to the successful scan date.
Age is derived from the date and is never persisted. Inaccessible tabs retain
their last accessible slot state while their current access metadata is saved;
when access returns, the next observation compares with that retained state.
Tab renames and icon changes do not affect slot identity.

`WindowPosition` contains `point`, `relativePoint`, `x`, and `y`. It lives
under the separate `ui` subtree. Resetting observations creates empty roster
and bank datasets but deep-copies this subtree, allowing data resets and future
migrations to preserve the user's window placement. Replacing one dataset after
a detected guild change likewise deep-copies the complete valid model before
clearing that dataset, so it cannot move the window or alter the other dataset.

Only the latest complete roster and bank state is retained. The roster state
may include members carried forward under the missing-member retention rule;
it does not include prior daily snapshots. Scan histories and unknown fields
are rejected rather than carried forward silently.

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
`RGMSCharacterDB` only after the copy reaches schema version 7 and passes full
validation. A fresh character receives a valid empty version 7 model.

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
- Schema version 2 roster members did not store `rankTenureStartDate`.
  Migration initializes it to the Pacific date of that member's saved
  `observedAt` timestamp, the earliest observation available in the retained
  snapshot.
- Schema version 3 roster members did not store `lastSeenDate` or `isMissing`.
  Migration initializes the date from each member's saved `observedAt`
  timestamp and marks every migrated member current.
- Schema version 4 could persist repeated realm suffixes returned by the game,
  including suffixes truncated at the client string limit. Migration
  canonicalizes roster and bank guild realms, canonicalizes member realms and
  display names, and coalesces equivalent members. When both a current and a
  retained-missing duplicate exist, the current observation wins.
- Schema version 5 bank slots did not store `stableSinceDate`. Migration
  initializes it to the Pacific date of each slot's saved `observedAt`
  timestamp, preserving the only retained observation available.
- Schema version 6 bank tabs did not store `lastAccessibleAt`, and bank slots
  did not cache their icon. Migration initializes accessible tabs from the
  overall bank scan timestamp and inaccessible tabs from their newest retained
  slot observation when one exists. Never-accessible empty tabs remain without
  a timestamp; item icons are populated by the next successful scan.
- The pre-schema development placeholder contained only `loadCount` and/or
  `lastLoadedAt`. Those diagnostic values did not contain observations and are
  migrated to a fresh empty version 7 model. Any other unversioned shape is
  preserved and classified as corrupt.

Every migration is deterministic and operates on a deep copy. There is no
best-effort migration that discards fields it does not recognize.
