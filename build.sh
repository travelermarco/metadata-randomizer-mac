#!/bin/bash
set -e

APP_NAME="Metadata Randomizer"
BINARY_NAME="MetadataRandomizerMac"
BUNDLE_ID="com.metarandom.mac"
APP_DIR="${APP_NAME}.app"

echo "→ Building release binary…"
swift build -c release 2>&1

echo "→ Packaging .app bundle…"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp ".build/release/${BINARY_NAME}" "$APP_DIR/Contents/MacOS/${BINARY_NAME}"

cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>      <string>${BINARY_NAME}</string>
    <key>CFBundleIdentifier</key>     <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>           <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>        <string>1.0</string>
    <key>CFBundleShortVersionString</key> <string>1.0</string>
    <key>CFBundlePackageType</key>    <string>APPL</string>
    <key>NSPrincipalClass</key>       <string>NSApplication</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSMinimumSystemVersion</key> <string>13.0</string>
    <key>NSSupportsAutomaticTermination</key> <false/>
    <key>NSSupportsSuddenTermination</key>    <false/>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS allows running without Gatekeeper quarantine for local use
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true

echo ""
echo "✓ Done: ${APP_DIR}"
echo "  Open: open '${APP_DIR}'"
