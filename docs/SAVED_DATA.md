# Saved data model

RGMS uses two World of Warcraft SavedVariables:

- `RGMSAccountDB` is account-wide and contains one isolated partition for every
  guild encountered by the account.
- `RGMSCharacterDB` remains per character. Its `ui.windowPosition` is the live
  source for that character's window placement. Its roster and bank fields are
  deprecated snapshots retained for the migration work in issues #50 and #51.

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

The version 0 through 7 migrations remain supported so existing characters can
retain their data until the roster and bank migration tickets consume it.
Account-storage creation does not import, merge, or delete those observations.

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
matching guild partition and marks its initialization flag true. The other
dataset, initialization flag, groups, notes, every other guild partition, and
the per-character window position are copied or retained unchanged. This
preserves existing transactional behavior without partial account-wide writes.

## Reset and recovery

Confirming `/rgms reset` while guilded clears the current guild's roster, bank,
groups, and notes. It leaves both dataset initialization flags true, preserves
all other guild partitions, preserves deprecated per-character observations for
their dedicated migration tickets, and preserves the character's window
position. A guildless manual reset is rejected without mutation.

Malformed or unsupported account data disables scans and reports without
overwriting the original. Accepted account recovery creates a fresh account
model and, when a current guild is available, an initialized empty partition.
Per-character recovery continues to retain only a valid window position.

## Guild activation

RGMS resolves the logged-in character's guild at addon load, player login, and
guild-membership changes. Resolution is read-only. It selects the matching
account partition for display or an empty view when no partition exists. The
first successful roster or bank transaction creates that guild's partition.

Sharing is limited to the local account's SavedVariables. RGMS performs no
player-to-player synchronization and provides no browser for inactive guilds.
