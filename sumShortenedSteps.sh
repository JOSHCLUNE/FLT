#!/usr/bin/env bash
# Sums the `shortenedStepsCount` field across all entries in every JSON file
# in jsonOutput/. Each file is a JSON array of objects (possibly empty).
set -euo pipefail

total=0

for f in jsonOutput/*.json; do
  file_sum=$(jq '[.[].shortenedStepsCount] | add // 0' "$f")
  echo "$(basename "$f"): $file_sum"
  total=$((total + file_sum))
done

echo "----------------------------------------"
echo "Total shortenedStepsCount: $total"
