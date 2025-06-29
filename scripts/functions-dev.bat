@echo off
setlocal enabledelayedexpansion

REM ==========================================
REM WellFin API Functions Development Server
REM ==========================================

echo.
echo 🔧 Starting WellFin API Functions...
echo ==========================================

REM 依存関係確認
cd functions
if not exist "node_modules" (
    echo 🔄 Installing dependencies...
    npm install
    if errorlevel 1 (
        echo ❌ npm install failed
        cd ..
        pause
        exit /b 1
    )
)

echo ✅ Dependencies ready
echo 🌐 Local API will be available at: http://localhost:3000
echo 🔑 Test with: X-API-Key: dev-secret-key
echo.
echo 📋 Available endpoints:
echo    GET  /health
echo    GET  /api/v1/vertex-ai-test
echo    POST /api/v1/analyze-task
echo    POST /api/v1/optimize-schedule
echo    POST /api/v1/recommendations
echo.

REM 開発サーバー起動
set ENVIRONMENT=development
set PORT=3000
npm run dev

cd .. 