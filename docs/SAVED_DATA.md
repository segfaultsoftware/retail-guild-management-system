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

## Account-wide schema: version 13

```text
{
  schemaVersion = 13,
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
        [MainIdentityKey] = { AltIdentityKey, ... },
      },
      characterNotes = {
        [CharacterIdentityKey] = NoteText,
      },
      tags = {
        definitions = {
          [NormalizedTagName] = true,
        },
        assignments = {
          [CharacterIdentityKey] = {
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
      chartHistory = {
        gold = { { date = PacificDate, value = nonnegative integer }, ... },
        members = {
          { rankIndex = integer >= 2, name = string,
            points = { { date = PacificDate, value = nonnegative integer }, ... } },
          ...
        },
      },
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
Version 8 permits the latest successful bank snapshot to retain its total money
in copper. Older snapshots migrate without an invented amount and remain blank
in the Provisions view until the next successful bank scan. Version 9 adds an
empty chart history to every guild partition without backfilling older roster
or bank snapshots. Version 10 removes the discontinued item-chart history from
every guild partition while preserving Gold and Members observations. Version
11 converts every existing partition identity and every nested roster or bank
identity to the product-aware contract, inferring Retail for all historical
data. The conversion verifies that each new Retail identity produces the
existing map key and never re-keys `guilds`; a mismatch disables the account
store and preserves the supplied table for recovery. Version 12 adds the exact
Feature 1.3 Retail character key to every persisted roster member and converts
each roster-news baseline member from `name` to the explicit `displayName`
field while retaining its existing opaque `identity`. Duplicate roster
identities are reconciled deterministically during migration, preferring a
present member over an equivalent retained-missing record and otherwise the
newest observation. Historical `newsSets` are not reinterpreted or rewritten;
their human-readable join, leave, and rank-change labels remain unchanged.
Bank data, charts, provisions, groups, notes, tags, and every other guild
partition are preserved. Version 13 converts only legacy Retail group labels
through the explicit Retail legacy parser into the same opaque identity keys
stored on roster members. Existing private-note and tag-assignment keys and
values are copied exactly because they already use canonical Retail character
identity. Empty, malformed, duplicate, or colliding group identities reject the
whole migration. Conversion happens only on a detached copy, so any late
validation failure leaves the complete supplied account store unchanged.

A `GuildIdentity` has one of these canonical shapes (fields shown as `nil` are
absent from the saved Lua table):

```text
Retail = {
  key = EstablishedRetailGuildKey,
  flavor = "retail",
  region = Region,
  name = ExactGuildName,
  realm = { name = CanonicalRealmName, slug = CanonicalRealmSlug },
  displayName = ExactGuildName,
  clubId = nil,
}

Forever = {
  key = OpaqueForeverGuildKey,
  flavor = "forever",
  region = Region,
  name = ExactGuildName,
  realm = nil,
  displayName = ExactGuildName,
  clubId = StableGuildClubId,
}
```

Retail keys remain the byte-for-byte established combination of exact guild
name and case-insensitive canonical realm slug. Forever keys use a separate,
versioned namespace containing product, region, and stable guild club ID, so
they cannot collide with Retail or with the same club ID in another region.
Callers treat both key forms as opaque and compare validated identities through
the shared guild-identity service.

Roster character identities follow the same product-aware boundary. Retail
continues to use the established canonical `Name-Realm` key byte-for-byte.
Forever uses a separate versioned namespace containing product, region, and the
complete case-preserving two-part name. The two name components remain one
indivisible value: the second component is never treated as a realm, and two
members sharing the first component cannot collide. Display and sort values are
stored beside the opaque key, and an optional GUID remains correlation metadata
rather than a portable identity.

Roster and bank initialization flags are independent. `false` means no
account-wide decision has been made for that dataset. `true` with empty
collections and no scan timestamp is an intentional empty state, including a
reset state; later migration code must not repopulate it from deprecated
per-character observations. Main/alt groups, character notes, tags, provisions,
and 180-day chart histories are stored in the same guild partition. Roster's
ByName presentation projects group
membership from this partition but limits its character population to the
active guild's saved roster. `rosterObservation` stores the immediately prior
complete API observation used only for news detection; unlike `roster`, it does
not retain absent members. `newsSets` stores immutable qualifying scan results
newest first until acknowledgement or expiry after their 21st Pacific calendar
day.

Main/alt membership, character-note keys, and tag-assignment keys are opaque,
non-empty roster character identities. Runtime paths never parse those keys or
display labels; labels and sort inputs come from the active roster record.
Version 13 preserves every existing Retail note and assignment key byte for
byte while re-keying only legacy groups. Saved note text is trimmed,
whitespace-only text is removed, and editor-created notes are limited to 5,500
characters. Grouping, promotion, and removal update only `mainAltGroups`, so
notes and tag assignments remain attached to their character identities. Tag
definitions are normalized
by trimming edge whitespace and downcasing ASCII letters while preserving
interior whitespace and non-ASCII spelling. Every guild catalog contains `me`;
custom definitions remain saved even when unused. Assignments are removed only
when their character leaves the retained roster database.

Provision quality is product-sensitive even though the persisted shape accepts
all three historical values. Retail preserves `silver`, `gold`, and `either`
and matches them against native Midnight crafting quality. Forever has no
crafting-quality capability: its editor and report are quality-neutral, its bank
slots omit quality, and every active-guild provision is canonicalized to
`either` before use. That normalization replaces only the validated provision
list through the normal copy-and-replace account-data path; a failure leaves the
supplied account store and unrelated guild fields unchanged.

The live guild-note adapter converts raw roster API names through the shared
character-identity service using the active guild's product and region. It
stores the resulting key beside the service-provided display label; note
visibility and the existing read-only guild-note editing policy are unchanged.
Public and officer guild notes live only in this transient session cache, not in
either SavedVariables store. Restricted or secret observations retain each
field's independent last-good usable value without persisting, printing,
searching, or transforming the secret value; retained officer data remains
hidden whenever the character lacks permission. The `characterNotes` table
above contains only RGMS's persistent private notes.

## Per-character schema: version 10

```text
{
  schemaVersion = 10,
  roster = DeprecatedRosterDataset,
  bank = DeprecatedBankDataset,
  ui = {
    windowPosition = WindowPosition | nil,
    selectedRosterRankIndex = integer | nil,
    selectedBankTabIndex = positive integer | nil,
  },
}
```

Saved data from versions 0 through 9 remains migratable. Version 8 adds
per-character numeric rank and bank-tab selections, so renaming an option does
not invalidate it. Version 9 infers Retail for guild identities in both
deprecated datasets and stores the canonical product-aware shape. Version 10
adds the exact Feature 1.3 Retail identity to every deprecated roster member
without changing its display label, tenure, missing-member state, GUID, bank
data, or UI state. Duplicate identities are resolved with the same deterministic
present-member and newest-observation preference as the account migration.
Migration and validation operate on a detached copy, so failure leaves the
original per-character store recoverable and unchanged. When the
current guild's account-wide roster is uninitialized, only the logged-in
character's matching deprecated roster can seed it. A missing or foreign-guild
snapshot initializes an empty current-guild roster instead. An already
initialized roster, including an intentionally empty reset state, is
authoritative and is never repopulated from another character.

Bank migration is deliberately deferred until the guild bank is open and a scan
is about to start. An uninitialized current-guild bank is seeded only from the
logged-in character's matching deprecated bank; foreign-guild data is ignored.
Once initialized, including as an intentional empty reset state, the account
bank remains authoritative and later characters cannot merge legacy snapshots.

`RosterNewsObservation` contains the scan timestamp and, for every member in
that successful API response, `{ identity, displayName, rankIndex, rankName }`.
The identity is a non-empty opaque key and is never parsed to recover the label.
A `RosterNewsSet` contains its unique scan-derived ID, Pacific creation date,
and non-empty change data across joining members, leaving members, and rank
changes. Rank changes save the member display name and new rank name; set
acknowledgement removes only the selected set. Saved set labels are immutable
display records even if the member's current display label later changes.

`WindowPosition` contains `point`, `relativePoint`, `x`, and `y`. The active
view references the current character's `ui` subtree, so dragging the window
continues to save independently for every character even though guild data is
shared account-wide.

## Dataset shapes

Roster and bank observation records retain their established fields, with the
legacy guild value replaced by the canonical product-aware `GuildIdentity`. A
successful observation includes that identity and a scan timestamp. An empty
uninitialized or reset dataset has empty collections and no guild or timestamp.

Roster members store a non-empty opaque `identity` separately from their
non-empty `displayName`, along with rank, online, observation, rank-tenure,
missing-member, and GUID correlation fields. Retail records retain legacy
`name` and canonical `realm` metadata where useful; `realm` is absent for
Forever records, and neither identity nor display is reconstructed from those
legacy fields. GUID remains correlation metadata and never replaces the
portable identity. Bank tabs retain access state and
last-access timestamps; a completed bank snapshot retains its total money in
copper; occupied bank slots retain item, quantity, icon,
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

Before publishing, the transaction compares its captured guild with a freshly
resolved active guild through the shared identity contract. If product, region,
or ownership changed while the scan was running, the commit is rejected before
account data, deprecated character data, or the active view can change.

Only a complete, validated success atomically replaces that one dataset and its
same-day chart observation in the matching guild partition and marks its
initialization flag true. A successful
roster commit also prunes expired News Sets, compares its raw API observation
with the prior successful observation, saves the new baseline, and appends one
News Set when qualifying changes exist. The commit also clears the logged-in
character's corresponding deprecated dataset
while preserving the other dataset and window position. Failed, incomplete,
timed-out, and canceled scans preserve both the last account-wide observations,
chart histories, and the pending deprecated data. The other account dataset, initialization
flag, groups, notes, provisions, tag definitions and assignments, and every
other guild partition remain unchanged. Successful roster commits reconcile assignments
against the retained roster while preserving the complete tag catalog.

Each SavedVariables store loads, migrates, and validates a detached copy. A
failure returns the established disabled/recovery state with the complete
supplied table untouched. Account and per-character stores recover
independently; RGMS does not impose a cross-store transaction.

## Reset and recovery

Confirming `/rgms reset` while guilded clears the current guild's roster, bank,
chart histories, provisions, groups, notes, custom tag definitions, tag assignments, news
baseline, and News Sets, then reseeds `me`.
It leaves both dataset initialization flags true, preserves
all other guild partitions and deprecated per-character observations, and
preserves the character's window position. The initialized empty datasets
prevent legacy repopulation; the next successful roster or bank scan removes
only the corresponding deprecated dataset for the current character. Reset
resolves the current product-aware identity again instead of trusting a stale
active view, so it cannot clear a same-named guild from another product or
region. A guildless manual reset is rejected without mutation.

Malformed or unsupported account data disables scans and reports without
overwriting the original. Accepted account recovery creates a fresh account
model and, when a current guild is available, an initialized empty partition.
Per-character recovery continues to retain only a valid window position.

## Guild activation

RGMS resolves the logged-in character's guild at addon load, player login, and
guild-membership changes. Retail resolution uses the canonical realm contract;
Forever resolution uses product, region, and the stable guild club ID and never
uses realm APIs as ownership fallback. Missing required inputs fail closed.
Activation initializes the current guild's roster partition conservatively,
selects only that opaque-key partition for display, and starts the normal roster
scan. A guildless character still receives an empty transient view. Bank
partitions are not initialized during activation or merely by opening RGMS. They
are initialized immediately before an eligible scan after the guild bank opens.

## Migration implementation choice

The schema migration remains project-owned after evaluating established shared
libraries. [AceDB-3.0](https://github.com/WoWUIDev/Ace3) is actively maintained
and broadly adopted for profiles, namespaces, and defaults, but it does not
provide RGMS's strict versioned validation, opaque guild and character identity
contracts, collision-safe group re-keying, or copy-on-write rollback.
[LibSerialize](https://github.com/rossnichols/LibSerialize)
is maintained, MIT-licensed, and Lua-compatible, but serializes arbitrary values
rather than migrating WoW SavedVariables already loaded as tables. The current
[LibSavedVars](https://github.com/silvereyes333/LibSavedVars) implementation is
small and targets Elder Scrolls Online rather than World of Warcraft. Reusing
RGMS's existing validators and detached-copy loaders therefore keeps the change
smaller and makes exact Retail-key preservation and per-store atomicity directly
testable without adding an unrelated framework.

Sharing is limited to the local account's SavedVariables. RGMS performs no
player-to-player synchronization and provides no browser for inactive guilds.
