# RGMS release runbook

This runbook takes a candidate at the tip of a `release/X.Y` branch through a
canonical GitHub-built package, live Retail verification, an automated draft
GitHub release, and a **manual** CurseForge upload. Local package builds are
useful for development validation, but only the retained **Build Release Candidate**
artifact may be live-tested, promoted, or uploaded to CurseForge.

GitHub automation uses only the repository-scoped `GITHUB_TOKEN`. RGMS does not
store or use CurseForge credentials, and a maintainer can complete the entire
CurseForge upload manually when credentials or APIs are unavailable.

## Release policy

RGMS follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

- Before `1.0.0`, increment MINOR for a planned user-visible capability or
  incompatible saved-data/behavior change and PATCH for a compatible fix.
- From `1.0.0` onward, increment MAJOR for incompatible user-facing command,
  persisted-data, or documented behavior changes; MINOR for compatible
  features; and PATCH for compatible fixes.
- Use prerelease versions `X.Y.Z-rc.N` for release candidates, increasing `N`
  for every rebuilt candidate.
- Git tags are `vX.Y.Z` or `vX.Y.Z-rc.N`. The `## Version` value in `RGMS.toc`
  is the same version without the leading `v`.
- Release branches are named `release/X.Y` and retain the complete history for
  every `X.Y.Z` and `X.Y.Z-rc.N` release in that major/minor line.
- Never move a shared tag, replace a release asset, or reuse a version. Create
  a new version instead.

The development manifest value `0.0.1-dev` is not a published release. Unless
there is a reason to declare the user-facing surface stable, start the first
public candidate at `0.1.0-rc.1` and the first public release at `0.1.0`.

## What automation enforces

[`scripts/build-release.ps1`](../scripts/build-release.ps1) performs the
release-critical checks in one command:

- validate a strict semantic version and require the same `Version` in
  `RGMS.toc`;
- require release-note content under the exact bracketed or unbracketed version
  heading, or under `Unreleased` for a prerelease, before building the
  candidate;
- validate required manifest fields and every manifest-listed Lua file;
- run the complete dependency-free Lua test suite before writing an artifact;
- package only the manifest, its runtime Lua files, `README.md`,
  `CHANGELOG.md`, `LICENSE`, and `THIRD_PARTY_NOTICES.md` under one top-level
  `RGMS` directory;
- reject duplicate, missing, contributor-only, generated, metadata,
  credential, and secret-like archive paths;
- compare every archived file with its verified source content;
- build twice in the same environment with fixed entry order, timestamps,
  permissions, and storage, then require identical SHA-256 hashes; and
- refuse to overwrite an existing `RGMS-<version>.zip`.

The **Tests** workflow runs the Lua suite and package validation for every pull
request and push to `main` or `release/*`. After candidate source and a blank QA
record are at the tip of their `release/X.Y` branch, a maintainer dispatches
**Build Release Candidate** from `main` for that branch and exact commit. GitHub
runs the authoritative tests and builder once, then retains the
canonical ZIP, signed-by-context metadata, and an automation-populated QA
record as one immutable Actions artifact.

The tester downloads that artifact, live-tests its inner ZIP without
rebuilding, and commits exactly one completed QA record. The **Release**
workflow infers that record and the release version from the QA commit, then
validates the release branch tip, candidate run, artifact, checksum, commit
ancestry, and QA-only diff before requesting `release` Environment approval.
Promotion downloads the same retained artifact, tags the QA commit, attaches
the original ZIP to a draft GitHub release, downloads it again, and verifies
its checksum.
Any failed build, expired or mismatched artifact, failed or malformed QA
signoff, packaged-source change, reused version, or missing changelog section
stops promotion. Checklist boxes remain human evidence and are not automated
release gates.

## Required access and tools

The release maintainer needs:

- push and release permission for
  `segfaultsoftware/retail-guild-management-system`;
- Git and an authenticated GitHub CLI session (`gh auth status`);
- PowerShell 7 (`pwsh`) and Lua for optional local validation;
- the live Retail client and characters/permissions required by the
  [`MVP scenario checklist`](MVP_SCENARIO_CHECKLIST.md); and
- a CurseForge account with owner or project-member permission for the manual
  upload, if a CurseForge release is being prepared.

GitHub-hosted workflows install Lua 5.1 and already provide PowerShell 7 for the
authoritative candidate build. No package manager or downloaded packaging
script is used by the builder.

## Update Retail support and release metadata

RGMS supports only the live Retail build exercised by release QA. It does not
support Classic, PTR, or Beta clients.

1. In the target live Retail client, run:

   ```text
   /dump GetBuildInfo()
   /dump select(4, GetBuildInfo())
   ```

2. Record the complete version/build string and numeric interface value in the
   candidate's QA record.
3. Compare the numeric value with `## Interface` in `RGMS.toc`. If it differs,
   update the manifest before QA and rerun the complete automated and live
   matrix. Never add an untested future interface value.
4. Set `## Version` to the candidate or final version without `v`.
5. Add user-visible changes under `Unreleased` in `CHANGELOG.md`. Before a
   final release, move them to `## [X.Y.Z] - YYYY-MM-DD` using the Pacific
   release date and restore an empty `Unreleased` section. An RC may use the
   current `Unreleased` section in its generated draft notes.

## Prepare a release-branch candidate

Use the dedicated release-line branch. Replace the example version in every
command with the version being prepared.

1. For a new major/minor line, confirm the checkout is at the intended `main`
   commit and contains no unrelated changes. For a patch, start from the
   existing `release/X.Y` branch and cherry-pick only the fixes intended for
   that patch:

   ```text
   git status --short --branch
   git fetch origin
   git log --oneline --decorate -5
   ```

2. Create and check out `release/X.Y` for a new line, or check out its existing
   remote branch for a patch. Make and commit any required `CHANGELOG.md` or
   behavior-documentation updates so the branch is clean before preparation.

   ```text
   git switch -c release/0.1
   ```

3. From Git Bash at the repository root, run the release preparation command.
   Pass the values observed from `GetBuildInfo()` when they are available:

   ```text
   bash ./scripts/prepare-release.sh \
     --version 0.1.0-rc.1 \
     --tester YOUR-NAME \
     --retail-version "12.1.0 (build 12345)" \
     --interface 120100
   ```

   The Bash entry point updates `RGMS.toc` and creates a prepopulated,
   tester-specific record under `docs/qa`. Candidate provenance, automated
   result, and package checksum remain pending until GitHub builds the package.
   The script does not build, commit, push, tag, or install the addon. A second
   invocation with the same version must fail rather than replace the record.
4. Review the manifest and blank QA record, commit all candidate source and
   metadata, and push `release/X.Y`. Do not merge the release preparation back
   to `main` as part of this procedure.
5. Copy the full 40-character SHA at the remote release branch tip. Dispatch
   the build before pushing anything else to that branch. A cherry-picked fix
   has a new SHA on the release branch; use that release-branch history, not
   the original SHA from `main`.

## Build and inspect the canonical candidate

1. Manually dispatch **Build Release Candidate** from `main` with the release
   branch, version, and candidate commit. The equivalent authenticated GitHub
   CLI command is:

   ```text
   gh workflow run "Build Release Candidate" \
     --repo segfaultsoftware/retail-guild-management-system \
     --ref main \
     -f branch=release/0.1 \
     -f version=0.1.0-rc.1 \
     -f commit=FULL_40_CHARACTER_CANDIDATE_COMMIT_SHA
   ```

2. Wait for the run to succeed. Its summary records the candidate commit,
   workflow run ID, immutable artifact ID, automated test result, package
   SHA-256, and authenticated artifact link.
3. Download and extract the workflow artifact wrapper. It must contain exactly
   `RGMS-0.1.0-rc.1.zip`, `candidate.json`, and `qa-record.md`. Do not rename or
   rebuild the inner ZIP.
4. Confirm the inner ZIP's SHA-256 matches both the workflow summary and
   `candidate.json`. Inspect it: it must contain exactly one `RGMS/` root with
   `RGMS.toc`, all manifest-listed runtime Lua files, `README.md`,
   `CHANGELOG.md`, `LICENSE`, and `THIRD_PARTY_NOTICES.md`. It must not contain
   `.github`, `.git`, `.release`, `docs`, `scripts`, `Tests`, fixtures, caches,
   local tooling, repository metadata, SavedVariables, or credentials.
5. Replace the prepared QA record at the path shown in the workflow summary
   with `qa-record.md`. Its candidate commit, workflow run ID, automated result,
   package SHA-256, and evidence path are already populated. Do not copy or
   retype these values.

Actions artifacts expire after the configured retention period, currently 90
days. Finish QA and promotion before expiration. If the artifact expires, build
and test a new RC identifier rather than substituting a local package.

## Test the exact package in Retail

Do not treat testing the linked source checkout or a local rebuild as package
verification.

1. Preserve the development link or directory outside `Interface/AddOns`.
2. Extract the canonical candidate ZIP so the resulting path is exactly
   `_retail_/Interface/AddOns/RGMS/RGMS.toc`.
3. Start Retail with only RGMS enabled. Confirm the addon list displays the
   candidate version and does not mark it out of date.
4. Run the complete [`MVP scenario checklist`](MVP_SCENARIO_CHECKLIST.md)
   against the extracted package, recording every observation in its QA
   record.
5. Confirm there are no Lua errors and roster, bank, reset/recovery, UI
   position, and per-character isolation match the documented expectations.
6. Complete the QA signoff with the tester's GitHub username, Pacific date, and
   `PASS` or `FAIL`. Use `FAIL` and record an owner when testing is blocked. Do
   not tag or release a failed candidate.
7. Restore the development link only after Retail is closed.
8. Commit exactly one completed QA record as the only file change and push it
   to the same `release/X.Y` branch; do not include source, workflow, changelog,
   manifest, or another QA-record change.

Before the first public release, a second person must follow
[`CONTRIBUTING.md`](../CONTRIBUTING.md) from a clean checkout and repeat this
runbook through canonical artifact download and inspection. Record that review
in the evidence section of the same QA record. That dry run does not require a
tag or remote release, and the final QA signoff remains a single-person record.

## Tag and create the automated draft

Only continue after automated checks, package inspection, live QA, and release
approval all pass.

Before the first promotion, create a GitHub Environment named `release` in the
repository settings and configure at least one required reviewer. The workflow
checks this configuration before it performs any release mutation.

1. Finish the candidate QA record. The checklist is human evidence; unchecked
   boxes do not fail automation. Document exceptions, then add exactly one
   signoff block using the tester's GitHub username and Pacific date:

   ```text
   ## QA signoff

   - QA GitHub username: @YOUR-NAME
   - QA date (Pacific): YYYY-MM-DD
   - Result: PASS
   ```

   `FAIL` is valid recorded evidence but stops release promotion.
2. Commit and push exactly that completed QA record as the only file change on
   the same `release/X.Y` branch after review and required checks pass.
3. Copy the full 40-character SHA at the release branch tip, then manually
   dispatch the **Release** workflow from `main`. Supply the branch and that QA
   commit SHA. The workflow infers the record path and release version.
   The equivalent authenticated GitHub CLI command is:

   ```text
   gh workflow run Release \
     --repo segfaultsoftware/retail-guild-management-system \
     --ref main \
     -f branch=release/0.1 \
     -f qa_commit=FULL_40_CHARACTER_QA_COMMIT_SHA
   ```

4. Wait for preflight. It validates that the QA commit is the named release
   branch tip, the candidate is its ancestor, and all post-candidate changes
   affect exactly the inferred record. It also requires that the recorded
   workflow run succeeded, exactly one matching immutable artifact remains
   available, the signoff is `PASS`, and the downloaded ZIP has the exact
   live-tested checksum. It does not inspect checkbox state.
5. Approve the waiting `release` Environment deployment. The promotion job
   rechecks version availability, creates and pushes the annotated tag, creates
   a draft named `RGMS 0.1.0-rc.1`, attaches the original candidate ZIP,
   downloads it again, and verifies the tag, metadata, asset name, and
   checksum. It never uploads to CurseForge or publishes the GitHub release.
6. Review the workflow's verified-release summary and resulting draft. Confirm
   the candidate artifact, live-tested ZIP, GitHub release asset, and later
   CurseForge upload all have the same SHA-256.

If preflight fails before the tag exists, correct only the QA record or workflow
input and rerun it against the same retained artifact. If source or packaged
content changes, or the candidate artifact expires, prepare and test the next
RC identifier. If promotion fails after creating the tag, do not create or
upload a replacement artifact under that version; fix the cause and use the
next RC. The workflow never overwrites or reuses a tag, release, or asset.

For a final version, repeat every preparation, automated, package, live-QA,
checksum, and draft-inspection step on a final `vX.Y.Z` tag. Do not rename an RC
tag or reuse its archive.

## Create the first CurseForge project

Skip this section after the project exists and its ownership has been verified.

1. Sign in to the
   [CurseForge Authors dashboard](https://authors.curseforge.com/).
2. Follow CurseForge's official
   [project creation and submission guide](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project).
3. Choose World of Warcraft, use **Retail Guild Management System (RGMS)** as
   the project name if available, describe only implemented behavior in the
   README, and select the MIT license.
4. Set the source URL to this repository and the issue tracker to this
   repository's Issues page. Do not claim Classic support, external sync, or
   any other MVP exclusion.
5. Add the resulting CurseForge project URL to the README in a reviewed commit.
   Keep ownership with the release maintainer or organization and grant the
   minimum project-member permissions another releaser needs.

CurseForge requires an uploaded file before a new project can complete
moderation. Use the manual procedure below and keep the candidate unpublished
when the dashboard provides that option.

## Upload manually to CurseForge

CurseForge uploads are deliberately manual. There is no project ID, API token,
repository secret, or upload workflow to configure, and credentials must never
be placed in the repository, `.release`, command output, or GitHub logs.

1. Sign in to the Authors dashboard and open the verified RGMS project.
2. Open **Files**, choose **Upload file**, and select the exact ZIP downloaded
   from and verified against the GitHub draft.
3. Use `RGMS X.Y.Z-rc.N` or `RGMS X.Y.Z` as the display name.
4. Choose **Beta** for an RC and **Release** for a final version. A project
   needs an approved Release file to appear normally in the CurseForge app.
5. If offered, keep the file unpublished until verification is complete.
6. Paste the matching changelog section, select only the tested live Retail
   version from the QA record, and add no dependencies.
7. Submit the file and record its CurseForge URL/status in the QA record. New
   projects and files may remain under moderation.

If the dashboard differs from the runbook, stop before publishing, update the
runbook in review, and record the difference. Manual upload remains the
supported fallback if API access or credentials are unavailable.

## Publish and verify

For an approved final release:

1. Download the ZIP from the GitHub draft and CurseForge. Confirm both SHA-256
   hashes match the locally inspected artifact and the checksum in the draft
   notes.
2. Install a downloaded copy into a clean Retail addon directory and smoke
   test the addon-list version, load message, `/rgms help`, roster refresh, and
   bank refresh while the default guild bank is open.
3. Publish the CurseForge file, then publish the GitHub draft:

   ```text
   gh release edit v0.1.0 --repo segfaultsoftware/retail-guild-management-system --draft=false --latest
   ```

4. Verify the GitHub release is public, its tag resolves to the tested commit,
   and its asset downloads with the recorded checksum.
5. After CurseForge moderation, verify the project page and app offer the final
   file for the intended Retail version and no Classic flavor.
6. Restore `RGMS.toc` on `main` to the next development version only in a new
   post-release commit; never change the released tag.

## Failure, rollback, deprecation, and hotfixes

If an unpublished candidate fails, leave its GitHub release as a draft,
withdraw or archive the unpublished CurseForge file, fix the issue, and create
a new `rc.N`. Do not publish, overwrite, or silently replace it.

If a public release is defective:

1. Record the impact and workaround in both release descriptions.
2. Mark the affected CurseForge file archived or unavailable when that control
   exists. Do not delete source tags or pretend downloaded copies can be
   recalled.
3. Edit the GitHub release title/notes to identify it as deprecated, retaining
   the original tag and asset unless security or legal requirements demand
   removal.
4. Restore a known-good version only through supported store controls; never
   repoint tags.
5. Cherry-pick the fix onto the affected `release/X.Y` branch, prepare the next
   PATCH version and QA record there, and repeat every automated, package,
   live-QA, GitHub, and CurseForge step.

The release is complete only when both distribution pages, their downloaded
artifacts, QA records, changelog, version, checksum, and Retail support agree.
