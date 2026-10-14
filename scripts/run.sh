#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ ! -x "$ROOT/dist/Birding.app/Contents/MacOS/Birding" ]]; then "$ROOT/scripts/build.sh"; fi
open -g "$ROOT/dist/Birding.app" --args "$@"
