# Changelog

All notable user-visible changes to RGMS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Changed

- Consolidated release packaging, artifact retention, tagging, and GitHub
  publication into one main-branch Create Release workflow, with release
  preparation now promoting the changelog and updating the manifest directly.
- Highlighted the exact Mains/Alts characters that match active name and tag
  filters while retaining the rest of each matching group for context.
- Tightened and raised the Mains/Alts Filter Tags control, increased its label
  size, and lowered the text slightly for a more balanced, readable pill.
- Restyled Roster and Guild Bank dropdown radio controls with compact slate
  rings, pink selection dots, and spacing aligned with the portal controls.
- Replaced the per-view contextual scan labels with a prominent centered
  indicator on a darker full-window overlay rendered above all page content.
- Replaced the Roster and Guild Bank text refresh buttons with standalone,
  clickable refresh icons and contextual tooltips.

### Fixed

- Hid the Roster, Mains/Alts, and Guild Bank report scrollbars when their
  selected content fits within the viewport, while retaining them for overflow.

## 1.0.1

### Fixed

- Click-dragging in editable text controls now preserves native text selection
  instead of moving the main RGMS window.
- Tag pills now use stable half-circle endcaps and compositor-safe text
  refreshes, preventing detached circular ends and missing labels.

## 1.0.0

### Added

- Added click-and-drag window movement from anywhere inside the main RGMS
  window while preserving scan-lock behavior and saved placement.
- Added persistent per-character tags and combined tag/name filtering to
  Mains/Alts, including inline creation, assignment previews, AND filtering,
  rounded capsule styling, full-group context, migration, reset, and
  roster-reconciliation support.
- Added live ordered-subsequence character-name search to Mains/Alts while
  preserving group order, full-group context, hidden selections, and search
  state across in-view report updates.

### Fixed

- Dropdown selections and Roster group headings now force their prepared text
  to render when first shown, and duplicate rank names remain distinguishable.
- Clicking anywhere outside a Mains/Alts tag editor now closes it without
  blocking controls inside RGMS, discards unsubmitted tag text, and treats the
  active character's tag icon as a close toggle instead of reopening it.
- Replaced the Mains/Alts Tags pills with compact tag icons that mirror the
  Note column's empty and populated states and leave the header unlabeled.
- Reduced the empty Mains/Alts selection column so its checkbox and expand
  chevron are separated by only four pixels.
- Tag previews no longer appear while a character's tag editor is open.
- Dropdown menus now apply RGMS typography without calling a font API that is
  disallowed on Blizzard-managed menu elements.
- Mains/Alts now recycles only the visible row controls while scrolling large
  guild rosters, avoiding the stutter caused by moving hundreds of live rows.

## 0.4

### Added

- Added per-character numeric roster-rank and guild-bank-tab selections, modern
  dropdown behavior, per-view session scrolling, and a global scan interaction
  lock with behavior-focused coverage.
- Bundled the Inter Regular and SemiBold fonts, the selected pink RGMS logo,
  and the minimal Lucide icon set used by the portal.

### Fixed

- Contextual dropdowns now hide with their inactive view, sidebar tab labels
  render only once, and the header logo renders above its background.
- Expanding or collapsing a Mains/Alts group now keeps the clicked main at the
  same visible row, including near the bottom of the table.
- Guild Bank item rows now render their numeric slot position in a dedicated
  fixed-width cell, with Slot and Count centered in their columns.
- Guild Bank status now stacks the overall scan and selected-tab accessibility
  timestamps on separate contextual-bar lines.
- The Mains/Alts Note header and note icons are centered within their column.
- The animated scan indicator now includes a visible `Scanning...` label on
  every main view while the global scan lock is active.
- The RGMS minimap button now uses LibDBIcon so it follows the active minimap's
  size and shape and integrates with EllesmereUI and MinimapButtonButton.

### Changed

- Redesigned RGMS as a fixed 840x560 management portal with a contextual
  header, left navigation, dashboard tables, modern controls, RGMS tooltips,
  and a restyled Character Note editor.
- Closing RGMS no longer cancels an active guild-bank scan, and every open now
  starts on Roster while retaining the character's saved window position.
- Release candidates and patch releases can now be built and promoted from
  validated `release/X.Y` branches while workflow definitions remain anchored
  to `main`.

## 0.2.0

### Added

#### Mains/Alts Tab

- Added an alphabetically sorted view of guild characters.
- Added expandable main/alt groups.
- Added multi-character selection for creating groups and adding characters to existing groups.
- Added controls for promoting an alt to main or removing an alt from a group.
- Added account-wide, per-guild character notes with note indicators and a multiline editor.
- Added stable scrolling that preserves reading position and focuses completed group changes.

#### Minimap

- Added a draggable RGMS minimap button that toggles the Roster window.
- The minimap button remembers its position account-wide.
- RGMS remains accessible through `/rgms`.

#### Diagnostics

- Added session-only `/rgms debug` logging for guild-bank scans.

### Changed

- Roster and guild-bank data are now shared across characters on an account while remaining separated by guild and realm.
- Existing per-character roster and bank data are migrated safely into account-wide storage.
- Main/alt groups and notes are automatically reconciled after successful roster scans.
- `/rgms reset` now clears the current guild’s roster, bank, groups, and notes while preserving window placement.

## 0.1.0-rc.8

### Added

- Several internal pipeline issues were addressed to try to get releases out quicker and more foolproof.

## 0.1.0-rc2

### Fixed

- Guild-bank scans now retry unexpectedly empty accessible tabs three times at
  one-second intervals before accepting the tab as genuinely empty.

### Added

- Contributor, testing, packaging, licensing, and manual release documentation.
- A repository-owned deterministic package builder with manifest, runtime-file,
  archive-layout, forbidden-file, and reproducibility validation.
- Pull-request and `main` package validation plus version-tag automation that
  attaches the verified ZIP and changelog notes to a draft GitHub release.

No public RGMS version has been released yet. The first release will move these
entries into a dated version section.
