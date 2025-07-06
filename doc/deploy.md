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
**リリース用APKビルド & デプロイ統合**
- APIキー設定を自動読み込み（config/development/api-config.json）
- セキュアな環境変数設定
- リリース用APKの自動ビルド
- Firebase App Distributionへの自動デプロイ
- ビルド成果物: `wellfin\build\app\outputs\flutter-apk\app-release.apk`

```batch
REM 完全自動（ビルド＋デプロイ）
scripts\flutter-build.bat

REM ビルドのみ（デプロイなし）
scripts\flutter-build.bat --no-deploy
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

### 3. リリースビルド & デプロイ

#### 3.1 統合デプロイ（推奨）
```batch
REM 自動ビルド＋Firebase App Distributionデプロイ
scripts\flutter-build.bat
```

**実行内容:**
1. APIキー設定の自動読み込み
2. Firebase CLI の確認
3. Flutter APK のリリースビルド
4. Firebase App Distribution への自動アップロード
5. テスターグループへの通知送信

#### 3.2 ビルドのみ（デプロイなし）
```batch
REM APKビルドのみ実行
scripts\flutter-build.bat --no-deploy
```

ビルド成果物：
- **APKファイル**: `wellfin\build\app\outputs\flutter-apk\app-release.apk`
- **自動バージョン設定**: config/development/api-config.jsonのversionを使用
- **セキュア設定**: APIキーは環境変数で安全に設定

#### 3.3 手動Firebase App Distributionデプロイ

**事前準備:**
```batch
REM Firebase CLI インストール（初回のみ）
npm install -g firebase-tools

REM Firebase ログイン（初回のみ）
firebase login
```

**手動デプロイコマンド:**
```batch
firebase appdistribution:distribute "wellfin/build/app/outputs/flutter-apk/app-release.apk"  --app "1:933043164976:android:97bcddf0bc4d976dd65af5"  --groups "testers"  --release-notes-file "doc/release_notes.md"
```

#### 3.4 その他のデプロイ方法

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

#### 4. Firebase App Distribution デプロイエラー
```batch
REM Firebase CLI確認とログイン
firebase --version
firebase login

REM 手動デプロイテスト
firebase appdistribution:distribute "wellfin/build/app/outputs/flutter-apk/app-release.apk" --app "1:933043164976:android:97bcddf0bc4d976dd65af5" --groups "testers" --release-notes-file "doc/release_notes.md"
```

**よくあるデプロイエラー:**
- **Firebase CLI未インストール**: `npm install -g firebase-tools`
- **未ログイン**: `firebase login` で認証
- **アプリID不正**: Firebase Console でアプリIDを確認
- **テスターグループ不存在**: Firebase Console で「testers」グループを作成
- **権限不足**: Firebase プロジェクトへのアクセス権限を確認

## 📚 参考資料

### スクリプト実行順序（推奨）
1. **初回セットアップ**: `scripts\dev-setup.bat`
2. **動作確認**: `scripts\health-check.bat`
3. **Firebase CLI準備**: `npm install -g firebase-tools` && `firebase login`
4. **開発作業**: `scripts\flutter-dev.bat` + `scripts\functions-dev.bat`
5. **リリースデプロイ**: `scripts\flutter-build.bat` （ビルド + App Distribution）
6. **定期チェック**: `scripts\health-check.bat`

### リリース時のワークフロー
1. **開発完了**: 機能実装・テスト完了
2. **バージョン更新**: `config\development\api-config.json` のversion更新
3. **リリースノート更新**: `doc\release_notes.md` の内容更新
4. **統合デプロイ実行**: `scripts\flutter-build.bat`
5. **テスター通知確認**: Firebase Console で配布状況確認

### 環境変数
- `WELLFIN_API_KEY`: Google Cloud APIキー
- `WELLFIN_API_URL`: Cloud Functions エンドポイントURL

### 重要ファイル
- `config/development/api-config.json`: APIキー設定（Git管理対象外）
- `functions/src/index.js`: Cloud Functions メインコード
- `terraform/`: Infrastructure as Code 設定 