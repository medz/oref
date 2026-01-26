#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEMORY_FILE="$ROOT_DIR/extension/devtools/app/DEVTOOLS_REFACTOR_MEMORY.md"

cd "$ROOT_DIR"

NOW_TS="$(date "+%Y-%m-%d %H:%M:%S %z")"

if [[ "${1:-}" == "--touch-memory" ]]; then
  if [[ -f "$MEMORY_FILE" ]]; then
    perl -0pi -e "s/^Last updated: .*/Last updated: $NOW_TS/m" "$MEMORY_FILE"
    echo "Updated memory timestamp: $NOW_TS"
  else
    echo "Memory file not found: $MEMORY_FILE"
  fi
fi

echo "== Oref DevTools Iteration Helper =="
echo "Now: $NOW_TS"

if [[ -f "$MEMORY_FILE" ]]; then
  echo "Memory header:"
  head -n 4 "$MEMORY_FILE"
fi

echo ""
echo "Git status:"
git status -sb

echo ""
echo "Recent commits:"
git log -5 --oneline

echo ""
echo "Formatting devtools app (lib + test)..."
dart format extension/devtools/app/lib extension/devtools/app/test >/dev/null

echo "Analyzing devtools app..."
flutter analyze extension/devtools/app

echo ""
echo "Done. Review git status and continue the next iteration."
