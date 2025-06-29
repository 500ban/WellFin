# WellFin - AI Agent Flutterアプリ

## 📋 プロジェクト概要
**WellFin**は、Flutter × Firebase × Google Cloud AI技術を活用した生産性向上アプリです。  
AIエージェント機能、タスク管理、習慣管理、目標管理などの機能を提供します。

### ✅ 実装完了機能（2025年6月29日現在）
- **🤖 AI Agent機能**: Cloud Run Functions API統合
- **✅ タスク管理機能**: 完全なUI/UX実装
- **🔄 習慣管理機能**: 完全なUI/UX実装
- **🎯 目標管理機能**: 完全なUI/UX実装
- **📊 ダッシュボード機能**: 完全なUI/UX実装
- **🏗️ Infrastructure as Code**: Terraform 100%自動化達成

## 🛠️ 環境情報
- **Flutter**: 最新版
- **Dart**: 最新版
- **OS**: Windows 11
- **Android Studio**: 2024.3.2
- **Java**: 17
- **IDE**: VS Code / Cursor
- **Git**: 最新版
- **Terraform**: 1.12.0
- **Google Cloud SDK**: 528.0.0

## 🚀 セットアップ手順

### 1. 環境準備
1. Windows 11 に Android Studio をインストール
  - https://developer.android.com/studio/install?hl=ja
2. Windows 11 に Flutter をインストール
  - https://docs.flutter.dev/get-started/install/windows
3. Windows 11 に Terraform をインストール
  - https://developer.hashicorp.com/terraform/install
4. Windows 11 に Google Cloud SDK をインストール
  - https://cloud.google.com/sdk/docs/install?hl=ja
5. このリポジトリをクローン

### 2. プロジェクトセットアップ
```bash
# プロジェクトディレクトリに移動
cd flutter-app/wellfin

# 依存関係のインストール
flutter pub get
```

### 3. 統合開発環境セットアップ（推奨）
```batch
# ワンクリック開発環境構築
scripts\dev-setup.bat

# Flutter開発実行
scripts\flutter-dev.bat

# APKビルド
scripts\flutter-build.bat

# システムヘルスチェック
scripts\health-check.bat
```

### 4. 手動実行（上級者向け）
```bash
# 手動APIキー生成
scripts\setup-api-keys.bat development

# 手動Flutter実行
flutter run --dart-define=WELLFIN_API_KEY=your-api-key

# 手動リリースビルド
flutter build apk --dart-define=WELLFIN_API_KEY=your-api-key
```

## 🔐 セキュリティ設定

- **APIキー認証**: Flutter ↔ Cloud Run Functions間の認証
- **Firebase認証**: ユーザーログイン管理  
- **Google Cloud IAM**: インフラ権限管理
- **Secret Manager**: 本番環境でのAPIキー管理

### 環境別APIキー管理
| 環境 | APIキー形式 | 管理方法 |
|------|-------------|----------|
| 開発 | `dev-xxx-xxx` | ローカル設定ファイル |
| ステージング | `stg-xxx-xxx` | CI/CD環境変数 |
| 本番 | `prod-xxx-xxx` | Google Secret Manager |

詳細: [📖 APIキー管理ガイド](doc/guide/api-key-management.md)

## 🏗️ 技術スタック
- **フロントエンド**: Flutter (Dart) + Riverpod
- **バックエンド**: Cloud Run Functions (Node.js 22 LTS) + Firebase
- **AI**: Vertex AI Gemini Pro + Google Cloud AI Services
- **データベース**: Firestore + Firebase Auth
- **状態管理**: Riverpod + クリーンアーキテクチャ
- **インフラ**: Google Cloud Platform + Terraform (100%IaC)

## 📋 インフラ管理

### ✅ Terraform完全統合達成（2025-06-29）
- **管理リソース**: すべてのGCPリソース（APIs, IAM, Cloud Run Functions）
- **設定ディレクトリ**: `terraform/`
- **実行方法**: `terraform apply -var="project_id=YOUR_PROJECT_ID"`
- **統合状況**: 🎉 **100%Infrastructure as Code化完了**

### 統合完了記録
- **統合記録**: [`doc/release_notes.md#v030`](doc/release_notes.md#v030) - v0.3.0統合詳細
- **Terraform確認**: [`terraform/README.md`](terraform/README.md) - 管理・確認方法
- **API確認**: [`functions/README.md`](functions/README.md) - 動作確認方法

```bash
# 現在の状態確認
cd terraform && terraform plan

# リソース状況確認（統合済み）
terraform show
```

## 📚 ドキュメント構成

### 🔧 開発・運用ドキュメント
- **[サービス仕様書](doc/servise/)**: 完全な5部構成（機能概要・アーキテクチャ・運用・実装・ガイドライン）
- **[リリースノート](doc/release_notes.md)**: v0.3.0 Infrastructure as Code完全統合 & セキュリティ強化
- **[デプロイガイド](doc/deploy.md)**: 実際のスクリプトベース手順
- **[開発トラブルシューティング](doc/develop_trouble.md)**: 実機デプロイ404エラー解決など

### 🔐 開発・セキュリティガイド
- **[APIキー管理ガイド](doc/guide/api-key-management.md)**: 環境別管理・セキュリティベストプラクティス

### 🤖 作業履歴
- **[Agent作業ログ](doc/agent_log.md)**: AI Agentによる実装作業の詳細履歴

### 📋 詳細設定
- **[Flutter設定管理](wellfin/config/README.md)**: 開発環境セットアップ・設定管理の詳細

## 🌐 外部リソース
- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [Firebase公式ドキュメント](https://firebase.google.com/docs)
- [Google Cloud AI ドキュメント](https://cloud.google.com/ai)

---

**最終更新**: 2025年6月29日 - AI Agent機能・Infrastructure as Code完全実装達成
