# 第2部：システム設計・アーキテクチャ

## 📋 ファイルの役割
このファイルは、WellFinアプリケーションのデータベース設計、システムアーキテクチャ、Google Cloud AI技術の活用戦略を記載する設計書です。
アプリケーションの基盤となるデータ構造とシステム設計を管理します。

## 5. デザインシステム・カラー定義

### 5.1 基本カラーパレット

WellFinアプリケーションでは、以下のカラーパレットを統一して使用します：

**基本カラー**
- **青色 (Colors.blue)**: アプリの基本カラー、AppBar、進捗バー、設定アイコンなど

**機能別カラー**
- **緑色 (Colors.green)**: タスク管理機能
- **オレンジ色 (Colors.orange)**: 習慣管理機能  
- **紫色 (Colors.purple)**: 目標管理機能

### 5.2 カラー使用ガイドライン

**UI要素別のカラー適用**
- **AppBar**: 青色（基本カラー）
- **進捗バー**: 青色（基本カラー）
- **タスク関連**: 緑色（タスクカラー）
- **習慣関連**: オレンジ色（習慣カラー）
- **目標関連**: 紫色（目標カラー）
- **設定アイコン**: 青色（基本カラー）

**アクセシビリティ考慮**
- カラーのみに依存しない情報伝達
- 十分なコントラスト比の確保
- 色覚異常への配慮

### 5.3 実装例

```dart
// 基本カラー
backgroundColor: Colors.blue

// 機能別カラー
taskColor: Colors.green
habitColor: Colors.orange  
goalColor: Colors.purple

// 進捗バー
LinearProgressIndicator(
  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
)
```

## 6. データベース設計

### 6.1 Firestoreコレクション構造
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

### 6.2 実装済み機能のモデル設計

#### 6.2.1 習慣管理モデル（実装済み）

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
- critical: 最重要

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

#### 6.2.2 タスク管理モデル（実装済み・2025年6月現在最新）

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
  final String? placeId;
}
```

**タスク優先度（TaskPriority）**
- low: 低
- medium: 中
- high: 高
- urgent: 緊急

**タスク難易度（TaskDifficulty）**
- easy: 簡単
- normal: 普通
- hard: 困難
- expert: 専門的

**タスクステータス（TaskStatus）**
- pending: 保留中
- in_progress: 進行中
- completed: 完了
- overdue: 遅延

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
          "priority": "high",
          "status": "pending",
          "difficulty": "normal",
          "subTasks": {
            "subTaskId": {
              "id": "subTaskId",
              "title": "サブタスク名",
              "completedAt": null
            }
          },
          "tags": ["work", "important"],
          "color": "#FF6B6B"
        }
      }
    }
  }
}
```

#### 6.2.3 目標管理モデル（実装済み・2025年6月29日最新）

**Goal エンティティ**
```dart
class Goal {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime targetDate;
  final GoalCategory category;
  final GoalPriority priority;
  final GoalStatus status;
  final GoalType type;
  final double progress; // 0.0 - 1.0
  final double? targetValue;
  final String? unit;
  final String color;
  final List<Milestone> milestones;
  final List<GoalProgress> progressHistory;
  final List<String> tags;
  final String? iconName;
  final String? notes;
  final bool isArchived;
}
```

**Milestone エンティティ**
```dart
class Milestone {
  final String id;
  final String title;
  final String? description;
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final double? targetValue;
  final String? unit;
  final int order;
}
```

**GoalProgress エンティティ**
```dart
class GoalProgress {
  final String id;
  final DateTime date;
  final double progress; // 0.0 - 1.0
  final double? currentValue;
  final String? notes;
  final DateTime createdAt;
}
```

**目標カテゴリ（GoalCategory）**
- personal: 個人
- health: 健康
- career: 仕事
- learning: 学習
- fitness: フィットネス
- financial: 財務
- creative: 創造性
- other: その他

**目標優先度（GoalPriority）**
- low: 低
- medium: 中
- high: 高
- critical: 最重要

**目標ステータス（GoalStatus）**
- active: アクティブ
- paused: 一時停止
- completed: 完了
- cancelled: キャンセル
- overdue: 期限切れ

**目標タイプ（GoalType）**
- general: 一般目標
- numeric: 数値目標
- milestone: マイルストーン型

**Firestore データ構造**
```json
{
  "users": {
    "userId": {
      "goals": {
        "goalId": {
          "id": "goalId",
          "title": "目標名",
          "description": "説明",
          "createdAt": "2024-01-01T00:00:00Z",
          "startDate": "2024-01-01T00:00:00Z",
          "targetDate": "2024-12-31T00:00:00Z",
          "category": "fitness",
          "priority": "high",
          "status": "active",
          "type": "numeric",
          "progress": 0.3,
          "targetValue": 10.0,
          "unit": "kg",
          "color": "#9C27B0",
          "milestones": {
            "milestoneId": {
              "id": "milestoneId",
              "title": "マイルストーン名",
              "targetDate": "2024-06-30T00:00:00Z",
              "isCompleted": false,
              "targetValue": 5.0,
              "order": 1
            }
          },
          "progressHistory": {
            "progressId": {
              "id": "progressId",
              "date": "2024-06-15T00:00:00Z",
              "progress": 0.3,
              "currentValue": 3.0,
              "notes": "進捗メモ"
            }
          },
          "tags": ["健康", "フィットネス"],
          "isArchived": false
        }
      }
    }
  }
}
```

### 6.3 システムアーキテクチャと開発計画

#### 6.3.1 実装済みアーキテクチャ（2025年6月29日現在）

**完全実装済み機能**
- ✅ AI Agent機能: Cloud Run Functions API統合
- ✅ 目標管理機能: 完全なUI/UX実装  
- ✅ Infrastructure as Code: Terraform 100%自動化
- ✅ セキュリティ強化: 機密情報保護・環境変数管理

**クリーンアーキテクチャ実装**
```
lib/
├── core/                    # 共通機能
│   ├── config/             # 設定ファイル
│   ├── constants/          # 定数定義  
│   ├── errors/             # エラーハンドリング
│   ├── network/            # ネットワーク層
│   └── utils/              # ユーティリティ
├── features/               # 機能別モジュール
│   ├── auth/              # 認証機能 ✅ (7.7KB, 206行)
│   │   ├── data/          # データ層
│   │   ├── domain/        # ドメイン層
│   │   └── presentation/  # プレゼンテーション層
│   ├── habits/            # 習慣管理 ✅ (52KB, 1427行)
│   ├── tasks/             # タスク管理 ✅ (9KB + 5ウィジェット)
│   ├── goals/             # 目標管理 ✅ (12KB + 5ウィジェット)
│   ├── ai_agent/          # AIエージェント ✅ (12KB, 366行)
│   ├── calendar/          # カレンダー機能 ❌ (未実装)
│   └── analytics/         # 分析機能 ❌ (未実装)
├── shared/                # 共有コンポーネント
│   ├── models/            # 共有モデル
│   ├── providers/         # 状態管理 ✅ (Riverpod完全実装)
│   ├── services/          # 共有サービス ✅ (AI Agent含む)
│   └── widgets/           # 共有ウィジェット
└── functions/             # Cloud Run Functions API ✅
    ├── src/index.js       # メインエントリーポイント (534行)
    ├── services/          # AI Service (Vertex AI Gemini統合)
    └── routes/            # 5つのAPIエンドポイント
```

#### 6.3.2 Cloud Run Functions API アーキテクチャ（実装済み）

**API エンドポイント構成**
```
https://asia-northeast1-[YOUR-GCP-PROJECT-ID].cloudfunctions.net/wellfin-ai-function/

├── /health                    # ヘルスチェック
├── /api/v1/vertex-ai-test    # Vertex AI接続テスト
├── /api/v1/analyze-task      # タスク分析
├── /api/v1/optimize-schedule # スケジュール最適化
└── /api/v1/recommendations   # パーソナライズ推奨
```

**技術スタック**
- **Runtime**: Node.js 22 LTS
- **Framework**: @google-cloud/functions-framework@4.0.0
- **AI統合**: Vertex AI Gemini Pro
- **認証**: APIキー認証
- **デプロイ**: Cloud Run Functions Gen2

**AI機能統合アーキテクチャ**
```
┌─────────────────────────────────────────────────────────────┐
│                Flutter App (Frontend) ✅                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Dashboard  │  │   Goals     │  │  AI Agent   │         │
│  │  (99KB)     │  │ Management  │  │  Test Page  │         │
│  │             │  │ (12KB+5widgets) │  (12KB)     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                 Flutter Services Layer ✅                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Auth        │  │ AI Agent    │  │ Goal        │         │
│  │ Service     │  │ Service     │  │ Provider    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│               Cloud Run Functions API ✅                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Health      │  │ Task        │  │ Schedule    │         │
│  │ Check       │  │ Analysis    │  │ Optimize    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                Vertex AI Services ✅                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Gemini Pro  │  │ Natural     │  │ Vector      │         │
│  │ API         │  │ Language    │  │ Search      │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│            Infrastructure as Code (Terraform) ✅            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ main.tf     │  │ IAM Roles   │  │ Secret      │         │
│  │ (136行)     │  │ API Keys    │  │ Manager     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

#### 6.3.3 セキュリティアーキテクチャ（実装済み）

**機密情報管理**
```
┌─────────────────────────────────────────────────────────────┐
│                    Git Repository (Public) ✅               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ 機密情報除外: .gitignore設定済み                        │ │
│  │ - config/development/api-config.json ❌ (Git管理外)    │ │
│  │ - terraform/terraform.tfvars ❌ (Git管理外)           │ │
│  │ - プレースホルダー使用: [YOUR-GCP-PROJECT-ID]         │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                ローカル開発環境 (Secure) ✅                 │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ config/development/api-config.json                     │ │
│  │ {                                                     │ │
│  │   "apiKey": "[ACTUAL-API-KEY]",                      │ │
│  │   "apiUrl": "https://...[ACTUAL-PROJECT-ID]...",     │ │
│  │   "version": "0.3.0"                                 │ │
│  │ }                                                     │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              ビルドプロセス (Automated) ✅                  │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ scripts/flutter-build.bat                              │ │
│  │ ↓                                                     │ │
│  │ 1. api-config.json読み込み                            │ │
│  │ 2. 環境変数設定: WELLFIN_API_KEY, WELLFIN_API_URL     │ │
│  │ 3. flutter build --dart-define=...                   │ │
│  │ 4. セキュアなAPKビルド完了                             │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Infrastructure as Code 構成**
```
terraform/ ✅
├── main.tf (136行)          # GCPリソース100%管理
│   ├── Cloud Run Functions  # AI API ホスティング
│   ├── IAM Roles           # aiplatform.admin 権限
│   ├── Secret Manager      # APIキー管理
│   └── Vertex AI APIs      # AI機能有効化
├── variables.tf            # 変数定義
├── outputs.tf              # 出力値定義
├── providers.tf            # GCPプロバイダー設定
└── terraform.tfvars ❌     # 実際の設定値 (Git管理外)
```

#### 6.3.4 Google Cloud AI技術の活用戦略

**Vertex AI統合アーキテクチャ**
```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Frontend)                   │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Auth      │  │  Dashboard  │  │   Tasks     │         │
│  │  Service    │  │   Widgets   │  │  Management │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                    Firebase Services                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Auth      │  │  Firestore  │  │     FCM     │         │
│  │             │  │             │  │             │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                  Google Cloud AI Services                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Vertex AI   │  │   Gemini    │  │ Natural     │         │
│  │ Agent       │  │    API      │  │ Language    │         │
│  │ Builder     │  │             │  │     AI      │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Vector      │  │Recommendation│  │ AutoML      │         │
│  │ Search      │  │     AI      │  │             │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                  Cloud Infrastructure                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Cloud Run   │  │ Cloud       │  │ Cloud       │         │
│  │             │  │ Functions   │  │ Storage     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

**AI機能統合戦略**

1. **Vertex AI Agent Builder**
   - インテリジェントなスケジュール最適化エージェント
   - ユーザー行動パターンの学習と分析
   - パーソナライズされた推奨システム

2. **Gemini API in Vertex AI**
   - 自然言語でのタスク入力と理解
   - コンテキスト認識型の提案生成
   - 感情分析によるモチベーション管理

3. **Vertex AI Vector Search**
   - ユーザー行動パターンの類似性検索
   - タスクと習慣の関連性分析
   - 最適な時間帯の推薦

4. **Recommendations AI**
   - パーソナライズされたタスク推奨
   - 時間帯別の最適化提案
   - 習慣形成の成功率向上

5. **Natural Language AI**
   - タスク記述の感情分析
   - 重要度の自動判定
   - 優先順位の最適化

**データフロー設計**
```
ユーザーアクション → Firebase → Cloud Functions → Vertex AI → 分析結果 → Firestore → UI更新
```

**セキュリティ設計**
- Firebase Security Rulesによるデータアクセス制御
- Cloud IAMによるサービス間認証
- Secret ManagerによるAPI鍵管理
- データ暗号化（転送中・保存時）

**スケーラビリティ設計**
- Cloud Runによる自動スケーリング
- Firestoreのリアルタイム同期
- Cloud Functionsのイベント駆動処理
- BigQueryによる大規模データ分析

---

*最終更新: 2025年6月29日 - AI Agent機能・Infrastructure as Code実装完了* 