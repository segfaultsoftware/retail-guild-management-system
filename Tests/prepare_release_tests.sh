#!/usr/bin/env bash

set -euo pipefail

fail() {
    printf 'prepare release test: %s\n' "$*" >&2
    exit 1
}

repository_path="$(git rev-parse --show-toplevel)"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/rgms-prepare-test.XXXXXX")"
trap 'rm -rf -- "$temporary_root"' EXIT

mkdir -p "$temporary_root/scripts"
cp "$repository_path/scripts/prepare-release.sh" "$temporary_root/scripts/prepare-release.sh"
cat > "$temporary_root/RGMS.toc" <<'EOF'
## Interface: 120105
## Version: 1.0.3
## X-RGMS-Retail-Version: 12.1.5 (build 11111)
## X-Curse-Project-ID: 1741733
EOF
cat > "$temporary_root/CHANGELOG.md" <<'EOF'
# Changelog

## Unreleased

### Added

- Test release behavior.

## 1.0.3

- Previous release.
EOF

git -C "$temporary_root" init --initial-branch=main --quiet
git -C "$temporary_root" config user.name "Release Test"
git -C "$temporary_root" config user.email "release-test@example.invalid"
git -C "$temporary_root" add RGMS.toc CHANGELOG.md scripts/prepare-release.sh
git -C "$temporary_root" commit --quiet -m "Test fixture"

(
    cd "$temporary_root"
    bash ./scripts/prepare-release.sh \
        --version 1.1.0-preview.2 \
        --retail-version "12.1.6 (build 22222)" \
        --interface 120106 >/dev/null
)

grep -Fxq '## Version: 1.1.0-preview.2' "$temporary_root/RGMS.toc" || \
    fail 'release version was not written to the manifest'
grep -Fxq '## Interface: 120106' "$temporary_root/RGMS.toc" || \
    fail 'interface was not written to the manifest'
grep -Fxq '## X-RGMS-Retail-Version: 12.1.6 (build 22222)' "$temporary_root/RGMS.toc" || \
    fail 'complete Retail version was not written to the manifest'
[[ "$(grep -Fc '## X-Curse-Project-ID: 1741733' "$temporary_root/RGMS.toc")" -eq 1 ]] || \
    fail 'stable CurseForge project metadata changed'
grep -Fxq '## 1.1.0-preview.2' "$temporary_root/CHANGELOG.md" || \
    fail 'general SemVer prerelease was not promoted in the changelog'

if (
    cd "$temporary_root"
    bash ./scripts/prepare-release.sh \
        --version 1.1.0+build.1 \
        --retail-version "12.1.6 (build 22222)" \
        --interface 120106 >/dev/null 2>&1
); then
    fail 'build metadata was accepted unexpectedly'
fi

printf '6 prepare release tests: 6 passed, 0 failed\n'
