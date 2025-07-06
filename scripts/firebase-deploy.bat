@echo off
setlocal enabledelayedexpansion

REM ==========================================
REM Firebase App Distribution Deployer
REM ==========================================

echo.
echo 🚀 Deploying to Firebase App Distribution...
echo ==========================================

REM APKファイルの存在確認
if exist "wellfin\build\app\outputs\flutter-apk\app-release.apk" (
    echo ✅ APK file found
) else (
    echo ❌ APK file not found
    echo 🔄 Run 'scripts\flutter-build-only.bat' first
    pause
    exit /b 1
)

REM リリースノートファイルの存在確認
if exist "doc\release_notes.md" (
    echo ✅ Release notes found
) else (
    echo ❌ Release notes not found
    pause
    exit /b 1
)

echo.
echo 🔨 Deploying to Firebase App Distribution...
firebase appdistribution:distribute "wellfin/build/app/outputs/flutter-apk/app-release.apk" --app "1:933043164976:android:97bcddf0bc4d976dd65af5" --groups "testers" --release-notes-file "doc/release_notes.md"

if errorlevel 1 (
    echo ❌ Firebase App Distribution deployment failed
    pause
    exit /b 1
)

echo.
echo ✅ Firebase App Distribution deployment completed!
echo. 