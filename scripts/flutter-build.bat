@echo off
setlocal enabledelayedexpansion

REM ==========================================
REM WellFin Flutter APK Builder & Deployer
REM ==========================================

echo.
echo 📦 Building WellFin Flutter APK and Deploying...
echo ==========================================

REM Step 1: APKビルド
echo Step 1: Building APK...
call scripts\flutter-build-only.bat

if errorlevel 1 (
    echo ❌ APK build failed
    pause
    exit /b 1
)

echo.
echo ✅ APK build completed successfully!
echo.

REM Step 2: Firebaseデプロイ
echo 🚀 Step 2: Deploying to Firebase...
call scripts\firebase-deploy.bat

if errorlevel 1 (
    echo ❌ Firebase deployment failed
    pause
    exit /b 1
)

echo.
echo ✅ Build and deployment completed successfully!
echo. 