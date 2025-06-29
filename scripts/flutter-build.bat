@echo off
setlocal enabledelayedexpansion

REM ==========================================
REM WellFin Flutter APK Builder
REM ==========================================

echo.
echo 📦 Building WellFin Flutter APK...
echo ==========================================

REM APIキー設定確認
if not exist "config\development\api-config.json" (
    echo ❌ API key configuration not found
    echo 🔄 Run 'scripts\dev-setup.bat' first
    pause
    exit /b 1
)

REM PowerShellでJSON設定読み込み
for /f "usebackq delims=" %%i in (`powershell -Command "$config = Get-Content 'config\development\api-config.json' | ConvertFrom-Json; $config.apiKey"`) do set API_KEY=%%i
for /f "usebackq delims=" %%i in (`powershell -Command "$config = Get-Content 'config\development\api-config.json' | ConvertFrom-Json; $config.apiUrl"`) do set API_URL=%%i
for /f "usebackq delims=" %%i in (`powershell -Command "$config = Get-Content 'config\development\api-config.json' | ConvertFrom-Json; $config.version"`) do set VERSION=%%i

echo ✅ Configuration loaded from config\development\api-config.json
echo 🔑 API Key: !API_KEY:~0,20!...
echo 🔗 API URL: !API_URL!
echo 📦 Version: !VERSION!
echo.

REM Flutter APKビルド
cd wellfin
echo 🔨 Building APK with configuration...
flutter build apk --release --build-name=!VERSION! --dart-define=WELLFIN_API_KEY=!API_KEY! --dart-define=WELLFIN_API_URL=!API_URL!

if errorlevel 1 (
    echo ❌ APK build failed
    cd ..
    pause
    exit /b 1
)

echo.
echo ✅ APK build completed!
echo 📱 APK location: build\app\outputs\flutter-apk\app-release.apk
echo.

cd ..
pause 