# Staged Retail and Forever core-beta checklist

Use this document to validate one RGMS beta package in the supported World of
Warcraft Retail and Forever clients. It is deliberately self-contained: a
tester should not need a GitHub issue or another checklist to identify the
package, setup, action, expected result, evidence, or rerun requirement.

Do not mark an item complete from memory or from a different checkout. Record
the observed result for the exact archive and client build under test. Keep raw
account, character, guild, and path identifiers out of shared evidence.

## Core gate and deferred parity

The **core beta gate** covers all of the following:

- installation and loading from one shared package;
- Retail preservation, product/region isolation, identity, and migrations;
- roster collection, Mains/Alts, tags, private notes, tenure, and News;
- public and officer guild-note visibility, permissions, and secret values;
- guild-bank balances, access states, retained data, and scan transactions;
- the shared window, menus, scrolling, tooltips, minimap button, and combat
  smoke checks.

Complete Forever Provisions and Auctionator parity belongs to Feature 5.1 and
is **deferred**. A missing Forever-specific quality or integration behavior is
not a core-beta failure. A load error, secret-value error, data loss, identity
collision, protected-action error, or failure in shared bank/UI infrastructure
is still a core blocker even if it is first noticed through a deferred view.

## Immutable test record

- Package version: _________________________________________________
- Full source commit SHA: __________________________________________
- Source worktree clean (`git status --short` is empty): YES / NO
- Build command: `./scripts/build-local-release.sh`
- Build result and automated test count: ____________________________
- Archive filename and sanitized/repository-relative evidence path: _________
- Archive SHA-256: _________________________________________________
- Archive file-list evidence: ______________________________________
- Tester: __________________________________________________________
- Test start in Pacific time: ______________________________________
- Test end in Pacific time: ________________________________________
- Sanitized/repository-relative evidence root: _____________________________

Record the exact client values reported by these commands; do not copy values
from `RGMS.toc` into the result fields:

```text
/dump GetBuildInfo()
/dump select(4, GetBuildInfo())
```

| Run | Product and exact UI preset label | Region | Version/build | Interface | Actor/guild alias | Staged ZIP SHA-256 before install | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R | Retail / standard UI | __________ | __________________ | __________ | __________ | __________________ | __________________ |
| F1 | Forever / preset 1: __________________ | __________ | __________________ | __________ | __________ | __________________ | __________________ |
| F2 | Forever / preset 2: __________________ | __________ | __________________ | __________ | __________ | __________________ | __________________ |
| F-R2 | Forever / isolation preset: __________ | __________ | __________________ | __________ | __________ | __________________ | __________________ |

The two Forever preset labels must be different and copied exactly from the
client. Record the chosen common UI scales and display sizes below, then run
the UI smoke matrix with the same profiles in Retail and both Forever presets.

- Profile A scale and display size: _________________________________
- Profile B scale and display size: _________________________________
- Second Forever region used for isolation: ________________________

- [ ] Retail's observed interface matches the first manifest `Interface`
  value, and its observed version/build matches `X-RGMS-Retail-Version`.
- [ ] Both primary Forever runs and F-R2 match the second manifest `Interface`
  value and `X-RGMS-Forever-Version`.
- [ ] Every value came from the client being tested. A mismatch blocks this
  package; do not edit the recorded observation to match the manifest.

## Automated and package preflight

Run the Lua suite and local package build from Git Bash on Windows:

```text
lua.exe Tests/run.lua
./scripts/build-local-release.sh
```

Run the release-workflow tests from PowerShell 7. They invoke the Lua suite
through Git Bash internally, while allowing the builder to resolve the standard
Git for Windows installation:

```text
pwsh.exe -NoProfile -File .\Tests\build_release_tests.ps1 -LuaCommand 'C:\Program Files (x86)\Lua\5.1\lua.exe'
```

Expected results:

- [ ] The Lua suite exits `0`; record the exact total, passed, and failed count.
- [ ] Release-workflow tests exit `0` and validate the dual-interface package
  fixtures.
- [ ] The local builder reruns the Lua gate, creates the archive twice, verifies
  byte equality, and prints one final SHA-256.
- [ ] The package was built from the clean full commit recorded above.

Inspect the exact archive reported by the builder:

```text
archive=.release/local-YYYYMMDD-HHMMSS/RGMS-X.Y.Z.zip
unzip -Z1 "$archive"
sha256sum "$archive"
```

- [ ] The ZIP contains one `RGMS/RGMS.toc`, all manifest-referenced shared and
  conditional runtime files exactly once, and no generated or product-specific
  TOC.
- [ ] The ZIP contains no tests, contributor-only files, repository metadata,
  local evidence, or secret-like path.
- [ ] The recorded SHA-256 matches the builder's value.
- [ ] The same archive bytes, not separate rebuilds, are staged for Retail and
  Forever.

The full suite owns deterministic coverage for flavor detection, manifest/load
order, product and region identities, copy-on-write migrations, partial roster
delivery, Mains/Alts, secret notes, bank failures/timeouts, shared UI, and
LibDBIcon. The `MVP-E2E-*` cases provide cross-layer transitions. Live testing
below validates behavior that cannot be faithfully emulated outside the game.

### Deterministic MVP fixture clock

`Tests/mvp_fixtures.lua` pairs each Pacific date with a fixed UTC timestamp.
Use the automated result as the evidence for calendar boundaries that cannot be
recreated during a short live beta run.

| Transition | Pacific date | Persisted UTC timestamp |
| --- | --- | --- |
| Day 1 morning | 2024-06-01 | `2024-06-01T16:00:00Z` (`1717257600`) |
| Day 1 afternoon | 2024-06-01 | `2024-06-01T20:00:00Z` (`1717272000`) |
| Day 2 | 2024-06-02 | `2024-06-02T16:00:00Z` (`1717344000`) |
| Day 3 | 2024-06-03 | `2024-06-03T16:00:00Z` (`1717430400`) |
| Day 4 | 2024-06-04 | `2024-06-04T16:00:00Z` (`1717516800`) |
| Day 5 | 2024-06-05 | `2024-06-05T16:00:00Z` (`1717603200`) |
| Day 6 | 2024-06-06 | `2024-06-06T16:00:00Z` (`1717689600`) |
| Day 7 | 2024-06-07 | `2024-06-07T16:00:00Z` (`1717776000`) |
| Day 8 | 2024-06-08 | `2024-06-08T16:00:00Z` (`1717862400`) |
| Missing day 21 | 2024-06-24 | `2024-06-24T16:00:00Z` (`1719244800`) |
| Missing day 22 | 2024-06-25 | `2024-06-25T16:00:00Z` (`1719331200`) |
| Reappearance | 2024-06-26 | `2024-06-26T16:00:00Z` (`1719417600`) |

- [ ] `MVP-E2E-03` retains an absent member through missing day 21, removes the
  member on day 22, and restarts tenure on reappearance.
- [ ] `MVP-E2E-04` preserves prior roster data after API failure and timeout.
- [ ] `MVP-E2E-05` preserves item/access transitions; `MVP-E2E-06` proves that
  hiding RGMS lets the bank scan finish while closing the Guild Bank cancels
  safely. The owning UI test also verifies close-without-cancel behavior.
- [ ] `MVP-E2E-08` covers declined and accepted account/character recovery,
  fresh-account and active-guild reset scope, valid window-position retention,
  and preservation of an unrelated Forever/EU account partition.
- [ ] `MVP-E2E-10` keeps same-first-name Forever identities distinct through
  persistence, tenure, and News.

The final deterministic bank fixture contains item `2002`, count `5`, in tab 1
slot 2. Its `stableSinceDate` is `2024-06-06`, and its final observation is
`2024-06-08T16:00:00Z`.

Automated evidence location: ______________________________________________

## Live-client preparation

Record anonymized mappings and use them consistently. Keep the exact two-part
Forever labels in private evidence; shared screenshots, exports, and records
must use the aliases below and redact the raw labels.

- Retail character A / character B: __________________ / __________________
- Forever character A / character B: _________________ / __________________
- Retail guild and comparison guild: _________________ / __________________
- Forever guild and comparison guild: ________________ / __________________
- Same-first Forever member aliases: _________________ / __________________
- Member used for join/leave/rank/note changes: ____________________________
- Guild master, officer, and ordinary-member test roles: ___________________
- Full-access, partial-access, and no-access bank characters: ______________
- Empty, accessible, and inaccessible bank tabs: ___________________________
- Distinct test item and starting tab/slot/count: __________________________

Before installing:

- [ ] Back up the Retail and Forever account-wide and per-character `RGMS.lua`
  SavedVariables files. Record their hashes in private evidence. The normal
  Windows path shapes are:

  ```text
  <WOW>\_retail_\WTF\Account\<ACCOUNT>\SavedVariables\RGMS.lua
  <WOW>\_retail_\WTF\Account\<ACCOUNT>\<REALM>\<CHARACTER>\SavedVariables\RGMS.lua
  <WOW>\_forever_\WTF\Account\<ACCOUNT>\SavedVariables\RGMS.lua
  <WOW>\_forever_\WTF\Account\<ACCOUNT>\<REALM>\<CHARACTER>\SavedVariables\RGMS.lua
  ```

  Before testing, save named, read-only copies for `original-user` and
  `retail-pre-beta`, plus an absence marker for the `fresh` baseline. Create
  `post-migration` only after the successful Scenario 2 migration. `fresh`
  means both RGMS saved values are absent, not that unrelated addon data is
  deleted.
- [ ] Fully close both clients before inspecting, replacing, or restoring a
  SavedVariables file.
- [ ] Whenever a step directs a baseline restore, restore the account and
  character files from the same named baseline unless that step explicitly
  replaces one store to test independent failure.
- [ ] Restore the successful `post-migration` baseline after
  migration/recovery testing. After Scenario 3 restores its `pre-isolation`
  QA baselines, run Scenarios 4–10 cumulatively unless a step explicitly
  directs another restore; roster/News and bank-retention checks depend on
  observations from the preceding scenario.
- [ ] If the checkout is linked, remove only its verified junction with:

  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Retail -Unlink
  powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Forever -Unlink
  ```

- [ ] Move any existing exact `Interface/AddOns/RGMS` package aside after
  verifying its path; do not overwrite an unknown file, directory, or link.
- [ ] Hash the same staged ZIP before each extraction and confirm it matches the
  recorded archive SHA-256.
- [ ] Extract it separately under `_retail_` and `_forever_` so each final path
  is exactly `Interface/AddOns/RGMS/RGMS.toc` with no extra nesting.
- [ ] Enable Lua errors with `/console scriptErrors 1` in each client.
- [ ] Enable only RGMS while collecting failure evidence. Optionally repeat the
  interaction smoke checks with a recorded normal-addon set after the RGMS-only
  core pass; optional interaction testing does not replace the core pass.

For every SavedVariables observation, `/reload` or log out to flush state and
then fully close the client before reading the file. `RGMSAccountDB` is
account-wide and holds product/region/guild partitions; `RGMSCharacterDB` holds
the current character's UI state and deprecated migration sources.

## Scenario 1 — clean install, load, and session persistence

Run this scenario in R, F1, and F2.

- [ ] At character selection, RGMS is listed once with the current branding and
  is enabled without an out-of-date or wrong-product warning.
- [ ] Log in on a guilded character with fresh RGMS SavedVariables.
  - Chat shows `RGMS: [development] loaded. Type /rgms help for available
    commands.` and a completed roster scan after the roster converges.
  - No Lua, secret-value, taint, or protected-action error appears.
  - The minimap button appears once and `/rgms` opens the shared branded window.
  - Fresh data uses account schema `13` and character schema `10`.
- [ ] Run `/reload`.
  - The last complete roster remains visible until a later complete scan
    replaces it; no empty or partial report flashes.
  - The window, minimap button, slash command, and saved position initialize
    once without duplicate handlers or controls.
- [ ] Log out and back in, then fully exit and cold-start the client.
  - Account-wide guild data, account-wide minimap position, and the character's
    UI position/selections persist in their respective stores.
  - A new scan can advance the timestamp but cannot erase the last-good report
    while data is still streaming.
- [ ] Confirm the installed layout still contains the exact archive file list
  under one `RGMS` directory. If extracted-file hashing is used, retain its
  separate method and results; do not compare a directory hash with the ZIP
  SHA-256.

| Run | Clean load | Reload | Logout/login | Cold restart | No errors | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| R | ____ | ____ | ____ | ____ | ____ | __________________ |
| F1 | ____ | ____ | ____ | ____ | ____ | __________________ |
| F2 | ____ | ____ | ____ | ____ | ____ | __________________ |

## Scenario 2 — Retail migrations, failure, and independent recovery

Use disposable copies of representative pre-beta Retail data. Never corrupt
the only backup. The expected migration path is account schema `10` to `13` and
per-character schema `8` to `10`.

### Successful migration

- [ ] Install valid pre-beta Retail `RGMSAccountDB` and `RGMSCharacterDB` copies
  with populated roster, bank, groups, tags, private notes, News, charts,
  Provisions, minimap position, and character UI position.
- [ ] Record the source hashes, start Retail, and allow RGMS to load.
  - Existing Retail partition keys remain unchanged.
  - Account data reaches schema `13`; product-aware guild/member identities and
    opaque Mains/Alts keys are added without losing unrelated fields.
  - Character data reaches schema `10`; deprecated roster identities migrate
    without changing display labels, tenure, bank data, or UI state.
  - The prior roster, bank, notes, tags, News, charts, Provisions, minimap
    position, and window position remain usable.
- [ ] Complete one roster scan and one bank scan.
  - Each successful account-wide commit clears only its corresponding
    deprecated per-character dataset.
  - The other dataset, every unrelated guild partition, and UI state remain
    unchanged.
- [ ] Fully close Retail and save the successfully migrated account and
  character files as the read-only `post-migration` baseline.

### Copy-on-write failure

- [ ] Copy the valid schema-10 account baseline containing at least two guild
  partitions. In the disposable copy only, change one legacy guild identity's
  `region` to `"Unknown"`; record that exact edit and the source backup hash.
- [ ] Start Retail with that account store and a valid character store.
  - The account store is reported corrupt, scans/reports remain disabled, and
    the complete supplied account table is preserved for recovery.
  - No earlier migration step is published into the failed store.
  - The valid character store can normalize independently to schema `10`.
- [ ] For the corrupt account copy, decline recovery and confirm the failing
  account source remains unchanged while the valid character store either
  remains current or completes only its own migration. Restore a fresh copy of
  the same account corruption, accept recovery, and confirm a fresh account
  model initializes only the current guild when available while the valid
  character model remains usable.
  - The valid character's window position and deprecated observations remain;
    stale numeric roster-rank and bank-tab selections are cleared.
- [ ] Restore the valid account baseline. Copy the schema-8 character baseline
  and, in the disposable copy only, change `bank.guild.region` to `"Unknown"`.
  Leave the account store valid, record the edit, and start Retail again.
  - The character store is preserved unchanged and reported corrupt.
  - The valid account store can normalize independently to schema `13`.
  - No other guild partition is partially migrated, re-keyed, or removed.
- [ ] For the corrupt character copy, decline recovery and confirm the failing
  character source remains unchanged while the valid account store either
  remains current or completes only its own migration. Restore a fresh copy of
  the same character corruption, accept recovery, and verify the
  confirmation's explicit destructive scope:
  - The replacement character store retains only a valid window position.
  - The active guild's account data is reset so the two stores resume from one
    known state; this occurs only after the tester accepts the confirmation.
  - Every other guild, product, and region partition in the valid account
    store remains field-for-field unchanged.
  - Before acceptance, the valid account store can normalize independently and
    the failing character source remains untouched.
- [ ] Fully close Retail and restore the successful `post-migration` account
  and character baseline before Scenario 3.

Successful migration evidence: ____________________________________________

Failure/rollback and recovery evidence: __________________________________

## Scenario 3 — product, region, guild, and full-name isolation

- [ ] Before seeding a product or region path, fully close its client and save
  the current QA files as that path's read-only `pre-isolation` baseline.
- [ ] In Forever, scan a roster containing two members with the same first name
  and different surnames.
  - Both complete names remain intact; neither surname is treated as a realm.
  - The members have different opaque identities and remain separate in saved
    roster data, sorting, tenure, Mains/Alts, tags, private notes, and News.
- [ ] Fully close both products. Seed the Forever test account with a
  disposable copy of the successfully migrated Retail account store, record
  its private hash, then start Forever and scan its active guild.
  - Retail identities keep their established `Name-Realm` behavior.
  - Forever guild keys use Forever, region, and stable club ID; member keys use
    Forever, region, and the complete full name.
  - Forever adds/selects a separate partition; no seeded Retail partition or
    member is overwritten by a similar Forever label.
- [ ] Fully close Forever. Seed the F-R2 account path with a disposable copy of
  the primary-region Forever store, record its private hash, then start the
  second region recorded above.
  - The second region creates/selects a different partition.
  - Save private before/after extracts of the primary-region `guilds[key]`
    table and compare them field-for-field. That partition remains unchanged
    even though the surrounding account file gains F-R2, and it is never
    exposed as the active guild.
  - After collecting evidence, fully close Forever and restore each product and
    region path's `pre-isolation` baseline so Scenarios 4–10 retain their QA
    feature state. Reserve `original-user` for final cleanup.
- [ ] Change from guild A to guild B and complete only a bank scan.
  - Bank displays guild B while roster still shows guild A's last complete
    report; neither dataset is partially rebound.
- [ ] Complete the guild B roster scan.
  - Roster changes to guild B; the committed guild B bank, other product/region
    partitions, minimap settings, and character UI state remain unchanged.
- [ ] Start a scan, then change product/region/guild ownership before commit in
  the disposable test setup, or cite the deterministic ownership test when a
  safe live transition cannot be forced.
  - The stale scan cannot commit into the new partition.

Product/region isolation evidence: ________________________________________

## Scenario 4 — roster streaming and membership transitions

Run the common path in Retail and Forever. Repeat cold-login convergence in F1
and F2.

- [ ] On cold login, compare the final RGMS member/rank counts with the native
  guild roster after it stabilizes.
  - RGMS may wait and request again while the client streams partial data, but
    it publishes only one complete snapshot.
  - During collection the prior complete report remains usable and the UI says
    `Updating...`; partial members/ranks never become the saved report.
- [ ] Verify guild master, officer, ordinary member, online, and offline rows.
  - Rank order/names, leadership, online state, and available last-online data
    match the native roster.
- [ ] Rename a rank and scan again.
  - The new label appears, but unchanged numeric rank indices preserve tenure.
- [ ] Promote and demote the test member, scanning after each action.
  - The member moves to the expected rank and each numeric rank change restarts
    tenure on that Pacific date.
- [ ] Change public/officer notes externally and scan again.
  - Roster collection remains complete and the live-note cache refreshes only
    usable values according to permission.
- [ ] Invite a member, then remove that member, scanning after each action.
  - Join/leave News is created once per qualifying complete observation.
  - A departed member remains in retention with its prior observation and
    missing warning until the documented 21-day boundary.
- [ ] Reinvite the retained member and scan.
  - The missing state clears, last-seen/observation advance, and tenure restarts
    even if the member returns at the same numeric rank.
- [ ] Close RGMS during a roster scan, then reopen it after completion.
  - Hiding the window does not cancel the active scan; the complete result is
    available after reopening.
- [ ] Record deterministic `MVP-E2E-04` evidence for API failure and timeout.
  - Both leave the prior timestamp and report unchanged.

Retail roster evidence: _________________________________________________

Forever roster and streaming evidence: __________________________________

## Scenario 5 — Mains/Alts, tags, private notes, tenure, and News

Use the same-first-name Forever pair as part of this scenario.

- [ ] In **By Name**, create a main/alt group, add an alt, promote an alt to
  main, remove an alt, and dissolve a two-character group.
  - Each operation affects only the selected opaque identities.
  - Full Forever labels determine display and ordering; neither identity is
    parsed to recover a label.
- [ ] Create a custom tag, assign it independently to both same-first members,
  filter the roster, toggle assignments, and delete the tag.
  - Filters use the correct full-name member, definitions remain deterministic,
    and deletion cleans assignments without altering other features.
- [ ] Save different private notes for both members, close/reopen the editor,
  search by each note, and remove one note.
  - Notes remain attached to the exact identity through grouping, sorting, and
    reload; one member's note never appears on the other.
- [ ] Switch between **By Name** and **By Tenure**.
  - Full names sort/display consistently, rank cohorts and approximate ages are
    correct, and missing retained members do not appear as current roster rows.
- [ ] Verify News for join, leave, return, and numeric rank change, then dismiss
  one set.
  - Historical labels remain immutable, sets are newest first, and dismissing
    one does not remove another.
- [ ] Repeat the persistence check after `/reload`, logout/login, and a cold
  restart.

Mains/Alts, notes, tags, tenure, and News evidence: ________________________

## Scenario 6 — public/officer notes, permissions, and secret values

Use characters with guild-master/officer, ordinary-member, and no-officer-note
permission. Do not paste private note text into shared evidence.

- [ ] With full permission, open a character note editor and verify usable
  public and officer notes are shown separately from the private note.
- [ ] With ordinary-member permission, verify public-note visibility and that
  officer-note values are not exposed or made searchable.
- [ ] Remove officer-note permission while a previously usable value is cached.
  - The last-good value is not replaced with an empty or secret value.
  - The retained officer value is hidden while permission is absent.
- [ ] Restore permission and refresh.
  - A usable current value replaces or confirms the cache and becomes visible
    again without exposing another character's value.
- [ ] Exercise an actually restricted/secret observation when the client makes
  one available, recording only the state and error outcome.
  - Public and officer restrictions are isolated from each other.
  - The first restricted observation remains unknown; a later restriction
    retains the independent last-good usable value.
  - RGMS retries within its bounded cadence and never compares, transforms,
    persists, prints, or searches the secret value.
  - No secret-value or Lua error occurs.
- [ ] If the live client provides no safe deterministic way to induce a secret
  value, record that fact and attach the passing owning-feature automated cases
  for secret public/officer fields, last-good retention, permission loss, and
  retry. This does not waive the live no-error observation.

Notes permission and secret-state evidence: _______________________________

## Scenario 7 — guild-bank access and transaction matrix

Run successful open/close and repeated scans in Retail and Forever. Exercise
zero, partial, and full permissions with the prepared characters.

| Product | Access case | Purchased tabs | Queried tabs | Expected committed result | Result/evidence |
| --- | --- | --- | --- | --- | --- |
| Retail | No access | ______ | None | Every purchased tab recorded inaccessible; no slot query | __________ |
| Retail | Partial access | ______ | Accessible only | Accessible contents plus retained/empty inaccessible state | __________ |
| Retail | Full access | ______ | Every accessible tab | Complete contents, empty tabs, and balance | __________ |
| Forever | No access | ______ | None | Every purchased tab recorded inaccessible; no slot query | __________ |
| Forever | Partial access | ______ | Accessible only | Accessible contents plus retained/empty inaccessible state | __________ |
| Forever | Full access | ______ | Every accessible tab | Complete contents, empty tabs, and balance | __________ |

- [ ] Opening the default Guild Bank opens RGMS on Bank and begins one eligible
  transaction after the active guild is resolved.
- [ ] The displayed money matches the native bank balance, including a zero
  balance when applicable.
- [ ] An accessible empty tab completes only after the bounded retry behavior;
  an inaccessible tab is never queried for contents.
- [ ] Refresh is enabled only while the bank is open and no scan is active.
- [ ] Close RGMS during a scan, then reopen it.
  - The scan remains active; the prior report stays committed until a complete
    success replaces it.
- [ ] Close the default Guild Bank during a later scan.
  - The active bank scan is canceled, no false completion is printed, and the
    prior complete report remains.
- [ ] Run repeated unchanged scans and one changed scan.
  - Timestamps advance only on complete success and no duplicate or partial
    slot records leak into saved data.
- [ ] Record deterministic owning-feature evidence for partial reads, API
  failure, unavailable money, and timeout when the live client offers no safe
  trigger.
  - Every path preserves the prior complete bank dataset and balance.

Retail bank evidence: ____________________________________________________

Forever bank evidence: ___________________________________________________

## Scenario 8 — retained bank data and item stability

After each action, reopen or refresh the Guild Bank and wait for a complete
success. Compare the Bank report with the saved account partition.

| Action | Expected UI/timestamp | Expected persisted result | Evidence |
| --- | --- | --- | --- |
| Leave item ID/count in the same slot | Row remains; age advances by Pacific date | `stableSinceDate` stays; `observedAt` advances | __________ |
| Increase the count | Row shows new count | Existing stability is preserved | __________ |
| Decrease the count | Row shows new count and age 0 | Stability resets | __________ |
| Replace the item | Replacement shows age 0 | ID/link/icon/count replace prior values; stability resets | __________ |
| Empty the slot | Row disappears after success | Slot record is removed | __________ |
| Move the item | New location shows age 0 | Destination receives new stability | __________ |
| Make the tab inaccessible | Tab shows `No access` and prior access time | Prior slots/observations/stability remain retained | __________ |
| Restore access unchanged | Current rows return | Observation/access time advance; stability remains | __________ |

- [ ] An inaccessible tab's retained rows are not counted as currently visible
  bank contents.
- [ ] Closing and reopening the bank, `/reload`, logout/login, and cold restart
  retain only the last complete committed dataset.

## Scenario 9 — shared UI and minimap smoke matrix

Run every row with Profile A and Profile B in Retail, Forever preset 1, and
Forever preset 2. Use representative common scales/sizes; do not infer a pass
for one preset from the other.

| Check | R/Profile A | R/Profile B | F1/Profile A | F1/Profile B | F2/Profile A | F2/Profile B | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Open, close, drag, clamp, and restore the main window | ___ | ___ | ___ | ___ | ___ | ___ | __________ |
| Switch primary tabs and By Name/By Tenure modes | ___ | ___ | ___ | ___ | ___ | ___ | __________ |
| Open/close menus, tag popovers, Notes, and News | ___ | ___ | ___ | ___ | ___ | ___ | __________ |
| Scroll long roster, rank, bank, tag, and News content | ___ | ___ | ___ | ___ | ___ | ___ | __________ |
| Show close, missing-member, item, control, and minimap tooltips | ___ | ___ | ___ | ___ | ___ | ___ | __________ |
| Start roster/bank scans and observe the global lock/close behavior | ___ | ___ | ___ | ___ | ___ | ___ | __________ |
| Drag minimap button, reload, and left-click to toggle Roster | ___ | ___ | ___ | ___ | ___ | ___ | __________ |
| Repeat open/close, menus, tooltips, minimap, and safe scans in combat | ___ | ___ | ___ | ___ | ___ | ___ | __________ |

Expected results:

- The shared window remains fully visible, readable, and interactive without a
  Forever-only layout.
- Scan overlays lock mutations while leaving the RGMS close control available;
  hiding RGMS does not cancel an active roster or bank scan.
- Scrollbars appear only when content overflows and never strand controls.
- Tooltips stay on screen and do not create taint, protected-action, secret-
  value, or Lua errors.
- LibDBIcon creates one button, follows each active minimap size/shape, persists
  its account-wide position, and toggles RGMS from every tested preset.

## Scenario 10 — account sharing, character UI, commands, and reset

- [ ] Log in on a fresh unguilded character and open Roster.
  - No guild partition is created, Roster Refresh is disabled, and the view
    reports that the character is not in a guild.
  - Manual `/rgms scanroster` reports the guild requirement without changing
    a timestamp or saved data.
- [ ] Join the prepared guild, wait for the native guild UI to settle, and run
  `/rgms scanroster`.
  - Guild activation creates/selects an initialized empty partition and makes
    Refresh available; only a complete scan populates roster data and commits
    its timestamp.
- [ ] On two characters in the same product/region/guild, complete roster and
  bank scans plus one group, tag, private note, and News change.
  - Both characters see the same current-guild account partition.
  - A character does not create a duplicate guild partition.
- [ ] Save different window positions and numeric roster-rank/bank-tab
  selections on the two characters.
  - Each character retains only its own UI state across reload and login.
  - Account-wide guild observations and minimap position remain shared.
- [ ] `/rgms` toggles the window and selects Roster when opening.
- [ ] `/rgms help` prints one heading and the six supported command lines:
  `/rgms`, `help`, `debug`, `scanroster`, `dumpbanktab N`, and `reset`.
- [ ] An unknown subcommand prints the same help and changes no data.
- [ ] `/rgms debug` toggles session-only diagnostics without persisting them.
- [ ] `/rgms scanroster` uses the same transaction as Roster Refresh; a second
  request during collection is rejected without starting another scan.
- [ ] `/rgms dumpbanktab N` prints only stored records for the requested tab and
  does not start a scan.
- [ ] Request `/rgms reset` during a scan.
  - The scan lock rejects reset and leaves all data unchanged.
- [ ] Cancel a normal reset, then accept it while guilded.
  - Cancel changes nothing.
  - Accept clears only the current product/region/guild's roster, bank, chart
    history, Provisions, groups, notes, tags, and News; it preserves other
    partitions and the character's window position.
  - The intentionally initialized empty datasets cannot be repopulated from
    deprecated character snapshots.
- [ ] Attempt reset while guildless.
  - Reset is rejected without creating or mutating a partition.

Account/character and command evidence: __________________________________

## Defect routing and reruns

Record every discovered defect before deciding whether the beta passes.

| Defect/issue | Product, preset, build | Checklist section | Core or deferred | Owning feature | Disposition | Rerun evidence/result |
| --- | --- | --- | --- | --- | --- | --- |
| __________ | __________ | __________ | __________ | __________ | __________ | __________ |
| __________ | __________ | __________ | __________ | __________ | __________ | __________ |
| __________ | __________ | __________ | __________ | __________ | __________ | __________ |

- [ ] Each defect is routed to its owning feature rather than fixed as unrelated
  #169 scope.
- [ ] Every affected checklist section is rerun after a fix.
- [ ] The complete Lua suite and package validation are rerun after any source,
  manifest, library, or build-tool fix.
- [ ] A deferred Feature 5.1 gap is labeled deferred and does not conceal a
  shared core failure.

## Cleanup and restoration

- [ ] Fully close Retail and Forever, including the F-R2 region client, before
  changing packages or SavedVariables.
- [ ] Preserve the completed sanitized evidence index and the private source,
  baseline, and staged-ZIP hashes.
- [ ] Restore each product/region's `original-user` account and character
  SavedVariables backups, or explicitly record that the disposable QA state is
  intentionally retained.
- [ ] Move the exact installed beta `RGMS` directories out of `Interface/AddOns`
  after verifying each path. Restore the prior package, or recreate development
  links separately with `link-addon.ps1 -Retail` and
  `link-addon.ps1 -Forever`.
- [ ] Start a restored client to confirm its pre-test state only when its
  matching prior package has also been restored. Otherwise leave it closed and
  retain the backups; do not let the beta package migrate restored originals.

## Completion gate

- [ ] The recorded full commit has a clean worktree and produced the exact
  archive under test.
- [ ] The full Lua suite, release-workflow tests, deterministic two-build
  comparison, archive inspection, and SHA-256 checks passed.
- [ ] The same staged ZIP SHA-256 was confirmed immediately before every Retail
  and Forever extraction; extracted-layout evidence is recorded separately.
- [ ] R, F1, F2, and F-R2 loaded with no wrong-product, out-of-date, Lua,
  secret-value, taint, or protected-action error.
- [ ] Existing Retail data remained usable except for the approved atomic
  schema-10-to-13 account and schema-8-to-10 character migrations.
- [ ] Migration success, late failure, rollback, independent store recovery,
  and unrelated-partition preservation were evidenced.
- [ ] Forever full names remained intact and could not collide across product
  or region partitions.
- [ ] Roster, Mains/Alts, tags, private notes, tenure, News, guild notes, bank,
  shared UI, and minimap passed with no unresolved core blocker.
- [ ] All required core boxes are checked; any untestable core item is recorded
  as a blocker, not silently waived.
- [ ] Feature 5.1 Provisions/Auctionator parity gaps are recorded separately and
  are not treated as completed by this beta.
- [ ] Shared evidence is sanitized of account, character, guild, path, note, and
  other private identifiers.
- [ ] Every defect has an owner and every fixed section has passing rerun
  evidence.

Unresolved blocker or failure notes and owner: _____________________________

## Test signoff

- Tester GitHub username: @_________________________________________
- Test date (Pacific): YYYY-MM-DD
- Core beta result: PASS / FAIL
- Deferred Feature 5.1 observations: _______________________________
- Evidence index: __________________________________________________
