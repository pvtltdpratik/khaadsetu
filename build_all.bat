@echo off
REM Builds the four release APKs. Output: build\app\outputs\flutter-apk\app-<flavor>-release.apk
cd /d "%~dp0"

call flutter build apk --flavor farmer -t lib/main_farmer.dart --release || goto :failed
call flutter build apk --flavor center -t lib/main_center.dart --release || goto :failed
call flutter build apk --flavor admin  -t lib/main_admin.dart  --release || goto :failed
call flutter build apk --flavor dev    -t lib/main_dev.dart    --release || goto :failed

echo.
echo Done. APKs are in build\app\outputs\flutter-apk\
dir /b build\app\outputs\flutter-apk\*.apk
goto :eof

:failed
echo.
echo A build failed. See the messages above.
exit /b 1
