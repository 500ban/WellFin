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

## 6. システムアーキテクチャと開発計画

### 6.1 アーキテクチャ設計（ハッカソン要件対応）
- **クリーンアーキテクチャパターン**採用
- **依存性注入フレームワーク**導入（GetIt/Riverpod）
- **マイクロサービスアプローチ**（Cloud Run + Cloud Functions）
- **APIゲートウェイパターン**実装
- **イベント駆動型アーキテクチャ**（Pub/Sub）
- **AIファースト設計**（Vertex AI統合）

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
WellFinは以下のFirestoreコレクション構造を使用します：

- **users**: ユーザープロファイル、設定、統計情報
- **goals**: 中長期的な目標とマイルストーン
- **tasks**: 日々のタスクとスケジュール項目
- **habits**: 習慣形成のための定期的活動
- **calendar**: Google Calendarと同期するイベント
- **analytics**: ユーザー行動の分析データ
- **ai_models**: AIパーソナライゼーション用のモデルデータ
- **notifications**: ユーザー通知
- **feedback**: システムからのフィードバックとアドバイス
- **ai_insights**: Vertex AIから生成されたインサイトと推奨事項
- **vector_embeddings**: タスクとユーザー行動のベクトル表現

コレクションはユーザーIDをベースにネストされた構造をとり、効率的なクエリと堅固なセキュリティを実現します。

### 6.4 セキュリティ設計
- **Firebaseセキュリティルール**によるアクセス制御
- **Secret Manager**によるAPI鍵管理
- **Cloud IAM**による認証と認可の管理
- **データ暗号化**（HTTPS, JWT）
- **ユーザー認証と権限管理**

### 6.5 データ同期戦略
- **リアルタイム同期**（重要データ）
- **バッチ同期**（分析データ、履歴）
- **オフラインサポート**とローカルキャッシュ
- **競合解決メカニズム**
- **Vertex AI**とのデータ同期

### 6.6 CI/CD・運用体制（ハッカソン要件対応）
- **Cloud Build**でCI/CDパイプライン構築
- **Cloud Run**でのコンテナ化デプロイ
- **Firebase Crashlytics**によるクラッシュレポート収集
- **Firebase Performance**によるモニタリング
- **Cloud Logging**とError Reporting実装
- **Firebase App Distribution**によるテスト配布
- **Cloud Monitoring**によるシステム監視

# WellFin - Firebaseデータベース設計

## 1. データベース概要

WellFinアプリケーションは、Cloud Firestoreを主要なデータストアとして使用します。Firestoreは柔軟なNoSQLデータベースであり、スケーラビリティが高く、リアルタイム同期と強力なオフラインサポートを提供します。

## 2. コレクション構造

### 2.1 `users`
ユーザー情報を格納する主要コレクション

```javascript
users/{userId}
```

**フィールド：**
```javascript
{
  uid: String,                  // Firebase Auth UID（Google認証から）
  email: String,                // ユーザーのメールアドレス
  displayName: String,          // 表示名
  photoURL: String,             // プロフィール画像URL
  createdAt: Timestamp,         // アカウント作成日時
  lastLogin: Timestamp,         // 最終ログイン日時
  timeZone: String,             // ユーザーのタイムゾーン（例："Asia/Tokyo"）
  preferences: {                // ユーザー設定
    language: String,           // UI言語設定（"ja" or "en"）
    theme: String,              // UIテーマ（"light", "dark", "system"）
    notificationChannels: {     // 通知設定
      app: Boolean,             // アプリ内通知
      push: Boolean,            // プッシュ通知
      email: Boolean            // メール通知
    },
    productivityPeakHours: [Number],  // 生産性が高い時間帯（0-23）
    weekStartDay: Number        // 週の開始日（0=日曜日, 1=月曜日...）
  },
  calendarSync: {               // カレンダー同期情報
    googleCalendarId: String,   // プライマリGoogle CalendarのID
    lastSyncTime: Timestamp,    // 最終同期時刻
    syncedCalendars: [String]   // 同期済みカレンダーIDリスト
  },
  stats: {                      // 統計情報
    completedTasks: Number,     // 完了タスク数
    completionRate: Number,     // タスク完了率（%）
    streakDays: Number,         // 連続達成日数
    totalGoalsCompleted: Number // 達成した合計目標数
  }
}
```

### 2.2 `goals`
ユーザーの中長期目標

```javascript
users/{userId}/goals/{goalId}
```

**フィールド：**
```javascript
{
  title: String,                // 目標タイトル
  description: String,          // 詳細説明
  category: String,             // カテゴリ（"health", "career", "personal" など）
  createdAt: Timestamp,         // 作成日時
  targetDate: Timestamp,        // 目標期日
  completedAt: Timestamp,       // 完了日時（nullの場合は未完了）
  progress: Number,             // 進捗率（0-100%）
  priority: Number,             // 優先度（1-5）
  status: String,               // ステータス（"active", "completed", "abandoned"）
  milestones: [{                // マイルストーンリスト
    id: String,                 // マイルストーンID
    title: String,              // マイルストーンタイトル
    dueDate: Timestamp,         // 期日
    completedAt: Timestamp,     // 完了日時（nullの場合は未完了）
    status: String              // ステータス
  }],
  recurringTaskIds: [String],   // 関連する定期タスクID
  tags: [String],               // タグリスト
  color: String,                // 表示色（HEXコード）
  icon: String                  // アイコン識別子
}
```

### 2.3 `tasks`
日々のタスクやToDo項目

```javascript
users/{userId}/tasks/{taskId}
```

**フィールド：**
```javascript
{
  title: String,                // タスクタイトル
  description: String,          // 詳細説明
  createdAt: Timestamp,         // 作成日時
  scheduledDate: Timestamp,     // 予定日
  scheduledTimeStart: Timestamp, // 開始予定時刻
  scheduledTimeEnd: Timestamp,  // 終了予定時刻
  estimatedDuration: Number,    // 予想所要時間（分）
  actualDuration: Number,       // 実際の所要時間（分）
  completedAt: Timestamp,       // 完了日時（nullの場合は未完了）
  reminderTime: Timestamp,      // リマインダー時刻
  priority: Number,             // 優先度（1-5）
  status: String,               // ステータス（"pending", "in_progress", "completed", "delayed"）
  difficulty: Number,           // 難易度（1-5）
  goalId: String,               // 関連する目標ID（nullの場合は独立タスク）
  milestoneId: String,          // 関連するマイルストーンID
  parentTaskId: String,         // 親タスクID（サブタスクの場合）
  repeatRule: {                 // 繰り返しルール（nullの場合は単発タスク）
    frequency: String,          // "daily", "weekly", "monthly", "yearly"
    interval: Number,           // 間隔（毎週=1, 隔週=2など）
    daysOfWeek: [Number],       // 曜日（0=日曜日, 1=月曜日...）[週次の場合]
    dayOfMonth: Number,         // 日付（1-31）[月次の場合]
    endDate: Timestamp,         // 繰り返し終了日
    count: Number               // 繰り返し回数
  },
  location: {                   // 関連する場所情報
    name: String,               // 場所名
    address: String,            // 住所
    coordinates: GeoPoint       // 緯度経度
  },
  calendarEventId: String,      // 同期されたGoogleカレンダーイベントID
  tags: [String],               // タグリスト
  color: String,                // 表示色（HEXコード）
  isSkippable: Boolean,         // スキップ可能か
  procrastinationRisk: Number,  // 先延ばしリスク（AIによる予測、0-100%）
  subTasks: [{                  // サブタスクリスト（小さいサブタスクの場合のみ）
    id: String,                 // サブタスクID
    title: String,              // サブタスクタイトル
    completedAt: Timestamp      // 完了日時（nullの場合は未完了）
  }]
}
```

### 2.4 `habits`
習慣形成のための定期的なアクティビティ

```javascript
users/{userId}/habits/{habitId}
```

**フィールド：**
```javascript
{
  title: String,                // 習慣タイトル
  description: String,          // 詳細説明
  createdAt: Timestamp,         // 作成日時
  category: String,             // カテゴリ（"health", "learning" など）
  frequency: {                  // 頻度設定
    type: String,               // "daily", "weekly", "monthly"
    timesPerPeriod: Number,     // 期間あたりの回数
    daysOfWeek: [Number],       // 曜日（0=日曜日, 1=月曜日...）
    specificDays: [Number]      // 特定の日（1-31）
  },
  timeOfDay: {                  // 実行時間帯
    preferredTimeStart: String, // 好ましい開始時間（"HH:MM"形式）
    preferredTimeEnd: String,   // 好ましい終了時間（"HH:MM"形式）
    duration: Number            // 予想所要時間（分）
  },
  streak: {                     // 継続記録
    current: Number,            // 現在の連続日数
    longest: Number,            // 最長連続日数
    lastCompleted: Timestamp    // 最終完了日時
  },
  goalId: String,               // 関連する目標ID
  progressionStages: [{         // 段階的難易度設定
    stageNumber: Number,        // ステージ番号
    description: String,        // ステージ説明
    targetCount: Number,        // 目標回数
    active: Boolean             // 現在アクティブなステージか
  }],
  reminderSettings: {           // リマインダー設定
    enabled: Boolean,           // リマインダー有効フラグ
    timeOffset: Number,         // 時間オフセット（分）
    smartTiming: Boolean        // AI最適化タイミング使用フラグ
  },
  trackedMetric: {              // 測定する指標（オプション）
    type: String,               // "count", "duration", "boolean"
    unit: String,               // 単位（"回", "分" など）
    target: Number              // 目標値
  },
  skipHistory: [Timestamp],     // スキップした日付履歴
  completionHistory: [{         // 完了履歴
    date: Timestamp,            // 完了日
    value: Number,              // 達成値（該当する場合）
    notes: String               // メモ
  }]
}
```

### 2.5 `calendar`
カレンダーイベント（Google Calendarと同期）

```javascript
users/{userId}/calendar/{eventId}
```

**フィールド：**
```javascript
{
  title: String,                // イベントタイトル
  description: String,          // 詳細説明
  startTime: Timestamp,         // 開始時刻
  endTime: Timestamp,           // 終了時刻
  allDay: Boolean,              // 終日イベントフラグ
  location: String,             // 場所
  calendarId: String,           // 元のGoogleカレンダーID
  googleEventId: String,        // GoogleカレンダーのイベントID
  recurrence: String,           // 繰り返しルール（RFC5545形式）
  attendees: [{                 // 参加者リスト
    email: String,              // メールアドレス
    name: String,               // 名前
    status: String              // 参加ステータス
  }],
  reminders: [{                 // リマインダーリスト
    method: String,             // 通知方法
    minutes: Number             // イベント前の通知時間（分）
  }],
  color: String,                // 表示色
  taskId: String,               // 関連するタスクID（存在する場合）
  isReadOnly: Boolean,          // 読み取り専用フラグ
  lastSynced: Timestamp         // 最終同期時刻
}
```

### 2.6 `analytics`
ユーザー行動分析データ

```javascript
users/{userId}/analytics/{dateId}
```

**フィールド：**
```javascript
{
  date: Timestamp,              // 日付
  taskCompletion: {             // タスク完了統計
    completed: Number,          // 完了タスク数
    delayed: Number,            // 遅延タスク数
    abandoned: Number,          // 放棄タスク数
    completionRate: Number,     // 完了率（%）
    byPriority: {               // 優先度別完了率
      1: Number,                // 優先度1の完了率
      2: Number,                // 優先度2の完了率
      // ...
    },
    byTimeOfDay: [{             // 時間帯別完了タスク数
      hour: Number,             // 時間（0-23）
      count: Number             // 完了数
    }]
  },
  habitCompletion: {            // 習慣完了統計
    completed: Number,          // 完了習慣数
    missed: Number,             // 未達成習慣数
    completionRate: Number      // 完了率（%）
  },
  timeAllocation: [{            // 時間配分統計
    category: String,           // カテゴリ
    plannedMinutes: Number,     // 計画時間（分）
    actualMinutes: Number       // 実際の時間（分）
  }],
  productivity: {               // 生産性統計
    focusTimeMinutes: Number,   // 集中時間（分）
    procrastinationTimeMinutes: Number, // 先延ばし時間（分）
    productivityScore: Number   // 生産性スコア（0-100）
  },
  mood: Number,                 // 気分スコア（1-5）
  energy: Number,               // エネルギーレベル（1-5）
  notes: String                 // 日記/メモ
}
```

### 2.7 `ai_models`
AIパーソナライゼーション用のモデルデータ

```javascript
users/{userId}/ai_models/{modelId}
```

**フィールド：**
```javascript
{
  modelType: String,            // モデルタイプ（"taskPrediction", "habitSuccess", "focus"）
  createdAt: Timestamp,         // 作成日時
  lastUpdated: Timestamp,       // 最終更新日時
  version: Number,              // モデルバージョン
  parameters: {                 // モデルパラメータ（モデル固有）
    // モデル固有のパラメータ
  },
  performanceMetrics: {         // パフォーマンス指標
    accuracy: Number,           // 精度
    recall: Number,             // 再現率
    precision: Number           // 適合率
  },
  features: [String],           // 使用特徴量リスト
  insights: [{                  // 生成されたインサイト
    type: String,               // インサイトタイプ
    description: String,        // 説明
    confidence: Number,         // 信頼度
    generatedAt: Timestamp      // 生成日時
  }]
}
```

### 2.8 `notifications`
ユーザー通知

```javascript
users/{userId}/notifications/{notificationId}
```

**フィールド：**
```javascript
{
  createdAt: Timestamp,         // 作成日時
  title: String,                // 通知タイトル
  body: String,                 // 通知本文
  type: String,                 // 通知タイプ（"task", "habit", "goal", "system"）
  priority: Number,             // 優先度（1-5）
  read: Boolean,                // 既読フラグ
  readAt: Timestamp,            // 既読日時
  deliveryStatus: String,       // 配信ステータス（"pending", "delivered", "failed"）
  deliveredAt: Timestamp,       // 配信日時
  action: {                     // アクション情報
    type: String,               // アクションタイプ（"open_task", "complete_habit" など）
    data: Map                   // アクション固有データ
  },
  relatedItemId: String,        // 関連するアイテムID（タスク、習慣など）
  expiresAt: Timestamp          // 有効期限
}
```

### 2.9 `feedback`
システムからのフィードバックとアドバイス

```javascript
users/{userId}/feedback/{feedbackId}
```

**フィールド：**
```javascript
{
  createdAt: Timestamp,         // 作成日時
  type: String,                 // フィードバックタイプ（"suggestion", "insight", "warning"）
  title: String,                // タイトル
  content: String,              // コンテンツ
  context: {                    // コンテキスト情報
    source: String,             // 発生源（"task_analysis", "habit_tracking" など）
    relatedItemIds: [String]    // 関連アイテムID
  },
  importance: Number,           // 重要度（1-5）
  viewed: Boolean,              // 閲覧済フラグ
  viewedAt: Timestamp,          // 閲覧日時
  actionTaken: Boolean,         // アクション実行フラグ
  actionResult: String,         // アクション結果
  validUntil: Timestamp         // 有効期限
}
```

## 3. インデックス定義

効率的なクエリのために必要なインデックス定義：

```javascript
// タスク検索用インデックス
collection('users/{userId}/tasks') {
  fields(status, scheduledDate, ASC)
  fields(priority, DESC, scheduledDate, ASC)
  fields(goalId, scheduledDate, ASC)
}

// 習慣検索用インデックス
collection('users/{userId}/habits') {
  fields('frequency.type', 'frequency.daysOfWeek')
  fields('streak.current', DESC)
  fields('category', 'streak.current', DESC)
}

// カレンダーイベント検索用インデックス
collection('users/{userId}/calendar') {
  fields(startTime, ASC)
  fields(calendarId, startTime, ASC)
}

// 通知検索用インデックス
collection('users/{userId}/notifications') {
  fields(read, createdAt, DESC)
  fields(priority, createdAt, DESC)
}
```

## 4. セキュリティルール

Firebaseのセキュリティルール例：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは自分のデータのみアクセス可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // ネストされたコレクションも同様
      match /{collection}/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // 管理者アクセス（実際の実装ではさらに制限が必要）
    match /admin/{docId} {
      allow read, write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```

## 5. データアクセスパターン

主要なアクセスパターンに基づいた効率的なクエリ例：

### 5.1 本日のタスク取得
```javascript
db.collection('users').doc(userId)
  .collection('tasks')
  .where('scheduledDate', '>=', todayStart)
  .where('scheduledDate', '<=', todayEnd)
  .where('status', 'in', ['pending', 'in_progress'])
  .orderBy('scheduledTimeStart', 'asc')
  .get()
```

### 5.2 特定の目標に関連するタスク取得
```javascript
db.collection('users').doc(userId)
  .collection('tasks')
  .where('goalId', '==', goalId)
  .orderBy('scheduledDate', 'asc')
  .get()
```

### 5.3 本日の習慣取得
```javascript
// 日次習慣の場合
db.collection('users').doc(userId)
  .collection('habits')
  .where('frequency.type', '==', 'daily')
  .get()

// 週次習慣の場合（本日の曜日に該当）
db.collection('users').doc(userId)
  .collection('habits')
  .where('frequency.type', '==', 'weekly')
  .where('frequency.daysOfWeek', 'array-contains', todayDayOfWeek)
  .get()
```

### 5.4 未読通知取得
```javascript
db.collection('users').doc(userId)
  .collection('notifications')
  .where('read', '==', false)
  .orderBy('createdAt', 'desc')
  .limit(20)
  .get()
```

## 6. データ同期戦略

1. **リアルタイム同期**
   - ユーザープロファイル
   - 今日のタスク
   - 未読通知
   - 進行中の習慣

2. **バッチ同期**
   - 履歴データ
   - 分析レポート
   - 過去のタスク

3. **オフラインサポート**
   - Firebase Firestoreの自動オフラインキャッシュを有効化
   - ローカルデータの一時保存と競合解決戦略の実装

## 7. データ移行とバックアップ戦略

1. **バックアップ**
   - Firestoreの定期的なエクスポート
   - Cloud Functionsを使用した重要データの定期バックアップ

2. **データ移行**
   - スキーマバージョン管理
   - マイグレーションスクリプト
   - ダウンタイムなしの移行戦略

3. **データアーカイブ**
   - 古いデータの自動アーカイブ
   - ストレージコスト最適化

## 8. 注意点とベストプラクティス

1. **データサイズの最適化**
   - 不必要なデータのネストを避ける
   - サブコレクションの適切な使用

2. **クエリパフォーマンス**
   - 複合クエリに必要なインデックスの作成
   - ページネーションの実装（大量データの取得時）

3. **セキュリティ**
   - 適切な認証とアクセス制御
   - センシティブなデータの暗号化

4. **コスト管理**
   - リード/ライト操作の最適化
   - インデックス数の管理
   - 不要なリアルタイムリスナーの回避