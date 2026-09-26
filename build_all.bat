@echo off
REM Builds the farmer, center and admin release APKs against the API below (the dev build is switched off).  Usage: build_all.bat [API_BASE_URL] [API_KEY]
REM Run it with no arguments to use the built-in address; pass a URL only to override it.
REM Output: build\app\outputs\flutter-apk\app-<flavor>-release.apk
cd /d "%~dp0"

set API_BASE_URL=https://api-proxy.khaadsetu-ec2.workers.dev
if not "%~1"=="" set API_BASE_URL=%~1
set DEFINES=--dart-define=API_BASE_URL=%API_BASE_URL%
REM Push notifications: firebase.json (git-ignored) holds the Firebase values, see firebase.example.json.
if exist firebase.json set DEFINES=%DEFINES% --dart-define-from-file=firebase.json
if not "%~2"=="" set DEFINES=%DEFINES% --dart-define=API_KEY=%~2
REM Self-update: every build sent to phones needs a higher number than the last:  set BUILD_NUMBER=7
if not "%BUILD_NUMBER%"=="" set DEFINES=%DEFINES% --build-number=%BUILD_NUMBER%

REM Gradle sometimes packs an OLD copy of the compiled app into the APK (the new code compiles, but the merged
REM native libraries are not refreshed). Clearing these three folders forces a fresh merge every time.
rmdir /s /q build\app\intermediates\merged_native_libs build\app\intermediates\merged_jni_libs build\app\intermediates\stripped_native_libs 2>nul

call flutter build apk --flavor farmer -t lib/main_farmer.dart --release %DEFINES% || goto :failed
rmdir /s /q build\app\intermediates\merged_native_libs build\app\intermediates\merged_jni_libs build\app\intermediates\stripped_native_libs 2>nul
call flutter build apk --flavor center -t lib/main_center.dart --release %DEFINES% || goto :failed
rmdir /s /q build\app\intermediates\merged_native_libs build\app\intermediates\merged_jni_libs build\app\intermediates\stripped_native_libs 2>nul
call flutter build apk --flavor admin  -t lib/main_admin.dart  --release %DEFINES% || goto :failed
REM call flutter build apk --flavor dev    -t lib/main_dev.dart    --release %DEFINES% || goto :failed

echo.
echo Done. APKs are in build\app\outputs\flutter-apk\
dir /b build\app\outputs\flutter-apk\*.apk
goto :eof

:failed
echo.
echo A build failed. See the messages above.
exit /b 1
