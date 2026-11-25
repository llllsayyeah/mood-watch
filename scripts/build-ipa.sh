#!/usr/bin/env bash
# Builds MoodWatch.ipa locally on macOS.
#
#   ./scripts/build-ipa.sh            # unsigned ipa -> build/MoodWatch.ipa
#   TEAM_ID=ABCDE12345 ./scripts/build-ipa.sh --signed
#
# Unsigned output is meant for a separate signing step (Sideloadly / eSign / AltStore /
# your own resign tool). Signed output needs a development team and a matching profile.
set -euo pipefail

cd "$(dirname "$0")/.."

SIGNED=0
[[ "${1:-}" == "--signed" ]] && SIGNED=1

BUNDLE_ID="${BUNDLE_ID:-com.moodwatch.app}"
VERSION="${MARKETING_VERSION:-1.0.0}"
BUILD_DIR="build"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

SIGN_ARGS=(
  CODE_SIGN_IDENTITY=""
  CODE_SIGNING_REQUIRED=NO
  CODE_SIGNING_ALLOWED=NO
)

if [[ $SIGNED -eq 1 ]]; then
  : "${TEAM_ID:?set TEAM_ID=XXXXXXXXXX for a signed build}"
  SIGN_ARGS=(
    -allowProvisioningUpdates
    CODE_SIGN_STYLE=Automatic
    DEVELOPMENT_TEAM="$TEAM_ID"
  )
fi

xcodebuild archive \
  -project MoodWatch.xcodeproj \
  -scheme MoodWatch \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$BUILD_DIR/MoodWatch.xcarchive" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  MARKETING_VERSION="$VERSION" \
  "${SIGN_ARGS[@]}"

APP="$BUILD_DIR/MoodWatch.xcarchive/Products/Applications/MoodWatch.app"
test -d "$APP" || { echo "archive did not produce MoodWatch.app"; exit 1; }

mkdir -p "$BUILD_DIR/Payload"
cp -R "$APP" "$BUILD_DIR/Payload/"

pushd "$BUILD_DIR" >/dev/null
rm -f MoodWatch.ipa
zip -qry MoodWatch.ipa Payload
popd >/dev/null

echo
echo "IPA:  $PWD/$BUILD_DIR/MoodWatch.ipa"
echo "ID:   $(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist" 2>/dev/null || echo "$BUNDLE_ID")"
echo "Name: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$APP/Info.plist" 2>/dev/null || echo 'Mood Watch')"
if [[ $SIGNED -eq 0 ]]; then
  echo
  echo "This IPA is unsigned. Sign it with your own certificate before installing:"
  echo "  Sideloadly / eSign / AltStore / Xcode 'Sign to Run Locally' all accept it."
fi
