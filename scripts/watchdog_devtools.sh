#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITERATE="$ROOT_DIR/scripts/iterate_devtools.sh"
LOG_FILE="$ROOT_DIR/build/devtools_watchdog.log"

INTERVAL_SECONDS=1800
TOUCH_MEMORY=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval)
      INTERVAL_SECONDS="$2"
      shift 2
      ;;
    --no-touch-memory)
      TOUCH_MEMORY=0
      shift
      ;;
    --help)
      echo "Usage: $0 [--interval <seconds>] [--no-touch-memory]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

mkdir -p "$ROOT_DIR/build"

echo "Watchdog started at $(date "+%Y-%m-%d %H:%M:%S %z")" | tee -a "$LOG_FILE"
echo "Interval: ${INTERVAL_SECONDS}s" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"

while true; do
  NOW_TS="$(date "+%Y-%m-%d %H:%M:%S %z")"
  echo "---" | tee -a "$LOG_FILE"
  echo "Cycle start: $NOW_TS" | tee -a "$LOG_FILE"
  if [[ $TOUCH_MEMORY -eq 1 ]]; then
    "$ITERATE" --touch-memory | tee -a "$LOG_FILE"
  else
    "$ITERATE" | tee -a "$LOG_FILE"
  fi
  echo "Cycle complete: $(date "+%Y-%m-%d %H:%M:%S %z")" | tee -a "$LOG_FILE"
  echo "Sleeping for ${INTERVAL_SECONDS}s..." | tee -a "$LOG_FILE"
  sleep "$INTERVAL_SECONDS"
done
