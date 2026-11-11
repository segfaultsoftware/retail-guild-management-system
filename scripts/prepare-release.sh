#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Prepare RGMS release metadata from Git Bash.

Usage:
  bash ./scripts/prepare-release.sh \
    --version VERSION \
    --retail-version TEXT \
    --retail-interface NUMBER \
    --forever-version TEXT \
    --forever-interface NUMBER

Required:
  --version VERSION          Release version, such as 1.1.0-rc.1 or 1.1.0.
  --retail-version TEXT      Retail version/build reported by GetBuildInfo().
  --retail-interface NUMBER Retail interface reported by GetBuildInfo().
  --forever-version TEXT     Forever version/build reported by GetBuildInfo().
  --forever-interface NUMBER Forever interface reported by GetBuildInfo().
  -h, --help                 Show this help.

The script runs only on a clean main branch. It updates the Version, Interface,
X-RGMS-Retail-Version, and X-RGMS-Forever-Version fields in RGMS.toc and
promotes CHANGELOG.md's Unreleased content to the requested version. It never
builds, commits, pushes, tags, or publishes a release.
EOF
}

fail() {
    printf 'prepare-release: %s\n' "$*" >&2
    exit 1
}

version=""
retail_version=""
retail_interface=""
forever_version=""
forever_interface=""
version_seen=false
retail_version_seen=false
retail_interface_seen=false
forever_version_seen=false
forever_interface_seen=false

while (($# > 0)); do
    case "$1" in
        --version)
            (($# >= 2)) || fail "--version requires a value"
            [[ "$version_seen" == false ]] || \
                fail "--version may be specified only once"
            version_seen=true
            version="$2"
            shift 2
            ;;
        --retail-version)
            (($# >= 2)) || fail "--retail-version requires a value"
            [[ "$retail_version_seen" == false ]] || \
                fail "--retail-version may be specified only once"
            retail_version_seen=true
            retail_version="$2"
            shift 2
            ;;
        --retail-interface)
            (($# >= 2)) || fail "--retail-interface requires a value"
            [[ "$retail_interface_seen" == false ]] || \
                fail "--retail-interface may be specified only once"
            retail_interface_seen=true
            retail_interface="$2"
            shift 2
            ;;
        --forever-version)
            (($# >= 2)) || fail "--forever-version requires a value"
            [[ "$forever_version_seen" == false ]] || \
                fail "--forever-version may be specified only once"
            forever_version_seen=true
            forever_version="$2"
            shift 2
            ;;
        --forever-interface)
            (($# >= 2)) || fail "--forever-interface requires a value"
            [[ "$forever_interface_seen" == false ]] || \
                fail "--forever-interface may be specified only once"
            forever_interface_seen=true
            forever_interface="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "unknown argument: $1"
            ;;
    esac
done

[[ -n "$version" ]] || fail "--version is required"
[[ -n "$retail_version" ]] || fail "--retail-version is required"
[[ -n "$retail_interface" ]] || fail "--retail-interface is required"
[[ -n "$forever_version" ]] || fail "--forever-version is required"
[[ -n "$forever_interface" ]] || fail "--forever-interface is required"

release_pattern='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*))?$'
product_version_pattern='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)([[:blank:]].*)?$'
[[ "$version" =~ $release_pattern ]] || \
    fail "version must be X.Y.Z or X.Y.Z-prerelease without build metadata"
[[ "$retail_version" != *$'\n'* && "$retail_version" != *$'\r'* ]] || \
    fail "retail version must be a single line"
[[ "$forever_version" != *$'\n'* && "$forever_version" != *$'\r'* ]] || \
    fail "forever version must be a single line"
[[ "$retail_version" =~ $product_version_pattern ]] || \
    fail "retail version must begin with X.Y.Z"
[[ "$forever_version" =~ $product_version_pattern ]] || \
    fail "forever version must begin with X.Y.Z"
[[ "$retail_interface" =~ ^[0-9]+$ ]] || \
    fail "retail interface must be numeric"
[[ "$forever_interface" =~ ^[0-9]+$ ]] || \
    fail "forever interface must be numeric"

command -v git >/dev/null 2>&1 || fail "git was not found"
command -v awk >/dev/null 2>&1 || fail "awk was not found"

repository_path="$(git rev-parse --show-toplevel 2>/dev/null)" || \
    fail "run this command from an RGMS Git checkout"
cd "$repository_path"

[[ -f RGMS.toc && -f CHANGELOG.md ]] || \
    fail "the checkout does not contain RGMS.toc and CHANGELOG.md"

branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" || \
    fail "release preparation requires a branch, not a detached HEAD"
[[ "$branch" == "main" ]] || \
    fail "release preparation must run on main, not $branch"

worktree_status="$(git status --porcelain --untracked-files=all)"
[[ -z "$worktree_status" ]] || {
    printf '%s\n' "$worktree_status" >&2
    fail "the working tree must be clean before release preparation"
}

tag="v$version"
if git show-ref --verify --quiet "refs/tags/$tag"; then
    fail "local tag already exists: $tag"
fi

manifest_backup="$(mktemp "${TMPDIR:-/tmp}/rgms-manifest.XXXXXX")"
changelog_backup="$(mktemp "${TMPDIR:-/tmp}/rgms-changelog.XXXXXX")"
manifest_replacement="$(mktemp "${TMPDIR:-/tmp}/rgms-manifest-new.XXXXXX")"
changelog_replacement="$(mktemp "${TMPDIR:-/tmp}/rgms-changelog-new.XXXXXX")"
cp RGMS.toc "$manifest_backup"
cp CHANGELOG.md "$changelog_backup"

completed=false
manifest_changed=false
changelog_changed=false

cleanup() {
    exit_code=$?
    if [[ "$completed" != true ]]; then
        if [[ "$manifest_changed" == true ]]; then
            cp "$manifest_backup" RGMS.toc
        fi
        if [[ "$changelog_changed" == true ]]; then
            cp "$changelog_backup" CHANGELOG.md
        fi
    fi
    rm -f -- \
        "$manifest_backup" \
        "$changelog_backup" \
        "$manifest_replacement" \
        "$changelog_replacement"
    exit "$exit_code"
}
trap cleanup EXIT

RGMS_RELEASE_VERSION="$version" \
RGMS_RETAIL_INTERFACE="$retail_interface" \
RGMS_FOREVER_INTERFACE="$forever_interface" \
RGMS_RETAIL_VERSION="$retail_version" \
RGMS_FOREVER_VERSION="$forever_version" \
awk '
    BEGIN {
        version = ENVIRON["RGMS_RELEASE_VERSION"]
        retail_interface = ENVIRON["RGMS_RETAIL_INTERFACE"]
        forever_interface = ENVIRON["RGMS_FOREVER_INTERFACE"]
        retail_version = ENVIRON["RGMS_RETAIL_VERSION"]
        forever_version = ENVIRON["RGMS_FOREVER_VERSION"]
        version_count = 0
        interface_count = 0
        retail_version_count = 0
        forever_version_count = 0
    }
    /^## Version:/ {
        print "## Version: " version
        version_count += 1
        next
    }
    /^## Interface:/ {
        print "## Interface: " retail_interface ", " forever_interface
        interface_count += 1
        next
    }
    /^## X-RGMS-Retail-Version:/ {
        print "## X-RGMS-Retail-Version: " retail_version
        retail_version_count += 1
        next
    }
    /^## X-RGMS-Forever-Version:/ {
        print "## X-RGMS-Forever-Version: " forever_version
        forever_version_count += 1
        next
    }
    { print }
    END {
        if (version_count != 1 || interface_count != 1 ||
                retail_version_count != 1 || forever_version_count != 1) {
            exit 42
        }
    }
' RGMS.toc > "$manifest_replacement" || \
    fail "RGMS.toc must contain exactly one Version, Interface, X-RGMS-Retail-Version, and X-RGMS-Forever-Version field"

awk -v version="$version" '
    BEGIN {
        unreleased_count = 0
        target_count = 0
        in_unreleased = 0
        unreleased_content = 0
    }
    $0 == "## Unreleased" {
        unreleased_count += 1
        in_unreleased = 1
        print
        print ""
        print "## " version
        next
    }
    $0 == "## " version || $0 == "## [" version "]" {
        target_count += 1
    }
    /^## / && in_unreleased {
        in_unreleased = 0
    }
    in_unreleased && $0 !~ /^[[:space:]]*$/ {
        unreleased_content += 1
    }
    { print }
    END {
        if (unreleased_count != 1 || target_count != 0 || unreleased_content == 0) {
            exit 42
        }
    }
' CHANGELOG.md > "$changelog_replacement" || \
    fail "CHANGELOG.md must contain one non-empty Unreleased section and no $version section"

manifest_changed=true
mv "$manifest_replacement" RGMS.toc
changelog_changed=true
mv "$changelog_replacement" CHANGELOG.md

git diff --check -- RGMS.toc CHANGELOG.md

completed=true
printf '\nPrepared release files:\n'
printf '  Release version: %s\n' "$version"
printf '  Retail version/build: %s\n' "$retail_version"
printf '  Retail interface: %s\n' "$retail_interface"
printf '  Forever version/build: %s\n' "$forever_version"
printf '  Forever interface: %s\n' "$forever_interface"
printf '  Manifest: RGMS.toc\n'
printf '  Changelog: CHANGELOG.md\n'
printf '\nNext steps:\n'
printf '  1. Review, commit, and push RGMS.toc and CHANGELOG.md on main.\n'
printf '  2. Copy the full 40-character main tip SHA.\n'
printf '  3. Dispatch Create Release from main with version %s and that SHA.\n' "$version"
