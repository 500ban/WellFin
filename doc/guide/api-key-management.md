# 🔐 WellFin APIキー管理ガイド

## 📋 概要

WellFinアプリケーションでは、FlutterアプリとCloud Run Functions間の認証にAPIキーを使用します。このガイドでは、開発から本番まで安全にAPIキーを管理する方法を説明します。

**⚠️ 重要**: このドキュメントは2025年6月29日に実装状況に合わせて更新されました。実際の実装とコード例を参照してください。

## 🏗️ アーキテクチャ

```
Flutter App → [環境変数 WELLFIN_API_URL] → Cloud Run Functions → Vertex AI
     ↓                                      ↓
api-config.json                      環境変数/Secret Manager
(Git管理外)                          (Terraform管理)
```

## 🔧 環境別管理方法

| 環境 | APIキー形式 | 管理方法 | セキュリティレベル |
|------|-------------|----------|-------------------|
| **開発** | `dev-xxx-xxx` | ローカルファイル | 低（開発専用） |
| **ステージング** | `stg-xxx-xxx` | CI/CD環境変数 | 中 |
| **本番** | `prod-xxx-xxx` | Secret Manager | 高 |

## 🚀 クイックスタート

### Step 1: APIキー生成

```bash
# 開発環境用
scripts/setup-api-keys.bat development

# ステージング環境用  
scripts/setup-api-keys.bat staging

# 本番環境用
scripts/setup-api-keys.bat production
```

### Step 2: Flutter開発

```bash
# 開発環境で実行
flutter run --dart-define-from-file=config/development/flutter.env

# ステージング環境でビルド
flutter build apk --release --dart-define-from-file=config/staging/flutter.env
```

### Step 3: インフラデプロイ

```bash
# 開発環境
cd terraform
terraform apply -var-file="../config/development/terraform.tfvars"

# 本番環境（Secret Manager使用）
terraform apply -var="environment=production" -var="project_id=your-prod-project"
```

## 📱 Flutter側の実装

### 現在の実装（2025年6月29日最新）
```dart
// lib/shared/services/ai_agent_service.dart
static String get _baseUrl => const String.fromEnvironment(
  'WELLFIN_API_URL', 
  defaultValue: 'http://localhost:8080'
);

static String get _apiKey => const String.fromEnvironment(
  'WELLFIN_API_KEY',
  defaultValue: 'your-api-key'
);

static Map<String, String> get _authHeaders => {
  'Content-Type': 'application/json',
  'X-API-Key': _apiKey,
  'X-App-Version': '1.0.0',
  'X-Platform': Platform.operatingSystem,
};
```

### 実行時設定（2025年6月29日最新）
```bash
# 現在の推奨方法：ビルドスクリプト使用
scripts\flutter-build.bat

# 手動設定の場合
flutter run --dart-define=WELLFIN_API_URL=https://asia-northeast1-[YOUR-GCP-PROJECT-ID].cloudfunctions.net/wellfin-ai-function --dart-define=WELLFIN_API_KEY=[YOUR-API-KEY]

# 設定ファイルから読み込み（api-config.json経由）
# config/development/api-config.json が自動読み込みされます
```

## 🔧 Node.js側の実装

### 環境変数取得
```javascript
// functions/src/index.js
const API_KEY = process.env.WELLFIN_API_KEY || 'dev-secret-key';

// APIキー認証ミドルウェア
function authenticateApiKey(req, res, next) {
  const providedKey = req.headers['x-api-key'];
  
  if (!providedKey || providedKey !== API_KEY) {
    return res.status(401).json({
      success: false,
      error: 'Invalid API key'
    });
  }
  
  next();
}
```

## 🏗️ Terraform設定

### 開発・ステージング環境
```hcl # variables.tf
variable "wellfin_api_key" {
  description = "WellFin API Key for authentication"
  type        = string
  default     = "dev-secret-key"
  sensitive   = true
}

# main.tf
resource "google_cloudfunctions2_function" "ai_function" {
  service_config {
    environment_variables = {
      WELLFIN_API_KEY = var.wellfin_api_key
      # ... other variables
    }
  }
}
```

### 本番環境（Secret Manager）
```hcl
# secret-manager.tf
resource "google_secret_manager_secret" "wellfin_api_key" {
  count     = var.environment == "production" ? 1 : 0
  secret_id = "wellfin-api-key"
  
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

# Cloud Run Functions設定
resource "google_cloudfunctions2_function" "ai_function_with_secrets" {
  count = var.environment == "production" ? 1 : 0
  
  service_config {
    secret_environment_variables {
      key        = "WELLFIN_API_KEY"
      project_id = var.project_id
      secret     = google_secret_manager_secret.wellfin_api_key[0].secret_id
      version    = "latest"
    }
  }
}
```

## 📁 ファイル構成（2025年6月29日現在）

```
├── scripts/                       # ✅ 実装済み
│   ├── generate-api-keys.js      # APIキー生成スクリプト
│   ├── flutter-build.bat         # Windows用ビルドスクリプト（推奨）
│   └── setup-api-keys.bat        # APIキー設定スクリプト
├── config/                       # ✅ 🚫 gitignore対象
│   └── development/
│       ├── api-config.json       # API設定（Git管理外）
│       └── terraform.tfvars      # Terraform変数（Git管理外）
├── terraform/                    # ✅ Infrastructure as Code
│   ├── main.tf                   # メイン設定（136行）
│   ├── variables.tf              # 変数定義
│   ├── outputs.tf                # 出力値定義
│   ├── providers.tf              # プロバイダー設定
│   └── secret-manager.tf         # Secret Manager設定
├── functions/                    # ✅ Cloud Run Functions
│   ├── src/index.js             # メインエントリーポイント（534行）
│   └── docs/openapi.yaml        # API仕様書
└── wellfin/lib/shared/services/  # ✅ Flutter実装
    └── ai_agent_service.dart     # AI Agent Service（366行）
```

## 🔒 セキュリティベストプラクティス

### ✅ やるべきこと

1. **環境分離**
   ```bash
   # 環境ごとに異なるAPIキー使用
   dev-1234-abcd...    # 開発環境
   stg-5678-efgh...    # ステージング環境
   prod-9012-ijkl...   # 本番環境
   ```

2. **設定ファイルの除外**
   ```gitignore
   # .gitignore
   config/*/api-config.json
   config/*/flutter.env
   config/*/terraform.tfvars
   *.api-key
   ```

3. **本番環境でのSecret Manager使用**
   ```bash
   # Secret Managerに手動でAPIキー設定
   gcloud secrets create wellfin-api-key --data-file=prod-api-key.txt
   ```

4. **定期的なローテーション**
   ```bash
   # 定期的にAPIキーを再生成
   scripts/setup-api-keys.bat production
   # 新しいキーをSecret Managerに手動更新
   ```

### ❌ やってはいけないこと

1. **APIキーのハードコード**
   ```dart
   // 絶対にやらない
   static const String _apiKey = 'prod-1234-abcd...';
   ```

2. **設定ファイルのコミット**
   ```bash
   # 絶対にコミットしない
   git add config/production/flutter.env  # ❌
   ```

3. **APIキーの平文保存**
   ```yaml
   # 絶対にやらない
   # pubspec.yaml
   flutter:
     api_key: "prod-1234-abcd..."  # ❌
   ```

## 🔧 トラブルシューティング

### 1. APIキー認証エラー
```bash
# エラー: 401 Unauthorized
# 原因: APIキーが設定されていない、または間違っている

# デバッグ方法
flutter run --dart-define=WELLFIN_API_KEY=your-api-key
```

### 2. 環境変数が読み込まれない
```dart
// デバッグ用コード
print('API Key: ${const String.fromEnvironment('WELLFIN_API_KEY', defaultValue: 'NOT_SET')}');
```

### 3. Secret Manager接続エラー
```bash
# Secret Managerの権限確認
gcloud secrets list --project=your-project-id

# サービスアカウント権限確認
gcloud projects get-iam-policy your-project-id
```

## 🚀 CI/CD設定例

### GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

env:
  WELLFIN_API_KEY: ${{ secrets.WELLFIN_API_KEY }}

jobs:
  deploy:
    steps:
      - name: Build Flutter
        run: |
          flutter build apk --release \
            --dart-define=WELLFIN_API_KEY=$WELLFIN_API_KEY
      
      - name: Deploy Infrastructure
        run: |
          cd terraform
          terraform apply -auto-approve \
            -var="environment=production" \
            -var="project_id=$PROJECT_ID"
```

## 📋 チェックリスト

### 開発開始時
- [ ] APIキー生成スクリプト実行
- [ ] 設定ファイルが.gitignoreされていることを確認
- [ ] Flutter実行時にAPIキーが正しく設定されることを確認

### ステージング環境デプロイ時
- [ ] ステージング用APIキー生成
- [ ] CI/CD環境変数設定
- [ ] Terraform変数ファイル作成

### 本番環境デプロイ時
- [ ] 本番用APIキー生成
- [ ] Secret Managerでの管理設定
- [ ] サービスアカウント権限設定
- [ ] APIキーローテーション計画策定

## 📞 サポート

問題が発生した場合は、以下の情報を含めて報告してください：

1. 環境（development/staging/production）
2. エラーメッセージ
3. 使用したコマンド
4. 設定ファイルの内容（APIキーは除く）

## 📚 関連ドキュメント

- [デプロイガイド](deploy.md) - 実際のデプロイ手順
- [開発トラブルシューティング](develop_trouble.md) - APIエラー対処法
- [システムアーキテクチャ](servise/02_architecture.md) - セキュリティ設計詳細
- [Terraform README](../terraform/README.md) - Infrastructure as Code詳細
- [OpenAPI仕様書](../functions/docs/openapi.yaml) - API仕様詳細

---

*最終更新: 2025年6月29日 - 実装状況に合わせて更新* 