#!/usr/bin/env bash
# Builds the four release APKs. Output: build/app/outputs/flutter-apk/app-<flavor>-release.apk
set -euo pipefail
cd "$(dirname "$0")"

flutter build apk --flavor farmer -t lib/main_farmer.dart --release
flutter build apk --flavor center -t lib/main_center.dart --release
flutter build apk --flavor admin  -t lib/main_admin.dart  --release
flutter build apk --flavor dev    -t lib/main_dev.dart    --release

echo
echo "Done. APKs are in build/app/outputs/flutter-apk/"
ls -1 build/app/outputs/flutter-apk/*.apk
