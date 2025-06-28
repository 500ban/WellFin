# WellFin - 日常生活向上AIエージェント - 要件定義と実装計画

## 1. システム概要
WellFin（ウェルフィン）は、日常生活の生産性を向上させ、共に良い終わりを目指すAIベースのスケジュール最適化・習慣形成サポートアプリケーションです。名前は「Well」（健康・幸福）と「Fin」（終わり・目標達成）を組み合わせたものです。

## 2. 機能要件

### 2.1 認証システム
- **要件**: 
  - Google認証のみを使用（Firebase Authentication）
  - シングルサインオン（SSO）の実装
  - セッション管理とトークン更新
- **実現方法**:
  - Firebase Authentication の実装
  - OAuth 2.0フローでのGoogle認証
  - JWTトークン管理とセキュアな更新メカニズム
  - FlutterFireパッケージでのネイティブアプリ統合

### 2.2 カレンダー管理
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

### 2.3 AIパーソナライゼーション（Google Cloud AI技術活用）
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

### 2.4 スケジュール最適化（AI駆動型最適化）
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

### 2.5 モチベーション管理
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

### 2.6 通知・リマインダー
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

### 2.7 レポートと分析
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

## 3. 非機能要件

### 3.1 パフォーマンス
- アプリ起動時間：3秒以内
- API応答時間：1秒以内
- オフライン機能の提供
- バッテリー消費の最適化

### 3.2 セキュリティ
- Firebase認証基盤の活用
- Googleの認証情報保護と安全な管理
- データ暗号化（転送中および保存時）
- APIキーと環境変数の安全な管理

### 3.3 可用性
- 99.9%のサービス可用性
- データバックアップと復元機能
- クラウドとローカルの同期

### 3.4 ユーザビリティ
- 直感的なUI/UX
- アクセシビリティ対応
- カスタマイズ可能なインターフェース
- 多言語対応（日本語・英語）

### 3.5 拡張性
- Firebaseエコシステムとの統合
- GCPサービスとの連携
- 将来的な機能追加に対応したモジュラー設計

## 4. 技術スタック

### 4.1 バックエンド（Google Cloud AI技術 - 必須条件）
- **Vertex AI**: AIモデルのホスティングと推論、パーソナライゼーション
- **Gemini API in Vertex AI**: 自然言語処理とAIアシスタント機能
- **Vertex AI Agent Builder**: インテリジェントなスケジュール最適化エージェント
- **Vertex AI Vector Search**: ユーザー行動パターンの類似性検索
- **Vertex AI Model Development Service**: カスタム機械学習モデルの開発
- **Vertex Explainable AI**: AI予測の説明可能性と透明性
- **Natural Language AI**: タスク記述の感情分析と重要度判定
- **Recommendations AI**: パーソナライズされたタスク推奨システム
- **Cloud Run**: サーバーレスAPIサービス（スケジュール最適化エンジン）
- **Cloud Functions**: イベント駆動型のバックエンド処理
- **Firebase Authentication**: Google認証専用
- **Cloud Firestore**: ユーザーデータとアプリケーションデータ
- **Firebase Cloud Messaging**: プッシュ通知
- **Firebase Analytics**: ユーザー行動分析

### 4.2 フロントエンド（Flutter/Firebase - 特別賞対象）
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

### 4.3 AI・機械学習（Google Cloud AI技術）
- **Vertex AI Agent Engine**: インテリジェントなスケジュール管理エージェント
- **Vertex AI Model Optimizer**: モデルパフォーマンス最適化
- **Gen AI Evaluation**: AIモデルの評価と改善
- **AutoML**: ユーザー行動予測モデルの自動構築
- **Document AI**: タスク関連文書の自動処理
- **Speech-to-Text**: 音声入力によるタスク作成
- **Text-to-speech**: 音声フィードバック

### 4.4 データ・分析（Google Cloud サービス）
- **BigQuery**: 大規模データ分析とレポート生成
- **Cloud Storage**: ファイル保存とバックアップ
- **Dataflow**: リアルタイムデータ処理パイプライン
- **Pub/Sub**: イベント駆動型アーキテクチャ
- **Cloud Scheduler**: 定期タスクとバッチ処理
- **Secret Manager**: API鍵と機密情報の安全な管理

### 4.5 セキュリティ・運用
- **Firebase Security Rules**: データアクセス制御
- **Cloud IAM**: 認証と認可の管理
- **Cloud Logging**: ログ管理と監視
- **Error Reporting**: エラー追跡と分析
- **Firebase Crashlytics**: クラッシュレポート収集
- **Firebase Performance**: パフォーマンス監視

### 4.6 開発・デプロイ
- **Cloud Build**: CI/CDパイプライン
- **Cloud Run**: コンテナ化されたアプリケーション
- **Firebase App Distribution**: テスト配布
- **Cloud Source Repositories**: ソースコード管理
- **Cloud Shell**: クラウドベースの開発環境

## 5. 主要ユースケース

### 5.1 初期セットアップ
1. アプリインストール・起動
2. Googleアカウントでログイン
3. Google Calendarへのアクセス許可
4. 基本的な目標や習慣の初期設定
5. パーソナライズのための質問回答
6. 通知設定カスタマイズ
7. ダッシュボードアクセス取得

### 5.2 日常的なスケジュール管理
1. アプリ起動（自動ログイン）
2. 今日のスケジュールと推奨タスク確認
3. タスクの追加・変更
4. AIによるスケジュール最適化提案確認
5. 提案の承認または調整
6. 更新スケジュールのGoogle Calendar同期

**実装済み機能詳細**
- **タスク一覧表示**: フィルター機能付きのタスクリスト
- **タスク作成**: フォームバリデーション付きダイアログ
- **タスク編集**: 詳細ダイアログでの編集機能
- **タスク完了**: ワンタップでの完了処理
- **タスク削除**: 確認ダイアログ付き削除機能
- **フィルター機能**: 全タスク、今日、完了、保留中、期限切れ
- **統計表示**: 完了率、平均時間、分布分析

### 5.3 サボり防止サポート
1. ユーザーのタスク先延ばしパターン検出
2. タスク前の動機付けメッセージ送信
3. 代替アプローチや細分化ステップの提案
4. ステップごとの即時フィードバック提供
5. タスク完了時の達成感強化通知

### 5.4 目標進捗管理
1. 長期目標設定
2. 達成可能なマイルストーンへの分解
3. 関連タスクのカレンダー自動配置
4. 定期的な進捗レポート生成
5. 目標達成に向けた励ましとフィードバック
6. 必要に応じた計画調整提案

### 5.5 スケジュール危機管理
1. 予期せぬ事態でのスケジュール変更要求
2. 影響を受けるタスクと予定の特定
3. 優先順位に基づく再スケジューリング提案
4. ユーザーによる提案確認・調整
5. 変更スケジュールのカレンダー同期
6. 関係者への通知生成（オプション）

### 5.6 週次振り返りと最適化
1. 週間レポート生成
2. タスク達成・未完了分析表示
3. パターン・傾向の視覚化
4. 翌週のスケジュール最適化提案
5. ユーザーによるフィードバック・調整
6. 次週スケジュール・目標の確定

### 5.7 習慣形成サポート
1. 形成したい習慣の入力
2. 適切な頻度・時間帯の提案
3. 段階的な計画作成
4. 達成記録・マイルストーン報酬設定
5. 習慣完了の確認・記録
6. 習慣定着進捗の視覚化

**実装済み機能詳細**
- **習慣作成ダイアログ**: 横幅最適化（画面幅の90%、最大500px）
- **カテゴリ管理**: 10種類のカテゴリ（個人、健康、仕事、学習、フィットネス、マインドフルネス、社交、財務、創造性、その他）
- **頻度設定**: 9種類の頻度（毎日、1日おき、週2回、週3回、週次、月2回、月次、四半期、年次、カスタム）
- **曜日選択**: 週次頻度での曜日指定機能
- **ステータス管理**: アクティブ・一時停止・終了の3段階
- **取り組み記録**: 日々の完了記録とストリーク管理
- **統計機能**: 習慣数、完了回数、平均ストリーク、カテゴリ分布
- **UI最適化**: カテゴリアイコン、ステータスフィルター、完了状態表示

## 6. システムアーキテクチャと開発計画

### 6.1 アーキテクチャ設計（ハッカソン要件対応）

#### 6.1.1 全体アーキテクチャ概要
```
┌─────────────────────────────────────────────────────────────────┐
│                        WellFin システム構成                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  📱 Flutter モバイルアプリ (Android/iOS)                        │
│  ├── Google Play Store / App Store で配布                      │
│  ├── Firebase App Distribution でテスト配布                    │
│  └── クリーンアーキテクチャ + Riverpod状態管理                  │
│                                                                 │
│  🌐 Flutter Web アプリ (オプション)                             │
│  ├── Firebase Hosting でホスト                                 │
│  └── モバイルアプリと同じコードベース                           │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    Google Cloud バックエンド                    │
│                                                                 │
│  🤖 Cloud Run (AIエージェントAPI)                              │
│  ├── スケジュール最適化エンジン                                 │
│  ├── 自然言語タスク解析API                                      │
│  └── パーソナライゼーションAPI                                  │
│                                                                 │
│  ⚡ Cloud Functions (イベント処理)                              │
│  ├── タスク完了時の分析処理                                      │
│  ├── 通知送信処理                                              │
│  └── データ同期処理                                            │
│                                                                 │
│  🧠 Vertex AI (AI/ML サービス)                                 │
│  ├── Gemini API (自然言語処理)                                  │
│  ├── Vertex AI Agent Builder (AIエージェント)                  │
│  ├── Recommendations AI (推奨システム)                         │
│  └── Vector Search (類似性検索)                                │
│                                                                 │
│  🔥 Firebase (認証・データ・通知)                               │
│  ├── Authentication (Google認証)                               │
│  ├── Firestore (データベース)                                   │
│  ├── Cloud Messaging (プッシュ通知)                             │
│  └── Analytics (ユーザー行動分析)                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 6.1.2 デプロイ戦略の詳細

**📱 Flutterアプリの配布先**
- **Android**: Google Play Store（本番）、Firebase App Distribution（テスト）
- **iOS**: App Store（本番）、TestFlight（テスト）
- **Web**: Firebase Hosting（静的ファイル配信）

**🤖 Cloud Runの役割**
- **AIエージェントAPI**: Flutterアプリから呼び出されるAI推論サービス
- **スケジュール最適化API**: タスクの最適な時間配分を計算
- **自然言語処理API**: ユーザーの自然言語入力を構造化データに変換

**⚡ Cloud Functionsの役割**
- **イベント駆動処理**: Firestoreのデータ変更をトリガーにした自動処理
- **バッチ処理**: 定期的な分析・レポート生成
- **通知処理**: プッシュ通知の送信

#### 6.1.3 技術スタック詳細

**フロントエンド（Flutter）**
- **クリーンアーキテクチャパターン**採用
- **依存性注入フレームワーク**導入（Riverpod）
- **Firebase SDK**統合（認証・データベース・通知）

**バックエンド（Google Cloud）**
- **マイクロサービスアプローチ**（Cloud Run + Cloud Functions）
- **APIゲートウェイパターン**実装
- **イベント駆動型アーキテクチャ**（Pub/Sub）
- **AIファースト設計**（Vertex AI統合）

**データ・分析**
- **Firestore**: リアルタイムデータベース
- **BigQuery**: 大規模データ分析
- **Vertex AI**: 機械学習・AI推論

#### 6.1.4 通信フロー

```
Flutterアプリ → Firebase Auth → Firestore
     ↓
Flutterアプリ → Cloud Run API → Vertex AI
     ↓
Firestore → Cloud Functions → 通知・分析処理
     ↓
Cloud Functions → Firebase Cloud Messaging → プッシュ通知
```

### 6.2 Google Cloud AI技術の活用戦略

#### 6.2.1 Vertex AI Agent Builder
- **スケジュール最適化エージェント**: ユーザーの行動パターンを学習し、最適なスケジュールを提案
- **習慣形成エージェント**: 個人の習慣形成パターンを分析し、効果的な習慣構築をサポート
- **モチベーションエージェント**: ユーザーの気分やエネルギー状態に応じた励ましメッセージを生成

#### 6.2.2 Gemini API in Vertex AI
- **自然言語タスク解析**: ユーザーが自然言語で入力したタスクを構造化データに変換
- **コンテキスト理解**: タスクの文脈を理解し、適切な優先度と時間配分を提案
- **パーソナライズされたアドバイス**: ユーザーの過去の行動データに基づく個別化されたアドバイス生成

#### 6.2.3 Vertex AI Vector Search
- **類似タスク検索**: 過去のタスクと類似性を検索し、効率的なタスク管理を支援
- **ユーザー行動パターン分析**: 類似ユーザーの行動パターンから学習し、改善提案を生成
- **コンテンツベース推奨**: タスクの内容に基づく関連タスクや習慣の推奨

#### 6.2.4 Recommendations AI
- **タスク推奨システム**: ユーザーの好みと行動パターンに基づくタスク推奨
- **時間帯最適化**: 生産性が高い時間帯に重要なタスクを配置する推奨
- **習慣形成推奨**: 成功確率の高い習慣形成パターンの推奨

### 6.3 データベース設計

#### 6.3.1 Firestoreコレクション構造
WellFinは以下のFirestoreコレクション構造を使用します：

**主要コレクション**
- **users**: ユーザープロファイル、設定、統計情報
- **goals**: 中長期的な目標とマイルストーン
- **tasks**: 日々のタスクとスケジュール項目
- **habits**: 習慣形成のための定期的活動
- **calendar**: Google Calendarと同期するイベント

**分析・AI関連コレクション**
- **analytics**: ユーザー行動の分析データ
- **ai_models**: AIパーソナライゼーション用のモデルデータ
- **ai_insights**: Vertex AIから生成されたインサイトと推奨事項
- **vector_embeddings**: タスクとユーザー行動のベクトル表現

**システム・通知コレクション**
- **notifications**: ユーザー通知
- **feedback**: システムからのフィードバックとアドバイス

**データ構造の特徴**
- ユーザーIDをベースにネストされた構造
- 効率的なクエリと堅固なセキュリティ
- リアルタイム同期対応
- スケーラブルな設計

#### 6.3.2 実装済み機能のモデル設計

##### 6.3.2.1 習慣管理モデル（実装済み）

**Habit エンティティ**
```dart
class Habit {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime? endDate;
  final HabitCategory category;
  final HabitFrequency frequency;
  final List<HabitDay> targetDays;
  final TimeOfDay? reminderTime;
  final HabitPriority priority;
  final HabitStatus status;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final List<HabitCompletion> completions;
  final String? goalId;
  final List<String> tags;
  final String color;
  final bool isActive;
  final String? iconName;
  final int targetCount;
  final String? notes;
}
```

**HabitCompletion エンティティ**
```dart
class HabitCompletion {
  final String id;
  final DateTime completedAt;
  final String? notes;
}
```

**習慣カテゴリ（HabitCategory）**
- personal: 個人
- health: 健康
- work: 仕事
- learning: 学習
- fitness: フィットネス
- mindfulness: マインドフルネス
- social: 社交
- financial: 財務
- creative: 創造性
- other: その他

**習慣頻度（HabitFrequency）**
- daily: 毎日
- everyOtherDay: 1日おき
- twiceAWeek: 週2回
- threeTimesAWeek: 週3回
- weekly: 週次（指定曜日）
- twiceAMonth: 月2回
- monthly: 月次
- quarterly: 四半期
- yearly: 年次
- custom: カスタム

**習慣ステータス（HabitStatus）**
- active: アクティブ
- paused: 一時停止
- finished: 終了

**習慣優先度（HabitPriority）**
- low: 低
- medium: 中
- high: 高

**Firestore データ構造**
```json
{
  "users": {
    "userId": {
      "habits": {
        "habitId": {
          "id": "habitId",
          "title": "習慣名",
          "description": "説明",
          "createdAt": "2024-01-01T00:00:00Z",
          "startDate": "2024-01-01T00:00:00Z",
          "category": "health",
          "frequency": "daily",
          "targetDays": ["monday", "wednesday", "friday"],
          "status": "active",
          "currentStreak": 5,
          "longestStreak": 10,
          "totalCompletions": 25,
          "completions": {
            "completionId": {
              "id": "completionId",
              "completedAt": "2024-01-15T10:30:00Z",
              "notes": "メモ"
            }
          },
          "isActive": true,
          "targetCount": 1
        }
      }
    }
  }
}
```

##### 6.3.2.2 タスク管理モデル（実装済み）

**Task エンティティ**
```dart
class Task {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime scheduledDate;
  final DateTime? scheduledTimeStart;
  final DateTime? scheduledTimeEnd;
  final int estimatedDuration;
  final int? actualDuration;
  final DateTime? completedAt;
  final DateTime? reminderTime;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskDifficulty difficulty;
  final String? goalId;
  final String? milestoneId;
  final String? parentTaskId;
  final RepeatRule? repeatRule;
  final TaskLocation? location;
  final String? calendarEventId;
  final List<String> tags;
  final String color;
  final bool isSkippable;
  final double procrastinationRisk;
  final List<SubTask> subTasks;
}
```

**SubTask エンティティ**
```dart
class SubTask {
  final String id;
  final String title;
  final DateTime? completedAt;
}
```

**RepeatRule エンティティ**
```dart
class RepeatRule {
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final int interval;
  final List<int>? daysOfWeek; // 0=日曜日, 1=月曜日, ...
  final int? dayOfMonth; // 1-31
  final DateTime? endDate;
  final int? count;
}
```

**TaskLocation エンティティ**
```dart
class TaskLocation {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
}
```

**タスク優先度（TaskPriority）**
- low: 低（値: 1）
- medium: 中（値: 3）
- high: 高（値: 5）
- urgent: 緊急（値: 7）

**タスクステータス（TaskStatus）**
- pending: 保留中
- inProgress: 進行中
- completed: 完了
- delayed: 遅延

**タスク難易度（TaskDifficulty）**
- easy: 簡単（値: 1）
- medium: 普通（値: 3）
- hard: 困難（値: 5）
- expert: 専門的（値: 7）

**Firestore データ構造**
```json
{
  "users": {
    "userId": {
      "tasks": {
        "taskId": {
          "id": "taskId",
          "title": "タスク名",
          "description": "説明",
          "createdAt": "2024-01-01T00:00:00Z",
          "scheduledDate": "2024-01-15T00:00:00Z",
          "scheduledTimeStart": "2024-01-15T09:00:00Z",
          "scheduledTimeEnd": "2024-01-15T10:00:00Z",
          "estimatedDuration": 60,
          "actualDuration": 45,
          "completedAt": "2024-01-15T09:45:00Z",
          "priority": 5,
          "status": "completed",
          "difficulty": 3,
          "tags": ["仕事", "重要"],
          "color": "#2196F3",
          "isSkippable": false,
          "procrastinationRisk": 0.2,
          "subTasks": [
            {
              "id": "subTaskId",
              "title": "サブタスク",
              "completedAt": "2024-01-15T09:30:00Z"
            }
          ],
          "repeatRule": {
            "frequency": "weekly",
            "interval": 1,
            "daysOfWeek": [1, 3, 5]
          },
          "location": {
            "name": "オフィス",
            "address": "東京都渋谷区...",
            "latitude": 35.6581,
            "longitude": 139.7016
          }
        }
      }
    }
  }
}
```

#### 6.3.3 実装済み機能の詳細

##### 6.3.3.1 習慣管理機能（実装済み）

**主要機能**
1. **習慣の作成・編集・削除**
   - カテゴリ別の習慣管理
   - 頻度設定（毎日、週次、月次など）
   - 曜日指定（週次頻度の場合）
   - 説明とメモ機能

2. **習慣トラッキング**
   - 日々の取り組み記録
   - ストリーク（連続達成日数）管理
   - 完了履歴の保存
   - 今日の完了状態表示

3. **習慣統計・分析**
   - 総習慣数、アクティブ数、一時停止数、終了数
   - 総完了回数と平均ストリーク
   - カテゴリ別分布
   - トップ習慣（ストリーク順）

4. **ステータス管理**
   - アクティブ・一時停止・終了の切り替え
   - フィルター機能
   - ステータス別の表示制御

5. **UI/UX機能**
   - カテゴリ別アイコン表示
   - ステータスバッジ
   - 完了状態の視覚的表示
   - レスポンシブなダイアログ設計

**実装済み機能詳細**
- **習慣作成ダイアログ**: 横幅最適化（画面幅の90%、最大500px）
- **カテゴリ管理**: 10種類のカテゴリ
- **頻度設定**: 9種類の頻度
- **曜日選択**: 週次頻度での曜日指定機能
- **ステータス管理**: アクティブ・一時停止・終了の3段階
- **取り組み記録**: 日々の完了記録とストリーク管理
- **統計機能**: 習慣数、完了回数、平均ストリーク、カテゴリ分布
- **UI最適化**: カテゴリアイコン、ステータスフィルター、完了状態表示

##### 6.3.3.2 タスク管理機能（実装済み）

**主要機能**
1. **タスクの作成・編集・削除**
   - タイトル、説明、日時設定
   - 優先度と難易度の設定
   - 予想時間の設定
   - タグ管理

2. **タスクスケジューリング**
   - 日付と時間の設定
   - 繰り返しルール（毎日、週次、月次、年次）
   - 場所情報の設定
   - リマインダー設定

3. **タスクトラッキング**
   - ステータス管理（保留中、進行中、完了、遅延）
   - 進捗率の計算
   - 実際の所要時間記録
   - サブタスク管理

4. **タスク分析・統計**
   - 完了率の計算
   - 優先度別・難易度別の分布
   - 平均完了時間
   - 先延ばしリスク分析

5. **フィルター・検索機能**
   - ステータス別フィルター
   - 日付別フィルター
   - 優先度別フィルター
   - タグ別フィルター

6. **UI/UX機能**
   - タスクカード表示
   - 優先度・ステータスバッジ
   - 進捗バー表示
   - レスポンシブなダイアログ設計

**実装済み機能詳細**
- **タスク作成ダイアログ**: フォームバリデーション、日時選択、優先度設定
- **タスク詳細ダイアログ**: 全情報表示、編集機能、サブタスク管理
- **タスクカード**: 視覚的な情報表示、クイックアクション
- **フィルターバー**: ステータス別、日付別のフィルタリング
- **統計機能**: 完了率、平均時間、分布分析
- **Firestore連携**: リアルタイム同期、エラーハンドリング

#### 6.3.4 今後の実装予定機能

##### 6.3.4.1 目標管理モデル（実装予定）
- **Goal エンティティ**: 長期目標とマイルストーン
- **Milestone エンティティ**: 中間目標
- **Progress エンティティ**: 進捗記録

##### 6.3.4.2 カレンダー管理モデル（実装予定）
- **CalendarEvent エンティティ**: Google Calendar連携
- **EventRule エンティティ**: イベントルール
- **CalendarSync エンティティ**: 同期状態管理

##### 6.3.4.3 AI分析モデル（実装予定）
- **UserBehavior エンティティ**: ユーザー行動データ
- **AIPrediction エンティティ**: AI予測結果
- **Recommendation エンティティ**: 推奨事項

#### 6.3.5 新機能追加ガイドライン（エージェント作業用）

##### 6.3.5.1 新機能実装時の手順

**1. ドキュメント更新手順**
```
1. 6.3.1 Firestoreコレクション構造に新しいコレクションを追加
2. 6.3.2 実装済み機能のモデル設計に新しいエンティティを追加
3. 6.3.3 実装済み機能の詳細に新しい機能の詳細を追加
4. 6.3.4 今後の実装予定機能から該当項目を削除
5. 6.3.5 アーキテクチャパターンに新しいプロバイダー・リポジトリを追加
```

**2. エンティティ定義のテンプレート**
```dart
// 新しいエンティティの例
class NewFeature {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;
  final NewFeatureStatus status;
  final List<String> tags;
  final String color;
  final bool isActive;
  // 機能固有のフィールド
}
```

**3. Firestore構造のテンプレート**
```json
{
  "users": {
    "userId": {
      "newFeatures": {
        "featureId": {
          "id": "featureId",
          "title": "機能名",
          "description": "説明",
          "createdAt": "2024-01-01T00:00:00Z",
          "updatedAt": "2024-01-01T00:00:00Z",
          "userId": "userId",
          "status": "active",
          "tags": ["タグ1", "タグ2"],
          "color": "#2196F3",
          "isActive": true
        }
      }
    }
  }
}
```

##### 6.3.5.2 実装時のファイル構成

**新しい機能を追加する際のディレクトリ構造**
```
lib/features/new_feature/
├── data/
│   ├── models/
│   │   └── new_feature_model.dart
│   └── repositories/
│       └── firestore_new_feature_repository.dart
├── domain/
│   ├── entities/
│   │   └── new_feature.dart
│   ├── repositories/
│   │   └── new_feature_repository.dart
│   └── usecases/
│       └── new_feature_usecases.dart
└── presentation/
    ├── pages/
    │   └── new_feature_list_page.dart
    ├── providers/
    │   └── new_feature_provider.dart
    └── widgets/
        ├── new_feature_card.dart
        └── add_new_feature_dialog.dart
```

##### 6.3.5.3 実装時の注意事項

**1. クリーンアーキテクチャの遵守**
- Domain層: エンティティ、リポジトリインターフェース、ユースケース
- Data層: リポジトリ実装、データモデル、Firestore連携
- Presentation層: UI、プロバイダー、ページ

**2. Riverpod状態管理の実装**
```dart
// プロバイダーの例
final newFeatureProvider = StateNotifierProvider<NewFeatureNotifier, AsyncValue<List<NewFeature>>>((ref) {
  final repository = ref.watch(newFeatureRepositoryProvider);
  return NewFeatureNotifier(repository);
});
```

**3. エラーハンドリング**
- Either型を使用した結果管理
- ユーザーフレンドリーなエラーメッセージ
- オフライン対応の考慮

**4. UI/UX設計原則**
- レスポンシブデザイン
- アクセシビリティ対応
- 一貫したデザインシステム
- ダイアログの横幅最適化（画面幅の90%、最大500px）

##### 6.3.5.4 テスト実装ガイドライン

**1. ユニットテスト**
- エンティティのテスト
- リポジトリのテスト
- ユースケースのテスト

**2. ウィジェットテスト**
- ページのテスト
- ダイアログのテスト
- カードのテスト

**3. 統合テスト**
- Firestore連携のテスト
- プロバイダーのテスト

##### 6.3.5.5 ドキュメント更新チェックリスト

**実装完了後の確認項目**
- [ ] エンティティ定義が6.3.2に追加されている
- [ ] Firestore構造が6.3.2に記載されている
- [ ] 機能詳細が6.3.3に追加されている
- [ ] 実装予定機能から該当項目が削除されている
- [ ] アーキテクチャパターンに新しいコンポーネントが追加されている
- [ ] コレクション構造に新しいコレクションが追加されている

##### 6.3.5.6 命名規則

**ファイル名**
- エンティティ: `snake_case.dart`
- モデル: `snake_case_model.dart`
- リポジトリ: `firestore_snake_case_repository.dart`
- プロバイダー: `snake_case_provider.dart`
- ページ: `snake_case_page.dart`
- ウィジェット: `snake_case_widget.dart`

**クラス名**
- エンティティ: `PascalCase`
- モデル: `PascalCaseModel`
- リポジトリ: `FirestorePascalCaseRepository`
- プロバイダー: `PascalCaseProvider`
- ページ: `PascalCasePage`
- ウィジェット: `PascalCaseWidget`

##### 6.3.5.7 実装順序の推奨

**1. ドメイン層の実装**
```
1. エンティティの定義
2. リポジトリインターフェースの定義
3. ユースケースの実装
```

**2. データ層の実装**
```
1. データモデルの実装
2. Firestoreリポジトリの実装
3. エラーハンドリングの実装
```

**3. プレゼンテーション層の実装**
```
1. プロバイダーの実装
2. ページの実装
3. ウィジェットの実装
4. UI/UXの最適化
```

**4. テストの実装**
```
1. ユニットテスト
2. ウィジェットテスト
3. 統合テスト
```

**5. ドキュメントの更新**
```
1. servise.mdの更新
2. README.mdの更新
3. コメントの追加
```

#### 6.3.6 アーキテクチャパターン（実装済み）

**クリーンアーキテクチャ**
- **Domain Layer**: エンティティ、リポジトリインターフェース、ユースケース
- **Data Layer**: リポジトリ実装、データモデル、Firestore連携
- **Presentation Layer**: UI、プロバイダー、ページ

**状態管理（Riverpod）**
- **HabitProvider**: 習慣データの状態管理
- **TaskProvider**: タスクデータの状態管理
- **非同期処理**: データ取得、作成、更新、削除
- **リアルタイム更新**: Firestoreリスナーによる自動更新

**リポジトリパターン**
- **HabitRepository**: 習慣データアクセスの抽象化
- **FirestoreHabitRepository**: Firestore実装
- **TaskRepository**: タスクデータアクセスの抽象化
- **FirestoreTaskRepository**: Firestore実装
- **エラーハンドリング**: Either型による結果管理

**実装済み機能**
- **習慣管理**: カテゴリ別管理、頻度設定、ストリーク管理、統計機能
- **タスク管理**: 優先度・難易度設定、スケジューリング、サブタスク管理、分析機能
- **Firestore連携**: リアルタイム同期、エラーハンドリング、データ永続化
- **UI/UX**: レスポンシブデザイン、フィルター機能、統計表示

### 6.4 セキュリティ設計
