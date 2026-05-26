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

# SPM workspace-state.json stores absolute artifact paths; stale cache breaks builds after moving the repo.
WORKSPACE_STATE="${SOURCE_PACKAGES_PATH}/workspace-state.json"
if [[ -f "${WORKSPACE_STATE}" ]] && ! grep -q "\"${ROOT_DIR}/" "${WORKSPACE_STATE}"; then
  echo "Removing stale Swift package cache (project path changed)..." >&2
  rm -rf "${SOURCE_PACKAGES_PATH}"
  mkdir -p "${SOURCE_PACKAGES_PATH}"
fi

xcodebuild \
  -project "${ROOT_DIR}/Dictator.xcodeproj" \
  -scheme "Dictator" \
  -configuration "Release" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -clonedSourcePackagesDirPath "${SOURCE_PACKAGES_PATH}" \
  CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}" \
  build

ditto "${APP_SOURCE}" "${APP_DIST}"

# Do NOT ad-hoc re-sign here. xcodebuild leaves the main binary linker-signed and Sparkle
# helpers adhoc/runtime — that pair loads correctly. Re-signing the main executable with "-"
# breaks dyld ("different Team IDs"). For Developer ID distribution use sign_and_notarize.sh.

codesign --verify --deep --strict --verbose=2 "${APP_DIST}" || {
  echo "Warning: Release bundle failed strict codesign verify; run from Xcode Debug or use sign_and_notarize.sh." >&2
}

"${ROOT_DIR}/scripts/create_dmg.sh"

echo "Release app: ${APP_DIST}"
echo "DMG: ${DIST_DIR}/Dictator.dmg"
