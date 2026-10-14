#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/dist/Birding.app/Contents/MacOS/Birding"
[[ -x "$BIN" ]] || "$ROOT/scripts/build.sh"
OUT="$(mktemp -d "$ROOT/.build/settings-check.XXXXXX")"
"$BIN" --verify-settings "$OUT"
cat "$OUT/report.json"
printf '\nEvidence: %s\n' "$OUT"
