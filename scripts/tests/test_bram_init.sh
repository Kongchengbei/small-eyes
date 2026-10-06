#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/../.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

${CC:-cc} -std=c99 -Wall -Wextra -Werror \
	-I"$repo_dir/scripts" \
	"$script_dir/test_bram_init.c" -o "$tmp_dir/test_bram_init"

if [ "$#" -gt 0 ]; then
	"$tmp_dir/test_bram_init" "$tmp_dir" "$1"
else
	"$tmp_dir/test_bram_init" "$tmp_dir"
fi
