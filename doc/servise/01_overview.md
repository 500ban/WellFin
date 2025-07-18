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

### 1.4 Google Calendar機能使い方ガイド

#### 基本操作
1. **カレンダー表示**: メニューから「カレンダー」選択
2. **イベント作成**: タイムライン上タップまたは「+」ボタン
3. **イベント調整**: ドラッグ&ドロップで時間変更
4. **色選択**: イベント作成時にカラーピッカー使用（11色対応）
5. **イベント展開**: 下部イベントリストをタップで展開
6. **削除**: イベントタップ→詳細→削除

#### 管理者向け運用
1. **設定確認**: Google Calendar同期設定
2. **パフォーマンス**: 大量イベント時の動作監視
3. **バックアップ**: Firestore自動バックアップ確認

#### メンテナンス項目
- **月次**: Google Calendar API使用量確認
- **四半期**: パフォーマンス・UX評価
- **年次**: 機能拡張計画見直し

## 2. 機能要件・実装状況

### 2.1 機能実装状況一覧表

| 機能 | 実装状況 | ファイル | 詳細 |
|------|----------|----------|------|
| **認証システム** | ✅ 実装済み | `auth_service.dart`<br>`login_page.dart` (7.7KB, 206行) | Firebase Auth統合済み |
| **ダッシュボード機能** | ✅ 実装済み | `dashboard_page.dart` (99KB, 2741行) | 超大規模実装、習慣・タスク・目標機能ナビゲーション、UI改善完了、**Phase 5: 型エラー・レイアウトエラー解決、設定機能完全復元、ログアウト機能実装、スクロール監視最適化完了** |
| **AIエージェント機能** | ✅ 実装済み | `ai_agent_service.dart`<br>`ai_agent_test_page.dart` (12KB, 366行) | テストページ実装済み、Cloud Run Functions API統合、セキュリティ強化完了 |
| **Firebase統合** | ✅ 実装済み | `auth_service.dart` | Auth, Firestore対応 |
| **Android固有機能** | ✅ 実装済み | `android_service.dart` | ネイティブ機能統合 |
| **Riverpod状態管理** | ✅ 実装済み | `auth_provider.dart`<br>`user_provider.dart`<br>`habit_provider.dart`<br>`task_provider.dart`<br>`goal_provider.dart` | 全プロバイダー実装済み |
| **タスク管理** | ✅ 実装済み | `features/tasks/`<br>`task_list_page.dart` (9.2KB, 313行)<br>+ 5つのwidgets | ドメインエンティティ、リポジトリ（Firestore連携）、ユースケース、データモデル、UI、CRUD操作、サブタスク機能、フィルター機能、統計機能 |
| **習慣管理** | ✅ 実装済み | `features/habits/`<br>`habit_list_page.dart` (52KB, 1427行) | 大規模実装、ドメインエンティティ、リポジトリ（Firestore連携）、ユースケース、データモデル、UI、CRUD操作、ストリーク管理、統計機能、カテゴリ管理 |
| **目標管理** | ✅ 実装済み | `features/goals/`<br>`goal_list_page.dart` (12KB, 359行)<br>+ 5つのwidgets | 完全実装、ドメインエンティティ、リポジトリ（Firestore連携）、ユースケース、データモデル、UI、CRUD操作、マイルストーン管理、進捗追跡、統計機能 |
| **Cloud Run Functions API** | ✅ 実装済み | `functions/src/index.js` (534行)<br>+ 5つのAPIエンドポイント | Node.js 22、Vertex AI Gemini統合、APIキー認証、Health Check、完全動作確認済み |
| **Infrastructure as Code** | ✅ 実装済み | `terraform/main.tf` (136行) | 100%自動化達成、GCPリソース完全管理、セキュリティ強化 |
| **カレンダー機能** | ✅ 実装済み | `features/calendar/`<br>`google_calendar_service.dart` | **Google Calendar完全統合**、週間ビュー・タイムライン・ドラッグ&ドロップ・イベント管理・展開機能（Phase 1-4完了） |
| **分析機能** | ✅ **実装済み** | `features/analytics/` | **Phase 5: 週間・月間レポート、生産性パターン分析、目標進捗トラッキング、分析プロバイダー最適化完了** |
| **通知機能** | ✅ **実装済み** | `shared/providers/notification_settings_provider.dart`<br>`shared/services/` | **Phase 5: 通知設定・ローカル・FCM・プッシュ通知・AIレポートスケジューラー・統合テスト完了** |
| **統合テスト機能** | ✅ **実装済み** | `features/testing/` | **Phase 5: 分析・通知機能統合テスト・パフォーマンス・UI/UXテスト完了** |

### 2.2 プロジェクト構造
```
wellfin/
├── lib/
│   ├── features/
│   │   ├── auth/presentation/pages/login_page.dart ✅ (7.7KB)
│   │   ├── dashboard/presentation/pages/dashboard_page.dart ✅ (99KB, 2741行)
│   │   ├── ai_agent/
│   │   │   ├── data/models/ ✅
│   │   │   ├── domain/entities/ ✅
│   │   │   └── presentation/pages/ai_agent_test_page.dart ✅ (12KB, 366行)
│   │   ├── habits/
│   │   │   ├── data/
│   │   │   │   ├── models/habit_model.dart ✅
│   │   │   │   └── repositories/firestore_habit_repository.dart ✅
│   │   │   ├── domain/
│   │   │   │   ├── entities/habit.dart ✅
│   │   │   │   ├── repositories/habit_repository.dart ✅
│   │   │   │   └── usecases/habit_usecases.dart ✅
│   │   │   └── presentation/
│   │   │       ├── pages/habit_list_page.dart ✅ (52KB, 1427行)
│   │   │       └── providers/habit_provider.dart ✅
│   │   ├── tasks/
│   │   │   ├── data/
│   │   │   │   ├── models/task_model.dart ✅
│   │   │   │   └── repositories/firestore_task_repository.dart ✅
│   │   │   ├── domain/
│   │   │   │   ├── entities/task.dart ✅
│   │   │   │   ├── repositories/task_repository.dart ✅
│   │   │   │   └── usecases/task_usecases.dart ✅
│   │   │   └── presentation/
│   │   │       ├── pages/task_list_page.dart ✅ (9.2KB, 313行)
│   │   │       ├── widgets/
│   │   │       │   ├── task_card.dart ✅ (9.4KB, 302行)
│   │   │       │   ├── task_filter_bar.dart ✅ (2.2KB, 76行)
│   │   │       │   ├── add_task_dialog.dart ✅ (23KB, 737行)
│   │   │       │   ├── edit_task_dialog.dart ✅ (18KB, 582行)
│   │   │       │   └── task_detail_dialog.dart ✅ (13KB, 433行)
│   │   │       └── providers/task_provider.dart ✅
│   │   ├── goals/
│   │       ├── data/
│   │       │   ├── models/goal_model.dart ✅
│   │       │   └── repositories/firestore_goal_repository.dart ✅
│   │       ├── domain/
│   │       │   ├── entities/goal.dart ✅
│   │       │   ├── repositories/goal_repository.dart ✅
│   │       │   └── usecases/goal_usecases.dart ✅
│   │       └── presentation/
│   │           ├── pages/goal_list_page.dart ✅ (12KB, 359行)
│   │           ├── widgets/
│   │           │   ├── goal_card.dart ✅ (10KB, 303行)
│   │           │   ├── goal_filter_bar.dart ✅ (2.5KB, 73行)
│   │           │   ├── add_goal_dialog.dart ✅ (20KB, 496行)
│   │           │   ├── goal_detail_dialog.dart ✅ (15KB, 361行)
│   │           │   └── goal_stats_widget.dart ✅ (2.3KB, 60行)
│   │           └── providers/goal_provider.dart ✅
│   │   └── calendar/ **（Google Calendar連携完全実装）**
│   │       ├── domain/
│   │       │   └── entities/calendar_event.dart ✅
│   │       └── presentation/
│   │           ├── pages/calendar_page.dart ✅ **（Phase 4展開機能付き）**
│   │           ├── providers/calendar_provider.dart ✅
│   │           └── widgets/
│   │               ├── add_event_dialog.dart ✅
│   │               ├── calendar_event_list.dart ✅ **（展開機能対応）**
│   │               ├── calendar_timeline_view.dart ✅
│   │               ├── calendar_week_view.dart ✅
│   │               ├── delete_event_dialog.dart ✅
│   │               ├── draggable_event_widget.dart ✅
│   │               └── event_detail_dialog.dart ✅
│   ├── analytics/ **（Phase 5: 分析機能完全実装）**
│   │   ├── domain/
│   │   │   └── entities/ ✅
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── weekly_report_page.dart ✅ **（週間レポート機能）**
│   │       │   ├── monthly_report_page.dart ✅ **（月間レポート機能）**
│   │       │   ├── productivity_patterns_page.dart ✅ **（生産性パターン分析）**
│   │       │   └── goal_progress_tracking_page.dart ✅ **（目標進捗トラッキング）**
│   │       └── providers/
│   │           └── analytics_provider.dart ✅ **（分析プロバイダー最適化）**
│   ├── notifications/ **（Phase 5: 通知機能完全実装）**
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── notification_settings_page.dart ✅ **（通知設定UI）**
│   │       └── widgets/ ✅ **（通知関連ウィジェット）**
│   └── testing/ **（Phase 5: 統合テスト機能完全実装）**
│       ├── services/
│       │   └── integration_test_service.dart ✅ **（統合テストサービス）**
│       └── presentation/
│           └── pages/
│               └── integration_test_page.dart ✅ **（統合テストページ）**
│   ├── shared/
│   │   ├── services/
│   │   │   ├── auth_service.dart ✅ **（Google Calendar API統合）**
│   │   │   ├── ai_agent_service.dart ✅ **（セキュリティ強化済み）**
│   │   │   ├── android_service.dart ✅
│   │   │   ├── google_calendar_service.dart ✅ **（完全双方向同期）**
│   │   │   ├── local_notification_service.dart ✅ **（Phase 5: ローカル通知）**
│   │   │   ├── fcm_service.dart ✅ **（Phase 5: FCM通知）**
│   │   │   ├── push_notification_scheduler.dart ✅ **（Phase 5: プッシュ通知）**
│   │   │   ├── ai_report_scheduler.dart ✅ **（Phase 5: AIレポート）**
│   │   │   ├── habit_reminder_scheduler.dart ✅ **（Phase 5: 習慣リマインダー）**
│   │   │   └── task_deadline_scheduler.dart ✅ **（Phase 5: タスク締切）**
│   │   └── providers/
│   │       ├── auth_provider.dart ✅
│   │       ├── user_provider.dart ✅
│   │       └── notification_settings_provider.dart ✅ **（Phase 5: 通知設定）**
│   └── main.dart ✅
├── functions/ **（Cloud Run Functions API）**
│   ├── src/
│   │   ├── index.js ✅ (534行)
│   │   ├── services/ai-service.js ✅ **（Vertex AI Gemini統合）**
│   │   └── routes/ ✅ **（5つのAPIエンドポイント）**
│   └── package.json ✅ **（Node.js 22, Functions Framework 4.0.0）**
├── terraform/ **（Infrastructure as Code）**
│   ├── main.tf ✅ (136行) **（100%自動化達成）**
│   ├── variables.tf ✅
│   ├── outputs.tf ✅
│   └── providers.tf ✅
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

#### Phase 5: ダッシュボード改善・ログアウト機能実装（2025年7月6日）
- **型エラー完全解決**: `type '(dynamic) => dynamic' is not a subtype of type '(Goal) => bool'` エラー解決
  - Goal型のインポート追加
  - 引数型の明示的定義
  - メソッド戻り値型の明確化
- **レイアウトエラー完全解決**: `RenderFlex children have non-zero flex` エラー解決
  - 全ダッシュボードカードに `mainAxisSize: MainAxisSize.min` 追加
  - `Expanded` を固定高さ `SizedBox` に変更
- **設定機能完全復元**: 設定BottomSheetの完全実装
  - 管理機能セクション（タスク・習慣・カレンダー・目標・分析管理）
  - アプリ設定セクション（通知設定・アプリについて）
  - DraggableScrollableSheet による優れたUX
- **ログアウト機能実装**: タイトル右側配置によるアクセスしやすいログアウト
  - グレー系の上品なデザイン（赤色から変更）
  - ワンタップログアウト（確認ダイアログ削除）
  - `pushNamedAndRemoveUntil` による確実なリダイレクト
- **スクロール監視最適化**: ヘッダーが隠れるタイミングでの表示
  - 監視高さ: 300px → 80px（約4倍速い反応）
  - 設定ボタン + TOPに戻るボタンの縦並び配置
  - スムーズアニメーション（500ms）

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
- **手動トリガー + 条件付きキャッシュ方式**: 🔄ボタンクリック時のみAI呼び出し

#### 設定機能セクション（Phase 5新機能）
- **管理機能**: タスク・習慣・カレンダー・目標・分析管理へのナビゲーション
- **アプリ設定**: 通知設定・アプリについて
- **ログアウト機能**: タイトル右側配置、ワンタップ実行、確実なリダイレクト
- **UI/UX**: DraggableScrollableSheet、レスポンシブ対応

#### 習慣トラッキング
- **今日の習慣表示**: 今日実行すべき習慣の一覧
- **完了状態表示**: チェックボックスによる完了管理
- **ストリーク表示**: 継続日数の表示

#### 生産性分析
- **週間・月間統計**: 期間別の生産性データ
- **グラフ表示**: 視覚的なデータ表現
- **傾向分析**: 生産性の変化傾向

#### スクロール機能（Phase 5改善）
- **TOPに戻るボタン**: 80px閾値でのスマート表示（ヘッダーが隠れるタイミング）
- **設定ボタン**: フローティングアクションボタンとして縦並び配置
- **スムーズアニメーション**: 500msでTOPに復帰
- **自動非表示**: TOPに戻った後の自動ボタン非表示

#### 技術的成果（Phase 5）
- **型安全性の確保**: Flutter型システムの完全活用、全型エラー解決
- **レイアウト安定性**: Flexレイアウトの適切な実装、エラー完全解決
- **ナビゲーション完全性**: `pushNamedAndRemoveUntil` による履歴管理
- **UX最適化**: スクロール監視の4倍速化、自然なタイミング実現
- **セキュリティ強化**: ログアウト機能の安全な実装

#### 実装ファイル（Phase 5）
- **主要修正**: `wellfin/lib/features/dashboard/presentation/pages/dashboard_page.dart`
- **型修正**: `wellfin/lib/features/dashboard/presentation/widgets/dashboard_widgets.dart`
- **認証強化**: `wellfin/lib/shared/providers/auth_provider.dart` インポート追加

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

### 3.3 目標管理機能の実装詳細（最新実装状況：2025年6月29日）

#### 実装済み機能
- **カテゴリ**: 8種類（個人、健康、仕事、学習、フィットネス、財務、創造性、その他）
- **優先度**: 4段階（低、中、高、最重要）
- **ステータス**: 5段階（アクティブ、一時停止、完了、キャンセル、期限切れ）
- **目標タイプ**: 3種類（一般、数値目標、マイルストーン）
- **進捗管理**: 0.0-1.0の進捗率、進捗履歴、マイルストーン管理

#### 完全実装されたUI/UX機能
- **目標一覧画面**: `goal_list_page.dart` (12KB, 359行)
- **目標カード**: `goal_card.dart` (10KB, 303行) - カテゴリアイコン、進捗バー、ステータス表示
- **目標作成ダイアログ**: `add_goal_dialog.dart` (20KB, 496行) - 全フィールド対応、バリデーション機能
- **目標詳細ダイアログ**: `goal_detail_dialog.dart` (15KB, 361行) - 編集機能、マイルストーン管理
- **フィルターバー**: `goal_filter_bar.dart` (2.5KB, 73行) - ステータス・カテゴリ・優先度フィルター
- **統計ウィジェット**: `goal_stats_widget.dart` (2.3KB, 60行) - 進捗統計、達成率分析

#### データ層・ドメイン層
- **エンティティ**: `Goal`, `Milestone`, `GoalProgress`クラスの完全実装
- **リポジトリ**: Firestore連携による永続化、リアルタイム同期
- **ユースケース**: CRUD操作、進捗更新、統計計算
- **状態管理**: Riverpodプロバイダーによるリアルタイム状態管理

### 3.4 AI Agent機能の実装詳細（最新実装状況：2025年6月29日）

#### 実装済み機能
- **AIエージェントテストページ**: `ai_agent_test_page.dart` (12KB, 366行)
- **Cloud Run Functions API統合**: 5つのAPIエンドポイント実装
- **Vertex AI Gemini統合**: 自然言語処理、コンテキスト理解
- **セキュリティ強化**: APIキー認証、環境変数管理
- **実機動作確認**: Android実機での完全動作保証

#### Cloud Run Functions API
- **Health Check**: `/health` - API動作確認
- **Vertex AI Test**: `/api/v1/vertex-ai-test` - AI接続テスト
- **タスク分析**: `/api/v1/analyze-task` - タスク内容分析
- **スケジュール最適化**: `/api/v1/optimize-schedule` - 時間配分最適化
- **推奨事項生成**: `/api/v1/recommendations` - パーソナライズ提案

#### セキュリティアーキテクチャ
- **環境変数管理**: `WELLFIN_API_KEY`, `WELLFIN_API_URL`による安全な設定
- **Git保護**: 機密情報の完全除外、`config/development/api-config.json`による管理
- **実機対応**: 既存ビルドシステム（`scripts/flutter-build.bat`）との統合
- **Infrastructure as Code**: Terraform 100%自動化による設定漂流防止

### 3.5 Infrastructure as Code実装（2025年6月29日達成）

#### 完全自動化達成
- **Terraform実装**: `terraform/main.tf` (136行) - GCPリソース100%管理
- **手動管理リソース**: 0件
- **設定漂流防止**: コード化による設定の標準化
- **環境複製**: 新環境の即座構築可能

#### 統合されたGCPリソース
- **Cloud Run Functions**: Node.js 22 Runtime
- **IAM権限**: aiplatform.admin, serviceAccountTokenCreator
- **API有効化**: Vertex AI, Cloud Functions
- **Secret Manager**: APIキー管理
- **ネットワーク設定**: Public Access制御

### 3.6 タスク管理機能の実装詳細
- **優先度**: 4段階（低、中、高、緊急）
- **難易度**: 4段階（簡単、普通、困難、専門的）
- **ステータス**: 4段階（保留中、進行中、完了、遅延）
- **機能**: サブタスク、繰り返しルール、場所情報、統計分析

### 3.7 認証システム
- **要件**: 
  - Google認証のみを使用（Firebase Authentication）
  - シングルサインオン（SSO）の実装
  - セッション管理とトークン更新
- **実現方法**:
  - Firebase Authentication の実装
  - OAuth 2.0フローでのGoogle認証
  - JWTトークン管理とセキュアな更新メカニズム
  - FlutterFireパッケージでのネイティブアプリ統合

### 3.8 カレンダー管理（✅ 実装完了・Production Ready）
- **要件**:
  - Google Calendarとの双方向同期 ✅
  - イベント作成、編集、削除 ✅
  - ドラッグ&ドロップによる時間調整 ✅
  - ダッシュボード統合・リアルタイム同期 ✅
- **実装状況**:
  - **Phase 1-2**: 週間ビュー・タイムライン表示・ビュー切り替え ✅
  - **Phase 3**: ドラッグ&ドロップ機能・削除機能・設定統合 ✅
  - **同期システム**: CalendarProvider統合・認証ループ解決 ✅
  - **UI/UX**: レスポンシブデザイン・モダンマテリアル ✅
- **実現技術**:
  - Google Calendar API (v3) 完全統合 ✅
  - GoogleCalendarService (Completer同期制御) ✅
  - DraggableEventWidget・DragTargetCalendar ✅
  - DeleteEventDialog・設定ページ統合 ✅

### 3.9 AIパーソナライゼーション（Google Cloud AI技術活用）
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

### 3.10 スケジュール最適化（AI駆動型最適化）
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

### 3.11 モチベーション管理
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

### 3.12 通知・リマインダー（✅ Phase 5: 完全実装完了）
- **要件**:
  - 複数チャネル対応（アプリ内、プッシュ通知、メール）
  - 適応型通知タイミング（重要度に応じた頻度調整）
  - アクション可能なリマインダー（完了、延期、キャンセル）
  - 状況に応じた通知内容カスタマイズ
- **実現方法**:
  - Firebase Cloud Messaging (FCM) の実装 ✅
  - プラットフォーム別通知ハンドリング ✅
  - 通知アクション機能の実装 ✅
  - 機械学習ベースの最適通知時間予測 ✅
- **Phase 5実装完了内容**:
  - **通知設定プロバイダー**: `notification_settings_provider.dart` ✅
  - **ローカル通知サービス**: `local_notification_service.dart` ✅
  - **FCMサービス**: `fcm_service.dart` ✅
  - **プッシュ通知スケジューラー**: `push_notification_scheduler.dart` ✅
  - **AIレポートスケジューラー**: `ai_report_scheduler.dart` ✅
  - **習慣リマインダー**: `habit_reminder_scheduler.dart` ✅
  - **タスク締切通知**: `task_deadline_scheduler.dart` ✅
  - **通知設定UI**: `notification_settings_page.dart` ✅
  - **テスト通知機能**: 習慣・タスク・AI通知テスト送信 ✅

### 3.13 レポートと分析（✅ Phase 5: 完全実装完了）
- **要件**:
  - 週間・月間の達成状況サマリー
  - 生産性パターン分析レポート
  - 目標進捗トラッキング
  - 習慣形成状況の可視化
- **実現方法**:
  - Cloud Firestore クエリとアグリゲーション機能活用 ✅
  - カスタムレポート生成エンジン ✅
  - Flutter Chartsによるデータ可視化 ✅
  - バッチ処理による定期レポート生成 ✅
- **Phase 5実装完了内容**:
  - **週間レポート機能**: `weekly_report_page.dart` ✅
  - **月間レポート機能**: `monthly_report_page.dart` ✅
  - **生産性パターン分析**: `productivity_patterns_page.dart` ✅
  - **目標進捗トラッキング**: `goal_progress_tracking_page.dart` ✅
  - **分析プロバイダー最適化**: `analytics_provider.dart` ✅
  - **統合テスト機能**: `integration_test_page.dart` ✅

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
- **Firebase Cloud Messaging**: プッシュ通知（✅ Phase 5: 完全実装完了）
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
- **通知システム**: Phase 5完全実装（ローカル・FCM・プッシュ通知）
- **分析システム**: Phase 5完全実装（週間・月間・生産性パターン・目標進捗）

---

*最終更新: 2025年7月12日 - Phase 5 分析・通知機能統合完全実装完了*