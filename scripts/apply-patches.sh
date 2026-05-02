#!/bin/sh
set -e

PATCH_DIR="$(dirname "$0")/../patches"
CATEGORIES="config perf mem sec compat"

for cat in $CATEGORIES; do
    dir="$PATCH_DIR/$cat"
    [ -d "$dir" ] || continue
    for patch in "$dir"/*.patch; do
        [ -f "$patch" ] || continue
        echo "[shinigami] Applying: $patch"
        git apply --check "$patch" || { echo "FAIL: $patch"; exit 1; }
        git apply "$patch"
    done
done

echo "[shinigami] All patches applied."
