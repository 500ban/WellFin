@echo off
setlocal enabledelayedexpansion

REM WellFin API Key Setup Script for Windows
REM Usage: setup-api-keys.bat [environment]

echo.
echo ================================
echo WellFin API Key Setup
echo ================================

REM 環境設定（デフォルトは development）
set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" set ENVIRONMENT=development

echo Environment: %ENVIRONMENT%
echo.

REM Node.js の確認
where node >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js が見つかりません。Node.js をインストールしてください。
    pause
    exit /b 1
)

echo 🔐 Generating API Key for %ENVIRONMENT%...
node scripts/generate-api-keys.js %ENVIRONMENT%

if errorlevel 1 (
    echo ❌ API Key generation failed
    pause
    exit /b 1
)

echo.
echo ✅ API Key setup completed for %ENVIRONMENT%
echo.

REM 環境別の次のステップを表示
if "%ENVIRONMENT%"=="development" (
    echo 📱 Flutter Development Commands:
    echo    flutter run --dart-define-from-file=config/development/flutter.env
    echo    flutter build apk --dart-define-from-file=config/development/flutter.env
    echo.
    echo 🏗️  Terraform Commands:
    echo    cd terraform
    echo    terraform apply -var-file="../config/development/terraform.tfvars"
)

if "%ENVIRONMENT%"=="staging" (
    echo 📱 Flutter Staging Commands:
    echo    flutter build apk --release --dart-define-from-file=config/staging/flutter.env
    echo.
    echo 🏗️  Terraform Commands:
    echo    cd terraform
    echo    terraform apply -var-file="../config/staging/terraform.tfvars"
)

if "%ENVIRONMENT%"=="production" (
    echo ⚠️  PRODUCTION SETUP REQUIRED:
    echo    1. Store API key in Google Secret Manager
    echo    2. Update Terraform to use Secret Manager
    echo    3. Use secure CI/CD pipeline for deployment
    echo.
    echo 🏗️  Manual Terraform Commands:
    echo    cd terraform
    echo    terraform apply -var="project_id=YOUR_PROD_PROJECT"
)

echo.
echo 📋 Configuration files created in: config/%ENVIRONMENT%/
echo.

pause 