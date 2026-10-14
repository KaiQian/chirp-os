#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/dist/Birding.app/Contents/MacOS/Birding"
[[ -x "$BIN" ]] || "$ROOT/scripts/build.sh"
OUT="$(mktemp -d "$ROOT/.build/desktop-check.XXXXXX")"
"$BIN" --fixture "$OUT" > "$OUT/fixture.log" 2>&1 &
FIXTURE_PID=$!
trap 'kill "$FIXTURE_PID" 2>/dev/null || true' EXIT
for i in {1..50}; do [[ -f "$OUT/fixture.json" ]] && break; sleep 0.1; done
set +e
"$BIN" --integration "$OUT" | tee "$OUT/integration.log"
RESULT=${PIPESTATUS[0]}
set -e
if [[ -f "$OUT/report.json" ]]; then cat "$OUT/report.json"; else printf 'Verification did not produce a report. See log files.\n'; fi
printf '\nEvidence: %s\n' "$OUT"
exit "$RESULT"
