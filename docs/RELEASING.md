# Releasing RGMS

RGMS releases are prepared on `main` and published by the manually dispatched
**Create Release** GitHub Actions workflow. The workflow builds one canonical
ZIP, publishes and verifies it on GitHub, and automatically submits that exact
asset to CurseForge for final releases.

Local package builds remain useful for development checks, but they must not be
substituted for the ZIP built and attached by **Create Release**.

## Release versions

Use semantic versions without a leading `v` or build metadata:

- final release: `X.Y.Z`, such as `1.1.0`;
- prerelease: `X.Y.Z-<prerelease>`, such as `1.1.0-rc.1`,
  `1.1.0-beta.2`, or `1.1.0-preview`.

Only an exact `X.Y.Z` is a CurseForge release. Every accepted prerelease is a
GitHub prerelease for internal testing and skips all CurseForge credential,
lookup, and upload work.

The workflow creates an annotated `v<version>` tag. Tags, release names, and
uploaded assets are never overwritten or reused.

## One-time CurseForge setup

A repository administrator must complete this once before the next final
release:

1. Sign in to the CurseForge account that owns or can upload files to project
   [1741733](https://www.curseforge.com/wow/addons/retailguildmanagementsystem).
2. Open [CurseForge API Tokens](https://www.curseforge.com/account/api-tokens)
   and generate an author API token with a descriptive name such as
   `RGMS GitHub Actions`.
3. In the GitHub repository, open **Settings > Secrets and variables > Actions**.
4. Create a **repository secret** named exactly `CURSEFORGE_API_TOKEN` and
   paste the token as its value.
5. Do not add the token as a variable, workflow input, environment file,
   repository file, command example, issue, log, or artifact.

No GitHub personal access token is needed. The workflow uses GitHub's scoped
`GITHUB_TOKEN` for its own repository and sends the CurseForge token only in
the author API's `X-Api-Token` request header.

If the CurseForge token is rotated or revoked, replace the value of the same
GitHub Actions secret. Final-release preflight fails before creating a GitHub
tag or release when the secret is missing, invalid, or cannot resolve exactly
one matching Retail version.

## Prepare a release

Before preparation, confirm that:

- the working tree on `main` is clean;
- user-visible changes are under `## Unreleased` in `CHANGELOG.md`;
- the complete automated test suite passes;
- the addon has been exercised against the intended live Retail client;
- `/dump GetBuildInfo()` and `/dump select(4, GetBuildInfo())` provide the
  Retail version and numeric interface value. The stored Retail text must begin
  with `X.Y.Z`; an optional build suffix may be retained for provenance.

From Git Bash on a clean `main` branch, run:

```text
bash ./scripts/prepare-release.sh \
  --version 1.1.0 \
  --retail-version "12.1.5" \
  --interface 120105
```

All three values are required. The script:

- validates an exact final or any valid SemVer prerelease version;
- updates `Version`, `Interface`, and `X-RGMS-Retail-Version` in
  `RGMS.toc`;
- preserves the complete supplied single-line Retail text, for example
  `## X-RGMS-Retail-Version: 12.1.5` or
  `## X-RGMS-Retail-Version: 12.1.5 (build 12345)`;
- leaves the stable `## X-Curse-Project-ID: 1741733` declaration intact;
- leaves a fresh `## Unreleased` heading and promotes its previous content to
  `## <version>` in `CHANGELOG.md`;
- never builds, commits, pushes, tags, or publishes anything.

Review the diff, run the automated suite, then commit and push the prepared
`RGMS.toc` and `CHANGELOG.md` files to `main`. Copy the resulting full
40-character commit SHA.

## Create the release

Dispatch **Create Release** from `main` with two inputs:

- `version`: the same version passed to `prepare-release.sh`, without `v`;
- `commit`: the full 40-character SHA at the current `main` tip.

The Actions run list labels each dispatch as **Create Release vX.Y.Z** so runs
for different addon versions can be distinguished at a glance.

The equivalent authenticated GitHub CLI command is:

```text
gh workflow run "Create Release" \
  --repo segfaultsoftware/retail-guild-management-system \
  --ref main \
  -f version=1.1.0 \
  -f commit=FULL_40_CHARACTER_MAIN_COMMIT_SHA
```

The jobs run in this order:

1. **Validate** checks the dispatch inputs, current `main` tip, manifest
   metadata, changelog, tag, and release availability without changing external
   state.
2. **Build and test** runs the complete suite, creates the deterministic ZIP,
   records its SHA-256, and retains it as a workflow artifact for 90 days.
3. **CurseForge preflight** runs only for exact final versions. It authenticates
   with the configured secret, extracts the leading `X.Y.Z` from
   `X-RGMS-Retail-Version`, queries CurseForge's current human-readable game
   versions, and requires exactly one matching numeric game-version ID. No
   per-patch CurseForge ID is stored in the repository.
4. **Publish GitHub** rechecks the target, creates and pushes the annotated tag,
   publishes the GitHub release, downloads its attached ZIP, and verifies it
   against the build checksum.
5. **Publish CurseForge** runs only for exact final versions. It downloads the
   public GitHub release asset, verifies the SHA-256 again, and submits those
   exact bytes once to the documented author Upload API.

The CurseForge file is submitted as:

- filename: `RGMS-X.Y.Z.zip`;
- display name: `RGMS X.Y.Z`;
- release type: **Release**;
- changelog: the matching `CHANGELOG.md` section as Markdown;
- supported version: the single Retail ID resolved in preflight;
- release option: public automatically after CurseForge approval;
- relationship: LibDBIcon-1.0 project `15552` as an embedded library.

LibDBIcon-1.0, LibDataBroker-1.1, CallbackHandler-1.0, and LibStub remain bundled
inside the RGMS ZIP. Users do not need to install them separately.

A successful summary contains the CurseForge file ID and direct URL, filename,
display name, full Retail version, Retail game-version ID, and the same SHA-256
recorded for the GitHub asset. The workflow considers the upload successful only
when CurseForge accepts it and returns a positive numeric file ID; it does not
wait for moderation or public visibility.

## Failure and retry behavior

If validation, building, or final-release CurseForge preflight fails, no GitHub
tag or release is created. Correct the source, input, secret, or CurseForge
version configuration and dispatch a new run.

If **Publish CurseForge** fails after **Publish GitHub** succeeds:

1. Leave the verified GitHub tag, release, and ZIP unchanged.
2. Open the failed workflow run and select **Re-run failed jobs**. This retries
   the failed CurseForge job without recreating the successful GitHub release.
3. If the request timed out or may have reached CurseForge, first open the
   project's **Files** dashboard and look for the same `RGMS X.Y.Z` display
   name. The author Upload API does not document an idempotency key or a safe
   duplicate-upload check, so do not retry until you have checked.

The upload request itself is not automatically retried within a job.

If a run fails after creating the Git tag but before GitHub publication is
verified, do not move or replace the tag and do not upload different bytes
under the same version. Diagnose the partial release and use the next
appropriate version.

## Manual CurseForge fallback

Manual upload is a recovery path, not the normal release process. Use it only
when a final GitHub release is already published and verified but automation
cannot complete:

1. Download `RGMS-X.Y.Z.zip` from that GitHub release; do not rebuild or
   rename its contents.
2. Confirm its SHA-256 matches the **Create Release** workflow summary.
3. In the CurseForge Authors dashboard for project `1741733`, check **Files**
   first to avoid a duplicate after an ambiguous automated failure.
4. Upload the exact GitHub ZIP with display name `RGMS X.Y.Z`.
5. Choose **Release**, select only the tested Retail `X.Y.Z`, and configure
   automatic publication after approval.
6. Paste the matching changelog section as Markdown.
7. Add LibDBIcon-1.0 project `15552` as an **Embedded Library** relationship;
   do not add the other bundled libraries as required external dependencies.
8. Submit once, then record the resulting file ID/URL and verify the filename,
   Retail version, display name, and checksum against the workflow summary.

Prereleases are never uploaded manually or automatically to CurseForge.

## Defective releases and hotfixes

If a public release is defective:

1. describe the impact and workaround in the GitHub and CurseForge release
   descriptions;
2. archive or mark the affected CurseForge file unavailable when possible;
3. retain the original GitHub tag and asset unless security or legal concerns
   require removal;
4. prepare the fix and changelog entry on `main`;
5. release a new PATCH version through the complete process above.
