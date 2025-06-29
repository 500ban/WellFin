#!/usr/bin/env node

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// 設定ファイルからプロジェクトIDを取得
function getProjectIdFromConfig() {
  try {
    const configPath = path.join(__dirname, '..', 'config', 'development', 'api-config.json');
    if (fs.existsSync(configPath)) {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      // URLからプロジェクトIDを抽出
      const urlMatch = config.apiUrl?.match(/https:\/\/[^-]+-([^.]+)\.cloudfunctions\.net/);
      return urlMatch ? urlMatch[1] : null;
    }
  } catch (error) {
    console.warn('⚠️  設定ファイルからプロジェクトIDを取得できませんでした');
  }
  return null;
}

/**
 * WellFin API Key Generator & Manager
 * セキュアなAPIキーの生成と管理
 */

// APIキーの長さとプレフィックス
const API_KEY_LENGTH = 32;
const ENVIRONMENT_PREFIXES = {
  development: 'dev',
  staging: 'stg', 
  production: 'prod'
};

// セキュアなAPIキー生成
function generateSecureApiKey(environment = 'development') {
  const prefix = ENVIRONMENT_PREFIXES[environment] || 'dev';
  const timestamp = Date.now().toString(36);
  const randomBytes = crypto.randomBytes(API_KEY_LENGTH).toString('hex');
  
  return `${prefix}-${timestamp}-${randomBytes}`;
}

// APIキー設定ファイルの生成
function generateEnvConfig(environment, apiKey) {
  // 実際のプロジェクトIDを環境変数または設定ファイルから取得
  const projectId = process.env.GCP_PROJECT_ID || getProjectIdFromConfig() || '[YOUR-GCP-PROJECT-ID]';
  const region = process.env.GCP_REGION || 'asia-northeast1';
  
  // 環境別URL設定
  const apiUrls = {
    development: `https://${region}-${projectId}.cloudfunctions.net/wellfin-ai-function`,
    staging: `https://${region}-${projectId}.cloudfunctions.net/wellfin-ai-function`,
    production: `https://${region}-${projectId}.cloudfunctions.net/wellfin-ai-function`
  };

  const config = {
    environment,
    apiKey,
    apiUrl: apiUrls[environment] || apiUrls.development,
    generatedAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(), // 1年後
    version: '1.0.0'
  };
  
  return config;
}

// Flutter用環境変数ファイル生成
function generateFlutterEnvFile(environment, apiKey, apiUrl) {
  const envContent = `# Generated API Key Configuration for ${environment}
# Generated at: ${new Date().toISOString()}
# ⚠️ DO NOT COMMIT TO VERSION CONTROL

# WellFin API Configuration
WELLFIN_API_KEY=${apiKey}
WELLFIN_API_URL=${apiUrl}
ENVIRONMENT=${environment}
API_VERSION=1.0.0

# Build Commands:
# flutter run --dart-define=WELLFIN_API_KEY=${apiKey} --dart-define=WELLFIN_API_URL=${apiUrl}
# flutter build apk --dart-define=WELLFIN_API_KEY=${apiKey} --dart-define=WELLFIN_API_URL=${apiUrl}
`;

  return envContent;
}

// Terraform用変数ファイル生成
function generateTerraformVars(environment, apiKey) {
  const tfVarsContent = `# Generated Terraform Variables for ${environment}
# Generated at: ${new Date().toISOString()}

# Project Configuration
project_id = "your-project-id"
region = "asia-northeast1"

# API Key Configuration
wellfin_api_key = "${apiKey}"
environment = "${environment}"
`;

  return tfVarsContent;
}

// ファイル出力
function writeConfigFiles(environment, apiKey) {
  const outputDir = path.join(__dirname, '..', 'config', environment);
  
  // ディレクトリ作成
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  
  // 設定ファイル
  const config = generateEnvConfig(environment, apiKey);
  fs.writeFileSync(
    path.join(outputDir, 'api-config.json'),
    JSON.stringify(config, null, 2)
  );
  
  // Flutter用環境変数ファイル
  const flutterEnv = generateFlutterEnvFile(environment, apiKey, config.apiUrl);
  fs.writeFileSync(
    path.join(outputDir, 'flutter.env'),
    flutterEnv
  );
  
  // Terraform用変数ファイル
  const tfVars = generateTerraformVars(environment, apiKey);
  fs.writeFileSync(
    path.join(outputDir, 'terraform.tfvars'),
    tfVars
  );
  
  console.log(`✅ Generated configuration files for ${environment}:`);
  console.log(`   📁 ${outputDir}/`);
  console.log(`   📄 api-config.json`);
  console.log(`   📄 flutter.env`);
  console.log(`   📄 terraform.tfvars`);
  console.log(`   🔑 API Key: ${apiKey}`);
  console.log(`   🔗 API URL: ${config.apiUrl}`);
}

// Git ignore エントリー生成
function generateGitIgnoreEntries() {
  const gitignoreContent = `
# WellFin API Key Configuration
config/*/api-config.json
config/*/flutter.env
config/*/terraform.tfvars
*.api-key
.env.local
.env.production
`;
  
  console.log('\n📝 Add these entries to your .gitignore:');
  console.log(gitignoreContent);
}

// メイン実行
function main() {
  const args = process.argv.slice(2);
  const environment = args[0] || 'development';
  
  if (!ENVIRONMENT_PREFIXES[environment]) {
    console.error('❌ Invalid environment. Use: development, staging, or production');
    process.exit(1);
  }
  
  console.log(`🔐 Generating API Key for ${environment} environment...`);
  
  // プロジェクトID設定確認
  const projectId = process.env.GCP_PROJECT_ID || getProjectIdFromConfig();
  if (!projectId || projectId === '[YOUR-GCP-PROJECT-ID]') {
    console.warn('⚠️  GCPプロジェクトIDが設定されていません');
    console.warn('   環境変数 GCP_PROJECT_ID を設定するか、');
    console.warn('   既存の config/development/api-config.json を配置してください');
    console.warn('   例: export GCP_PROJECT_ID=your-actual-project-id');
  }
  
  const apiKey = generateSecureApiKey(environment);
  writeConfigFiles(environment, apiKey);
  
  if (environment === 'development') {
    generateGitIgnoreEntries();
  }
  
  console.log('\n🚀 Next Steps:');
  console.log(`1. Add config files to .gitignore`);
  console.log(`2. Use flutter.env for Flutter development`);
  console.log(`3. Use terraform.tfvars for infrastructure deployment`);
  console.log(`4. Store production keys securely in Secret Manager`);
  console.log(`5. Set GCP_PROJECT_ID environment variable for production use`);
}

// CLI実行チェック
if (require.main === module) {
  main();
}

module.exports = {
  generateSecureApiKey,
  generateEnvConfig,
  generateFlutterEnvFile,
  generateTerraformVars
}; 