# CryptOpt Benchmarking Guide

This guide explains how to reproduce the experimental setup from the CryptOpt paper (Section 7.1 & 8.3.1).

## Overview

The benchmarking process has two phases:
1. **Phase 1: Optimization** - Generate assembly implementations (20-40 hours)
2. **Phase 2: Evaluation** - Measure with locked CPU frequency (optional, for final paper numbers)

## Prerequisites

### 1. Build CryptOpt
```bash
cd ~/CryptOpt
make build
```

This compiles CryptOpt and creates `dist/CryptOpt.js`.

### 2. Close IDE (Important!)
For the most rigorous reproduction matching the paper:
- Close VS Code Remote / Cursor IDE
- Use **terminal-only** SSH connection
- This reduces background noise and matches paper's "no unnecessary background tasks" setup

## Phase 1: Optimization (Generating Implementations)

### What This Does
- Runs **3 parallel CryptOpt optimizations** (one per core)
- Pins each process to cores 1, 2, 3 using `taskset`
- Leaves core 0 free for OS activity
- Each optimization uses a **different random seed**
- Generates 3 assembly implementations
- Takes **20-40 hours** depending on hardware

### Hardware Setup (Matches Paper)
- ✅ Uses `taskset` for CPU core pinning
- ✅ Runs 3 parallel processes (matching paper's methodology)
- ✅ Leaves one core for OS
- ✅ Uses Algorithm 3 for measurements (built into CryptOpt)

### How to Run

#### 1. Connect via Terminal SSH
```bash
# From your local machine:
ssh harutok@your-server-address
```

#### 2. Navigate and Run
```bash
cd /home/harutok/CryptOpt-Scripts
./run_parallel_cryptopt.sh
```

The script will:
- Kill previous node processes (cleanup)
- Create/attach to tmux session
- Start 3 CryptOpt processes on cores 1, 2, 3
- Each with different random seed
- Show htop monitoring in first pane

#### 3. Monitor Progress (Optional)
```bash
tmux attach
# You'll see:
# - Pane 0: htop showing CPU usage for node processes
# - Pane 1-3: Three CryptOpt processes running

# To detach: Press Ctrl+B then D
```

#### 4. Disconnect and Let It Run
```bash
# After attaching/checking, detach from tmux:
# Press: Ctrl+B then D

# Then disconnect from SSH:
exit
```

The optimization continues running in tmux. **You can safely disconnect!**

#### 5. Check Back Later
```bash
# Reconnect:
ssh harutok@your-server-address

# Check if still running:
ps aux | grep CryptOpt

# Reattach to see progress:
tmux attach

# Check results so far:
ls -la ~/CryptOpt/results/fiar-comp/
```

### Results Location
Results are saved to: `~/CryptOpt/results/fiar-comp/`

Structure:
```
~/CryptOpt/results/fiar-comp/
└── fiat/
    └── fiat_curve25519_carry_mul/
        ├── seed0001234567890_ratio09123.asm  # Implementation 1
        ├── seed0001234567890_ratio09123.json # Metadata
        ├── seed9876543210000_ratio08456.asm  # Implementation 2
        └── ...
```

## Phase 2: Final Evaluation with Locked CPU Frequency (Optional)

### What This Does
- Re-measures ALL .asm files in the results directory
- **Locks CPU frequency** to 2.2 GHz (your CPU's base frequency)
- Disables CPU boost
- Sets governor to PERFORMANCE
- Uses same Algorithm 3 for measurement
- Keeps only top 30 best-performing files per function
- Takes **a few minutes to hours** depending on number of files

### When to Use This
- When you want the **most stable, reproducible numbers** for your paper
- For fair cross-platform comparisons
- To generate final performance tables

### How to Run

```bash
cd /home/harutok/CryptOpt-Scripts/clean

# Set environment variables
export FREQ=2200000  # Your CPU base frequency (2.2 GHz)
export RES=~/CryptOpt/results/fiar-comp  # Results directory to evaluate

# Run evaluation with locked frequency
sudo ./gru.sh
```

This will:
1. Lock CPU frequency to 2.2 GHz
2. Disable boost
3. Start minion workers to re-measure all .asm files
4. Keep only top 30 best files per function
5. Reset CPU frequency when done

### Results
After Phase 2, each function directory will have:
- `.last_clean_run` file with cycle counts
- Only the best 30 implementations (slow ones deleted)

## Configuration

### Change Curve/Method
Edit `run_parallel_cryptopt.sh` line 7:
```bash
runArgs="--bridge fiat --curve secp256k1 --method square --evals 200k --bets 20 --betRatio 0.1 --fair-comparison --resultDir ~/CryptOpt/results/my-experiment"
```

### Change Number of Parallel Runs
Edit line 8:
```bash
cpumasklist="1 2 3 4 5"  # 5 parallel runs on cores 1-5
```

**Note:** Paper uses 3 parallel runs for fair comparison across platforms.

### Change CPU Frequency (Phase 2)
Check your CPU's base frequency:
```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/base_frequency
# Output: 2200000 (2.2 GHz)
```

Use this value for `FREQ` in Phase 2.

## Troubleshooting

### Script kills my SSH connection
- Make sure you're using **terminal-only SSH**, not VS Code Remote
- The script kills node processes, which includes IDE remote connections
- If you must use IDE, see the commented alternative in the script

### Permission denied for sudo commands
Some commands need sudo:
- `echo 1 | sudo tee /proc/sys/kernel/perf_event_paranoid` (enable performance counters)
- `sudo ./gru.sh` (lock CPU frequency)

Ask your system administrator for sudo access if needed.

### tmux session already exists
If you get errors about existing tmux sessions:
```bash
# List sessions:
tmux list-sessions

# Kill all sessions:
tmux kill-server

# Then run the script again
```

### Results directory already exists
The script appends to existing results. To start fresh:
```bash
rm -rf ~/CryptOpt/results/fiar-comp
```

## Paper Reference

This setup reproduces:
- **Section 7.1 "Experimental Setup"** - Hardware platforms, generation, bet-and-run
- **Section 8.3.1 "Software Setup"** - CPU pinning with taskset, parallel runs
- **Appendix A "On Reliable Performance Measurement"** - Algorithm 3, frequency locking

### Key Methodology Points
1. ✅ 3 parallel optimization runs (fair comparison across platforms)
2. ✅ CPU core pinning using `taskset` (reduce context switching noise)
3. ✅ One core left for OS activity
4. ✅ Algorithm 3 for cycle measurement (batch size, median, t-test)
5. ✅ CPU frequency locking for final evaluation (Phase 2 only)
6. ✅ No GUI or unnecessary background tasks (terminal-only)

## Quick Reference

```bash
# Phase 1: Optimization (20-40 hours)
cd /home/harutok/CryptOpt-Scripts
./run_parallel_cryptopt.sh
tmux attach  # Monitor
# Ctrl+B then D to detach
exit  # Disconnect

# Check later:
ssh harutok@server
ps aux | grep CryptOpt  # Still running?
tmux attach  # See progress

# Phase 2: Evaluation (optional, a few minutes)
cd /home/harutok/CryptOpt-Scripts/clean
export FREQ=2200000
export RES=~/CryptOpt/results/fiar-comp
sudo ./gru.sh

# View results:
ls ~/CryptOpt/results/fiar-comp/fiat/*/
cat ~/CryptOpt/results/fiar-comp/fiat/*/.last_clean_run
```

## Summary

| Phase | Duration | CPU Freq | Output | Purpose |
|-------|----------|----------|--------|---------|
| Phase 1 | 20-40h | Normal | 3 .asm files | Generate implementations |
| Phase 2 | Minutes | Locked | Cycle counts | Stable final numbers |

**For your paper:** You can report numbers from Phase 1 directly, or use Phase 2 for the most stable results.
