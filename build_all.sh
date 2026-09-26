#!/usr/bin/env bash
# Builds the four release APKs against the API below.  Usage: ./build_all.sh [API_BASE_URL] [API_KEY]
# Run it with no arguments to use the built-in address; pass a URL only to override it.
# Output: build/app/outputs/flutter-apk/app-<flavor>-release.apk
set -euo pipefail
cd "$(dirname "$0")"

DEFINES=("--dart-define=API_BASE_URL=${1:-https://api-proxy.khaadsetu-ec2.workers.dev}")
[ -n "${2:-}" ] && DEFINES+=("--dart-define=API_KEY=$2")
# Push notifications: firebase.json (git-ignored) holds the Firebase values, see firebase.example.json.
[ -f firebase.json ] && DEFINES+=("--dart-define-from-file=firebase.json")

# Gradle sometimes packs an OLD copy of the compiled app into the APK; clearing these folders forces a fresh merge.
fresh() { rm -rf build/app/intermediates/merged_native_libs build/app/intermediates/merged_jni_libs build/app/intermediates/stripped_native_libs; }

fresh
flutter build apk --flavor farmer -t lib/main_farmer.dart --release "${DEFINES[@]}"
fresh
flutter build apk --flavor center -t lib/main_center.dart --release "${DEFINES[@]}"
fresh
flutter build apk --flavor admin  -t lib/main_admin.dart  --release "${DEFINES[@]}"
flutter build apk --flavor dev    -t lib/main_dev.dart    --release "${DEFINES[@]}"

echo
echo "Done. APKs are in build/app/outputs/flutter-apk/"
ls -1 build/app/outputs/flutter-apk/*.apk
