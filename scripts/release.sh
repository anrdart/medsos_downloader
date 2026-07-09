#!/usr/bin/env bash
# One-command release for ANR Saver:
#   1) bump version in pubspec.yaml
#   2) build 3 split-per-abi obfuscated release APKs
#   3) create a GitHub release and upload the APKs
#   4) point Firebase Remote Config at the release (per-abi auto-update)
#
# Usage:
#   scripts/release.sh <versionName> <versionCode> "<changelog>" [--forced]
#   scripts/release.sh 1.6.0 8 "Perbaikan download & auto-update"
set -euo pipefail

VNAME="${1:-}"; VCODE="${2:-}"; CHANGELOG="${3:-}"; FORCED="${4:-}"
[[ -n "$VNAME" && -n "$VCODE" ]] || {
  echo "Usage: scripts/release.sh <versionName> <versionCode> \"<changelog>\" [--forced]"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
TAG="v$VNAME"
APK_DIR="build/app/outputs/flutter-apk"
SA="${FIREBASE_SA_JSON:-scripts/.firebase-sa.json}"

echo ">> Preflight..."
command -v gh >/dev/null || { echo "gh CLI not found"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Run: gh auth login"; exit 1; }
[[ -f "$SA" ]] || { echo "Missing service-account JSON: $SA (see scripts/README.md)"; exit 1; }
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

echo ">> Bumping version to $VNAME+$VCODE..."
sed -i "s/^version:.*/version: $VNAME+$VCODE/" pubspec.yaml

echo ">> Building split-per-abi obfuscated release..."
mkdir -p build/debug-symbols
flutter build apk --release --obfuscate \
  --split-debug-info=build/debug-symbols --split-per-abi

APKS=(
  "$APK_DIR/app-arm64-v8a-release.apk"
  "$APK_DIR/app-armeabi-v7a-release.apk"
  "$APK_DIR/app-x86_64-release.apk"
)
for a in "${APKS[@]}"; do [[ -f "$a" ]] || { echo "Missing APK: $a"; exit 1; }; done

echo ">> Creating GitHub release $TAG on $REPO..."
if gh release view "$TAG" >/dev/null 2>&1; then
  gh release upload "$TAG" "${APKS[@]}" --clobber
else
  gh release create "$TAG" "${APKS[@]}" --title "$TAG" --notes "${CHANGELOG:-$TAG}"
fi

URL_BASE="https://github.com/$REPO/releases/download/$TAG"

echo ">> Updating Firebase Remote Config..."
FORCED_FLAG=""
[[ "$FORCED" == "--forced" ]] && FORCED_FLAG="--forced"
python3 scripts/set_remote_config.py \
  --version-name "$VNAME" --version-code "$VCODE" \
  --url-base "$URL_BASE" --changelog "$CHANGELOG" $FORCED_FLAG

echo
echo "Released $TAG. Users on older versions will auto-update to the APK"
echo "matching their device ABI from: $URL_BASE"
