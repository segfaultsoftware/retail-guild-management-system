# RGMS release runbook

This runbook takes a tested commit through a reproducible local package, live
Retail verification, an automated draft GitHub release, and a **manual**
CurseForge upload. The repository-owned builder is the only supported package
path; local builds and tag builds use the same command and validation.

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
- validate required manifest fields and every manifest-listed Lua file;
- run the complete dependency-free Lua test suite before writing an artifact;
- package only the manifest, its runtime Lua files, `README.md`,
  `CHANGELOG.md`, and `LICENSE` under one top-level `RGMS` directory;
- reject duplicate, missing, contributor-only, generated, metadata,
  credential, and secret-like archive paths;
- compare every archived file with its verified source content;
- build twice with fixed entry order, timestamps, permissions, and storage,
  then require identical SHA-256 hashes; and
- refuse to overwrite an existing `RGMS-<version>.zip`.

The **Tests** workflow runs the Lua suite and package validation for every pull
request and push to `main`. A tag matching `v*.*.*` starts the **Release**
workflow, which validates the stricter semantic-version pattern, rebuilds from
the tagged revision, prepares notes from the matching changelog section, and
attaches the exact verified ZIP to a draft GitHub release. Any failed test,
manifest mismatch, invalid archive, reused release, or missing changelog
section stops the workflow before a new draft release is created.

## Required access and tools

The release maintainer needs:

- push and release permission for
  `segfaultsoftware/retail-guild-management-system`;
- Git and an authenticated GitHub CLI session (`gh auth status`);
- PowerShell 7 (`pwsh`) on Windows, macOS, or Linux;
- Lua 5.1 for the authoritative automated run;
- the live Retail client and characters/permissions required by the
  [`MVP scenario checklist`](MVP_SCENARIO_CHECKLIST.md); and
- a CurseForge account with owner or project-member permission for the manual
  upload, if a CurseForge release is being prepared.

GitHub-hosted workflows install Lua 5.1 and already provide PowerShell 7. No
package manager or downloaded packaging script is used by the builder.

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

## Build and inspect a release candidate

Use a dedicated release branch or pull request. Replace the example version in
every command with the version being prepared.

1. Confirm the checkout is based on the intended `main` commit and contains no
   unrelated changes:

   ```text
   git status --short --branch
   git fetch origin
   git log --oneline --decorate -5
   ```

2. Update `RGMS.toc`, `CHANGELOG.md`, and any affected behavior
   documentation. Copy `MVP_SCENARIO_CHECKLIST.md` to a tester-specific record
   under `docs/qa`, following [`docs/qa/README.md`](qa/README.md).
3. From the repository root, run the one supported build command:

   ```text
   pwsh ./scripts/build-release.ps1 -Version 0.1.0-rc.1
   ```

   Expected result: the command reports zero Lua test failures, lists every ZIP
   entry, prints a SHA-256 checksum, and creates
   `.release/RGMS-0.1.0-rc.1.zip`. A second invocation with the same output
   location must fail instead of replacing that file.
4. Inspect the printed list. It must contain exactly one `RGMS/` root with
   `RGMS.toc`, all manifest-listed runtime Lua files, `README.md`,
   `CHANGELOG.md`, and `LICENSE`. It must not contain `.github`, `.git`,
   `.release`, `docs`, `scripts`, `Tests`, fixtures, caches, local tooling,
   repository metadata, SavedVariables, or credentials.
5. Record the printed SHA-256 checksum in the candidate QA record. To confirm
   it later on PowerShell, run:

   ```text
   Get-FileHash -Algorithm SHA256 .release/RGMS-0.1.0-rc.1.zip
   ```

The command stages nothing outside `.release`, which is ignored by Git.

## Test the exact package in Retail

Do not treat testing the linked source checkout as package verification.

1. Preserve the development link or directory outside `Interface/AddOns`.
2. Extract the candidate ZIP so the resulting path is exactly
   `_retail_/Interface/AddOns/RGMS/RGMS.toc`.
3. Start Retail with only RGMS enabled. Confirm the addon list displays the
   candidate version and does not mark it out of date.
4. Run the complete [`MVP scenario checklist`](MVP_SCENARIO_CHECKLIST.md)
   against the extracted package, recording every observation in its QA
   record.
5. Confirm there are no Lua errors and roster, bank, reset/recovery, UI
   position, and per-character isolation match the documented expectations.
6. Set the record disposition to `PASS`, `FAIL`, or `BLOCKED`. Do not tag or
   release a failed or blocked candidate.
7. Restore the development link only after Retail is closed.

Before the first public release, a second person must follow
[`CONTRIBUTING.md`](../CONTRIBUTING.md) from a clean checkout and repeat this
runbook through ZIP creation and inspection. Record the result in a second QA
record. That dry run does not require a tag or remote release.

## Tag and create the automated draft

Only continue after automated checks, package inspection, live QA, and release
approval all pass.

1. Commit the completed candidate work and QA evidence. Confirm the working
   tree is clean, then rebuild once from that exact commit. If an older local
   file occupies the default artifact path, preserve it elsewhere or remove
   that exact ignored file before rebuilding; the builder will never overwrite
   it.
2. Create an annotated tag whose version exactly matches `RGMS.toc`:

   ```text
   git tag -a v0.1.0-rc.1 -m "RGMS 0.1.0-rc.1"
   ```

3. Push the reviewed commit, then the tag:

   ```text
   git push origin HEAD
   git push origin v0.1.0-rc.1
   ```

4. Wait for the **Release** workflow. It runs tests and the same builder before
   creating a draft named `RGMS 0.1.0-rc.1`. It never uploads to CurseForge or
   publishes the GitHub release.
5. Inspect the draft's tag, target commit, title, changelog notes, SHA-256, and
   ZIP. Download the asset and confirm its SHA-256 matches the locally verified
   package. The fixed archive metadata makes clean builds of the same revision
   byte-for-byte reproducible across supported PowerShell environments.

If the tag workflow fails, do not create or upload an artifact manually under
that version. Fix the cause and use the next RC identifier after any tag has
been shared. If a draft already exists, the workflow stops rather than
overwriting or reusing it; inspect and resolve that draft explicitly.

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
5. Prepare a PATCH hotfix, add a `Fixed` changelog entry, and repeat every
   automated, package, live-QA, GitHub, and CurseForge step.

The release is complete only when both distribution pages, their downloaded
artifacts, QA records, changelog, version, checksum, and Retail support agree.
