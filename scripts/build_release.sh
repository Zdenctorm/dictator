#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${ROOT_DIR}/build/DerivedData"
SOURCE_PACKAGES_PATH="${ROOT_DIR}/build/SourcePackages"
DIST_DIR="${ROOT_DIR}/dist"
APP_SOURCE="${DERIVED_DATA_PATH}/Build/Products/Release/Dictator.app"
APP_DIST="${DIST_DIR}/Dictator.app"

mkdir -p "${DIST_DIR}" "${SOURCE_PACKAGES_PATH}"
rm -rf "${APP_DIST}"

xcodebuild \
  -project "${ROOT_DIR}/Dictator.xcodeproj" \
  -scheme "Dictator" \
  -configuration "Release" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -clonedSourcePackagesDirPath "${SOURCE_PACKAGES_PATH}" \
  CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}" \
  build

ditto "${APP_SOURCE}" "${APP_DIST}"

# Do NOT run `codesign --deep` here. Release builds from xcodebuild already carry a
# consistent ad-hoc/linker-signed main binary + Sparkle.framework. Re-signing the bundle
# leaves Sparkle on a different Team ID than Dictator and dyld aborts at launch with:
#   "mapping process and mapped file have different Team IDs"
# For distribution signing, use scripts/sign_and_notarize.sh (Developer ID, inside-out).

codesign --verify --deep --strict --verbose=2 "${APP_DIST}" || {
  echo "Warning: local Release bundle failed strict codesign verify; run from Xcode Debug or use sign_and_notarize.sh." >&2
}

"${ROOT_DIR}/scripts/create_dmg.sh"

echo "Release app: ${APP_DIST}"
echo "DMG: ${DIST_DIR}/Dictator.dmg"
