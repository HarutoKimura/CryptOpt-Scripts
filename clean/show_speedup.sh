#!/usr/bin/env bash
# Show speedup comparison between optimized assembly and baseline

INFO_FILE=".last_clean_run"

if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_results_directory>"
  echo "Example: $0 ~/CryptOpt/results/fiar-comp/fiat/fiat_curve25519_carry_mul"
  exit 1
fi

RESULT_DIR="$1"

# Check for .last_clean_run, or fall back to .last_clean_run-wip
if [ -f "${RESULT_DIR}/${INFO_FILE}" ]; then
  RESULTS_FILE="${RESULT_DIR}/${INFO_FILE}"
elif [ -f "${RESULT_DIR}/${INFO_FILE}-wip" ]; then
  RESULTS_FILE="${RESULT_DIR}/${INFO_FILE}-wip"
  echo "Note: Using work-in-progress file (sorting/deletion phase not yet completed)"
  echo ""
else
  echo "Error: ${RESULT_DIR}/${INFO_FILE} or ${RESULT_DIR}/${INFO_FILE}-wip not found"
  exit 1
fi

echo "==================================================================="
echo "Performance Comparison: Optimized Assembly vs Baseline"
echo "==================================================================="
echo ""
printf "%-8s %-10s %-10s %-10s %s\n" "Rank" "Opt (cyc)" "Base (cyc)" "Speedup" "Filename"
echo "-------------------------------------------------------------------"

rank=1
while read -r asm_cycles baseline_cycles filename; do
  if [ -n "$asm_cycles" ] && [ -n "$baseline_cycles" ]; then
    speedup=$(echo "scale=3; $baseline_cycles / $asm_cycles" | bc)
    printf "%-8d %-10.2f %-10.2f %-10s %s\n" "$rank" "$asm_cycles" "$baseline_cycles" "${speedup}x" "$filename"
    ((rank++))
  fi
done < "${RESULTS_FILE}"

echo ""
echo "Legend:"
echo "  Opt (cyc)  = Optimized assembly cycle count"
echo "  Base (cyc) = Baseline (fiat-crypto C) cycle count"
echo "  Speedup    = Baseline / Optimized (higher is better)"
