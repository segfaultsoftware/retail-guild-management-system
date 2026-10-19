# Saved data model

RGMS uses two World of Warcraft SavedVariables:

- `RGMSAccountDB` is account-wide and contains one isolated partition for every
  guild encountered by the account.
- `RGMSCharacterDB` remains per character. Its `ui` subtree is the live source
  for that character's window placement and numeric dropdown selections. Its roster and bank fields are
  deprecated snapshots. Each is retained until its corresponding successful
  account-wide scan.

The addon's active `RGMS.DB` is a view over the current guild's account
partition plus the logged-in character's `ui` table. It never exposes another
saved guild through the UI. A guildless character receives an empty transient
view and does not create, bind, replace, or erase an account guild partition.

## Account-wide schema: version 3

```text
{
  schemaVersion = 3,
  settings = {
    minimapPos = number,
  },
  guilds = {
    [GuildKey] = {
      identity = GuildIdentity,
      rosterInitialized = boolean,
      roster = RosterDataset,
      bankInitialized = boolean,
      bank = BankDataset,
      mainAltGroups = {
        [MainNameRealm] = { AltNameRealm, ... },
      },
      characterNotes = {
        [CharacterNameRealm] = NoteText,
      },
    },
  },
}
```

`settings.minimapPos` is a finite angle from 0 (inclusive) to 360 (exclusive).
LibDBIcon uses it to place the draggable RGMS button around the current minimap
shape and size. The position is shared by every character on the account.
Version 1 account data gains the default position of 225 degrees, and version 2
renames `minimapAngle` to LibDBIcon's `minimapPos`; both migrations are
copy-on-write, so the original table is left untouched if validation fails.

A `GuildKey` is a deterministic, collision-safe combination of the exact guild
name and the case-insensitive canonical realm slug. Consequently, identically
named guilds on different realms are separate, while realm capitalization and
repeated realm suffixes normalize to the same partition. Guild ID, region, and
display-realm fields remain metadata and do not change ownership.

Roster and bank initialization flags are independent. `false` means no
account-wide decision has been made for that dataset. `true` with empty
collections and no scan timestamp is an intentional empty state, including a
reset state; later migration code must not repopulate it from deprecated
per-character observations. Main/alt groups and character notes are stored in
the same guild partition. The Mains/Alts tab projects group membership from
this partition but limits its character population to the active guild's saved
roster.

Character-note keys use the same case-insensitive canonical character identity
as the roster projection. Saved note text is trimmed, whitespace-only text is
removed, and editor-created notes are limited to 5,500 characters. Grouping,
promotion, and removal update only `mainAltGroups`, so notes remain attached to
their character identities.

## Per-character schema: version 8

```text
{
  schemaVersion = 8,
  roster = DeprecatedRosterDataset,
  bank = DeprecatedBankDataset,
  ui = {
    windowPosition = WindowPosition | nil,
    selectedRosterRankIndex = integer | nil,
    selectedBankTabIndex = positive integer | nil,
  },
}
```

The version 0 through 8 migrations remain supported. Version 8 adds per-character
numeric rank and bank-tab selections, so renaming an option does not invalidate
it. When the current guild's
account-wide roster is uninitialized, only the logged-in character's matching
deprecated roster can seed it. A missing or foreign-guild snapshot initializes
an empty current-guild roster instead. An already initialized roster, including
an intentionally empty reset state, is authoritative and is never repopulated
from another character.

Bank migration is deliberately deferred until the guild bank is open and a scan
is about to start. An uninitialized current-guild bank is seeded only from the
logged-in character's matching deprecated bank; foreign-guild data is ignored.
Once initialized, including as an intentional empty reset state, the account
bank remains authoritative and later characters cannot merge legacy snapshots.

`WindowPosition` contains `point`, `relativePoint`, `x`, and `y`. The active
view references the current character's `ui` subtree, so dragging the window
continues to save independently for every character even though guild data is
shared account-wide.

## Dataset shapes

Roster and bank dataset records retain the existing schema-7 shapes. A
successful observation includes its guild identity and scan timestamp. An
empty uninitialized or reset dataset has empty collections and no guild or
timestamp.

Roster members retain canonical `Name-Realm`, rank, online, observation,
rank-tenure, and missing-member fields. Bank tabs retain access state and
last-access timestamps; occupied bank slots retain item, quantity, icon,
observation, and stable-since fields. Detailed validation and legacy migration
rules remain implemented in `Core/SavedData.lua`.

## Transactional ownership

Roster and Bank scans request a detached copy of the current guild's relevant
account dataset. Roster scans and scans of already initialized banks do not
create or alter a partition when they begin. Immediately before the first
eligible bank scan, bank migration initializes the current-guild partition from
matching legacy data or an empty baseline. Failure, timeout, partial data, or
cancellation then discards the detached scan work while preserving that baseline
and the still-pending per-character bank data.

Only a complete, validated success atomically replaces that one dataset in the
matching guild partition and marks its initialization flag true. A successful
commit also clears the logged-in character's corresponding deprecated dataset
while preserving the other dataset and window position. Failed, incomplete,
timed-out, and canceled scans preserve both the last account-wide observations
and the pending deprecated data. The other account dataset, initialization
flag, groups, notes, and every other guild partition remain unchanged.

## Reset and recovery

Confirming `/rgms reset` while guilded clears the current guild's roster, bank,
groups, and notes. It leaves both dataset initialization flags true, preserves
all other guild partitions and deprecated per-character observations, and
preserves the character's window position. The initialized empty datasets
prevent legacy repopulation; the next successful roster or bank scan removes
only the corresponding deprecated dataset for the current character. A
guildless manual reset is rejected without mutation.

Malformed or unsupported account data disables scans and reports without
overwriting the original. Accepted account recovery creates a fresh account
model and, when a current guild is available, an initialized empty partition.
Per-character recovery continues to retain only a valid window position.

## Guild activation

RGMS resolves the logged-in character's guild at addon load, player login, and
guild-membership changes. Activation initializes the current guild's roster
partition conservatively, selects it for display, and starts the normal roster
scan. A guildless character still receives an empty transient view. Bank
partitions are not initialized during activation or merely by opening RGMS. They
are initialized immediately before an eligible scan after the guild bank opens.

Sharing is limited to the local account's SavedVariables. RGMS performs no
player-to-player synchronization and provides no browser for inactive guilds.
