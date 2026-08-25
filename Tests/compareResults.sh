#!/usr/bin/env bash
# compareResults.sh: Compare the jsonOutput results of two tests and report
# locations where one test's tactic succeeded and the other's failed.
#
# Usage: ./compareResults.sh TEST_DIR_1 TEST_DIR_2
# Example: ./compareResults.sh GrindTest NoGrindTest
#
# Locations are identified by (filepath, startLine, startCol). Only locations
# present in both tests' results are compared.

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 TEST_DIR_1 TEST_DIR_2" >&2
    exit 1
fi

dir1="${1%/}/jsonOutput"
dir2="${2%/}/jsonOutput"

for d in "$dir1" "$dir2"; do
    if [ ! -d "$d" ]; then
        echo "Error: $d is not a directory" >&2
        exit 1
    fi
done

name1="$(basename "${1%/}")"
name2="$(basename "${2%/}")"

only1=0
only2=0
both=0
neither=0
skipped=0

for f1 in "$dir1"/*.json; do
    base="$(basename "$f1")"
    f2="$dir2/$base"
    if [ ! -f "$f2" ]; then
        echo "Warning: $base has no counterpart in $dir2; skipping" >&2
        skipped=$((skipped + 1))
        continue
    fi

    # Join the two result arrays on (filepath, startLine, startCol) and emit
    # one line per shared location: "STATUS<TAB>filepath:startLine:startCol"
    # where STATUS is 1 (only test 1 succeeded), 2 (only test 2 succeeded),
    # B (both), or N (neither).
    while IFS=$'\t' read -r status loc; do
        case "$status" in
            1) only1=$((only1 + 1)); echo "Succeeded only in $name1: $loc" ;;
            2) only2=$((only2 + 1)); echo "Succeeded only in $name2: $loc" ;;
            B) both=$((both + 1)) ;;
            N) neither=$((neither + 1)) ;;
        esac
    done < <(jq -rn --slurpfile a "$f1" --slurpfile b "$f2" '
        def key: "\(.filepath):\(.startLine):\(.startCol)";
        ($b[0] | map({(key): .tacticSucceeded}) | add // {}) as $bmap
        | $a[0][]
        | (key) as $k
        | select($bmap | has($k))
        | ([.tacticSucceeded, $bmap[$k]]
           | if . == [true, false] then "1"
             elif . == [false, true] then "2"
             elif . == [true, true] then "B"
             else "N" end) as $status
        | "\($status)\t\($k)"
    ')
done

echo ""
echo "Summary (locations present in both tests):"
echo "  Succeeded only in $name1: $only1"
echo "  Succeeded only in $name2: $only2"
echo "  Succeeded in both:        $both"
echo "  Failed in both:           $neither"
if [ "$skipped" -gt 0 ]; then
    echo "  Files skipped (missing counterpart): $skipped"
fi
