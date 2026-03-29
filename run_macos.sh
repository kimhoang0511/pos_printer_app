#!/bin/bash
set -e

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="$APP_DIR/build/macos/Build/Products/Debug/pos_printer_app.app"

echo ">>> Bước 1: flutter build macos (debug, bỏ qua codesign)..."
cd "$APP_DIR"
flutter build macos --debug \
  --dart-define=FLUTTER_XCODE_CODE_SIGNING_ALLOWED=NO 2>&1 || \
xcrun xcodebuild \
  -workspace macos/Runner.xcworkspace \
  -configuration Debug \
  -scheme Runner \
  -derivedDataPath build/macos \
  -destination platform=macOS,arch=arm64 \
  OBJROOT=build/macos/Build/Intermediates.noindex \
  SYMROOT=build/macos/Build/Products \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -quiet

echo ">>> Bước 2: Xoá com.apple.provenance khỏi app bundle..."
find "$APP_BUNDLE" -exec xattr -c {} \; 2>/dev/null || true
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

echo ">>> Bước 3: Ad-hoc codesign..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo ">>> Bước 4: Mở app..."
open "$APP_BUNDLE"

echo ">>> App đã chạy! Dùng 'flutter attach' để hot reload."
echo "    flutter attach -d macos"
