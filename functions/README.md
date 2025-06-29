# WellFin AI Agent API - 開発環境

## 📋 概要

WellFin AI分析エージェントのAPIサーバーです。ローカル開発環境とCloud Run本番環境の両方で動作します。

## 🚀 ローカル開発環境のセットアップ

### 前提条件
- Node.js 18以上
- npm または yarn
- Google Cloud SDK（本番環境用）

### 1. 依存関係のインストール

```bash
npm install
```

### 2. 開発サーバーの起動

#### Windows PowerShell
```bash
.\start-dev.bat
```

#### Linux/macOS
```bash
chmod +x start-dev.sh
./start-dev.sh
```

#### 手動起動
```bash
# 環境変数を設定
set ENVIRONMENT=development
set PORT=3000

# サーバー起動
npm run dev
```

### 3. 動作確認

```bash
# ヘルスチェック
curl http://localhost:3000/health

# API情報取得
curl http://localhost:3000/
```

## 🔐 認証設定

### 開発環境
- **認証方式**: 簡易認証（dev-token）
- **ヘッダー**: `dev-token: dev-secret-key`
- **認証不要**: `/health`, `/`エンドポイント

### 本番環境
- **認証方式**: Firebase Auth IDトークン
- **ヘッダー**: `Authorization: Bearer <id_token>`
- **認証必須**: すべてのAPIエンドポイント（`/health`を除く）

## 📡 APIエンドポイント

### 開発環境
- **ベースURL**: `http://localhost:3000`
- **ヘルスチェック**: `GET /health`
- **API情報**: `GET /`

### 本番環境（Terraform管理）
- **ベースURL**: `<環境変数WELLFIN_API_URLで設定>`
- **ヘルスチェック**: `GET /health`
- **API情報**: `GET /`
- **認証テスト**: `GET /api/v1/vertex-ai-test`

### 主要API
- **タスク分析**: `POST /api/v1/analyze-task`
- **スケジュール最適化**: `POST /api/v1/optimize-schedule`
- **推奨事項生成**: `POST /api/v1/recommendations`

## 🧪 テスト

### APIテスト例

#### タスク分析
```bash
curl -X POST http://localhost:3000/api/v1/analyze-task \
  -H "Content-Type: application/json" \
  -H "dev-token: dev-secret-key" \
  -d '{
    "task": {
      "title": "プロジェクト計画書作成",
      "description": "新規プロジェクトの計画書を作成する必要があります。",
      "priority": "high",
      "deadline": "2025-07-15",
      "estimatedHours": 8
    }
  }'
```

#### スケジュール最適化
```bash
curl -X POST http://localhost:3000/api/v1/optimize-schedule \
  -H "Content-Type: application/json" \
  -H "dev-token: dev-secret-key" \
  -d '{
    "tasks": [
      {
        "title": "プロジェクト計画書作成",
        "priority": "high",
        "estimatedHours": 8,
        "deadline": "2025-07-15"
      }
    ],
    "preferences": {
      "workHours": {
        "start": "09:00",
        "end": "18:00"
      },
      "breakTime": 60,
      "focusBlocks": 4
    }
  }'
```

## 🔧 設定

### 環境変数
- `ENVIRONMENT`: 実行環境（development/production）
- `PORT`: サーバーポート（デフォルト: 8080）
- `VERTEX_AI_KEY`: Vertex AI APIキー（本番環境用）

### 開発用設定
- 認証簡略化
- ローカルポート3000
- 詳細ログ出力

## 📚 関連ドキュメント

- [OpenAPI仕様書](docs/openapi.yaml)
- [Terraform設定](../terraform/README.md)
- [実装計画書](../../doc/ai_agent_implementation_plan.md)

## 🚀 デプロイ

### Cloud Runへのデプロイ

```bash
# Dockerイメージのビルド
gcloud builds submit --tag gcr.io/{PROJECT_ID}/wellfin-ai-api:latest .

# Terraformでのデプロイ
cd ../terraform
terraform apply -var="project_id={PROJECT_ID}"
```

### 本番環境の確認（Terraform統合後）

```bash
# 環境変数設定（事前実行が必要）
export WELLFIN_API_URL="<your-api-url>"
export WELLFIN_API_KEY="<your-api-key>"

# ヘルスチェック
curl $WELLFIN_API_URL/health

# API情報
curl $WELLFIN_API_URL/

# Vertex AI認証テスト（要APIキー）
curl -X GET $WELLFIN_API_URL/api/v1/vertex-ai-test \
  -H "X-API-Key: $WELLFIN_API_KEY"

# 期待レスポンス
# {"timestamp":"...","status":"SUCCESS","vertexAITest":{"success":true,...}}
```

### 統合完了確認

```bash
# すべてのAPIエンドポイントが正常動作するかテスト
# 環境変数を設定してから実行
export WELLFIN_API_URL="<your-api-url>"
export WELLFIN_API_KEY="<your-api-key>"

# 1. ヘルスチェック（認証不要）
curl $WELLFIN_API_URL/health

# 2. Vertex AI認証テスト（APIキー必要）
curl -X GET $WELLFIN_API_URL/api/v1/vertex-ai-test \
  -H "X-API-Key: $WELLFIN_API_KEY"

# 3. タスク分析テスト
curl -X POST $WELLFIN_API_URL/api/v1/analyze-task \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $WELLFIN_API_KEY" \
  -d '{"userInput": "明日の会議資料を準備する"}'
``` 