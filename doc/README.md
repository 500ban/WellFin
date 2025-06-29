# WellFin ドキュメント構成ガイド

## 📋 概要
このファイルは、WellFinアプリケーションのdocフォルダ内の全ドキュメント構成をAgentが効率的に参照・更新できるように整理したガイドです。

## 📚 ドキュメント構成

### 🔧 開発・運用ドキュメント

#### [サービス仕様書](./servise/) ディレクトリ内に5部構成で分割
**概要**: WellFinアプリケーションの包括的なサービス仕様書
**内容**: 
- システム概要・要件定義
- 機能要件・実装状況一覧
- 詳細実装仕様
- 非機能要件
- 技術スタック
- データベース設計
- システムアーキテクチャ
- 運用・セキュリティ・ベストプラクティス
- ユースケース・実装計画
- 開発ガイドライン・参考資料

**実際の配置場所**: 
- [第1部：サービス概要・要件定義](./servise/01_overview.md)
- [第2部：システム設計・アーキテクチャ](./servise/02_architecture.md)
- [第3部：運用・セキュリティ・ベストプラクティス](./servise/03_operations.md)
- [第4部：ユースケース・実装計画](./servise/04_implementation.md)
- [第5部：開発ガイドライン・参考資料](./servise/05_guideline.md)

#### [API仕様書（OpenAPI 3.0）](../functions/docs/openapi.yaml)
**概要**: Cloud Run Functions AI Agent APIの完全な技術仕様書
**内容**:
- 5つのAPIエンドポイント詳細仕様
- リクエスト・レスポンススキーマ定義
- 認証方式（APIキー認証）
- エラーハンドリング仕様
- 使用例・サンプルコード
- Vertex AI Gemini Pro統合仕様

**実装状況**: ✅ 100%実装完了（Node.js 22 LTS + Express）
**テスト環境**: `https://asia-northeast1-[PROJECT-ID].cloudfunctions.net/wellfin-ai-function`

#### [リリースノート](./release_notes.md)
**概要**: 各バージョンのリリース情報と変更履歴
**内容**:
- バージョン履歴
- 新機能・改善点・バグ修正
- UI/UX改善
- 技術的変更
- 対応プラットフォーム
- 既知の問題
- 次のリリース予定
- パフォーマンス・セキュリティ情報

### 🔐 開発・セキュリティガイド

#### [guide](./guide/) ディレクトリ内の開発ガイド集
**概要**: 開発者向けの詳細ガイドとベストプラクティス集
**配置場所**:

##### [APIキー管理ガイド](./guide/api-key-management.md)
**概要**: セキュリティベストプラクティスとAPIキー管理の完全ガイド
**内容**:
- 環境別APIキー管理（development/staging/production）
- Flutter・Node.js・Terraformの実装例
- セキュリティベストプラクティス
- CI/CD設定例（GitHub Actions等）
- トラブルシューティング
- チェックリスト

### 🚀 運用・デプロイドキュメント

#### [デプロイガイド](./deploy.md)
**概要**: アプリケーションのデプロイ手順と設定
**内容**:
- デプロイ環境設定
- ビルド手順
- リリース手順
- 環境別設定

#### [開発トラブルシューティング](./develop_trouble.md)
**概要**: 開発時の問題解決ガイド
**内容**:
- よくある問題と解決方法
- エラー対処法
- デバッグ手順

### 🤖 Agent作業ログ

#### [Agent作業ログ](./agent_log.md)
**概要**: AI Agentによる作業履歴と成果物
**内容**:
- 作業日時・内容
- 実装した機能
- 解決した問題
- 技術的決定事項

## 🔄 更新ルール

### 📝 ドキュメント更新時の注意事項

1. **サービス仕様書の更新**
   - `servise/`内のファイルを更新する場合は、対応する`servise/`内のファイルも同時に更新
   - 実装状況の変更は即座に反映
   - 技術仕様の変更は詳細に記録

2. **リリースノートの更新**
   - 新機能実装時は必ず更新
   - バグ修正時は詳細を記録
   - バージョン番号は適切に管理

3. **作業ログの記録**
   - Agentによる作業は必ず記録
   - 実装した機能の詳細を記載
   - 技術的決定の理由を記録

### 🎯 Agent参照優先順位

1. **新機能実装時**
   - `servise/README.md` → 各種ドキュメントの内容把握
   - `servise/01_overview.md` → 実装状況確認
   - `servise/02_architecture.md` → アーキテクチャ・データベース設計確認
   - `../functions/docs/openapi.yaml` → API仕様詳細確認
   - `servise/03_operations.md` → ユースケース確認
   - `servise/04_implementation.md` → 実装計画確認
   - `servise/05_guideline.md` → 開発ガイドライン確認
   - `architecture-diagram.md` → システムアーキテクチャ図確認

2. **バグ修正時**
   - `develop_trouble.md` → 既知の問題確認
   - `release_notes.md` → 既知の問題確認

3. **API開発・AI Agent機能作業時**
   - `../functions/docs/openapi.yaml` → API仕様詳細確認
   - `guide/api-key-management.md` → APIキー管理・認証方式確認
   - `servise/02_architecture.md` → AI Agent・セキュリティアーキテクチャ確認
   - `architecture-diagram.md` → システムアーキテクチャ図確認

4. **セキュリティ・APIキー関連作業時**
   - `guide/api-key-management.md` → APIキー管理・セキュリティベストプラクティス確認
   - `servise/02_architecture.md` → セキュリティアーキテクチャ確認

5. **ドキュメント更新時**
   - `servise/README.md` → 全体構成確認
   - 対応する`servise/`内ファイル → 詳細内容確認
   - `architecture-diagram.md` → システムアーキテクチャ図確認

6. **リリース準備時**
   - `release_notes.md` → 変更履歴確認
   - `deploy.md` → デプロイ手順確認

**最終更新**: 2025年6月29日 - guide/ディレクトリ追加、APIキー管理ガイド移動  
**次回更新予定**: doc配下にドキュメントを追加する場合
