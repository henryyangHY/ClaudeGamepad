#!/bin/bash
set -e

PRODUCT_NAME="ClaudeGamepad"
BUILD_DIR=".build/release"
APP_NAME="${PRODUCT_NAME}.app"
APP_DIR="${APP_NAME}/Contents"

echo "Building release..."
swift build -c release

echo "Packaging .app bundle..."
rm -rf "${APP_NAME}"
mkdir -p "${APP_DIR}/MacOS"
mkdir -p "${APP_DIR}/Resources"

# Binary
cp "${BUILD_DIR}/${PRODUCT_NAME}" "${APP_DIR}/MacOS/"

# Resources: copy flat into Contents/Resources/ (Bundle.main finds them here)
BUNDLE_RESOURCES="${BUILD_DIR}/${PRODUCT_NAME}_${PRODUCT_NAME}.bundle/Resources"
if [ -d "${BUNDLE_RESOURCES}" ]; then
    cp -R "${BUNDLE_RESOURCES}/"* "${APP_DIR}/Resources/"
fi

# Info.plist
cp "Info.plist" "${APP_DIR}/"

# Ad-hoc code sign
codesign --force --sign - "${APP_NAME}"

echo ""
echo "✅ ${APP_NAME} ready."
echo ""
echo "Next steps:"
echo "  1. cp -R ${APP_NAME} /Applications/"
echo "  2. System Settings → General → Login Items → add ClaudeGamepad"
echo "  3. First launch: grant Accessibility in Privacy & Security"
