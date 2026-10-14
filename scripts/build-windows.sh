#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DOTNET="${CHIRPOS_DOTNET:-dotnet}"
if [[ -x "$ROOT/.build/tools/dotnet/dotnet" ]]; then DOTNET="$ROOT/.build/tools/dotnet/dotnet"; fi
if [[ ! -f shared/art/manifest.json || ! -f shared/AppIcon.ico ]]; then echo 'Missing shared assets; run scripts/export-shared.sh on macOS first.' >&2; exit 1; fi
"$DOTNET" run --project platforms/windows/ChirpOS.Tests -c Release
for rid in "${@:-win-arm64}"; do
    case "$rid" in win-arm64|win-x64) ;; *) echo "Unsupported target: $rid" >&2; exit 1;; esac
    OUT="$ROOT/dist/windows/$rid"
    "$DOTNET" publish platforms/windows/ChirpOS/ChirpOS.csproj -c Release -r "$rid" --self-contained true -o "$OUT"
    cp LICENSE "$OUT/LICENSE.txt"
    cp platforms/windows/Verify-Windows.cmd "$OUT/Verify-Windows.cmd"
    cp platforms/windows/README.md "$OUT/README.md"
    mkdir -p dist/releases
    cp "$OUT/ChirpOS.exe" "$ROOT/dist/releases/ChirpOS-0.3.1-$rid.exe"
    if [[ "$(uname -s)" == Darwin && "$rid" == win-arm64 ]]; then
        SHARE="${CHIRPOS_SHARE_DIR:-$HOME/Downloads/share}"
        mkdir -p "$SHARE"
        cp "$OUT/ChirpOS.exe" "$SHARE/ChirpOS.exe"
    fi
done
