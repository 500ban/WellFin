# 第1部：サービス概要・要件定義

## 📋 ファイルの役割
このファイルは、WellFinアプリケーションのサービス概要、機能要件、実装状況、技術スタックを記載する仕様書です。
アプリケーションの全体像と各機能の詳細仕様を管理します。

## 1. システム概要

### 1.1 サービスコンセプト
WellFin（ウェルフィン）は、日常生活の生産性を向上させ、共に良い終わりを目指すAIベースのスケジュール最適化・習慣形成サポートアプリケーションです。名前は「Well」（健康・幸福）と「Fin」（終わり・目標達成）を組み合わせたものです。

### 1.2 ビジネス価値
- **AI駆動型パーソナライゼーション**: Google Cloud AI技術を活用した個別最適化
- **習慣形成サポート**: 科学的根拠に基づく習慣構築支援
- **スケジュール最適化**: 生産性ピーク時間を活用した効率的な時間管理
- **モチベーション維持**: 継続的な励ましと達成感の提供

### 1.3 ターゲットユーザー
- 生産性向上を目指すビジネスパーソン
- 習慣形成に取り組む個人
- 時間管理を改善したい学生・社会人
- AI技術を活用した生活改善に興味があるユーザー

## 2. 機能要件・実装状況

### 2.1 機能実装状況一覧表

| 機能 | 実装状況 | ファイル | 詳細 |
|------|----------|----------|------|
| **認証システム** | ✅ 実装済み | `auth_service.dart`<br>`login_page.dart` | Firebase Auth統合済み |
| **ダッシュボード機能** | ✅ 実装済み | `dashboard_page.dart` | UI実装済み、習慣・タスク機能ナビゲーション追加済み、UI改善完了 |
| **AIエージェント機能** | 🔄 部分実装 | `ai_agent_service.dart` | サービス層のみ実装 |
| **Firebase統合** | ✅ 実装済み | `auth_service.dart` | Auth, Firestore対応 |
| **Android固有機能** | ✅ 実装済み | `android_service.dart` | ネイティブ機能統合 |
| **Riverpod状態管理** | ✅ 実装済み | `auth_provider.dart`<br>`user_provider.dart`<br>`habit_provider.dart`<br>`task_provider.dart` | 全プロバイダー実装済み |
| **タスク管理** | ✅ 実装済み | `features/tasks/`<br>`firestore_task_repository.dart`<br>`task_model.dart`<br>`task_provider.dart` | ドメインエンティティ、リポジトリ（Firestore連携）、ユースケース、データモデル、UI、CRUD操作、フィルター機能、統計機能 |
| **習慣管理** | ✅ 実装済み | `features/habits/`<br>`firestore_habit_repository.dart`<br>`habit_model.dart`<br>`habit_provider.dart` | ドメインエンティティ、リポジトリ（Firestore連携）、ユースケース、データモデル、UI、CRUD操作、ストリーク管理、統計機能、カテゴリ管理 |
| **目標管理** | ❌ 未実装 | `features/goals/` | ディレクトリ構造のみ |
| **カレンダー機能** | ❌ 未実装 | `features/calendar/` | ディレクトリ構造のみ |
| **分析機能** | ❌ 未実装 | `features/analytics/` | ディレクトリ構造のみ |

### 2.2 プロジェクト構造
```
wellfin/
├── lib/
│   ├── features/
│   │   ├── auth/presentation/pages/login_page.dart ✅
│   │   ├── dashboard/presentation/pages/dashboard_page.dart ✅
│   │   ├── ai_agent/data/models/ (空) 🔄
│   │   ├── habits/
│   │   │   ├── data/
│   │   │   │   ├── models/habit_model.dart ✅
│   │   │   │   └── repositories/firestore_habit_repository.dart ✅
│   │   │   ├── domain/
│   │   │   │   ├── entities/habit.dart ✅
│   │   │   │   ├── repositories/habit_repository.dart ✅
│   │   │   │   └── usecases/habit_usecases.dart ✅
│   │   │   └── presentation/
│   │   │       ├── pages/habit_list_page.dart ✅
│   │   │       ├── widgets/
│   │   │       │   ├── habit_card.dart ✅
│   │   │       │   ├── add_habit_dialog.dart ✅
│   │   │       │   └── habit_stats_widget.dart ✅
│   │   │       └── providers/habit_provider.dart ✅
│   │   └── tasks/
│   │       ├── data/
│   │       │   ├── models/task_model.dart ✅
│   │       │   └── repositories/firestore_task_repository.dart ✅
│   │       ├── domain/
│   │       │   ├── entities/task.dart ✅
│   │       │   ├── repositories/task_repository.dart ✅
│   │       │   └── usecases/task_usecases.dart ✅
│   │       └── presentation/
│   │           ├── pages/task_list_page.dart ✅
│   │           ├── widgets/
│   │           │   ├── task_card.dart ✅
│   │           │   ├── task_filter_bar.dart ✅
│   │           │   ├── add_task_dialog.dart ✅
│   │           │   └── task_detail_dialog.dart ✅
│   │           └── providers/task_provider.dart ✅
│   ├── shared/
│   │   ├── services/
│   │   │   ├── auth_service.dart ✅
│   │   │   ├── ai_agent_service.dart 🔄
│   │   │   └── android_service.dart ✅
│   │   └── providers/
│   │       ├── auth_provider.dart ✅
│   │       └── user_provider.dart ✅
│   └── main.dart ✅
└── android/
    └── app/
        ├── build.gradle.kts ✅
        ├── google-services.json ✅
        └── src/main/
            ├── AndroidManifest.xml ✅
            └── kotlin/com/wellfin/aiagent/MainActivity.kt ✅
```

### 2.3 開発環境設定

#### **現在の環境**
- **OS**: Windows 10/11
- **Flutter**: Stable Channel
- **Android Studio**: 最新版
- **Java**: JDK 17
- **Android SDK**: API 34/35

#### **重要な設定ファイル**
- `pubspec.yaml`: 依存関係管理
- `android/app/build.gradle.kts`: Android設定
- `android/app/google-services.json`: Firebase設定
- `android/app/src/main/AndroidManifest.xml`: アプリ権限・設定

## 3. 詳細実装仕様

### 3.1 ダッシュボード機能（最新実装状況）
**ファイル**: `lib/features/dashboard/presentation/pages/dashboard_page.dart`

#### 最新のUI改善（2025年6月28日）
- **FloatingActionButton削除**: 右下のタスク追加ボタンを削除し、UIをよりシンプルに
- **クイックアクセスメニュー簡素化**: 
  - 今日のタスク、高優先度、完了済みの項目を削除
  - タスク設定、習慣設定、目標設定の3項目に整理
  - タスク追加機能は「タスク設定」ボタンから利用可能に
- **表記統一**: 「管理」を「設定」に統一
  - 「タスク管理」→「タスク設定」
  - 「習慣管理」→「習慣設定」
- **ナビゲーション修正**: 習慣設定の遷移を直接的なMaterialPageRouteに変更
- **UIデザイン復元**: 元のカラフルなカードスタイルを維持

#### 今日のタスク表示
- **今日のタスク専用カード**: 今日のタスクのみを表示する専用セクション
- **タスク操作機能**: 完了チェックボックス、詳細表示ボタン、編集ボタンを追加
- **進捗バー表示**: 今日のタスクの完了進捗を視覚的に表示
- **優先度順ソート**: 高優先度タスクを上位に表示
- **統計情報の充実**: 完了率、残りタスク数、進捗状況を表示
- **「すべて表示」ボタン**: 今日のタスクフィルターでタスク管理画面に遷移

#### クイックアクセスメニュー
- **タスク設定**: タスク管理画面に遷移（すべてのタスクフィルター）
- **習慣設定**: 習慣管理画面に遷移
- **目標設定**: 準備中（将来実装予定）

#### ユーザー情報表示
- **プロフィール画像**: Firebase Authから取得
- **ユーザー名**: 表示名の表示
- **挨拶メッセージ**: 時間帯に応じた挨拶

#### 今日のサマリー
- **タスク統計**: 今日のタスク数、完了数、完了率
- **習慣統計**: 今日の習慣数、完了数、完了率
- **生産性スコア**: 総合的な生産性指標

#### AI推奨セクション
- **生産性向上提案**: AIによる個別化された提案
- **習慣継続サポート**: ストリーク情報を活用した継続支援
- **時間管理アドバイス**: 集中力の高い時間帯の提案

#### 習慣トラッキング
- **今日の習慣表示**: 今日実行すべき習慣の一覧
- **完了状態表示**: チェックボックスによる完了管理
- **ストリーク表示**: 継続日数の表示

#### 生産性分析
- **週間・月間統計**: 期間別の生産性データ
- **グラフ表示**: 視覚的なデータ表現
- **傾向分析**: 生産性の変化傾向

### 3.2 習慣管理機能の実装詳細（最新実装状況：2025年6月28日）

#### 実装済み機能
- **カテゴリ**: 10種類（個人、健康、仕事、学習、フィットネス、マインドフルネス、社交、財務、創造性、その他）
- **頻度**: 9種類（毎日、1日おき、週2回、週3回、週次、月2回、月次、四半期、年次、カスタム）
- **ステータス**: 3段階（アクティブ、一時停止、終了）
- **優先度**: 4段階（低、中、高、最重要）
- **統計**: 習慣数、完了回数、平均ストリーク、カテゴリ分布

#### 最新のUI改善（2025年6月28日）
- **習慣詳細画面のオーバーフロー修正**:
  - ボタンテキストの短縮（「今日の取り組み完了済み」→「完了済み」、「今日の取り組みを記録」→「記録」）
  - ダイアログの横幅拡大（90%→95%、最大幅500px→600px）
  - ボタンレイアウトの改善（Row→Wrap、自動折り返し対応）

- **習慣編集機能の実装**:
  - 詳細画面の編集ボタン（えんぴつマーク）から専用編集ダイアログを表示
  - 既存データを初期値として設定した編集フォーム
  - タイトル、説明、カテゴリ、頻度、優先度、ステータスの編集可能
  - 週次の場合は対象曜日も選択可能
  - バリデーション機能（習慣名必須、週次の場合の曜日選択必須）
  - `habit.copyWith()`を使用した安全な更新処理
  - 成功時のスナックバー通知

- **リンターエラー修正**:
  - FloatingActionButtonのchild引数を最後に移動
  - DayOfWeek型をHabitDay型に修正

#### 習慣管理画面の機能
- **ステータスフィルター**: アクティブ、一時停止、終了の切り替え
- **カテゴリ別表示**: 習慣をカテゴリごとにグループ化して表示
- **習慣カード**: カテゴリアイコン、タイトル、説明、頻度を表示
- **操作メニュー**: 一時停止、再開、終了、削除の操作
- **統計表示**: 習慣統計ダイアログで詳細な分析情報を表示
- **完了記録**: 今日の取り組み完了の記録機能
- **ストリーク管理**: 継続日数の自動計算と表示

### 3.3 タスク管理機能の実装詳細
- **優先度**: 4段階（低、中、高、緊急）
- **難易度**: 4段階（簡単、普通、困難、専門的）
- **ステータス**: 4段階（保留中、進行中、完了、遅延）
- **機能**: サブタスク、繰り返しルール、場所情報、統計分析

### 3.4 認証システム
- **要件**: 
  - Google認証のみを使用（Firebase Authentication）
  - シングルサインオン（SSO）の実装
  - セッション管理とトークン更新
- **実現方法**:
  - Firebase Authentication の実装
  - OAuth 2.0フローでのGoogle認証
  - JWTトークン管理とセキュアな更新メカニズム
  - FlutterFireパッケージでのネイティブアプリ統合

### 3.5 カレンダー管理
- **要件**:
  - Google Calendarとの双方向同期
  - イベント作成、編集、削除
  - 繰り返しイベントの管理
  - カレンダー間の連携と統合表示
- **実現方法**:
  - Google Calendar API (v3) の実装
  - OAuth 2.0スコープによる権限取得
  - 専用サービスレイヤーとモデル設計
  - Firebase Cloud Functionsでバックグラウンド同期処理

### 3.6 AIパーソナライゼーション（Google Cloud AI技術活用）
- **要件**:
  - ユーザー行動パターンの学習と分析
  - サボりがちなタスクやタイムスロットの特定
  - 個人の生産性ピーク時間の把握と活用
  - コンテキスト認識型の提案生成
  - 自然言語でのタスク入力と理解
  - 感情分析によるモチベーション管理
- **実現方法**:
  - **Vertex AI Agent Builder**でのインテリジェントエージェント構築
  - **Gemini API in Vertex AI**での自然言語処理とコンテキスト理解
  - **Vertex AI Vector Search**でのユーザー行動パターン類似性検索
  - **Recommendations AI**でのパーソナライズされた推奨システム
  - **Natural Language AI**でのタスク記述の感情分析と重要度判定
  - **Vertex AI Model Development Service**でのカスタム機械学習モデル構築
  - **AutoML**でのユーザー行動予測モデルの自動構築
  - Firebase Analyticsでのユーザー行動データ収集
  - Cloud Firestoreでの時系列データ保存と分析

### 3.7 スケジュール最適化（AI駆動型最適化）
- **要件**:
  - 空き時間の効率的活用提案
  - タスクの優先順位付けと時間配分
  - 準備時間や移動時間を考慮したスケジューリング
  - スケジュール競合の自動検出と解決提案
  - AIによる最適な時間帯の自動選択
  - ユーザーの気分やエネルギー状態を考慮したスケジューリング
- **実現方法**:
  - **Vertex AI Agent Engine**でのインテリジェントスケジューリングエージェント
  - **Vertex AI Model Optimizer**でのスケジューリングアルゴリズム最適化
  - **Gemini API**での自然言語によるスケジュール調整指示の理解
  - **Vertex Explainable AI**でのスケジュール提案の説明可能性
  - **Recommendations AI**での時間帯別タスク推奨
  - Cloud RunでのスケジューリングエンジンAPI
  - Firebase Cloud Functionsでのイベント駆動型スケジュール更新
  - 優先度スコアリングシステム構築
  - 時間ブロック最適化アルゴリズム
  - リアルタイムカレンダー解析エンジン

### 3.8 モチベーション管理
- **要件**:
  - 目標達成進捗の視覚化
  - カスタマイズ可能な達成報酬システム
  - 適切なタイミングでの励ましメッセージ
  - 長期目標と日常タスクの関連付け
- **実現方法**:
  - Flutterでのカスタムインターフェース実装
  - 目標-タスク階層構造のデータモデル設計
  - ガミフィケーション要素（バッジ、ストリーク）の実装
  - 行動科学に基づくポジティブ強化アルゴリズム

### 3.9 通知・リマインダー
- **要件**:
  - 複数チャネル対応（アプリ内、プッシュ通知、メール）
  - 適応型通知タイミング（重要度に応じた頻度調整）
  - アクション可能なリマインダー（完了、延期、キャンセル）
  - 状況に応じた通知内容カスタマイズ
- **実現方法**:
  - Firebase Cloud Messaging (FCM) の実装
  - プラットフォーム別通知ハンドリング
  - 通知アクション機能の実装
  - 機械学習ベースの最適通知時間予測

### 3.10 レポートと分析
- **要件**:
  - 週間・月間の達成状況サマリー
  - 生産性パターン分析レポート
  - 目標進捗トラッキング
  - 習慣形成状況の可視化
- **実現方法**:
  - Cloud Firestore クエリとアグリゲーション機能活用
  - カスタムレポート生成エンジン
  - Flutter Chartsによるデータ可視化
  - バッチ処理による定期レポート生成

## 4. 非機能要件

### 4.1 パフォーマンス
- アプリ起動時間：3秒以内
- API応答時間：1秒以内
- オフライン機能の提供
- バッテリー消費の最適化

### 4.2 セキュリティ
- Firebase認証基盤の活用
- Googleの認証情報保護と安全な管理
- データ暗号化（転送中および保存時）
- APIキーと環境変数の安全な管理

### 4.3 可用性
- 99.9%のサービス可用性
- データバックアップと復元機能
- クラウドとローカルの同期

### 4.4 ユーザビリティ
- 直感的なUI/UX
- アクセシビリティ対応
- カスタマイズ可能なインターフェース
- 多言語対応（日本語・英語）

### 4.5 拡張性
- Firebaseエコシステムとの統合
- GCPサービスとの連携
- 将来的な機能追加に対応したモジュラー設計

## 5. 技術スタック

### 5.1 バックエンド（Google Cloud AI技術 - 必須条件）
- **Vertex AI**: AIモデルのホスティングと推論、パーソナライゼーション
- **Gemini API in Vertex AI**: 自然言語処理とAIアシスタント機能
- **Vertex AI Agent Builder**: インテリジェントなスケジュール最適化エージェント
- **Vertex AI Vector Search**: ユーザー行動パターンの類似性検索
- **Vertex AI Model Development Service**: カスタム機械学習モデルの開発
- **Vertex AI Explainable AI**: AI予測の説明可能性と透明性
- **Natural Language AI**: タスク記述の感情分析と重要度判定
- **Recommendations AI**: パーソナライズされたタスク推奨システム
- **Cloud Run**: サーバーレスAPIサービス（スケジュール最適化エンジン）
- **Cloud Functions**: イベント駆動型のバックエンド処理
- **Firebase Authentication**: Google認証専用
- **Cloud Firestore**: ユーザーデータとアプリケーションデータ
- **Firebase Cloud Messaging**: プッシュ通知
- **Firebase Analytics**: ユーザー行動分析

### 5.2 フロントエンド（Flutter/Firebase - 特別賞対象）
- **Flutter**: クロスプラットフォーム対応（iOS/Android）
- **FlutterFire**: Flutter用Firebase SDK
- **Google Calendar API**: カレンダー連携
- **Provider/Riverpod**: 状態管理
- **Hive/SQLite**: ローカルデータキャッシュと同期

**実装済みアーキテクチャ**
- **クリーンアーキテクチャ**: Domain、Data、Presentation層の分離
- **Riverpod**: 状態管理と依存性注入
- **Repository Pattern**: データアクセスの抽象化
- **Use Case Pattern**: ビジネスロジックの分離
- **Feature-based Structure**: 機能別ディレクトリ構成
- **Firestore Integration**: リアルタイムデータ同期
- **Error Handling**: Either型による結果管理
- **Responsive UI**: 適応型レイアウトとダイアログ設計

### 5.3 AI・機械学習（Google Cloud AI技術）
- **Vertex AI Agent Engine**: インテリジェントなスケジュール管理エージェント
- **Vertex AI Model Optimizer**: モデルパフォーマンス最適化
- **Gen AI Evaluation**: AIモデルの評価と改善
- **AutoML**: ユーザー行動予測モデルの自動構築
- **Document AI**: タスク関連文書の自動処理
- **Speech-to-Text**: 音声入力によるタスク作成
- **Text-to-speech**: 音声フィードバック

### 5.4 データ・分析（Google Cloud サービス）
- **BigQuery**: 大規模データ分析とレポート生成
- **Cloud Storage**: ファイル保存とバックアップ
- **Dataflow**: リアルタイムデータ処理パイプライン
- **Pub/Sub**: イベント駆動型アーキテクチャ
- **Cloud Scheduler**: 定期タスクとバッチ処理
- **Secret Manager**: API鍵と機密情報の安全な管理

### 5.5 セキュリティ・運用
- **Firebase Security Rules**: データアクセス制御
- **Cloud IAM**: 認証と認可の管理
- **Cloud Logging**: ログ管理と監視
- **Error Reporting**: エラー追跡と分析
- **Firebase Crashlytics**: クラッシュレポート収集
- **Firebase Performance**: パフォーマンス監視

### 5.6 開発・デプロイ
- **Cloud Build**: CI/CDパイプライン
- **Cloud Run**: コンテナ化されたアプリケーション
- **Firebase App Distribution**: テスト配布
- **Cloud Source Repositories**: ソースコード管理
- **Cloud Shell**: クラウドベースの開発環境

---

*最終更新: 2025年6月28日* 