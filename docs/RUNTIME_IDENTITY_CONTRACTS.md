# Runtime Identity Contracts and Evidence

This record supports issue #154 and the identity, persistence, and roster work
that follows it. It defines how to collect comparable World of Warcraft Retail
and Forever evidence with the standalone `RGMSRuntimeProbe` addon, how to
sanitize that evidence, and which identity decisions are currently safe to
consume.

## Current status

**CONTRACTS APPROVED FROM COMPOSITE EVIDENCE — the full-boundary Forever
capture establishes stable converged full-name/GUID and club relationships
through reload, logout/login, and cold restart; the supplemental capture
establishes that complete two-part names distinguish members sharing a first
component.** The two runs remain separate evidence sources rather than a
synthetic timeline. Together they approve all four contracts below. Exact
observer permissions, run times, and immutable probe provenance were not
supplied and remain recorded as inaccessible evidence rather than invented
metadata.

The live observations establish these constraints:

- A member GUID is correlation metadata. It must never be the sole portable
  character key, even though the observed GUID aliases remained stable.
- The guild club ID is stable across reload, logout/login, and cold restart on
  both products once club state becomes available. When it is unavailable,
  guild identity is unresolved and collection must retry; there is no
  name/realm fallback.
- Realm API results are intermittent and semantically inconsistent on Forever.
  They are excluded from Forever character and guild identity.
- Member names are canonical inputs only from a converged club observation.
  Retail produced 42 transient alternate name aliases for stable GUID aliases
  before club-count convergence.
- Two Forever members with the shared alias `First-048` retained distinct
  surname, full-name, and GUID aliases throughout initial-login and reload
  observations. The independent base capture supplies full-name/GUID stability
  evidence across logout/login and cold restart for the same product/API
  contract; it is not alias-correlated with the supplemental run.
- Display labels are presentation data, not durable keys.

Automated tests verify the probe, the sanitized fixture shape, the base
cross-boundary stability evidence, and the supplemental same-first
distinguishability evidence as independent propositions.

## Formatter and sanitizer choice

The probe uses a project-owned fixed schema and allowlisted formatter instead
of a general serialization dependency:

- [LibSerialize](https://github.com/rossnichols/LibSerialize) is maintained,
  MIT-licensed, documented, and supports deterministic map serialization, but
  it does not anonymize values and its arbitrary-table format is broader than
  this evidence contract.
- [AceSerializer](https://github.com/WoWUIDev/Ace3) is mature and actively
  maintained, but adopting Ace3 would add a framework and redistribution
  constraints without solving sanitization or schema validation.
- [LibDeflate](https://github.com/SafeteeWoW/LibDeflate) is established and
  permissively licensed, but compression makes fixtures less reviewable and
  provides no privacy protection; its source is also less active.
- [wow-name-anonymizer](https://github.com/swixfort/wow-name-anonymizer) is a
  low-adoption GPL-3.0 standalone addon rather than a composable sanitizer and
  is not license- or architecture-compatible with this use.

The custom implementation accepts only the fields required by issue #154,
replaces every identity-bearing value with bounded opaque aliases, rejects
unknown fields and executable fixture input, and produces human-reviewable Lua
without adding runtime dependencies. This narrower design makes privacy and
Lua 5.1 compatibility directly testable.

## Probe boundary

The probe is a development-only addon in
`Diagnostics/RGMSRuntimeProbe`. It is deliberately separate from RGMS so it
can run before dual-product RGMS loading exists. Its single dual-interface
manifest is `RGMSRuntimeProbe.toc`; do not add the diagnostic to `RGMS.toc` or
to a release package.

The probe writes two account-level SavedVariables values:

- `RGMSRuntimeProbeDB` is the local working record while capture is active. It
  can contain raw names and identifiers and must never be shared or committed.
  A complete, non-truncated `/rgmsprobe stop` clears this working value after
  building the sanitized export, so the final normal logout flush retains only
  the export. If a bound was exceeded, the private working value is retained
  locally for diagnosis and must still never be shared.
- `RGMSRuntimeProbeExport` is the probe-produced sanitized representation.
  It preserves the equality and distinctness relationships needed for the
  matrix without retaining the original guild name, member names, GUIDs, club
  ID, or realm names. Values that an API does not expose remain explicit in
  availability maps rather than disappearing from the record. Closed,
  non-identifying error codes distinguish missing APIs and failed calls without
  carrying client error text into a fixture.

Collection is opt-in and bounded. The supported commands are:

| Command | Purpose |
| --- | --- |
| `/rgmsprobe start` | Start or resume bounded capture. |
| `/rgmsprobe status` | Show capture state and bounded counts. |
| `/rgmsprobe snapshot` | Request and capture the current roster surfaces. |
| `/rgmsprobe mark reload` | Mark the next session as a UI reload. |
| `/rgmsprobe mark logout-login` | Mark the next session as logout/login. |
| `/rgmsprobe mark cold-restart` | Mark the next session as a cold client restart. |
| `/rgmsprobe stop` | Capture once more, stop, and finalize the export. |
| `/rgmsprobe export` | Refresh the sanitized export without printing its contents. |
| `/rgmsprobe reset confirm` | Erase all local probe data. |

Do not use `/rgmsprobe reset confirm` until any existing local evidence that
must be retained has been backed up outside the repository. The required
`confirm` token prevents an incomplete reset command from deleting evidence.

## Required test setup

Run the complete procedure once on a supported Retail build and once on a
supported Forever build from the exact same checkout. Use a guild member who
can view the complete guild roster. Disable RGMS and every other addon while
collecting timing or event evidence; enable only `RGMSRuntimeProbe`.

Prepare these private role mappings. Record only the role codes in committed
evidence:

| Role code | Requirement |
| --- | --- |
| `Observer` | Character that runs the probe and can view the complete roster. |
| `SameFirst-A` | Forever guild member whose full name has the required shared first component. |
| `SameFirst-B` | Different Forever guild member with the same first component and a different surname. |
| `RosterChanger` | Member whose login, logout, invitation, removal, or other safe state change can cause a roster event, if available. |

`SameFirst-A` and `SameFirst-B` may include the observer, but they must be two
different members and must appear together in at least one converged Forever
observation. If the required guild membership, permissions, or second member
cannot be arranged, mark the Forever run blocked; do not substitute invented
fixture data.

Before each product run, record privately:

- source commit and whether the checkout is clean;
- tester and test role;
- client version/build and interface version from `GetBuildInfo()`;
- runtime product identifier and region;
- guild size and the relevant guild permissions;
- local start and end times with timezone;
- any API, permission, or environment evidence that is inaccessible.

The probe captures the product identifier, region, guild name, guild club ID,
member full name, member GUID, roster member count, and relevant realm API
results. The raw values are private. The sanitized export must retain aliases,
presence, equality, and change relationships rather than the values themselves.

## Install the standalone probe

Close every WoW client. From the repository root in Git Bash, run Windows
PowerShell to create a directory junction for each client to be tested. Adjust
the installation paths when Battle.net uses a non-default location.

```bash
powershell.exe -NoProfile -Command '
$ErrorActionPreference = "Stop"
$probeSource = (Resolve-Path ".\Diagnostics\RGMSRuntimeProbe").Path
New-Item -ItemType Junction -Path "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\RGMSRuntimeProbe" -Target $probeSource
New-Item -ItemType Junction -Path "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\RGMSRuntimeProbe" -Target $probeSource
'
```

The resulting files must be at these exact depths:

```text
_retail_/Interface/AddOns/RGMSRuntimeProbe/RGMSRuntimeProbe.toc
_forever_/Interface/AddOns/RGMSRuntimeProbe/RGMSRuntimeProbe.toc
```

`New-Item` must fail rather than replace an existing file, directory, or link.
If either destination already exists, inspect it and resolve it manually; do
not delete an unknown directory. Restart the client after adding the probe.

At the character screen, enable only **RGMS Runtime Identity Probe**. If the
addon is marked incompatible or out of date, record the product, build,
interface number, and exact message as a blocker. Do not treat **Load out of
date AddOns** as proof that the manifest supports the build.

After login, enable Lua errors:

```text
/console scriptErrors 1
```

Record the first Lua error in full if one occurs. Stop that product's run; do
not continue with a partially functioning probe.

## Per-product collection procedure

Perform every step below first on Retail and then from a reset probe state on
Forever. Keep the Guild & Communities window closed until instructed so the
initial samples are comparable.

### 1. Start from a clean probe record

1. Log in as `Observer` and wait only until chat accepts commands.
2. Run `/rgmsprobe reset confirm`.
3. Run `/rgmsprobe start`.
4. Run `/rgmsprobe status` and record its message privately.
5. Immediately run `/rgmsprobe snapshot`.

If `start`, `status`, or the first snapshot reports an error, mark the run
blocked. Do not replace a missing API result with an assumed value.

### 2. Observe initial, partial, and converged delivery

1. Preserve the automatic samples and roster-event sequence recorded after
   `start`.
2. Run `/rgmsprobe snapshot` once immediately, once after the first recorded
   roster event, and once after event activity has stopped for 15 seconds.
3. Open Guild & Communities to the guild roster and run
   `/rgmsprobe snapshot` again.
4. If `RosterChanger` is available, perform one safe, reversible action that
   normally refreshes the roster, record the exact action, wait for event
   activity to stop for 15 seconds, and run `/rgmsprobe snapshot`.
5. Run `/rgmsprobe status`.

For every automatic and explicit observation, retain:

- the triggering command, marker, or roster event;
- the reported `clubInfo.memberCount` and the number of entries returned by
  `C_Club.GetClubMembers`;
- whether either value or the member list was absent;
- whether member identities came from `C_Club` or the guild-roster fallback;
- the first observation at which the two counts converged;
- later divergence or reconvergence;
- the roster events that preceded a changed observation;
- all relevant realm API results, including absence or errors.

A sample is partial when the reported and returned counts differ in either
direction, a required club surface is unavailable, or any returned member
lacks a complete full name or GUID. Equality is evidence of count convergence
only; it does not by itself prove that member records are complete. If no
partial sample is captured, record **not observed in this run** with the event
sequence and timings. Do not claim that the client never streams partial data.

On Forever, confirm that `SameFirst-A` and `SameFirst-B` both appear in the
same converged sample. Their sanitized full-name representations must keep the
same-first/different-surname relationship and must resolve to distinct member
aliases. A probe or sanitizer that collapses them blocks the run.

### 3. Cross a UI-reload boundary

1. Run `/rgmsprobe mark reload`.
2. Run `/reload` without stopping the probe.
3. Immediately after reload, run `/rgmsprobe status` and then
   `/rgmsprobe snapshot`.
4. Wait for event activity to stop for 15 seconds and take one more snapshot.

The first status after reload must show that the bounded collection continued.
If it did not, record a probe blocker rather than silently starting a new run.

### 4. Cross a logout/login boundary

1. Run `/rgmsprobe mark logout-login`.
2. Log out to character selection normally.
3. Log back in as the same `Observer` without closing the client.
4. Immediately run `/rgmsprobe status` and `/rgmsprobe snapshot`.
5. Wait for event activity to stop for 15 seconds and take one more snapshot.

### 5. Cross a cold-restart boundary

1. Run `/rgmsprobe mark cold-restart`.
2. Log out and exit World of Warcraft normally.
3. Verify that the game process has ended completely. This distinguishes a
   cold restart from a disconnect or return to character selection.
4. Relaunch the same product and log back in as the same `Observer`.
5. Immediately run `/rgmsprobe status` and `/rgmsprobe snapshot`.
6. Wait for event activity to stop for 15 seconds and take one more snapshot.

### 6. Finalize and flush

1. Run `/rgmsprobe stop`.
2. Run `/rgmsprobe export`.
3. Run `/rgmsprobe status` and retain the final message privately.
4. Log out and exit the client normally so SavedVariables are flushed.
5. Verify that the game process has ended before reading its files.

Do not open, copy, or export the active client's SavedVariables file while WoW
is running; the in-memory value can overwrite it during logout or exit.

## Extract and review a sanitized fixture

Run the extractor from the repository root in Git Bash, using the matching
product's account-level SavedVariables file as input and a private output path
outside the checkout. The output path must be new; the extractor refuses to
overwrite an existing file. The placeholder command is:

```text
lua.exe scripts/export-runtime-probe.lua <SavedVariables input> <fixture output>
```

For example:

```text
lua.exe scripts/export-runtime-probe.lua \
  'C:/Program Files (x86)/World of Warcraft/_forever_/WTF/Account/<ACCOUNT>/SavedVariables/RGMSRuntimeProbe.lua' \
  'C:/Users/<USER>/Documents/private-rgms-evidence/forever-runtime-probe.lua'
```

The extractor must read `RGMSRuntimeProbeExport`; it must not reproduce
`RGMSRuntimeProbeDB` in its output. Run `/rgmsprobe stop` and then
`/rgmsprobe export` before extraction; the extractor accepts only a finalized
export with `complete=true`. A missing, malformed, incomplete, truncated, or
over-capacity export is a blocker.

Before copying any fixture into the repository, review it manually and confirm
all of the following:

- no account, character, guild, or real realm name appears;
- no raw GUID or club ID appears;
- repeated raw identities use the same opaque alias across all boundaries;
- distinct raw identities use different aliases;
- the two Forever surname-distinguished members remain distinct while their
  shared first-component relationship remains represented;
- product/build/interface metadata, counts, nil/presence results, event names,
  boundary markers, and timing order remain intact;
- every unavailable source value remains explicit in the corresponding
  availability map;
- inaccessible evidence and collection errors remain explicit;
- the fixture contains no SavedVariables path or other local identifier.

Keep the raw SavedVariables file and private role mapping outside the
repository. A hash of a real name or identifier is not sufficient
anonymization when its input space is small; committed evidence must use the
probe's opaque aliases.

## Evidence record

All three supplied exports pass the strict schema and privacy loader with
`complete=true` and `truncated=false`. The committed files contain only opaque
aliases and allowlisted metadata.

| Field | Retail | Forever |
| --- | --- | --- |
| Matrix status | Captured across all four required boundaries | Composite accepted: base capture covers all four boundaries; independent supplemental capture covers the required pair across initial login and reload |
| Source checkout | `dcede87` plus uncommitted issue #154 probe changes; exact immutable probe revision unavailable | Base: `dcede87` plus uncommitted changes; supplemental source checkout and exact probe revision not supplied |
| Checkout clean before run | No; the issue implementation was intentionally uncommitted | Base: no; supplemental status not supplied |
| Tester role | `Observer`; exact guild rank not supplied | `Observer`; exact guild rank not supplied |
| Client version/build | `12.1.5` / `70783` | `1.60.1` / `70888` |
| Interface version | `120105` | `16001` |
| Runtime product identifier | `1` | `18` |
| Region | `US` | `US` |
| Observed guild size | 652 | 56 in the base capture; 57 in the supplemental pair capture |
| Observer permissions | Full club roster observed; exact permission set not supplied | Full club roster observed; exact permission set not supplied |
| Local start/end and timezone | Not supplied; recorded as inaccessible evidence | Not supplied; recorded as inaccessible evidence |
| Sanitized fixture | `Tests/fixtures/runtime_contract/retail.lua` | Base: `Tests/fixtures/runtime_contract/forever.lua`; supplemental: `Tests/fixtures/runtime_contract/forever_same_first.lua` |
| Fixture SHA-256 | `C063DBB47C901EBC5B7FCE181FA2CEDB833E5D9D510BD539D257534C0C0D8CA7` | Base: `8D19E4384711494310B36CD96A107EDA541FC0086B733AEF1214340368F1844F`; supplemental: `6D20ED432A8CACA277226E471BAB5869B77C3EBA98AB2EF6B336BB909CC8507C` |
| Private raw evidence | Not supplied or committed; never commit | Not supplied or committed; never commit |
| Inaccessible evidence | Exact tester rank/times, exact immutable probe revision, and member-specific club events | The supplemental pair was not itself observed across logout/login/cold restart; exact tester rank/times, supplemental checkout/probe revision, and member-specific club events were not supplied |

### Observation results

#### Retail

- Runtime metadata remained product `1`, region `US`, version `12.1.5`, build
  `70783`, and interface `120105` across `initial`, `reload`, `logout-login`,
  and `cold-restart` sessions.
- Initial and reload observations were already converged at 652 members.
- Logout/login and cold restart both streamed through the same states:
  club ID unavailable with legacy count zero; legacy count 652 with unusable
  member identities; `C_Club` list 652 while `clubInfo.memberCount` was 101;
  then 652/652 convergence on `CLUB_MEMBERS_UPDATED`.
- The partial 101/652 observations exposed 42 alternate name aliases for 42
  stable GUID aliases. The next converged observation restored the original
  name aliases. This forbids canonicalizing member names before convergence
  and confirms GUID's correlation-only value.
- Every converged club observation used `Guild-001` and `Club-001`. The settled
  652-member name/GUID mapping was identical across all boundaries.
- `GetRealmName` was `Realm-001`; normalized/player realm was `Realm-002` when
  available; guild realm was the distinct `Realm-003`. Normalized/player realm
  was unavailable during early logout/login and cold-restart initialization.
- Evidence anchors: session 3 observations 1–12 and session 4 observations
  1–12 in `retail.lua`; automated assertions are in
  `Tests/spec/runtime_contract_evidence_spec.lua`.

#### Forever

- Runtime metadata remained product `18`, region `US`, version `1.60.1`, build
  `70888`, and interface `16001` across all required boundaries. A fifth
  unclassified `initial` session was also retained before probe stop.
- Initial and reload observations were converged at 56 members. Logout/login
  and cold restart streamed from unavailable club state and legacy count zero,
  through a populated 56-member legacy roster, to a converged 56/56 club
  roster.
- `Club-001`, `Guild-001`, and the converged 56-member name/GUID mapping were
  stable across every required boundary. No name/GUID reassignment occurred.
- `GetRealmName` was `Realm-001`, normalized realm was `Realm-002` only in the
  first two sessions, and player realm was the distinct `Realm-003`. Guild
  realm was always unavailable. Realm-shaped values therefore cannot identify
  a Forever character or guild.
- `GUILD_ROSTER_UPDATE` occurred in zero, fallback, and converged states and is
  not a completion signal. `CLUB_MEMBERS_UPDATED` and
  `INITIAL_CLUBS_LOADED` were useful re-read triggers after startup streaming.
- All 56 full-name aliases in the base capture have distinct first-component
  aliases. A separate 57-member capture contains exactly one shared-first
  group: `First-048 Surname-042` / `Guid-048` and
  `First-048 Surname-043` / `Guid-049`. The two mappings remain distinct and
  stable across all 30 converged observations in its `initial` and `reload`
  sessions.
- The supplemental capture is complete and error-free, but it contains no
  logout/login, cold-restart, unavailable, partial, or fallback observation.
  It supplies the required name-structure and disambiguation evidence; the base
  capture independently supplies cross-boundary stability evidence for
  converged complete-name values from the same product/API contract.
- Aliases, session indices, and observations are local to each fixture. This
  record does not correlate similarly numbered aliases across files or claim
  that the supplemental pair was observed during logout/login or cold restart.
- Evidence anchors: base session 3 observations 1–13 and session 4 observations
  1–12 in `forever.lua`; all observations in supplemental sessions 1–2 in
  `forever_same_first.lua`; automated assertions are in
  `Tests/spec/runtime_contract_evidence_spec.lua`.

No `CLUB_MEMBER_UPDATED` or `CLUB_MEMBER_PRESENCE_UPDATED` event was observed
on either product. Those events are not approved as retry triggers by this
record.

## Identity decision record

The decision state below is the integration contract for dependent features.
Each approved row states the inputs and failure behavior consumers may
implement from the combined evidence.

| Contract | Evidence required | Current decision |
| --- | --- | --- |
| Forever character identity | Cross-boundary complete-name stability plus same-first/different-surname disambiguation | **Approved from composite evidence.** Canonical inputs are `(productId, region, completeFullName)` from a converged `C_Club.GetMemberInfo` record. Treat the complete two-component client value as one opaque, case-preserving input; never reinterpret its second component as a realm. Exclude every realm API result and retain GUID only as optional correlation metadata. The base run establishes cross-boundary complete-name stability; the independent supplemental run establishes surname-based distinction. The captures do not define additional Unicode, whitespace, or key-encoding normalization; Feature 1.3 must preserve the complete logical value and cover those synthetic edge cases explicitly. |
| Forever guild identity | Product, region, and club-ID alias relationships across every boundary | **Approved.** Canonical inputs are `(productId, region, guildClubId)`. Guild name is display metadata. If club ID is unavailable, identity is unresolved and collection must retry. No name/realm fallback is approved or needed by the observed stable club ID. |
| Human-readable member label | Converged full-name structure and same-first/different-surname disambiguation | **Approved from composite evidence.** Display the complete two-component client value without a synthesized realm or GUID. Preserve the client-provided presentation; a missing component makes the record incomplete. |
| Roster completion and retry triggers | Initial/partial sequences, count convergence, complete member records, and event ordering on both products | **Approved.** Require guild club ID, numeric `clubInfo.memberCount`, `C_Club.GetClubMembers`, equal club/list/captured counts, and complete full-name/GUID records. Legacy roster data is diagnostic only. Re-read after `PLAYER_GUILD_UPDATE`, `GUILD_ROSTER_UPDATE`, `CLUB_MEMBERS_UPDATED`, and `INITIAL_CLUBS_LOADED`; no event alone completes a scan. Never commit during `PLAYER_LEAVING_WORLD` or `PLAYER_LOGOUT`. |

### Feature 1.3 character-identity implementation choice

The product-aware character contract is a small project-owned pure module.
Established libraries were evaluated before choosing that implementation:

- Ace3 is mature, maintained, widely adopted, documented, and compatible with
  current WoW Lua. AceDB recognizes regional unique names for profile storage,
  but Ace3 exposes no reusable roster-character identity contract and its
  redistribution terms and framework surface would add substantially more than
  this feature needs.
- LibRealmInfo is zlib-licensed, documented, and historically embedded by
  major addons, but its last release predates Forever, it is Retail-only, and
  its realm/GUID-centric model directly conflicts with the approved contract.
- LibSerialize is maintained, MIT-licensed, documented, and Lua 5.1-compatible,
  but arbitrary-table serialization would not define flavor/region validation,
  preserve the established Retail key, or keep display and sort data separate.

`Core/CharacterIdentity.lua` therefore delegates Retail construction to the
existing `Roster/Names.lua` behavior and uses a versioned, length-framed
Forever string containing product, canonical region, and the exact complete
name bytes. The encoding is intentionally opaque to consumers and avoids a
new runtime dependency while keeping every requirement directly testable.
Regions normalize to the approved uppercase codes. A Forever name must have
exactly two non-whitespace components separated by one or more ordinary
spaces; the check does not expose either component, and the original bytes,
including repeated separator spaces, remain unchanged in identity and display
data. Equality uses only the opaque key, while deterministic ordering uses the
established Retail key or Forever's separate ASCII-folded sort input, followed
by the opaque key as a tie-breaker.

### Evidence limitations and follow-on work

No additional probe run is required for issue #154. The base and supplemental
Forever fixtures are intentionally independent and must remain separate; their
sessions must not be spliced into a fabricated single run.

Exact tester rank/permissions, run times, immutable supplemental probe
revision, pair-specific logout/cold observations, and member-specific club
events were not supplied or observed. Issue #154 requires inaccessible evidence
to be recorded; these are scope limitations, not inputs to the approved
contracts, and must not be fabricated.

Dependent work may consume all four approved contracts. Feature 1.3 still owns
the key's encoding and synthetic normalization edge cases; Feature 1.4 must use
the approved no-fallback club-ID contract.

