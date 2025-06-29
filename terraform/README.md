# WellFin AI Agent - Terraform Infrastructure

## 📋 概要

このディレクトリには、WellFin AI分析エージェントのGoogle Cloud Platform (GCP) インフラストラクチャを管理するTerraform設定が含まれています。

**⚠️ 現在は開発段階のため、必要最小限のリソースのみ構築します。**

## 🏗️ 作成されるリソース

### ✅ 構築対象リソース（開発環境のみ）
- **Google Cloud APIs** (必要最小限)
  - Cloud Functions API
  - Vertex AI API
  - Cloud Build API
  - Cloud Storage API

- **Cloud Run Functions**
  - `wellfin-ai-function` - 開発環境のみ
  - Node.js 22ランタイム
  - HTTPトリガー

- **サービスアカウント**
  - `wellfin-ai-function@{PROJECT_ID}.iam.gserviceaccount.com`

- **IAM権限**
  - Vertex AI User
  - Logging Log Writer

- **Cloud Storage**
  - Functions用ソースコードバケット（自動生成）

### ❌ 構築しないリソース（開発段階では不要）
- ~~本番環境~~
- ~~Secret Manager~~ （APIキーは環境変数で管理）
- ~~Artifact Registry~~ （Cloud Run Functionsは不要）
- ~~Firestore~~ （データ管理はFlutter側で実施）
- ~~Natural Language API~~ （現在未使用）
- ~~Monitoring API~~ （開発段階では不要）

## 🚀 デプロイ手順

### 前提条件
- Google Cloud SDK がインストール済み
- 適切なGCPプロジェクトが選択済み
- 必要な権限が付与済み

### 1. 初期設定

```bash
# GCPの認証情報を取得
gcloud auth application-default login

# プロジェクトIDを設定
# Windows PowerShellの場合
$env:PROJECT_ID="your-project-id"
```

### 2. Terraform初期化

```bash
# Terraformの初期化
terraform init

# 現在の状態を確認
# Windows PowerShellの場合
terraform plan -var="project_id=$env:PROJECT_ID"
```

### 3. インフラストラクチャのデプロイ

```bash
# インフラストラクチャの作成
# Windows PowerShellの場合
terraform apply -var="project_id=$env:PROJECT_ID"

# Linux/macOSの場合
terraform apply -var="project_id=$PROJECT_ID"
```

### 4. Cloud Run Functionsのソースアップロード

```bash
# functionsディレクトリに移動
cd ../functions

# 依存関係のインストール
npm install

# ソースコードをCloud Storageにアップロード（Terraformが自動実行）
# 手動でアップロードする場合：
# Windows PowerShellの場合
gcloud functions deploy wellfin-ai-function --gen2 --runtime nodejs24 --trigger-http --source . --project $env:PROJECT_ID --region asia-northeast1
```

## 🌐 アクセスURL

### 開発環境
- **URL**: `https://asia-northeast1-{PROJECT_ID}.cloudfunctions.net/wellfin-ai-function`
- **認証**: APIキー認証（X-API-Key ヘッダー）

### 認証方式
```bash
# APIテスト例
curl -X POST https://asia-northeast1-{PROJECT_ID}.cloudfunctions.net/wellfin-ai-function/api/v1/recommendations \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-secret-key" \
  -d '{"userProfile": {"goals": ["生産性向上"]}, "context": {"currentTasks": ["日常業務"]}}'
```

## 🔐 認証設定

### APIキー認証
- すべてのAPIエンドポイント（`/health`を除く）でAPIキー認証が必要
- Flutterアプリからは`X-API-Key: {API_KEY}`ヘッダーで送信
- デフォルトAPIキー: `dev-secret-key`（開発環境のみ）

### サービスアカウント認証
- Cloud Run Functionsは`wellfin-ai-function`サービスアカウントを使用
- Vertex AIへのアクセス権限を保有
- Firestoreアクセス権限は削除済み（データ管理はFlutter側）

## 🤖 Vertex AI 接続

### 自動認証設定
Cloud Run Functions から Vertex AI への接続は以下のように自動化されています：

1. **サービスアカウント**: `wellfin-ai-function@{PROJECT_ID}.iam.gserviceaccount.com`
2. **IAM権限**: `roles/aiplatform.user`
3. **環境変数**: 
   - `GOOGLE_CLOUD_PROJECT`: プロジェクトID
   - `VERTEX_AI_LOCATION`: リージョン（asia-northeast1）

### 接続テスト
```bash
# Vertex AI接続テスト
curl https://asia-northeast1-{PROJECT_ID}.cloudfunctions.net/wellfin-ai-function/test-ai

# 期待される成功レスポンス
{
  "success": true,
  "project": "your-project-id", 
  "location": "asia-northeast1",
  "model": "gemini-1.5-flash",
  "result": {
    "status": "success",
    "message": "Vertex AI connection is working"
  }
}
```

### 使用するAIモデル
- **Vertex AI Gemini 1.5 Flash**: タスク分析、スケジュール最適化、推奨事項生成
- **Natural Language API**: 感情分析（必要に応じて）

## 📊 出力値

```bash
# 出力値を確認
terraform output

# 主要な出力値
function_url = "https://asia-northeast1-{PROJECT_ID}.cloudfunctions.net/wellfin-ai-function"
service_account_email = "wellfin-ai-function@{PROJECT_ID}.iam.gserviceaccount.com"
```

## 🔧 管理コマンド

### 状態確認
```bash
# 現在の状態を確認
terraform plan -var="project_id=$env:PROJECT_ID"

# 出力値を確認
terraform output

# 管理リソース一覧確認
terraform show
```

### 統合完了確認
```bash
# すべてのリソースがTerraform管理下か確認
terraform plan
# 期待出力: "No changes. Your infrastructure matches the configuration."

# API正常動作確認
curl -X GET https://asia-northeast1-{PROJECT_ID}.cloudfunctions.net/wellfin-ai-function/api/v1/vertex-ai-test \
  -H "X-API-Key: {API_KEY}"
# 期待出力: {"status":"SUCCESS",...}
```

### 更新
```bash
# 設定変更の適用
terraform apply -var="project_id=$env:PROJECT_ID"
```

### 削除
```bash
# すべてのリソースを削除
terraform destroy -var="project_id=$env:PROJECT_ID"
```

## 📝 設定ファイル

- `main.tf` - メインリソース定義（Cloud Run Functions）
- `variables.tf` - 変数定義
- `outputs.tf` - 出力値定義
- `providers.tf` - プロバイダー設定

## 🔍 トラブルシューティング

### よくある問題

1. **API有効化エラー**
   ```bash
   # APIが有効化されていない場合
   gcloud services enable cloudfunctions.googleapis.com
   gcloud services enable aiplatform.googleapis.com
   gcloud services enable cloudbuild.googleapis.com
   ```

2. **権限エラー**
   ```bash
   # 必要な権限を確認
   gcloud projects get-iam-policy $env:PROJECT_ID
   ```

3. **ソースコードアップロードエラー**
   ```bash
   # functions ディレクトリに移動してから実行
   cd ../functions
       gcloud functions deploy wellfin-ai-function --gen2 --runtime nodejs24 --trigger-http --source .
   ```

## 📚 参考資料

- [Cloud Run Functions Terraform チュートリアル](https://cloud.google.com/functions/docs/tutorials/terraform?hl=ja)
- [Terraform Google Provider - Cloud Functions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function)

## 🚧 開発ロードマップ

### 完了済み
- ✅ Firestore依存関係の削除
- ✅ APIキー認証方式への変更
- ✅ 軽量化されたAPI設計

### 今後の予定
- 🔄 Cloud Run Functions デプロイ
- 📈 本格運用時の本番環境構築
- 🔒 本番用APIキー管理の実装

