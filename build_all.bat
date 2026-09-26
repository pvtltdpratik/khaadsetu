@echo off
REM Builds the four release APKs against the API below.  Usage: build_all.bat [API_BASE_URL] [API_KEY]
REM Run it with no arguments to use the built-in address; pass a URL only to override it.
REM Output: build\app\outputs\flutter-apk\app-<flavor>-release.apk
cd /d "%~dp0"

set API_BASE_URL=https://api-proxy.khaadsetu-ec2.workers.dev
if not "%~1"=="" set API_BASE_URL=%~1
set DEFINES=--dart-define=API_BASE_URL=%API_BASE_URL%
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
