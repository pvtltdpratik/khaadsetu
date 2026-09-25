#!/usr/bin/env bash
# Builds the four release APKs.  Usage: ./build_all.sh [API_BASE_URL] [API_KEY]
# Example: ./build_all.sh http://35.173.238.53:3000
# Output: build/app/outputs/flutter-apk/app-<flavor>-release.apk
set -euo pipefail
cd "$(dirname "$0")"

DEFINES=()
[ -n "${1:-}" ] && DEFINES+=("--dart-define=API_BASE_URL=$1")
[ -n "${2:-}" ] && DEFINES+=("--dart-define=API_KEY=$2")

flutter build apk --flavor farmer -t lib/main_farmer.dart --release "${DEFINES[@]}"
flutter build apk --flavor center -t lib/main_center.dart --release "${DEFINES[@]}"
flutter build apk --flavor admin  -t lib/main_admin.dart  --release "${DEFINES[@]}"
flutter build apk --flavor dev    -t lib/main_dev.dart    --release "${DEFINES[@]}"

echo
echo "Done. APKs are in build/app/outputs/flutter-apk/"
ls -1 build/app/outputs/flutter-apk/*.apk
