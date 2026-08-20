#!/usr/bin/env bash
#
# Run `lake exe tryAtEachStep "hammer"` on each Lean file in the main FLT
# library (the FLT/ directory, plus FLT.lean and FermatsLastTheorem.lean).
#
# For each Lean file, output is written with a flattened name derived from the
# file's path (path separators replaced by underscores):
#   - JSON results  -> jsonOutput/<name>.json     (via --outfile)
#   - summary stats -> summaryOutput/<name>.txt   (via --summaryfile)
#   - stderr (progress + error messages) -> errorOutput/<name>.txt
#
# After each file, progress is printed as "File X has been processed (Y/Z) in Ns"
# (where N is the processing time in seconds, also appended to the summary
# file), with an additional warning if the invocation exited non-zero or its
# stderr contains the word "error".
#
# Each invocation runs in its own systemd scope (a dedicated cgroup) so that:
#   - MemoryMax caps the invocation's memory. If it is exceeded, the cgroup's
#     own OOM killer kills just that invocation (exit code 137); the global OOM
#     killer never engages, so the premise-selection server, Docker, and sshd
#     are never at risk.
#   - RuntimeMaxSec bounds wall-clock time. On expiry systemd kills every
#     process in the scope, so a hung invocation (e.g. one stuck inside an
#     uninterruptible cvc5 FFI call) cannot survive as an orphan the way it
#     would under `timeout`, which only signals `lake`.
# After each invocation, any stray tryAtEachStep process left behind by a
# crashed or killed run is reaped before the next file starts.

set -u

JSON_DIR="jsonOutput"
SUMMARY_DIR="summaryOutput"
ERROR_DIR="errorOutput"

# Per-invocation resource bounds (see header comment).
MEMORY_MAX="8G"
RUNTIME_MAX_SEC="3000"

if ! systemd-run --user --scope --quiet -p MemoryMax="$MEMORY_MAX" -- /bin/true; then
  echo "ERROR: 'systemd-run --user --scope' with a MemoryMax limit does not work here." >&2
  echo "Memory containment is required to keep this sweep from taking down the machine." >&2
  exit 1
fi

# Collect the Lean files to process (sorted for a stable order).
mapfile -t FILES < <(
  {
    find "FLT" -type f -name '*.lean'
    printf '%s\n' "FLT.lean" "FermatsLastTheorem.lean"
  } | sort
)

TOTAL=${#FILES[@]}
COUNT=0
FAILED=0

echo "Running tryAtEachStep \"hammer\" on $TOTAL Lean files."

for file in "${FILES[@]}"; do
  COUNT=$((COUNT + 1))

  # Path relative to the repo root, e.g. FLT/Mathlib/Algebra/Order/Hom/Monoid.lean
  rel="${file}"

  # Flattened output name, e.g. FLT_Mathlib_Algebra_Order_Hom_Monoid
  name="${rel%.lean}"
  name="${name//\//_}"

  json_file="$JSON_DIR/$name.json"
  summary_file="$SUMMARY_DIR/$name.txt"
  error_file="$ERROR_DIR/$name.txt"

  echo "About to process $rel"

  start_time=$SECONDS
  systemd-run --user --scope --quiet \
    -p MemoryMax="$MEMORY_MAX" \
    -p RuntimeMaxSec="$RUNTIME_MAX_SEC" \
    lake exe tryAtEachStep "hammer" "$rel" \
    --outfile "$json_file" \
    --summaryfile "$summary_file" \
    2> "$error_file"
  status=$?
  elapsed=$((SECONDS - start_time))

  # Reap anything a crashed or killed invocation left behind (no-op after a
  # clean exit; nothing else on this machine runs the tryAtEachStep executable).
  pkill -x tryAtEachStep 2>/dev/null

  echo "File $rel has been processed ($COUNT/$TOTAL) in ${elapsed}s"
  echo "Time taken: ${elapsed}s" >> "$summary_file"

  if [ "$status" -eq 137 ]; then
    FAILED=$((FAILED + 1))
    echo "WARNING: $rel was killed (exit code 137), likely by the ${MEMORY_MAX} MemoryMax cap" >> $error_file
    echo "WARNING: $rel was killed (exit code 137), likely by the ${MEMORY_MAX} MemoryMax cap; see $error_file"
  elif [ "$status" -ne 0 ] || grep -qi 'error' "$error_file"; then
    FAILED=$((FAILED + 1))
    echo "WARNING: $rel produced errors (exit code $status)" >> $error_file
    echo "WARNING: $rel produced errors (exit code $status); see $error_file"
  fi
done

echo "Done: $TOTAL files processed, $FAILED with errors."
