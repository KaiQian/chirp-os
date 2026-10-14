#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
swift build -c release
.build/release/Birding --export-shared "$ROOT/shared"
.build/release/Birding --export-icon "$ROOT/Assets"
mkdir -p .build/windows-icon
for size in 16 32 48 64 128 256; do sips -z "$size" "$size" Assets/AppIcon.png --out ".build/windows-icon/$size.png" >/dev/null; done
python3 - <<'PY'
from pathlib import Path
import struct
sizes=[16,32,48,64,128,256];images=[Path(f'.build/windows-icon/{n}.png').read_bytes() for n in sizes]
header=struct.pack('<HHH',0,1,len(images));offset=6+16*len(images);entries=[]
for n,data in zip(sizes,images):
 entries.append(struct.pack('<BBBBHHII',n%256,n%256,0,0,1,32,len(data),offset));offset+=len(data)
Path('shared/AppIcon.ico').write_bytes(header+b''.join(entries)+b''.join(images))
PY
