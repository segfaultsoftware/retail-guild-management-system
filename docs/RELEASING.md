# Releasing RGMS

RGMS releases are built, retained, tagged, and published by the manually
dispatched **Create Release** GitHub Actions workflow. Development and release
preparation happen on `main`; release branches and separate QA promotion commits
are not part of the release process.

The workflow is the only supported source of public release ZIPs. Local package
builds remain useful for development checks, but they must not be substituted
for the ZIP built and attached by **Create Release**.

## Release versions

Use semantic versions without a leading `v`:

- final release: `X.Y.Z`, such as `1.1.0`
- prerelease: `X.Y.Z-rc.N`, such as `1.1.0-rc.1`

The workflow creates an annotated `vX.Y.Z` or `vX.Y.Z-rc.N` tag. Final releases
are marked latest; release candidates are published as GitHub prereleases.
Tags, release names, and uploaded assets are never overwritten or reused.

## Prerequisites

Before preparing a release, confirm that:

- the working tree on `main` is clean;
- the intended user-visible changes are under `## Unreleased` in
  `CHANGELOG.md`;
- the complete automated test suite passes;
- the addon has been exercised against the intended live Retail client;
- `/dump GetBuildInfo()` and `/dump select(4, GetBuildInfo())` provide the
  Retail build text and numeric interface value used below.

The project owner may perform a full regression before release, but no separate
QA record, QA-only commit, release branch, or GitHub Environment approval is
required by the release workflow.

## Prepare the release commit

From Git Bash on a clean `main` branch, run:

```text
bash ./scripts/prepare-release.sh \
  --version 1.1.0 \
  --retail-version "12.1.0 (build 12345)" \
  --interface 120100
```

All three values are required. The script:

- refuses to run outside `main` or with a dirty working tree;
- validates the release and interface formats;
- updates the `Version` and `Interface` fields in `RGMS.toc`;
- leaves a fresh `## Unreleased` heading and promotes its previous content to
  `## <version>` in `CHANGELOG.md`;
- refuses to reuse an existing local tag or changelog version section;
- prints the supplied Retail build for review;
- never builds, commits, pushes, tags, or publishes anything.

Review the diff, run the automated suite, then commit and push the two prepared
files to `main`. Copy the resulting full 40-character commit SHA.

## Create the release

Dispatch **Create Release** from `main` with exactly two inputs:

- `version`: the same version passed to `prepare-release.sh`, without `v`;
- `commit`: the full 40-character SHA at the current `main` tip.

The equivalent authenticated GitHub CLI command is:

```text
gh workflow run "Create Release" \
  --repo segfaultsoftware/retail-guild-management-system \
  --ref main \
  -f version=1.1.0 \
  -f commit=FULL_40_CHARACTER_MAIN_COMMIT_SHA
```

The workflow then:

1. verifies the version, SHA, `main` tip, `RGMS.toc`, changelog section, and
   availability of the matching tag and release;
2. installs Lua 5.1 and runs the deterministic release builder, including the
   complete automated test suite and package validation;
3. retains `RGMS-<version>.zip` as a workflow artifact for 90 days;
4. prepares release notes from the promoted changelog section;
5. rechecks the `main` tip and version availability before remote mutation;
6. creates and pushes the annotated tag;
7. publishes the GitHub release with the same ZIP attached;
8. downloads the public asset and verifies its SHA-256 checksum against the
   package built earlier in the run.

The completed workflow summary includes the tag, commit, test result, retained
artifact ID, package checksum, and public release URL.

If validation or packaging fails before the tag is created, correct the source
or inputs and dispatch a new run. If a run fails after creating the tag, do not
move or replace that tag and do not upload different bytes under the same
version; diagnose the partial release and use the next appropriate version.

## Upload manually to CurseForge

CurseForge uploads remain manual. No project ID, API token, repository secret,
or upload workflow is required, and credentials must never be placed in the
repository, `.release`, command output, or GitHub logs.

1. Download the ZIP attached to the published GitHub release.
2. Confirm its SHA-256 matches the **Create Release** workflow summary.
3. Sign in to the CurseForge Authors dashboard and open the RGMS project.
4. Upload that exact ZIP without rebuilding or renaming its contents.
5. Use `RGMS X.Y.Z-rc.N` or `RGMS X.Y.Z` as the display name.
6. Choose **Beta** for an RC and **Release** for a final version.
7. Paste the matching changelog section, select the tested live Retail version,
   add no dependencies, and submit the file.
8. After moderation, verify that the project page and app offer the intended
   Retail file and no Classic flavor.

CurseForge moderation is separate from the GitHub release and does not require
a repository QA record or a second GitHub Actions promotion step.

## Defective releases and hotfixes

If a public release is defective:

1. describe the impact and workaround in the GitHub and CurseForge release
   descriptions;
2. archive or mark the affected CurseForge file unavailable when possible;
3. retain the original GitHub tag and asset unless security or legal concerns
   require removal;
4. prepare the fix and changelog entry on `main`;
5. release a new PATCH version through the complete process above.
