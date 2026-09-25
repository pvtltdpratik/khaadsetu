@echo off
REM Builds the four release APKs.  Usage: build_all.bat [API_BASE_URL] [API_KEY]
REM Example: build_all.bat http://35.173.238.53:3000
REM Output: build\app\outputs\flutter-apk\app-<flavor>-release.apk
cd /d "%~dp0"

set DEFINES=
if not "%~1"=="" set DEFINES=--dart-define=API_BASE_URL=%~1
if not "%~2"=="" set DEFINES=%DEFINES% --dart-define=API_KEY=%~2

call flutter build apk --flavor farmer -t lib/main_farmer.dart --release %DEFINES% || goto :failed
call flutter build apk --flavor center -t lib/main_center.dart --release %DEFINES% || goto :failed
call flutter build apk --flavor admin  -t lib/main_admin.dart  --release %DEFINES% || goto :failed
call flutter build apk --flavor dev    -t lib/main_dev.dart    --release %DEFINES% || goto :failed

echo.
echo Done. APKs are in build\app\outputs\flutter-apk\
dir /b build\app\outputs\flutter-apk\*.apk
goto :eof

:failed
echo.
echo A build failed. See the messages above.
exit /b 1
