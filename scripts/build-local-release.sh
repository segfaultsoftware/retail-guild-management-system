#!/usr/bin/env bash

set -euo pipefail

fail() {
    printf 'build-local-release: %s\n' "$*" >&2
    exit 1
}

script_path=${BASH_SOURCE[0]}
script_dir=$(CDPATH= cd -- "$(dirname -- "$script_path")" && pwd)
repository_path=$(CDPATH= cd -- "$script_dir/.." && pwd)
manifest_path="$repository_path/RGMS.toc"

[[ -f "$manifest_path" ]] || fail "RGMS.toc was not found at $manifest_path"

mapfile -t manifest_versions < <(
    sed -nE 's/^[[:space:]]*##[[:space:]]+Version:[[:space:]]*(.*[^[:space:]])[[:space:]]*$/\1/p' \
        "$manifest_path" | tr -d '\r'
)
if ((${#manifest_versions[@]} != 1)); then
    fail "RGMS.toc must contain exactly one Version metadata field"
fi
version=${manifest_versions[0]}

pwsh_command=$(command -v pwsh.exe || true)
[[ -n "$pwsh_command" ]] || fail "pwsh.exe (PowerShell 7) was not found on PATH"

lua_command=${RGMS_LUA_COMMAND:-}
if [[ -z "$lua_command" ]]; then
    lua_path=$(command -v lua.exe || true)
    if [[ -n "$lua_path" ]]; then
        lua_command=$(cygpath -w "$lua_path")
    else
        lua_command='C:\Program Files (x86)\Lua\5.1\lua.exe'
    fi
fi
lua_path=$(cygpath -u "$lua_command" 2>/dev/null || true)
[[ -n "$lua_path" && -f "$lua_path" ]] || fail "Lua was not found at $lua_command"

git_exec_path=$(cygpath -u "$(git --exec-path)")
git_install_path=$(CDPATH= cd -- "$git_exec_path/../../.." && pwd)
git_command_path="${git_install_path%/}/cmd"
[[ -f "$git_command_path/git.exe" ]] \
    || fail "Git for Windows command directory was not found at $git_command_path"

timestamp=$(date +'%Y%m%d-%H%M%S')
output_directory=".release/local-$timestamp"

printf 'Building RGMS %s into %s\n' "$version" "$output_directory"
PATH="$git_command_path:$PATH" "$pwsh_command" \
    -NoProfile \
    -File "$script_dir/build-release.ps1" \
    -Version "$version" \
    -LuaCommand "$lua_command" \
    -OutputDirectory "$output_directory"
