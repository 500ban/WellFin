# WellFin Flutter App 設定管理

## 🚀 **統合開発セットアップ（2025年6月29日最新）**

### **ワンクリック開発環境構築**

```batch
# 初回セットアップ（全依存関係インストール）
scripts\dev-setup.bat

# Flutter開発実行（推奨）
scripts\flutter-dev.bat

# セキュアAPKビルド（api-config.json自動読み込み）
scripts\flutter-build.bat

# システム全体ヘルスチェック
scripts\health-check.bat
```

### **🔐 自動APIキー管理システム**
- **api-config.json自動読み込み**: `config/development/api-config.json`から自動設定
- **Git保護**: 設定ファイルは自動的に.gitignore対象
- **環境変数設定**: `WELLFIN_API_KEY`, `WELLFIN_API_URL`の自動設定

## 📱 **APIキー設定方法**

### **自動設定（推奨）**

```batch
# APIキー生成・設定（初回のみ）
scripts\setup-api-keys.bat development

# 以降は自動読み込み
scripts\flutter-build.bat
```

### **設定確認方法**

```batch
# 設定ファイル確認
type config\development\api-config.json

# 出力例:
# {
#   "environment": "development",
#   "apiKey": "dev-xxx-xxx",
#   "apiUrl": "https://asia-northeast1-[PROJECT-ID].cloudfunctions.net/wellfin-ai-function",
#   "version": "1.0.0"
# }
```

### **手動設定（デバッグ用）**

```bash
# 環境変数直接指定
flutter run --dart-define=WELLFIN_API_KEY=your-api-key --dart-define=WELLFIN_API_URL=your-api-url

# デバッグビルド
flutter build apk --dart-define=WELLFIN_API_KEY=your-api-key --dart-define=WELLFIN_API_URL=your-api-url
```

## 🔐 **APIキー管理**

### **現在の有効設定**
- **開発環境**: `config/development/api-config.json` で自動管理
- **Git保護**: ✅ `.gitignore`設定済み
- **セキュリティ**: 機密情報はローカルのみ保存

### **環境別自動設定**

| 環境 | 設定ファイル | 生成コマンド | 管理方法 |
|------|-------------|-------------|----------|
| 開発 | `config/development/api-config.json` | `scripts\setup-api-keys.bat development` | ローカルファイル |
| ステージング | `config/staging/api-config.json` | `scripts\setup-api-keys.bat staging` | CI/CD環境変数 |
| 本番 | Secret Manager | `scripts\setup-api-keys.bat production` | Google Secret Manager |

## 🔧 **統合スクリプト一覧**

### **開発セットアップ**
- `scripts\dev-setup.bat` - 初回開発環境構築（全依存関係）
- `scripts\setup-api-keys.bat` - APIキー生成・管理

### **Flutter開発**
- `scripts\flutter-dev.bat` - 開発実行（api-config.json自動読み込み）
- `scripts\flutter-build.bat` - セキュアAPKビルド（推奨）

### **AI Agent API開発**
- `scripts\functions-dev.bat` - ローカルAPI起動（Node.js 22 LTS）
- AI Agent API URL: `https://asia-northeast1-[PROJECT-ID].cloudfunctions.net/wellfin-ai-function`

### **テスト・監視**
- `scripts\health-check.bat` - システム全体ヘルスチェック
- AI Agent機能: ✅ 100%実装完了
- Infrastructure as Code: ✅ Terraform 100%自動化

## ⚠️ **セキュリティ注意事項**

1. **自動Git保護**: `config/` ディレクトリは自動的に.gitignore済み
2. **APIキー自動管理**: api-config.json経由で安全に管理
3. **本番環境**: Google Secret Manager使用（Terraform管理）
4. **定期ローテーション**: 開発環境APIキーの定期更新推奨

## 🔍 **デバッグ方法**

### **AI Agent機能テスト**
```dart
// Flutter内でのAPIキー確認
final status = await AIAgentService.checkAuthStatus();
print('API Key Status: $status');

// AI Agentヘルスチェック
final health = await AIAgentService.healthCheck();
print('API Health: $health');

// Vertex AI接続テスト
final testResult = await AIAgentService.analyzeTask(userInput: 'テストタスク');
print('AI Analysis: $testResult');
```

### **設定ファイル確認**
```batch
# API設定確認
type config\development\api-config.json

# 環境変数確認（PowerShell）
echo $env:WELLFIN_API_KEY
echo $env:WELLFIN_API_URL
```

## 📋 **トラブルシューティング**

### **認証エラー（401）**
```batch
# 解決方法1: 新しいAPIキー生成
scripts\setup-api-keys.bat development

# 解決方法2: 設定ファイル確認
type config\development\api-config.json
```

### **API接続エラー（404/500）**
```batch
# Cloud Run Functions状態確認
scripts\health-check.bat

# 手動API確認
curl https://asia-northeast1-[PROJECT-ID].cloudfunctions.net/wellfin-ai-function/health
```

### **ビルドエラー**
```batch
# 完全な環境再構築
scripts\dev-setup.bat

# Flutter診断
cd wellfin
flutter doctor
flutter pub get
```

### **AI Agent機能エラー**
```batch
# Vertex AI接続確認
curl -X POST https://asia-northeast1-[PROJECT-ID].cloudfunctions.net/wellfin-ai-function/api/v1/vertex-ai-test

# API仕様確認
start functions\docs\openapi.yaml
```

## 🎯 **開発フロー**

### **初回セットアップ**
1. **環境構築**: `scripts\dev-setup.bat`
2. **APIキー設定**: `scripts\setup-api-keys.bat development`
3. **動作確認**: `scripts\health-check.bat`

### **日常開発**
1. **開発実行**: `scripts\flutter-dev.bat`（api-config.json自動読み込み）
2. **AI Agent機能テスト**: Flutter内でAPI呼び出し確認
3. **リリースビルド**: `scripts\flutter-build.bat`

### **デプロイ・運用**
1. **ローカルテスト**: `scripts\health-check.bat`
2. **APKビルド**: `scripts\flutter-build.bat`
3. **実機テスト**: Android実機でAI機能動作確認
4. **本番デプロイ**: 手動またはCI/CD

## 📚 **関連ドキュメント**

- **[APIキー管理ガイド](../doc/guide/api-key-management.md)**: セキュリティベストプラクティス
- **[開発トラブルシューティング](../doc/develop_trouble.md)**: 実機デプロイ404エラー等の解決法
- **[システムアーキテクチャ](../doc/servise/02_architecture.md)**: AI Agent・セキュリティ設計詳細
- **[Agent作業ログ](../doc/agent_log.md)**: AI Agent機能実装の詳細履歴

---

**最終更新**: 2025年6月29日 - AI Agent機能100%実装・api-config.json自動読み込み対応 