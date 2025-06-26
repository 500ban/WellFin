# WellFin - AI Agent Flutterアプリ

## 📋 プロジェクト概要
**WellFin**は、Flutter × Firebase × Google Cloud AI技術を活用した生産性向上アプリです。  
AIエージェント機能、タスク管理、習慣管理、目標管理などの機能を提供します。

## 🛠️ 環境情報
- **Flutter**: 最新版
- **Dart**: 最新版
- **OS**: Windows 11
- **Android Studio**: 2024.3.2
- **Java**: 17
- **IDE**: VS Code / Cursor
- **Git**: 最新版

## 📁 プロジェクト構造

```
flutter-app/
├── 📁 log/                          # 開発ログ・トラブルシューティング
│   ├── 📄 agent_log.md             # 開発進捗・実装状況ログ
│   └── 📄 develop_trouble.md       # トラブルシューティング履歴
│
├── 📁 wellfin/                      # メインFlutterアプリ
│   ├── 📁 android/                  # Android設定
│   │   └── 📁 app/
│   ├── 📁 ios/                      # iOS設定
│   ├── 📁 web/                      # Web設定
│   ├── 📁 windows/                  # Windows設定
│   ├── 📁 macos/                    # macOS設定
│   ├── 📁 linux/                    # Linux設定
│   │
│   ├── 📁 lib/                      # Dartソースコード
│   │   ├── 📄 main.dart             # アプリエントリーポイント
│   │   │
│   │   ├── 📁 core/                 # コア機能
│   │   │   ├── 📁 config/           # 設定ファイル
│   │   │   ├── 📁 constants/        # 定数
│   │   │   ├── 📁 errors/           # エラーハンドリング
│   │   │   ├── 📁 network/          # ネットワーク関連
│   │   │   └── 📁 utils/            # ユーティリティ
│   │   ├── 📁 features/             # 機能別モジュール
│   │   │   ├── 📁 ai_agent/         # AIエージェント機能
│   │   │   │   ├── 📁 data/models/  # データモデル
│   │   │   │   └── 📁 domain/entities/ # ドメインエンティティ
│   │   │   ├── 📁 analytics/        # 分析機能
│   │   │   │   └── 📁 domain/entities/
│   │   │   ├── 📁 auth/             # 認証機能
│   │   │   │   └── 📁 presentation/pages/
│   │   │   │       └── 📄 login_page.dart # ログインページ
│   │   │   ├── 📁 calendar/         # カレンダー機能
│   │   │   │   └── 📁 domain/entities/
│   │   │   ├── 📁 dashboard/        # ダッシュボード機能
│   │   │   │   └── 📁 presentation/pages/
│   │   │   │       └── 📄 dashboard_page.dart # ダッシュボードページ
│   │   │   ├── 📁 goals/            # 目標管理機能
│   │   │   │   └── 📁 domain/entities/
│   │   │   ├── 📁 habits/           # 習慣管理機能
│   │   │   │   └── 📁 domain/entities/
│   │   │   └── 📁 tasks/            # タスク管理機能
│   │   │
│   │   └── 📁 shared/               # 共有リソース
│   │       ├── 📁 models/           # 共有モデル
│   │       │   ├── 📄 task_model.dart
│   │       │   └── 📄 user_model.dart
│   │       │
│   │       ├── 📁 providers/        # Riverpodプロバイダー
│   │       │   ├── 📄 auth_provider.dart
│   │       │   └── 📄 user_provider.dart
│   │       │
│   │       ├── 📁 services/         # サービス層
│   │       │   ├── 📄 ai_agent_service.dart # AIエージェントサービス
│   │       │   ├── 📄 android_service.dart  # Android固有サービス
│   │       │   └── 📄 auth_service.dart     # 認証サービス
│   │       │
│   │       └── 📁 widgets/          # 共有ウィジェット
│   │           ├── 📄 android_widgets.dart
│   │           └── 📄 loading_widget.dart
│   │
│   ├── 📁 assets/                   # アセットファイル
│   │   ├── 📁 animations/           # アニメーション
│   │   ├── 📁 fonts/                # フォント
│   │   ├── 📁 icons/                # アイコン
│   │   └── 📁 images/               # 画像
│   │
│   ├── 📁 test/                     # テストファイル
│   │   └── 📄 widget_test.dart
│   │
│   ├── 📄 pubspec.yaml              # 依存関係設定
│   ├── 📄 pubspec.lock              # 依存関係ロック
│   ├── 📄 analysis_options.yaml     # 静的解析設定
│   └── 📄 README.md                 # アプリ詳細README
│
├── 📄 Dockerfile                    # Docker設定
├── 📄 docker-compose.yml            # Docker Compose設定
├── 📄 firebase.json                 # Firebase設定
├── 📄 .firebaserc                   # Firebaseプロジェクト設定
├── 📄 firestore.rules               # Firestoreセキュリティルール
├── 📄 storage.rules                 # Firebase Storageルール
├── 📄 servise.md                    # サービス仕様書
└── 📄 README.md                     # プロジェクト概要README
```

## 🚀 セットアップ手順

### 1. 環境準備
1. Windows 11 に Android Studio をインストール
2. Windows 11 に Flutter をインストール
3. このリポジトリをクローン

### 2. プロジェクトセットアップ
```bash
# プロジェクトディレクトリに移動
cd flutter-app/wellfin

# 依存関係のインストール
flutter pub get
```

### 3. アプリケーション実行
```bash
# デバッグモードで実行
flutter run

# リリースビルド
flutter build apk --release
```

## 📊 実装状況

### ✅ 実装済み機能
- 認証システム（Firebase Auth）
- ダッシュボード機能
- Firebase統合
- Android固有機能

### 🔄 部分実装
- AIエージェント機能（サービス層のみ）
- Riverpod状態管理（プロバイダー構造のみ）

### ❌ 未実装機能
- タスク管理
- 習慣管理
- 目標管理
- カレンダー機能
- 分析機能

## 🔧 開発情報

### 技術スタック
- **フロントエンド**: Flutter (Dart)
- **バックエンド**: Firebase (Auth, Firestore, Functions)
- **AI**: Google Cloud AI (Vertex AI, Gemini API)
- **状態管理**: Riverpod
- **アーキテクチャ**: クリーンアーキテクチャ

### 重要なファイル
- `wellfin/lib/main.dart`: アプリエントリーポイント
- `wellfin/pubspec.yaml`: 依存関係管理
- `wellfin/android/app/build.gradle.kts`: Android設定
- `wellfin/android/app/google-services.json`: Firebase設定
- `log/agent_log.md`: 開発進捗ログ
- `log/develop_trouble.md`: トラブルシューティング履歴

## 📚 参考資料
- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [Firebase公式ドキュメント](https://firebase.google.com/docs)
- [開発ログ](./log/agent_log.md)
- [トラブルシューティング履歴](./log/develop_trouble.md)

---

**最終更新**: 2025年6月26日
