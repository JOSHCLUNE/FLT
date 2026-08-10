#!/usr/bin/env bash
# Tally results, successes, and time across all files in summaryOutput.
set -euo pipefail

DIR="${1:-summaryOutput}"

total_results=0
total_successes=0
total_time=0

for f in "$DIR"/*; do
    results=$(grep -oP 'Total number of results: \K[0-9]+' "$f")
    successes=$(grep -oP 'Total number of successes: \K[0-9]+' "$f")
    time_taken=$(grep -oP 'Time taken: \K[0-9]+' "$f")

    total_results=$((total_results + results))
    total_successes=$((total_successes + successes))
    total_time=$((total_time + time_taken))
done

echo "Total number of results: $total_results"
echo "Total number of successes: $total_successes"
echo "Time taken: ${total_time}s"
