# Changelog

All notable user-visible changes to RGMS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.4.0

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
