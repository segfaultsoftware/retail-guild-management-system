#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Prepare RGMS release metadata from Git Bash.

Usage:
  bash ./scripts/prepare-release.sh \
    --version VERSION \
    --retail-version TEXT \
    --interface NUMBER

Required:
  --version VERSION       Release version, such as 1.1.0-rc.1 or 1.1.0.
  --retail-version TEXT   Retail version/build reported by GetBuildInfo().
  --interface NUMBER      Retail interface reported by GetBuildInfo().
  -h, --help              Show this help.

The script runs only on a clean main branch. It updates the Version and
Interface fields in RGMS.toc and promotes CHANGELOG.md's Unreleased content to
the requested version. It never builds, commits, pushes, tags, or publishes a
release.
EOF
}

fail() {
    printf 'prepare-release: %s\n' "$*" >&2
    exit 1
}

version=""
retail_version=""
interface_number=""

while (($# > 0)); do
    case "$1" in
        --version)
            (($# >= 2)) || fail "--version requires a value"
            version="$2"
            shift 2
            ;;
        --retail-version)
            (($# >= 2)) || fail "--retail-version requires a value"
            retail_version="$2"
            shift 2
            ;;
        --interface)
            (($# >= 2)) || fail "--interface requires a value"
            interface_number="$2"
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
[[ -n "$interface_number" ]] || fail "--interface is required"

release_pattern='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-rc\.(0|[1-9][0-9]*))?$'
[[ "$version" =~ $release_pattern ]] || \
    fail "version must be X.Y.Z or X.Y.Z-rc.N"
[[ "$interface_number" =~ ^[0-9]+$ ]] || \
    fail "interface must be numeric"
[[ "$retail_version" != *$'\n'* && "$retail_version" != *$'\r'* ]] || \
    fail "retail version must be a single line"

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

awk -v version="$version" -v interface_number="$interface_number" '
    BEGIN { version_count = 0; interface_count = 0 }
    /^## Version:/ {
        print "## Version: " version
        version_count += 1
        next
    }
    /^## Interface:/ {
        print "## Interface: " interface_number
        interface_count += 1
        next
    }
    { print }
    END {
        if (version_count != 1 || interface_count != 1) {
            exit 42
        }
    }
' RGMS.toc > "$manifest_replacement" || \
    fail "RGMS.toc must contain exactly one Interface and one Version field"

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

mv "$manifest_replacement" RGMS.toc
manifest_changed=true
mv "$changelog_replacement" CHANGELOG.md
changelog_changed=true

git diff --check -- RGMS.toc CHANGELOG.md

completed=true
printf '\nPrepared release files:\n'
printf '  Release version: %s\n' "$version"
printf '  Retail version/build: %s\n' "$retail_version"
printf '  Retail interface: %s\n' "$interface_number"
printf '  Manifest: RGMS.toc\n'
printf '  Changelog: CHANGELOG.md\n'
printf '\nNext steps:\n'
printf '  1. Review, commit, and push RGMS.toc and CHANGELOG.md on main.\n'
printf '  2. Copy the full 40-character main tip SHA.\n'
printf '  3. Dispatch Create Release from main with version %s and that SHA.\n' "$version"
