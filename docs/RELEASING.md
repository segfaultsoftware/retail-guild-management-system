# RGMS release runbook

This runbook takes a tested commit through a local release-candidate package,
GitHub release, and **manual** CurseForge upload. RGMS has no release or upload
automation. Do not add API tokens to this repository or to `.release`.

The external commands and links in this runbook were checked on 2026-10-12
against GitHub CLI, BigWigs Packager v2.6.1, and CurseForge's author support
documentation.

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
- Never move a public tag or replace the contents of a published version. Make
  a new release instead.

The development manifest value `0.0.1-dev` is not a published release. Unless
there is a reason to declare the user-facing surface stable, start the first
public candidate at `0.1.0-rc.1` and the first public release at `0.1.0`.

## Changelog format

[`CHANGELOG.md`](../CHANGELOG.md) follows
[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).

- Add user-visible work under `Unreleased` as `Added`, `Changed`, `Deprecated`,
  `Removed`, `Fixed`, or `Security`.
- Do not paste a raw Git log. Describe the effect on users and maintainers.
- For a final release, move the relevant entries to
  `## [X.Y.Z] - YYYY-MM-DD`, using the Pacific release date, and restore an
  empty `Unreleased` section above it.
- A release candidate may retain entries under `Unreleased`; its GitHub notes
  should identify the candidate and link its QA record.

## Required access and tools

The release maintainer needs:

- push and release permission for
  `segfaultsoftware/retail-guild-management-system`;
- an authenticated GitHub CLI session (`gh auth status`);
- a CurseForge account with owner or project-member permission and any required
  two-factor authentication;
- the live Retail client and characters/permissions required by the
  [`MVP scenario checklist`](MVP_SCENARIO_CHECKLIST.md);
- Lua 5.1 for the authoritative automated run;
- Bash 4.3 or newer, `git`, `curl`, `zip`, `awk`, `grep`, and `sed` for the
  pinned BigWigs packaging script. Windows maintainers can use WSL or Git Bash.

Manual CurseForge uploads do **not** require a CurseForge API token. No
CurseForge project, project ID, repository secret, or upload workflow is
currently configured. The first release maintainer must complete the one-time
CurseForge setup below using the project owner's account.

## Update Retail support and the manifest

RGMS supports only the live Retail build that was exercised by the release QA.
It does not support Classic, PTR, or Beta clients.

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
5. During the CurseForge upload, select the exact Retail game version observed
   in this step. Do not select Classic flavors or untested Retail versions.

The interface value is a client compatibility marker, not a Lua or addon
schema version. Changing it does not replace live-client testing.

## Prepare a release candidate

Use a dedicated release branch or pull request. Replace each example version
with the version being prepared.

1. Confirm the checkout is based on the intended `main` commit and contains no
   unrelated changes:

   ```text
   git status --short --branch
   git fetch origin
   git log --oneline --decorate -5
   ```

2. Choose the next candidate, for example `0.1.0-rc.1`.
3. Update `RGMS.toc` `Version` and, if live Retail requires it, `Interface`.
4. Update `CHANGELOG.md` and any behavior documentation affected by the
   release.
5. Copy `docs/MVP_SCENARIO_CHECKLIST.md` to a tester-specific record under
   `docs/qa`, following [`docs/qa/README.md`](qa/README.md).
6. Run the full suite:

   ```text
   lua Tests/run.lua
   ```

   Expected result: exit status `0` and zero failed tests. Also confirm the
   GitHub **Tests** workflow passed for the candidate commit.

7. Review the diff, commit the candidate changes, and create an annotated local
   tag:

   ```text
   git diff --check
   git diff
   git tag -a v0.1.0-rc.1 -m "RGMS 0.1.0-rc.1"
   ```

Do not push the candidate tag until its local package has been inspected. If a
local-only candidate fails, delete that local tag, fix the release branch, and
use the next `rc.N` identifier once any candidate tag has been shared remotely.

## Build the distributable ZIP

RGMS uses `.pkgmeta` and the official
[BigWigs Packager](https://github.com/BigWigsMods/packager) to stage a single
`RGMS` addon directory and exclude development-only content. The documented
tool version is [v2.6.1](https://github.com/BigWigsMods/packager/releases/tag/v2.6.1).

From the repository root in Bash:

```text
mkdir -p .release
curl --fail --location https://raw.githubusercontent.com/BigWigsMods/packager/v2.6.1/release.sh --output .release/release.sh
bash .release/release.sh -d -n "RGMS-0.1.0-rc.1"
```

`-d` disables every upload but still creates the ZIP. The staging directory and
archives remain under ignored `.release/`. Replace the `-n` value with the
candidate version; it keeps the archive name free of the Git tag's leading
`v`. The tag at `HEAD` still supplies the embedded project version and
changelog range. If the packager does not report the expected tag as its current
version, stop and correct the checked-out tag before continuing.

List the archive without extracting it:

```text
unzip -l .release/RGMS-0.1.0-rc.1.zip
```

The archive must have exactly one top-level directory named `RGMS`. Confirm:

- `RGMS/RGMS.toc`, all manifest-listed runtime Lua files, `README.md`,
  `CHANGELOG.md`, and `LICENSE` are present;
- `RGMS.toc` contains the intended `Interface` and `Version` values;
- `.github`, `.gitignore`, `.pkgmeta`, `.release`, `docs`, `scripts`, and
  `Tests` are absent, as required by `.pkgmeta`;
- no account data, SavedVariables, credentials, editor files, or unrelated
  files are present.

On PowerShell, `Get-FileHash -Algorithm SHA256
.release\RGMS-0.1.0-rc.1.zip` records the archive checksum. On macOS or Linux,
use `sha256sum .release/RGMS-0.1.0-rc.1.zip`. Put the checksum in the QA record
and later in the GitHub release notes.

## Test the exact package

Do not treat testing the linked source checkout as package verification.

1. Preserve the development link or directory outside `Interface/AddOns`.
2. Extract the candidate ZIP so the resulting path is exactly
   `_retail_/Interface/AddOns/RGMS/RGMS.toc`.
3. Start Retail with only RGMS enabled and confirm the addon list displays the
   candidate version and does not mark it out of date.
4. Run the complete [`MVP scenario checklist`](MVP_SCENARIO_CHECKLIST.md)
   against the extracted package, recording observations in its QA record.
5. Confirm there are no Lua errors and that roster, bank, reset/recovery, UI
   position, and per-character isolation match the documented expectations.
6. Set the record disposition to `PASS`, `FAIL`, or `BLOCKED`. Do not release a
   failed or blocked candidate.
7. Restore the development link only after Retail is closed.

Before the first public release, a second person must follow
[`CONTRIBUTING.md`](../CONTRIBUTING.md) from a clean checkout and repeat this
runbook through ZIP creation and inspection. Their unpublished-package dry run
stops here; it does not require pushing a tag or creating a remote release.

## Create the first CurseForge project

Skip this section after the project exists and its ownership has been verified.

1. Sign in to the
   [CurseForge Authors dashboard](https://authors.curseforge.com/).
2. Follow CurseForge's official
   [project creation and submission guide](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project).
3. Choose World of Warcraft, use **Retail Guild Management System (RGMS)** as
   the project name if available, describe only the implemented behavior in the
   README, and select the MIT license.
4. Set the source URL to this repository and the issue tracker to this
   repository's Issues page. Do not claim Classic support, external sync, or
   any other MVP exclusion.
5. Add the resulting CurseForge project URL to the README in a normal reviewed
   commit. Keep project ownership with the release maintainer or organization;
   grant the minimum project-member permissions needed for another releaser.

CurseForge requires an uploaded file before a new project can complete
moderation. Use the manual upload procedure below and keep the candidate
unpublished when the dashboard offers that release option.

## Create an unpublished GitHub release

Only continue after package inspection and release approval. Push the reviewed
commit and its exact tag, then create a draft so the asset can be checked before
publication:

```text
git push origin HEAD
git push origin v0.1.0-rc.1
gh release create v0.1.0-rc.1 .release/RGMS-0.1.0-rc.1.zip --repo segfaultsoftware/retail-guild-management-system --verify-tag --draft --prerelease --title "RGMS 0.1.0-rc.1" --notes-file .release/release-notes.md
```

`.release/release-notes.md` should contain the relevant changelog entries, Retail
version/build and interface value, QA-record link, SHA-256 checksum, known
limitations, and the explicit MVP exclusions. It is a temporary working file;
do not put credentials in it.

Inspect the draft in GitHub and confirm the tag, target commit, title, notes,
and ZIP are exact. A draft is not a public release.

For a final version, repeat the preparation, tests, package inspection, and QA
on a final `vX.Y.Z` tag. Do not rename an RC tag or reuse its archive.

## Upload manually to CurseForge

CurseForge uploads are deliberately manual; there is no workflow, API token, or
repository secret to operate.

1. Sign in to the Authors dashboard and open the verified RGMS project.
2. Open **Files**, choose **Upload file**, and select the exact ZIP attached to
   the GitHub draft.
3. Use `RGMS X.Y.Z-rc.N` or `RGMS X.Y.Z` as the display name.
4. Choose **Beta** for an RC and **Release** for a final version. A project needs
   an approved Release file to appear normally in the CurseForge app.
5. If the dashboard offers a manual-release/unpublished option, enable it until
   verification is complete.
6. Paste the matching changelog section and select only the tested live Retail
   version from the QA record. Add no dependencies because RGMS bundles and
   requires none.
7. Submit the file and record its CurseForge file URL/status in the QA record.
   New projects and files may remain under moderation.

CurseForge's official
[file upload documentation](https://support.curseforge.com/support/solutions/articles/9000197242)
defines the current fields and release types. If its UI differs from this
runbook, stop before publishing, update the runbook in review, and record the
difference.

## Publish and verify

For an approved final release:

1. Download the ZIP from the GitHub draft and the CurseForge file. Confirm each
   SHA-256 matches the locally inspected archive.
2. Install a downloaded copy into a clean Retail addon directory and perform a
   smoke test: addon-list version, load message, `/rgms help`, roster refresh,
   and bank refresh while the default guild bank is open.
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

If an unpublished candidate fails, keep the GitHub release as a draft, withdraw
or archive the unpublished CurseForge file, fix the issue, and create a new
`rc.N`. Do not publish it and do not overwrite an uploaded archive.

If a public release is defective:

1. Record the impact and workaround in both release descriptions immediately.
2. Mark the affected CurseForge file archived or unavailable in the project
   dashboard when that control is available. Do not delete historical source
   tags or pretend downloaded copies can be recalled.
3. Edit the GitHub release title/notes to identify it as deprecated; retain the
   original tag and asset for traceability unless removal is required for a
   security or legal reason.
4. Restore a previous known-good version for users only through the supported
   store controls; do not repoint tags.
5. Prepare a PATCH hotfix from the affected release, add a `Fixed` changelog
   entry, and repeat every automated, package, live-QA, GitHub, and CurseForge
   step. Security fixes should disclose only what is safe before the hotfix is
   available.

The release is complete only when both distribution pages, their downloadable
artifacts, the QA record, and the changelog agree on version and Retail support.
