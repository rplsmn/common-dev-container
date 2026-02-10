#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values (prefer jq; fall back to python3)
if command -v jq >/dev/null 2>&1; then
    CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
    MODEL=$(echo "$input" | jq -r '.model.display_name // ""')
    PERCENT_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
    COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
elif command -v python3 >/dev/null 2>&1; then
    readarray -t _vals < <(python3 - <<'PY' <<<"$input"
import json,sys

data = json.load(sys.stdin)

def g(keys, default=None):
    cur = data
    for k in keys:
        if isinstance(cur, dict) and k in cur:
            cur = cur[k]
        else:
            return default
    return cur

current_dir = g(["workspace", "current_dir"], None) or g(["cwd"], "") or ""
model = g(["model", "display_name"], "") or ""
percent = g(["context_window", "used_percentage"], 0) or 0
cost = g(["cost", "total_cost_usd"], 0) or 0

print(current_dir)
print(model)
print(percent)
print(cost)
PY
)
    CURRENT_DIR="${_vals[0]}"
    MODEL="${_vals[1]}"
    PERCENT_USED="${_vals[2]:-0}"
    COST_USD="${_vals[3]:-0}"
else
    CURRENT_DIR=""
    MODEL=""
    PERCENT_USED="0"
    COST_USD="0"
fi

CURRENT_DIR="${CURRENT_DIR:-$PWD}"
DIR_NAME=$(basename "$CURRENT_DIR")

# Format percentage to 1 decimal place
PERCENT_USED=$(printf "%.1f" "${PERCENT_USED:-0}")

# Format cost to show more precision for small amounts
if awk -v c="${COST_USD:-0}" 'BEGIN{exit !(c < 0.01)}'; then
    COST_DISPLAY=$(printf "%.4f" "${COST_USD:-0}")
else
    COST_DISPLAY=$(printf "%.2f" "${COST_USD:-0}")
fi

# Get git branch if in a git repo (change to current directory first)
GIT_BRANCH=""
cd "$CURRENT_DIR" 2>/dev/null
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        GIT_BRANCH=" ($BRANCH)"
    fi
fi

# Build status line with ANSI colors
# \033[36m = cyan, \033[32m = green, \033[33m = yellow, \033[35m = magenta, \033[0m = reset
echo -e "\033[36m${DIR_NAME}\033[0m\033[32m${GIT_BRANCH}\033[0m - \033[33m${MODEL}\033[0m - \033[35m${PERCENT_USED}%\033[0m - \033[36m\$${COST_DISPLAY}\033[0m"
