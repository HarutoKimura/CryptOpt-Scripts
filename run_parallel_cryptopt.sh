#!/usr/bin/env bash
# Direct version of session.mux.j2 for local use
# This matches the paper's setup in section 8.3.1

# Configuration - Edit these for your experiment
CC="clang"
runArgs="--bridge fiat --curve curve25519 --method mul --evals 200k --bets 20 --betRatio 0.1 --fair-comparison --resultDir ~/CryptOpt/results/fiar-comp"
cpumasklist="1 2 3"  # Paper uses 3 parallel runs (leaving core 0 for OS)
wd="${1:-$HOME/CryptOpt}"  # CryptOpt directory (pass as argument or use ~/CryptOpt)

# Kill previous node processes to ensure clean state
# Since using terminal-only (no IDE), we can safely kill all node processes
pkill node -U $UID 2>/dev/null || true

# Check if tmux session exists, create if not
if ! tmux has-session 2>/dev/null; then
  tmux new-session -d
fi

tmux select-window -t 0
# kill all panes
tmux kill-pane -a 2>/dev/null || true

# one htop at the start
tmux split-pane 'htop -F node'
tmux kill-pane -t 0

# don't start just before timing issues
[[ $(date +"%-S") -gt 55 ]] && echo "waiting for the glory time to arrive " && sleep 5 && echo "the time has come."

# enable pmc (performance counters)
echo 1 | sudo tee /proc/sys/kernel/perf_event_paranoid

IFS=' ' read -ra masks <<<"${cpumasklist}"
# and for every cpu start one proc
for mask in "${masks[@]}"; do
  tmux split-pane bash
  # if using split-pane ./CryptOpt ..., the pane closes once the command finished.
  tmux send-keys "CC=${CC} taskset ${mask} ${wd}/CryptOpt ${runArgs} --seed $(date +%N) " C-m
  tmux select-layout even-vertical
done

tmux select-layout even-vertical

echo ""
echo "Started ${#masks[@]} parallel CryptOpt processes (one per core)"
echo "Each pinned to a specific CPU core using taskset"
echo ""
echo "To monitor: tmux attach"
echo "To detach: Press Ctrl+B then D"
echo ""
