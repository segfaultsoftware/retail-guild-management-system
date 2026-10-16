#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Prepare RGMS release-candidate metadata from Git Bash.

Usage:
  bash ./scripts/prepare-release.sh --version VERSION --tester TESTER [options]

Required:
  --version VERSION       Release version, such as 0.1.0-rc.1 or 0.1.0.
  --tester TESTER         Tester identifier used in the QA record filename.

Options:
  --retail-version TEXT   Retail version/build reported by GetBuildInfo().
  --interface NUMBER      Retail interface reported by GetBuildInfo().
  --qa-record PATH        QA record path under docs/qa. Defaults to
                          docs/qa/VERSION-TESTER.md.
  -h, --help              Show this help.

--retail-version and --interface must be supplied together. The script updates
RGMS.toc and creates a prepopulated QA record for review and merge to main.
GitHub builds the canonical package only after that merge. This script never
builds, commits, pushes, tags, or installs files into the Retail client.
EOF
}

fail() {
    printf 'prepare-release: %s\n' "$*" >&2
    exit 1
}

version=""
tester=""
retail_version=""
interface_number=""
qa_record=""

while (($# > 0)); do
    case "$1" in
        --version)
            (($# >= 2)) || fail "--version requires a value"
            version="$2"
            shift 2
            ;;
        --tester)
            (($# >= 2)) || fail "--tester requires a value"
            tester="$2"
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
        --qa-record)
            (($# >= 2)) || fail "--qa-record requires a value"
            qa_record="$2"
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
[[ -n "$tester" ]] || fail "--tester is required"

release_pattern='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-rc\.(0|[1-9][0-9]*))?$'
[[ "$version" =~ $release_pattern ]] || fail "version must be X.Y.Z or X.Y.Z-rc.N"
[[ "$tester" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || \
    fail "tester must contain only letters, numbers, dots, underscores, and hyphens"

if [[ -n "$retail_version" || -n "$interface_number" ]]; then
    [[ -n "$retail_version" && -n "$interface_number" ]] || \
        fail "--retail-version and --interface must be supplied together"
fi
[[ -z "$interface_number" || "$interface_number" =~ ^[0-9]+$ ]] || \
    fail "interface must be numeric"
[[ "$retail_version" != *$'\n'* && "$retail_version" != *$'\r'* ]] || \
    fail "retail version must be a single line"

command -v git >/dev/null 2>&1 || fail "git was not found"
command -v awk >/dev/null 2>&1 || fail "awk was not found"

repository_path="$(git rev-parse --show-toplevel 2>/dev/null)" || \
    fail "run this command from an RGMS Git checkout"
cd "$repository_path"

[[ -f RGMS.toc && -f docs/MVP_SCENARIO_CHECKLIST.md ]] || \
    fail "the checkout does not contain the expected RGMS release files"

branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" || \
    fail "release preparation requires a branch, not a detached HEAD"
[[ "$branch" != "main" ]] || \
    fail "create and check out a release candidate branch before preparing a release"

worktree_status="$(git status --porcelain --untracked-files=all)"
[[ -z "$worktree_status" ]] || {
    printf '%s\n' "$worktree_status" >&2
    fail "the working tree must be clean before release preparation"
}

git show-ref --verify --quiet refs/remotes/origin/main || \
    fail "origin/main is unavailable; fetch it before preparing a release"
git merge-base --is-ancestor refs/remotes/origin/main HEAD || \
    fail "the candidate branch must contain the locally known origin/main"

tag="v$version"
if git show-ref --verify --quiet "refs/tags/$tag"; then
    fail "local tag already exists: $tag"
fi

if [[ -z "$qa_record" ]]; then
    qa_record="docs/qa/$version-$tester.md"
fi
qa_record="${qa_record//\\//}"
[[ "$qa_record" =~ ^docs/qa/[A-Za-z0-9._-]+\.md$ ]] || \
    fail "QA record must be a simple Markdown path directly under docs/qa"
[[ ! -e "$qa_record" ]] || fail "QA record already exists: $qa_record"

manifest_backup="$(mktemp "${TMPDIR:-/tmp}/rgms-manifest.XXXXXX")"
manifest_replacement="$(mktemp "${TMPDIR:-/tmp}/rgms-manifest-new.XXXXXX")"
qa_replacement="$(mktemp "${TMPDIR:-/tmp}/rgms-qa.XXXXXX")"
cp RGMS.toc "$manifest_backup"

completed=false
manifest_changed=false
qa_created=false

cleanup() {
    exit_code=$?
    if [[ "$completed" != true ]]; then
        if [[ "$manifest_changed" == true ]]; then
            cp "$manifest_backup" RGMS.toc
        fi
        if [[ "$qa_created" == true ]]; then
            rm -f -- "$qa_record"
        fi
    fi
    rm -f -- "$manifest_backup" "$manifest_replacement" "$qa_replacement"
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
        if (interface_number != "") {
            print "## Interface: " interface_number
        } else {
            print $0
        }
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
mv "$manifest_replacement" RGMS.toc
manifest_changed=true

awk \
    -v version="$version" \
    -v tester="$tester" \
    -v retail_version="$retail_version" \
    -v interface_number="$interface_number" '
    /^- Release candidate:/ {
        print "- Release candidate: " version
        next
    }
    /^- Retail version\/build from/ && retail_version != "" {
        print "- Retail version/build from `/dump GetBuildInfo()`: " retail_version
        next
    }
    /^- Retail interface number from/ && interface_number != "" {
        print "- Retail interface number from `/dump select(4, GetBuildInfo())`: " interface_number
        next
    }
    /^- Tester:/ {
        print "- Tester: " tester
        next
    }
    /^- Automated result and test count:/ {
        print "- Automated result and test count: PENDING (Build Release Candidate workflow)"
        next
    }
    { print }
' docs/MVP_SCENARIO_CHECKLIST.md > "$qa_replacement"
mv "$qa_replacement" "$qa_record"
qa_created=true

git diff --check -- RGMS.toc "$qa_record"

completed=true
printf '\nPrepared release candidate files:\n'
printf '  Manifest: RGMS.toc\n'
printf '  QA record: %s\n' "$qa_record"
printf '\nNext steps:\n'
printf '  1. Commit and push this candidate branch, then merge its reviewed PR to main.\n'
printf '  2. Dispatch Build Release Candidate for version %s and the merged main SHA.\n' "$version"
printf '  3. Download that workflow artifact and replace %s with its populated qa-record.md.\n' "$qa_record"
printf '  4. Test the canonical ZIP, complete the record, and add the QA signoff.\n'
printf '  5. Commit only that completed QA record and merge it to main.\n'
printf '  6. Dispatch Release with the full QA commit SHA from main.\n'
