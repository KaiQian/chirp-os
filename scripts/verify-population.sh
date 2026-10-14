#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/dist/ChirpOS.app/Contents/MacOS/Birding"
[[ -x "$BIN" ]] || "$ROOT/scripts/build.sh"
OUT="$(mktemp -d "$ROOT/.build/population-check.XXXXXX")"
"$BIN" --verify-population "$OUT/report.json"
cat "$OUT/report.json"
printf '\nEvidence: %s\n' "$OUT"
