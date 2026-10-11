#!/bin/sh

set -eu

retail_path=${1:-"/Applications/World of Warcraft/_retail_"}
script_path=$0
script_dir=$(CDPATH= cd -- "$(dirname -- "$script_path")" && pwd)
repository_path=$(CDPATH= cd -- "$script_dir/.." && pwd)
manifest_path="$repository_path/RGMS.toc"

if [ ! -f "$manifest_path" ]; then
    printf 'RGMS.toc was not found at the repository root: %s\n' "$repository_path" >&2
    exit 1
fi

if [ ! -d "$retail_path" ]; then
    printf 'Retail directory not found: %s\n' "$retail_path" >&2
    printf 'Pass the path to your _retail_ directory as the first argument.\n' >&2
    exit 1
fi

addons_path="$retail_path/Interface/AddOns"
mkdir -p "$addons_path"

link_path="$addons_path/RGMS"
if [ -e "$link_path" ] || [ -L "$link_path" ]; then
    printf 'The target already exists: %s\n' "$link_path" >&2
    printf 'Move or remove it after confirming it is safe, then run this script again.\n' >&2
    exit 1
fi

ln -s "$repository_path" "$link_path"
printf 'Linked RGMS addon:\n  %s\n    -> %s\n' "$link_path" "$repository_path"
