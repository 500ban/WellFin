# WellFin デプロイガイド

## 📋 ファイルの役割
このファイルは、WellFinアプリケーションのデプロイ手順とリリースプロセスを記載する実用的なデプロイガイドです。
開発環境から本番環境への安全なデプロイ設定を管理します。

## 🛠️ 開発・テスト用スクリプト

### スクリプトファイル一覧（scripts/）

#### dev-setup.bat
**統合開発環境セットアップ**
- Flutter、Node.js、Google Cloud SDKの環境確認
- APIキー設定の自動生成（config/development/api-config.json）
- Flutter依存関係のインストール（pub get）
- Functions依存関係のインストール（npm install）

```batch
scripts\dev-setup.bat
```

#### flutter-dev.bat
**開発時のFlutter実行**
- APIキー設定を自動読み込み（config/development/api-config.json）
- 環境変数でAPIキーとURLを設定
- 開発モードでFlutterアプリを起動

```batch
scripts\flutter-dev.bat
```

#### flutter-build.bat
**リリース用APKビルド**
- APIキー設定を自動読み込み（config/development/api-config.json）
- セキュアな環境変数設定
- リリース用APKの自動ビルド
- ビルド成果物: `wellfin\build\app\outputs\flutter-apk\app-release.apk`

```batch
scripts\flutter-build.bat
```

#### functions-dev.bat
**ローカルAPI開発サーバー**
- Cloud Run Functionsのローカル実行
- 開発時のAPI動作確認用

```batch
scripts\functions-dev.bat
```

#### health-check.bat
**システムヘルスチェック**
- API動作確認（/health、/api/v1/vertex-ai-test）
- Vertex AI認証テスト
- タスク分析API動作確認
- Flutter依存関係チェック
- Functions依存関係確認

```batch
scripts\health-check.bat
```

#### setup-api-keys.bat
**APIキー個別セットアップ**
- 特定環境のAPIキー設定
- config/development/api-config.jsonの生成

```batch
scripts\setup-api-keys.bat development
```

#### generate-api-keys.js
**APIキー生成スクリプト**
- Google Cloud APIキーの自動生成
- セキュリティ設定の自動適用

```bash
node scripts\generate-api-keys.js
```

### 設定ファイル構成

#### config/development/api-config.json
```json
{
  "apiKey": "[YOUR-API-KEY]...", 
  "apiUrl": "https://asia-northeast1-[YOUR-GCP-PROJECT-ID].cloudfunctions.net/wellfin-ai-function",
  "version": "0.3.0",
  "environment": "development"
}
```

**セキュリティ重要事項:**
- このファイルはGit管理対象外（.gitignore設定済み）
- 機密情報を含むため外部共有厳禁
- スクリプトにより自動生成・管理

## 🚀 デプロイ手順

### 1. 初期環境セットアップ

#### 1.1 開発環境準備
```batch
REM 統合セットアップ実行（初回のみ）
scripts\dev-setup.bat
```

このスクリプトで以下が自動実行されます：
- 必要ツールの環境確認（Node.js、Flutter、gcloud CLI）
- APIキー設定の自動生成
- Flutter依存関係のインストール
- Functions依存関係のインストール

#### 1.2 動作確認
```batch
REM システム動作確認
scripts\health-check.bat
```

### 2. 開発・テスト

#### 2.1 ローカル開発
```batch
REM Flutter開発実行
scripts\flutter-dev.bat

REM 別ターミナルでAPI開発サーバー起動
scripts\functions-dev.bat
```

#### 2.2 動作テスト
```batch
REM ヘルスチェック実行
scripts\health-check.bat
```

### 3. リリースビルド

#### 3.1 APKビルド
```batch
REM リリース用APK作成
scripts\flutter-build.bat
```

ビルド成果物：
- **APKファイル**: `wellfin\build\app\outputs\flutter-apk\app-release.apk`
- **自動バージョン設定**: config/development/api-config.jsonのversionを使用
- **セキュア設定**: APIキーは環境変数で安全に設定

### 3.1.1 Firebase App Distributionへのデプロイ

```batch
firebase appdistribution:distribute "wellfin/build/app/outputs/flutter-apk/app-release.apk"  --app "1:933043164976:android:97bcddf0bc4d976dd65af5"  --groups "testers"  --release-notes-file "doc/release_notes.md"
```

#### 3.2 Firebase App Distribution以外のデプロイ

**Android実機インストール:**
```batch
REM APKを実機に直接インストール
adb install wellfin\build\app\outputs\flutter-apk\app-release.apk
```

**社内配布:**
- APKファイルを直接配布
- セキュアなファイル共有サービス利用推奨

### 4. Infrastructure as Code（Terraform）

#### 4.1 インフラデプロイ
```bash
# Terraformでインフラ構築
cd terraform
terraform init
terraform plan
terraform apply
```

#### 4.2 Cloud Functions デプロイ
```bash
# Functions手動デプロイ
cd functions
gcloud functions deploy wellfin-ai-function \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --region asia-northeast1
```

## 🔐 セキュリティ考慮事項

### APIキー管理
- **自動生成**: generate-api-keys.js による安全な生成
- **Git管理除外**: config/development/api-config.json は.gitignore設定
- **環境変数化**: スクリプトで自動的に環境変数設定
- **制限設定**: APIキーにIP制限・リファラ制限を自動適用

### 実機デプロイ時の重要事項
1. **環境変数の確実な設定**: flutter-build.batで自動設定
2. **APIエンドポイントの正確性**: config/development/api-config.jsonで管理
3. **認証情報の暗号化**: Google Cloud秘密管理機能活用

## 🧪 トラブルシューティング

### よくある問題と解決方法

#### 1. API 404エラー
```batch
REM 設定確認とヘルスチェック
scripts\health-check.bat
```

#### 2. 依存関係エラー
```batch
REM 開発環境再セットアップ
scripts\dev-setup.bat
```

#### 3. ビルドエラー
```batch
REM Flutterクリーンビルド
cd wellfin
flutter clean
flutter pub get
cd ..
scripts\flutter-build.bat
```

## 📚 参考資料

### スクリプト実行順序（推奨）
1. **初回セットアップ**: `scripts\dev-setup.bat`
2. **動作確認**: `scripts\health-check.bat`
3. **開発作業**: `scripts\flutter-dev.bat` + `scripts\functions-dev.bat`
4. **リリース準備**: `scripts\flutter-build.bat`
5. **定期チェック**: `scripts\health-check.bat`

### 環境変数
- `WELLFIN_API_KEY`: Google Cloud APIキー
- `WELLFIN_API_URL`: Cloud Functions エンドポイントURL

### 重要ファイル
- `config/development/api-config.json`: APIキー設定（Git管理対象外）
- `functions/src/index.js`: Cloud Functions メインコード
- `terraform/`: Infrastructure as Code 設定 