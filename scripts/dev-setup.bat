@echo off
setlocal enabledelayedexpansion

REM ==========================================
REM WellFin AI Agent 統合開発セットアップ
REM ==========================================

echo.
echo 🚀 WellFin AI Agent Development Setup
echo ==========================================

REM 環境確認
echo 📋 Environment Check...
where node >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js not found. Please install Node.js
    pause
    exit /b 1
)

where flutter >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter not found. Please install Flutter
    pause
    exit /b 1
)

where gcloud >nul 2>&1
if errorlevel 1 (
    echo ❌ gcloud CLI not found. Please install Google Cloud SDK
    pause
    exit /b 1
)

echo ✅ All required tools found
echo.

REM APIキー設定確認
echo 🔐 API Key Configuration...
if exist "config\development\api-config.json" (
    echo ✅ API key configuration found
) else (
    echo 🔄 Generating API key configuration...
    call scripts\setup-api-keys.bat development
)

REM Flutter依存関係
echo 📱 Flutter Dependencies...
cd wellfin
flutter pub get
if errorlevel 1 (
    echo ❌ Flutter pub get failed
    pause
    exit /b 1
)
cd ..

REM Functions依存関係
echo 🔧 Functions Dependencies...
cd functions
npm install
if errorlevel 1 (
    echo ❌ npm install failed
    pause
    exit /b 1
)
cd ..

echo.
echo ✅ Development setup completed!
echo.
echo 🎯 Available Commands:
echo ========================
echo.
echo 📱 Flutter Development:
echo    scripts\flutter-dev.bat         - Run Flutter app with API key
echo    scripts\flutter-build.bat       - Build Flutter APK
echo.
echo 🔧 API Functions:
echo    scripts\functions-dev.bat       - Start local API server
echo    scripts\functions-deploy.bat    - Deploy to Cloud Functions
echo.
echo 🧪 Testing:
echo    scripts\test-api.bat            - Test API endpoints
echo    scripts\health-check.bat        - Check system health
echo.
pause 