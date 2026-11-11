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
tag or release when the secret is missing or invalid, or when the catalog does
not resolve exactly one correctly typed Retail target and one correctly typed
Forever target.

## Prepare a release

Before preparation, confirm that:

- the working tree on `main` is clean;
- user-visible changes are under `## Unreleased` in `CHANGELOG.md`;
- the complete automated test suite passes;
- the addon has been exercised against the intended live Retail and Forever
  clients.

On each client being released, run these commands in chat:

```text
/dump GetBuildInfo()
/dump select(4, GetBuildInfo())
```

The first command reports the client version and build. Preserve both as one
value such as `12.1.6 (build 22222)`. The second command reports the numeric
interface. Record the Retail and Forever results separately and use the exact
observed values rather than copying the representative values below. Each
stored product value must be a non-empty single line beginning with `X.Y.Z`.

From Git Bash on a clean `main` branch, run:

```text
bash ./scripts/prepare-release.sh \
  --version 1.1.0 \
  --retail-version "12.1.6 (build 22222)" \
  --retail-interface 120106 \
  --forever-version "1.60.2 (build 33333)" \
  --forever-interface 16002
```

All five values are required exactly once. The script:

- validates an exact final or any valid SemVer prerelease version, both numeric
  interfaces, and both product version/build values;
- updates exactly one `Version`, one comma-delimited `Interface`, one
  `X-RGMS-Retail-Version`, and one `X-RGMS-Forever-Version` in `RGMS.toc`;
- writes `Interface` in deterministic Retail-then-Forever order, for example
  `## Interface: 120106, 16002`;
- preserves the complete supplied single-line product text, including optional
  build provenance;
- leaves the stable `## X-Curse-Project-ID: 1741733` declaration intact;
- leaves a fresh `## Unreleased` heading and promotes its previous content to
  `## <version>` in `CHANGELOG.md`;
- restores both `RGMS.toc` and `CHANGELOG.md` byte-for-byte if any input or
  required field is invalid, missing, or duplicated, or if final diff
  validation fails;
- never builds, commits, pushes, tags, or publishes anything.

Review the diff, run the automated suite, then commit and push the prepared
`RGMS.toc` and `CHANGELOG.md` files to `main`.

## Package contract and inspection

[`scripts/build-release.ps1`](../scripts/build-release.ps1) is the canonical
package builder. It accepts one legacy or two unique numeric values in the
single comma-delimited `Interface` field. A release-prepared dual-product
manifest contains the tested Retail value first and the Forever value second.

Runtime entries may be shared or end in supported client load directives:

```text
Core\Shared.lua
Core\Retail.lua [AllowLoadGameType standard]
Core\Forever.lua [AllowLoadGameType camelot]
```

`AllowLoadGameType` and `ExcludeLoadGameType` are supported only with the
`standard` and `camelot` game types. The builder validates and removes those
trailing directives only when resolving source paths. It packages every shared
and conditional source exactly once while preserving the original `RGMS.toc`
bytes and directive text in the archive for the game client to evaluate.
Malformed directives, empty or duplicate interface values, duplicate source
paths, missing files, repository escapes, and linked files or directories fail
before an artifact is retained.

One invocation produces one `RGMS-X.Y.Z.zip`. It never creates product-specific
archives or generated TOCs. The existing distribution allowlist,
contributor/secret exclusions, fixed ZIP metadata, per-entry source hashes,
Lua test gate, no-overwrite rule, two-build byte comparison, and final SHA-256
report remain release requirements.

The maintained, public-domain BigWigs Packager supports multiple interfaces,
Forever, native TOC directives, and multi-target uploads. RGMS retains its small
`System.IO.Compression` builder and direct use of the documented
[CurseForge Authors API](https://support.curseforge.com/support/solutions/articles/9000197321)
because the general packager does not provide this repository's exact allowlist,
source-content verification, fixed cross-platform ZIP metadata, or mandatory
two-build equality contract. Its version lookup can also
substitute another catalog version and its upload path retries requests, while
RGMS requires exact product-typed targets and manual review after an ambiguous
upload. Other shared upload actions and API clients do not replace that strict
pre-mutation validation and would add a dependency or another token-bearing
runtime. Extending the existing module therefore preserves the release contract
while using the API's native multi-ID `gameVersions` metadata.

After a local build, inspect the exact archive from Git Bash, substituting its
timestamped directory and version:

```text
archive=.release/local-YYYYMMDD-HHMMSS/RGMS-X.Y.Z.zip
unzip -Z1 "$archive"
sha256sum "$archive"
```

Expect one `RGMS/RGMS.toc`, every manifest-referenced shared and conditional
runtime file exactly once, and the documented distribution files. Expect no
generated TOC, product-specific archive, contributor file, or secret-like
path. A repeat build in a different empty output directory must report the same
SHA-256 for unchanged source bytes.

## Create the release

Dispatch **Create Release** from `main` with one input:

- `version`: the same version passed to `prepare-release.sh`, without `v`.

GitHub supplies the current `main` HEAD automatically. Validation pins the
checkout to that dispatch SHA and confirms it is still the current
`origin/main` tip before publishing anything.

The Actions run list labels each dispatch as **Create Release vX.Y.Z** so runs
for different addon versions can be distinguished at a glance.

The equivalent authenticated GitHub CLI command is:

```text
gh workflow run "Create Release" \
  --repo segfaultsoftware/retail-guild-management-system \
  --ref main \
  -f version=1.1.0
```

The jobs run in this order:

1. **Validate** checks the dispatch inputs, current `main` tip, manifest
   metadata, changelog, tag, and release availability without changing external
   state.
2. **Build and test** runs the complete suite, validates the dual-product
   fixture and current manifest, creates the deterministic ZIP twice, requires
   byte equality, records its SHA-256, and retains it as a workflow artifact
   for 90 days.
3. **CurseForge preflight** runs only for exact final versions. It authenticates
   with the configured secret, extracts each leading `X.Y.Z` from
   `X-RGMS-Retail-Version` and `X-RGMS-Forever-Version`, and makes one query to
   CurseForge's game-scoped `wow` version catalog. It requires exactly one
   positive ID for the exact Retail name with product type `517` and exactly
   one positive ID for the exact Forever name with product type `88568`, then
   rejects equal IDs. It never substitutes a nearest, newest, or same-major
   version. The unscoped endpoint is not used because it can return another
   game's catalog, and no per-patch ID is stored in the repository. Both
   lookups finish before any tag, GitHub release, or CurseForge file is created.
4. **Publish GitHub** rechecks the target, creates and pushes the annotated tag,
   publishes the GitHub release, downloads its attached ZIP, and verifies it
   against the build checksum.
5. **Publish CurseForge** runs only for exact final versions. It downloads the
   public GitHub release asset, verifies the SHA-256 again, and submits those
   exact bytes in one request with the ordered Retail and Forever target IDs.

The CurseForge file is submitted as:

- filename: `RGMS-X.Y.Z.zip`;
- display name: `RGMS-X.Y.Z.zip`;
- release type: **Release**;
- changelog: a `## X.Y.Z` heading followed by the matching `CHANGELOG.md`
  section as Markdown;
- supported versions: the distinct Retail and Forever IDs resolved in
  preflight, in deterministic Retail-then-Forever order;
- release option: public automatically after CurseForge approval;
- relationship: LibDBIcon-1.0 project `15552` as an embedded library.

LibDBIcon-1.0, LibDataBroker-1.1, CallbackHandler-1.0, and LibStub remain bundled
inside the RGMS ZIP. Users do not need to install them separately.

A successful summary contains the CurseForge file ID and direct URL, the one
filename and display name, both full product versions and extracted catalog
versions, both resolved target IDs, and the same SHA-256 recorded for the
GitHub asset. The workflow considers the upload successful only when CurseForge
accepts it and returns a positive numeric file ID; it does not wait for
moderation or public visibility.

Before the first dual-product publication, treat live storefront verification
as required:

1. Compare the preflight summary with the authenticated live CurseForge `wow`
   catalog. Confirm the Retail name/ID has product type `517`, the Forever
   name/ID has product type `88568`, and neither name was substituted.
2. Confirm the preflight filename and SHA-256 match the canonical GitHub asset
   recorded by the workflow.
3. After CurseForge accepts the single upload, open its file entry and confirm
   that it lists both the requested Retail and Forever versions for the same
   filename. Record the file URL as release evidence.

## Failure and retry behavior

If validation, building, or final-release CurseForge preflight fails, no GitHub
tag or release is created. Correct the source, input, secret, exact catalog
version, product type, or duplicate target and dispatch a new run.

If **Publish CurseForge** fails after **Publish GitHub** succeeds:

1. Leave the verified GitHub tag, release, and ZIP unchanged.
2. Open the failed workflow run and select **Re-run failed jobs**. This retries
   the failed CurseForge job without recreating the successful GitHub release.
3. If the request timed out or may have reached CurseForge, first open the
   project's **Files** dashboard and look for the same `RGMS-X.Y.Z.zip` display
   name. The author Upload API does not document an idempotency key or a safe
   duplicate-upload check, so do not retry until you have checked.

The failure summary repeats the immutable filename and checksum plus both full
product versions, extracted catalog versions, and target IDs. Compare all of
them with the existing GitHub release and any possibly created CurseForge file
before choosing whether to rerun.

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
4. Upload the exact GitHub ZIP with display name `RGMS-X.Y.Z.zip`.
5. Choose **Release**, select exactly the tested Retail and Forever `X.Y.Z`
   versions, and configure automatic publication after approval. Do not
   substitute another patch or another product with the same version name.
6. Paste the matching changelog section as Markdown.
7. Add LibDBIcon-1.0 project `15552` as an **Embedded Library** relationship;
   do not add the other bundled libraries as required external dependencies.
8. Submit once, then record the resulting file ID/URL and verify the filename,
   both product versions, display name, and checksum against the workflow
   summary.

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
