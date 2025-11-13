#!/usr/bin/env bash
# Direct version of session.mux.j2 for local use
# This matches the paper's setup in section 8.3.1

# Configuration - Edit these for your experiment
CC="clang"
runArgs="--bridge fiat --curve curve25519 --method mul --evals 200k --bets 20 --betRatio 0.1 --fair-comparison --resultDir ~/CryptOpt/results/fiar-comp"
cpumasklist="2 4 6"  # Use allowed CPUs (avoiding blocked odd-numbered cores)
wd="${1:-$HOME/CryptOpt}"  # CryptOpt directory (pass as argument or use ~/CryptOpt)
SESSION_NAME="cryptopt"

# Kill previous node processes to ensure clean state
pgrep -f "CryptOpt" -U $UID | xargs -r kill 2>/dev/null || true

# Kill existing session if it exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# Create a new detached session with a name
tmux new-session -d -s "$SESSION_NAME"

# don't start just before timing issues
[[ $(date +"%-S") -gt 55 ]] && echo "waiting for the glory time to arrive " && sleep 5 && echo "the time has come."

# enable pmc (performance counters)
echo 1 | sudo tee /proc/sys/kernel/perf_event_paranoid

# Create htop pane at the top
tmux send-keys -t "$SESSION_NAME:0" 'htop -F node' C-m

IFS=' ' read -ra masks <<<"${cpumasklist}"
# and for every cpu start one proc
for mask in "${masks[@]}"; do
  tmux split-window -t "$SESSION_NAME:0" -v
  # if using split-pane ./CryptOpt ..., the pane closes once the command finished.
  tmux send-keys -t "$SESSION_NAME:0" "CC=${CC} taskset -c ${mask} ${wd}/CryptOpt ${runArgs} --seed $(date +%N) " C-m
  tmux select-layout -t "$SESSION_NAME:0" even-vertical
done

tmux select-layout -t "$SESSION_NAME:0" even-vertical

echo ""
echo "Started ${#masks[@]} parallel CryptOpt processes (one per core)"
echo "Each pinned to a specific CPU core using taskset"
echo ""
echo "To monitor: tmux attach -t $SESSION_NAME"
echo "To detach: Press Ctrl+B then D"
echo ""