#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
swift build -c release
APP="$ROOT/dist/Birding.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$ROOT/Assets"
cp .build/release/Birding "$APP/Contents/MacOS/Birding.new"
mv -f "$APP/Contents/MacOS/Birding.new" "$APP/Contents/MacOS/Birding"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Birding</string>
<key>CFBundleIdentifier</key><string>dev.birding.desktop</string>
<key>CFBundleName</key><string>Birding</string>
<key>CFBundleDisplayName</key><string>Birding · 桌面观鸟</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
"$ROOT/.build/release/Birding" --export-art "$ROOT/Assets"
cp "$ROOT/Assets/stand.png" "$APP/Contents/Resources/stand.png"
codesign --force --sign - "$APP"
printf 'Built: %s\n' "$APP"
