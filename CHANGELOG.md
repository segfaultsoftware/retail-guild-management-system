# Changelog

All notable user-visible changes to RGMS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
