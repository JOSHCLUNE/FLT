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

set -u

JSON_DIR="jsonOutput"
SUMMARY_DIR="summaryOutput"
ERROR_DIR="errorOutput"

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

# for file in "${FILES[@]}"; do
for file in "FLT/Basic/Lemmas.lean"; do
  COUNT=$((COUNT + 1))

  # Path relative to the repo root, e.g. FLT/Mathlib/Algebra/Order/Hom/Monoid.lean
  rel="${file}"

  # Flattened output name, e.g. FLT_Mathlib_Algebra_Order_Hom_Monoid
  name="${rel%.lean}"
  name="${name//\//_}"

  json_file="$JSON_DIR/$name.json"
  summary_file="$SUMMARY_DIR/$name.txt"
  error_file="$ERROR_DIR/$name.txt"

  start_time=$SECONDS
  lake exe tryAtEachStep "hammer" "$rel" \
    --outfile "$json_file" \
    --summaryfile "$summary_file" \
    2> "$error_file"
  status=$?
  elapsed=$((SECONDS - start_time))

  echo "File $rel has been processed ($COUNT/$TOTAL) in ${elapsed}s"
  echo "Time taken: ${elapsed}s" >> "$summary_file"

  if [ "$status" -ne 0 ] || grep -qi 'error' "$error_file"; then
    FAILED=$((FAILED + 1))
    echo "  WARNING: $rel produced errors (exit code $status); see $error_file"
  fi
done

echo "Done: $TOTAL files processed, $FAILED with errors."
