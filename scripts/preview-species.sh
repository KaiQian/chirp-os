#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/build.sh"
"$ROOT/dist/Birding.app/Contents/MacOS/Birding" --export-species "$ROOT/Assets/Species"
