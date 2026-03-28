#!/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "Building NotchNook..."
swift build -c release

APP="NotchNook.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp .build/release/NotchNook "$APP/Contents/MacOS/NotchNook"
cp Resources/Info.plist      "$APP/Contents/Info.plist"

codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "Done -> $APP"
echo "Run:  open $APP"
echo "Install: ./scripts/install.sh"
