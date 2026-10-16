# Saved data model

RGMS uses two World of Warcraft SavedVariables:

- `RGMSAccountDB` is account-wide and contains one isolated partition for every
  guild encountered by the account.
- `RGMSCharacterDB` remains per character. Its `ui.windowPosition` is the live
  source for that character's window placement. Its roster and bank fields are
  deprecated snapshots; roster data is retained until a successful account-wide
  roster scan, while bank data remains available for issue #51.

The addon's active `RGMS.DB` is a view over the current guild's account
partition plus the logged-in character's `ui` table. It never exposes another
saved guild through the UI. A guildless character receives an empty transient
view and does not create, bind, replace, or erase an account guild partition.

## Account-wide schema: version 1

```text
{
  schemaVersion = 1,
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
the same guild partition but are not yet exposed by the UI.

## Per-character schema: version 7

```text
{
  schemaVersion = 7,
  roster = DeprecatedRosterDataset,
  bank = DeprecatedBankDataset,
  ui = {
    windowPosition = WindowPosition | nil,
  },
}
```

The version 0 through 7 migrations remain supported. When the current guild's
account-wide roster is uninitialized, only the logged-in character's matching
deprecated roster can seed it. A missing or foreign-guild snapshot initializes
an empty current-guild roster instead. An already initialized roster, including
an intentionally empty reset state, is authoritative and is never repopulated
from another character. Deprecated bank observations are not changed here.

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
account dataset. A guild with no partition receives a detached empty baseline,
but beginning a scan does not create the partition. Failure, timeout, partial
data, or cancellation discards the detached work without changing saved data.

Only a complete, validated success atomically replaces that one dataset in the
matching guild partition and marks its initialization flag true. A successful
roster commit also clears the logged-in character's deprecated roster while
preserving its bank and window position. Failed, incomplete, timed-out, and
canceled scans preserve both the last account-wide roster and the deprecated
roster. The other account dataset, initialization flag, groups, notes, and every
other guild partition remain unchanged.

## Reset and recovery

Confirming `/rgms reset` while guilded clears the current guild's roster, bank,
groups, and notes. It leaves both dataset initialization flags true, preserves
all other guild partitions and deprecated per-character observations, and
preserves the character's window position. The initialized empty roster prevents
legacy repopulation; its next successful scan removes the current character's
deprecated roster. A guildless manual reset is rejected without mutation.

Malformed or unsupported account data disables scans and reports without
overwriting the original. Accepted account recovery creates a fresh account
model and, when a current guild is available, an initialized empty partition.
Per-character recovery continues to retain only a valid window position.

## Guild activation

RGMS resolves the logged-in character's guild at addon load, player login, and
guild-membership changes. Activation initializes the current guild's roster
partition conservatively, selects it for display, and starts the normal roster
scan. A guildless character still receives an empty transient view. Bank
partitions remain initialized only by their own reset or successful transaction.

Sharing is limited to the local account's SavedVariables. RGMS performs no
player-to-player synchronization and provides no browser for inactive guilds.
