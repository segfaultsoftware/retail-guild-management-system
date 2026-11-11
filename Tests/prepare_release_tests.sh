#!/usr/bin/env bash

set -euo pipefail

pass_count=0
scenario_number=0
fixture_name=""
fixture_path=""
output_path=""
command_status=0

fail() {
    printf 'prepare release test (%s): %s\n' \
        "${fixture_name:-setup}" "$*" >&2
    if [[ -n "${output_path:-}" && -f "$output_path" ]]; then
        printf '%s\n' '--- command output ---' >&2
        cat "$output_path" >&2
    fi
    exit 1
}

pass() {
    pass_count=$((pass_count + 1))
}

assert_success() {
    [[ "$command_status" -eq 0 ]] || \
        fail "command failed with status $command_status"
    pass
}

assert_failure() {
    [[ "$command_status" -ne 0 ]] || \
        fail "command succeeded unexpectedly"
    pass
}

assert_output_contains() {
    grep -Fq -- "$1" "$output_path" || \
        fail "command output did not contain: $1"
    pass
}

assert_exact_line() {
    local expected="$1"
    local path="$2"
    grep -Fxq -- "$expected" "$path" || \
        fail "$path did not contain exact line: $expected"
    pass
}

assert_line_count() {
    local expected_count="$1"
    local line="$2"
    local path="$3"
    local actual_count
    actual_count="$(grep -Fxc -- "$line" "$path" || true)"
    [[ "$actual_count" -eq "$expected_count" ]] || \
        fail "expected $expected_count copies of '$line' in $path; found $actual_count"
    pass
}

assert_prefix_count() {
    local expected_count="$1"
    local prefix="$2"
    local path="$3"
    local actual_count
    actual_count="$(awk -v prefix="$prefix" '
        index($0, prefix) == 1 { count += 1 }
        END { print count + 0 }
    ' "$path")"
    [[ "$actual_count" -eq "$expected_count" ]] || \
        fail "expected $expected_count '$prefix' fields in $path; found $actual_count"
    pass
}

assert_equal() {
    local expected="$1"
    local actual="$2"
    local description="$3"
    [[ "$actual" == "$expected" ]] || \
        fail "$description; expected '$expected', found '$actual'"
    pass
}

assert_files_equal() {
    local expected="$1"
    local actual="$2"
    local description="$3"
    cmp -s -- "$expected" "$actual" || fail "$description"
    pass
}

repository_path="$(git rev-parse --show-toplevel)"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/rgms-prepare-test.XXXXXX")"
trap 'rm -rf -- "$temporary_root"' EXIT

valid_args=(
    --version "1.1.0-preview.2"
    --retail-version "12.1.6 (build 22222)"
    --retail-interface "120106"
    --forever-version "1.60.2 (build 33333)"
    --forever-interface "16002"
)

create_fixture() {
    scenario_number=$((scenario_number + 1))
    fixture_name="scenario-$scenario_number-$1"
    fixture_path="$temporary_root/$fixture_name"
    output_path="$temporary_root/$fixture_name.output"

    mkdir -p "$fixture_path/scripts"
    cp "$repository_path/scripts/prepare-release.sh" \
        "$fixture_path/scripts/prepare-release.sh"
    cat > "$fixture_path/RGMS.toc" <<'EOF'
## Interface: 120105, 16001
## Version: 1.0.3
## X-RGMS-Retail-Version: 12.1.5 (build 11111)
## X-RGMS-Forever-Version: 1.60.1 (build 44444)
## X-Curse-Project-ID: 1741733
EOF
    cat > "$fixture_path/CHANGELOG.md" <<'EOF'
# Changelog

## Unreleased

### Added

- Test release behavior.

## 1.0.3

- Previous release.
EOF

    git -C "$fixture_path" init --initial-branch=main --quiet
    git -C "$fixture_path" config user.name "Release Test"
    git -C "$fixture_path" config user.email "release-test@example.invalid"
    git -C "$fixture_path" config core.autocrlf false
    git -C "$fixture_path" add RGMS.toc CHANGELOG.md scripts/prepare-release.sh
    git -C "$fixture_path" commit --quiet -m "Test fixture"
}

commit_fixture_change() {
    git -C "$fixture_path" add RGMS.toc CHANGELOG.md
    git -C "$fixture_path" commit --quiet -m "Adjust test fixture"
}

run_prepare() {
    set +e
    (
        cd "$fixture_path"
        bash ./scripts/prepare-release.sh "$@"
    ) > "$output_path" 2>&1
    command_status=$?
    set -e
}

snapshot_release_files() {
    cp "$fixture_path/RGMS.toc" "$temporary_root/$fixture_name.RGMS.before"
    cp "$fixture_path/CHANGELOG.md" \
        "$temporary_root/$fixture_name.CHANGELOG.before"
}

assert_release_files_unchanged() {
    assert_files_equal \
        "$temporary_root/$fixture_name.RGMS.before" \
        "$fixture_path/RGMS.toc" \
        "RGMS.toc was not restored byte-for-byte"
    assert_files_equal \
        "$temporary_root/$fixture_name.CHANGELOG.before" \
        "$fixture_path/CHANGELOG.md" \
        "CHANGELOG.md was not restored byte-for-byte"
}

expect_failure_unchanged() {
    local expected_output="$1"
    shift
    snapshot_release_files
    run_prepare "$@"
    assert_failure
    assert_output_contains "$expected_output"
    assert_release_files_unchanged
}

set_argument_value() {
    local target_option="$1"
    local target_value="$2"
    local index
    case_args=()
    for ((index = 0; index < ${#valid_args[@]}; index += 2)); do
        case_args+=("${valid_args[index]}")
        if [[ "${valid_args[index]}" == "$target_option" ]]; then
            case_args+=("$target_value")
        else
            case_args+=("${valid_args[index + 1]}")
        fi
    done
}

remove_manifest_field() {
    local prefix="## $1:"
    awk -v prefix="$prefix" 'index($0, prefix) != 1 { print }' \
        "$fixture_path/RGMS.toc" > "$fixture_path/RGMS.toc.new"
    mv "$fixture_path/RGMS.toc.new" "$fixture_path/RGMS.toc"
}

duplicate_manifest_field() {
    local prefix="## $1:"
    awk -v prefix="$prefix" '
        { print }
        index($0, prefix) == 1 { print }
    ' "$fixture_path/RGMS.toc" > "$fixture_path/RGMS.toc.new"
    mv "$fixture_path/RGMS.toc.new" "$fixture_path/RGMS.toc"
}

# One invocation writes all dual-product metadata in deterministic order,
# preserves build text, promotes the changelog, and changes no repository state
# beyond the two release files.
create_fixture "success"
head_before="$(git -C "$fixture_path" rev-parse HEAD)"
run_prepare "${valid_args[@]}"
assert_success
assert_exact_line '## Version: 1.1.0-preview.2' "$fixture_path/RGMS.toc"
assert_exact_line '## Interface: 120106, 16002' "$fixture_path/RGMS.toc"
assert_exact_line \
    '## X-RGMS-Retail-Version: 12.1.6 (build 22222)' \
    "$fixture_path/RGMS.toc"
assert_exact_line \
    '## X-RGMS-Forever-Version: 1.60.2 (build 33333)' \
    "$fixture_path/RGMS.toc"
assert_prefix_count 1 '## Version:' "$fixture_path/RGMS.toc"
assert_prefix_count 1 '## Interface:' "$fixture_path/RGMS.toc"
assert_prefix_count 1 '## X-RGMS-Retail-Version:' "$fixture_path/RGMS.toc"
assert_prefix_count 1 '## X-RGMS-Forever-Version:' "$fixture_path/RGMS.toc"
assert_line_count 1 '## X-Curse-Project-ID: 1741733' "$fixture_path/RGMS.toc"
assert_exact_line '## 1.1.0-preview.2' "$fixture_path/CHANGELOG.md"
assert_line_count 1 '## Unreleased' "$fixture_path/CHANGELOG.md"
cat > "$temporary_root/success.CHANGELOG.expected" <<'EOF'
# Changelog

## Unreleased

## 1.1.0-preview.2

### Added

- Test release behavior.

## 1.0.3

- Previous release.
EOF
assert_files_equal \
    "$temporary_root/success.CHANGELOG.expected" \
    "$fixture_path/CHANGELOG.md" \
    'changelog promotion did not preserve a fresh Unreleased section and move its content'
assert_output_contains 'Release version: 1.1.0-preview.2'
assert_output_contains 'Retail version/build: 12.1.6 (build 22222)'
assert_output_contains 'Retail interface: 120106'
assert_output_contains 'Forever version/build: 1.60.2 (build 33333)'
assert_output_contains 'Forever interface: 16002'
assert_equal "$head_before" "$(git -C "$fixture_path" rev-parse HEAD)" \
    'release preparation created a commit'
assert_equal '' "$(git -C "$fixture_path" tag --list)" \
    'release preparation created a tag'
assert_equal $' M CHANGELOG.md\n M RGMS.toc' \
    "$(git -C "$fixture_path" status --short --untracked-files=all)" \
    'release preparation changed unexpected files or created artifacts'

# Exact final versions remain valid alongside general SemVer prereleases.
set_argument_value --version '1.1.0'
create_fixture "final-version-success"
run_prepare "${case_args[@]}"
assert_success
assert_exact_line '## Version: 1.1.0' "$fixture_path/RGMS.toc"
assert_exact_line '## 1.1.0' "$fixture_path/CHANGELOG.md"

# Help documents all required inputs without touching release files.
create_fixture "help"
snapshot_release_files
run_prepare --help
assert_success
assert_output_contains '--retail-interface NUMBER'
assert_output_contains '--forever-interface NUMBER'
assert_release_files_unchanged

# Every input is required exactly once.
for omitted_option in \
    --version \
    --retail-version \
    --retail-interface \
    --forever-version \
    --forever-interface
do
    case_args=()
    for ((index = 0; index < ${#valid_args[@]}; index += 2)); do
        if [[ "${valid_args[index]}" != "$omitted_option" ]]; then
            case_args+=("${valid_args[index]}" "${valid_args[index + 1]}")
        fi
    done
    create_fixture "missing-input"
    expect_failure_unchanged "$omitted_option is required" "${case_args[@]}"
done

for duplicate_index in 0 2 4 6 8; do
    duplicate_option="${valid_args[duplicate_index]}"
    duplicate_value="${valid_args[duplicate_index + 1]}"
    create_fixture "duplicate-input"
    expect_failure_unchanged \
        "$duplicate_option may be specified only once" \
        "${valid_args[@]}" "$duplicate_option" "$duplicate_value"
done

create_fixture "legacy-interface-option"
expect_failure_unchanged 'unknown argument: --interface' \
    "${valid_args[@]}" --interface 120106

# Product versions must be non-empty, single-line, and begin with X.Y.Z.
for product_option in --retail-version --forever-version; do
    product_name="${product_option#--}"
    product_name="${product_name//-/ }"

    set_argument_value "$product_option" ''
    create_fixture "empty-product-version"
    expect_failure_unchanged "$product_option is required" "${case_args[@]}"

    set_argument_value "$product_option" 'version 1.2.3'
    create_fixture "malformed-product-version"
    expect_failure_unchanged \
        "$product_name must begin with X.Y.Z" \
        "${case_args[@]}"

    set_argument_value "$product_option" $'1.2.3\n(build 99999)'
    create_fixture "lf-product-version"
    expect_failure_unchanged \
        "$product_name must be a single line" \
        "${case_args[@]}"

    set_argument_value "$product_option" $'1.2.3\r(build 99999)'
    create_fixture "cr-product-version"
    expect_failure_unchanged \
        "$product_name must be a single line" \
        "${case_args[@]}"
done

# Both interface inputs are independently numeric.
set_argument_value --retail-interface '120A06'
create_fixture "invalid-retail-interface"
expect_failure_unchanged 'retail interface must be numeric' "${case_args[@]}"

set_argument_value --forever-interface '16 002'
create_fixture "invalid-forever-interface"
expect_failure_unchanged 'forever interface must be numeric' "${case_args[@]}"

# General SemVer prereleases remain supported while malformed versions and
# build metadata remain rejected.
for invalid_release in '1.1' '1.1.0+build.1' '1.1.0-01'; do
    set_argument_value --version "$invalid_release"
    create_fixture "invalid-release-version"
    expect_failure_unchanged \
        'version must be X.Y.Z or X.Y.Z-prerelease without build metadata' \
        "${case_args[@]}"
done

# Every required manifest field must occur exactly once.
for manifest_field in \
    Version \
    Interface \
    X-RGMS-Retail-Version \
    X-RGMS-Forever-Version
do
    create_fixture "missing-manifest-field"
    remove_manifest_field "$manifest_field"
    commit_fixture_change
    expect_failure_unchanged \
        'RGMS.toc must contain exactly one Version, Interface, X-RGMS-Retail-Version, and X-RGMS-Forever-Version field' \
        "${valid_args[@]}"

    create_fixture "duplicate-manifest-field"
    duplicate_manifest_field "$manifest_field"
    commit_fixture_change
    expect_failure_unchanged \
        'RGMS.toc must contain exactly one Version, Interface, X-RGMS-Retail-Version, and X-RGMS-Forever-Version field' \
        "${valid_args[@]}"
done

# Changelog validation remains atomic for missing, duplicate, empty, and
# already-promoted target sections.
create_fixture "missing-unreleased"
awk '$0 != "## Unreleased" { print }' \
    "$fixture_path/CHANGELOG.md" > "$fixture_path/CHANGELOG.md.new"
mv "$fixture_path/CHANGELOG.md.new" "$fixture_path/CHANGELOG.md"
commit_fixture_change
expect_failure_unchanged 'CHANGELOG.md must contain one non-empty Unreleased section' \
    "${valid_args[@]}"

create_fixture "duplicate-unreleased"
awk '
    { print }
    $0 == "## Unreleased" { print ""; print "## Unreleased" }
' "$fixture_path/CHANGELOG.md" > "$fixture_path/CHANGELOG.md.new"
mv "$fixture_path/CHANGELOG.md.new" "$fixture_path/CHANGELOG.md"
commit_fixture_change
expect_failure_unchanged 'CHANGELOG.md must contain one non-empty Unreleased section' \
    "${valid_args[@]}"

create_fixture "empty-unreleased"
cat > "$fixture_path/CHANGELOG.md" <<'EOF'
# Changelog

## Unreleased

## 1.0.3

- Previous release.
EOF
commit_fixture_change
expect_failure_unchanged 'CHANGELOG.md must contain one non-empty Unreleased section' \
    "${valid_args[@]}"

create_fixture "existing-target-version"
cat >> "$fixture_path/CHANGELOG.md" <<'EOF'

## 1.1.0-preview.2

- Existing target.
EOF
commit_fixture_change
expect_failure_unchanged 'CHANGELOG.md must contain one non-empty Unreleased section' \
    "${valid_args[@]}"

# A failure after both replacements are installed restores both source files.
set_argument_value --retail-version '12.1.6 '
create_fixture "post-write-rollback"
expect_failure_unchanged 'trailing whitespace' "${case_args[@]}"
assert_equal '' "$(git -C "$fixture_path" status --porcelain)" \
    'rollback did not restore a clean worktree'

# Existing branch, worktree, and tag safeguards still fail before mutation.
create_fixture "non-main"
git -C "$fixture_path" switch --quiet -c feature/release-test
expect_failure_unchanged 'release preparation must run on main' \
    "${valid_args[@]}"

create_fixture "detached-head"
git -C "$fixture_path" checkout --quiet --detach
expect_failure_unchanged 'release preparation requires a branch' \
    "${valid_args[@]}"

create_fixture "dirty-tracked"
printf '\nDirty fixture.\n' >> "$fixture_path/CHANGELOG.md"
expect_failure_unchanged 'the working tree must be clean' "${valid_args[@]}"

create_fixture "dirty-untracked"
printf '%s\n' 'untracked' > "$fixture_path/untracked.txt"
expect_failure_unchanged 'the working tree must be clean' "${valid_args[@]}"

create_fixture "existing-tag"
git -C "$fixture_path" tag v1.1.0-preview.2
expect_failure_unchanged 'local tag already exists: v1.1.0-preview.2' \
    "${valid_args[@]}"

printf '%d prepare release tests: %d passed, 0 failed\n' \
    "$pass_count" "$pass_count"
