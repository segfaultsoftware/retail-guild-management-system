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

## Account-wide schema: version 7

```text
{
  schemaVersion = 7,
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
      tags = {
        definitions = {
          [NormalizedTagName] = true,
        },
        assignments = {
          [CharacterNameRealm] = {
            [NormalizedTagName] = true,
          },
        },
      },
      rosterObservation = RosterNewsObservation | nil,
      newsSets = { RosterNewsSet, ... },
      provisions = {
        { id = positive integer, name = string,
          quality = "silver" | "gold" | "either",
          target = integer from 1 through 99999 },
        ...
      },
      nextProvisionId = positive integer,
    },
  },
}
```

`settings.minimapPos` is a finite angle from 0 (inclusive) to 360 (exclusive).
LibDBIcon uses it to place the draggable RGMS button around the current minimap
shape and size. The position is shared by every character on the account.
Version 1 account data gains the default position of 225 degrees, and version 2
renames `minimapAngle` to LibDBIcon's `minimapPos`. Version 3 data gains an
empty-assignment tag catalog containing the required `me` definition. All
migrations are copy-on-write, so the original table is left untouched if
validation fails. Version 4 data gains an empty News Set collection and no
raw-observation baseline, so its first successful scan establishes the baseline
without manufacturing historical news. Version 5 data gains an empty provision
list and a next-ID value of 1 for every saved guild. Provision IDs are never
reused within a partition, so exact duplicates remain independently selectable
and movable. Version 6 provision arrays are converted once to the previously
visible case-insensitive item-name order, with creation ID breaking equal-name
ties; version 7 preserves that array as the guild's authoritative manual order.

A `GuildKey` is a deterministic, collision-safe combination of the exact guild
name and the case-insensitive canonical realm slug. Consequently, identically
named guilds on different realms are separate, while realm capitalization and
repeated realm suffixes normalize to the same partition. Guild ID, region, and
display-realm fields remain metadata and do not change ownership.

Roster and bank initialization flags are independent. `false` means no
account-wide decision has been made for that dataset. `true` with empty
collections and no scan timestamp is an intentional empty state, including a
reset state; later migration code must not repopulate it from deprecated
per-character observations. Main/alt groups, character notes, tags, and
provisions are stored in the same guild partition. Roster's ByName presentation projects group
membership from this partition but limits its character population to the
active guild's saved roster. `rosterObservation` stores the immediately prior
complete API observation used only for news detection; unlike `roster`, it does
not retain absent members. `newsSets` stores immutable qualifying scan results
newest first until acknowledgement or expiry after their 21st Pacific calendar
day.

Character-note keys use the same case-insensitive canonical character identity
as the roster projection. Saved note text is trimmed, whitespace-only text is
removed, and editor-created notes are limited to 5,500 characters. Grouping,
promotion, and removal update only `mainAltGroups`, so notes and tag assignments
remain attached to their character identities. Tag definitions are normalized
by trimming edge whitespace and downcasing ASCII letters while preserving
interior whitespace and non-ASCII spelling. Every guild catalog contains `me`;
custom definitions remain saved even when unused. Assignments are removed only
when their character leaves the retained roster database.

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

`RosterNewsObservation` contains the scan timestamp and a canonical identity,
display name, numeric rank index, and current rank name for every member in that
successful API response. A `RosterNewsSet` contains its unique scan-derived ID,
Pacific creation date, and non-empty change data across joining members, leaving
members, and rank changes. Rank changes save the member display name and new
rank name; set acknowledgement removes only the selected set.

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
observation, and stable-since fields. New observations may also retain the
native Midnight reagent crafting-quality tier used by Provisions matching.
Detailed validation and legacy migration rules remain implemented in
`Core/SavedData.lua`.

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
roster commit also prunes expired News Sets, compares its raw API observation
with the prior successful observation, saves the new baseline, and appends one
News Set when qualifying changes exist. The commit also clears the logged-in
character's corresponding deprecated dataset
while preserving the other dataset and window position. Failed, incomplete,
timed-out, and canceled scans preserve both the last account-wide observations
and the pending deprecated data. The other account dataset, initialization
flag, groups, notes, provisions, tag definitions and assignments, and every
other guild partition remain unchanged. Successful roster commits reconcile assignments
against the retained roster while preserving the complete tag catalog.

## Reset and recovery

Confirming `/rgms reset` while guilded clears the current guild's roster, bank,
provisions, groups, notes, custom tag definitions, tag assignments, news
baseline, and News Sets, then reseeds `me`.
It leaves both dataset initialization flags true, preserves
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
