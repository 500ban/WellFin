@echo off
setlocal enabledelayedexpansion

REM ==========================================
REM WellFin Flutter Development Runner
REM ==========================================

echo.
echo 📱 Starting WellFin Flutter App...
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

echo ✅ Configuration loaded from config\development\api-config.json
echo 🔑 API Key: !API_KEY:~0,20!...
echo 🔗 API URL: !API_URL!
echo.

REM Flutter実行
cd wellfin
echo 🚀 Running Flutter app with configuration...
flutter run --dart-define=WELLFIN_API_KEY=!API_KEY! --dart-define=WELLFIN_API_URL=!API_URL!

cd .. 