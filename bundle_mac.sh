#!/bin/bash
set -e

APP_NAME="MyGTKApp"
BIN_NAME="my-gtk-app" # Name defined in build.zig
BUILD_DIR="zig-out/bin"
OUTPUT_DIR="dist"

# 1. Clean and Build
rm -rf "$OUTPUT_DIR"
zig build -Doptimize=ReleaseSafe

# 2. Create Directory Structure
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_BUNDLE/Contents/Libs"

# 3. Copy Binary
cp "$BUILD_DIR/$BIN_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 4. Create Info.plist (This tells macOS "I am a GUI app")
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 5. Bundle Libraries (Fixes "Image not found" crash on other Macs)
echo "Bundling dynamic libraries..."
dylibbundler \
  -od -b \
  -x "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
  -d "$APP_BUNDLE/Contents/Libs" \
  -p "@executable_path/../Libs/"

echo "Done. App created at $APP_BUNDLE"