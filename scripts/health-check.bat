@echo off
setlocal enabledelayedexpansion

REM ==========================================
REM WellFin AI Agent Health Check
REM ==========================================

echo.
echo 🏥 WellFin AI Agent Health Check
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
for /f "usebackq delims=" %%i in (`powershell -Command "$config = Get-Content 'config\development\api-config.json' | ConvertFrom-Json; $config.apiUrl"`) do set FUNCTION_URL=%%i

echo ✅ Configuration loaded from config\development\api-config.json
echo 🔑 API Key: !API_KEY:~0,20!...
echo 🔗 API URL: !FUNCTION_URL!

echo.
echo 🔍 1. API Health Check
echo --------------------------------
curl -s "%FUNCTION_URL%/health"

echo.
echo 🔍 2. Vertex AI Authentication Test
echo --------------------------------
curl -s -H "X-API-Key: !API_KEY!" "%FUNCTION_URL%/api/v1/vertex-ai-test"

echo.
echo 🔍 3. Task Analysis API Test
echo --------------------------------
curl -s -X POST -H "Content-Type: application/json" -H "X-API-Key: !API_KEY!" -d "{\"userInput\":\"テスト用のタスクです\"}" "%FUNCTION_URL%/api/v1/analyze-task"

echo.
echo 🔍 4. Flutter Dependencies Check
echo --------------------------------
cd wellfin
flutter doctor --android-licenses > nul 2>&1
flutter doctor
cd ..

echo.
echo 🔍 5. Functions Dependencies Check
echo --------------------------------
cd functions
if exist "node_modules" (
    echo ✅ Functions dependencies installed
) else (
    echo ❌ Functions dependencies missing - run 'npm install'
)
cd ..

echo.
echo ✅ Health check completed
pause 