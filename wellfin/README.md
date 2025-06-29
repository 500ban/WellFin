# WellFin - AI Agent

日常生活向上AIエージェントアプリケーション

## 概要

WellFinは、AIを活用して日常生活の向上をサポートするFlutterアプリケーションです。Androidプラットフォームに最適化されており、Material Design 3に準拠した美しいUIと豊富な機能を提供します。

## 主な機能

- 🤖 AIエージェントによる日常生活サポート
- 📊 ダッシュボードと分析機能
- 📅 カレンダーとスケジュール管理
- ✅ タスク設定
- 🎯 目標設定と追跡
- 🔄 習慣設
- 🔐 セキュアな認証システム
- 📱 Android最適化機能

## Android最適化機能

### 1. パフォーマンス最適化
- **コード最適化**: ProGuard/R8によるコード縮小と難読化
- **マルチDEX対応**: 大きなアプリケーションのサポート
- **ベクター描画**: 高解像度ディスプレイでの美しい表示
- **バンドル分割**: 言語、密度、ABI別の最適化

### 2. Material Design 3
- **完全なMD3実装**: 最新のMaterial Designガイドライン準拠
- **ダークテーマ対応**: システム設定に応じた自動切り替え
- **カスタムテーマ**: ブランドカラーに合わせた統一されたデザイン
- **アニメーション**: スムーズなトランジションとインタラクション

### 3. Android固有機能
- **バイブレーション**: タッチフィードバックと通知
- **権限管理**: 通知、カメラ、位置情報、ストレージ権限の適切な管理
- **デバイス情報**: バッテリー、ネットワーク、システム情報の取得
- **ファイル共有**: ネイティブの共有機能との統合
- **アプリ評価**: Google Play Storeへの直接リンク

### 4. システム統合
- **通知システム**: Firebase Cloud Messagingによるプッシュ通知
- **ディープリンク**: `wellfin://` スキームによるアプリ内ナビゲーション
- **バックアップ**: Android 12+のデータ抽出ルール対応
- **システムUI**: ステータスバーとナビゲーションバーの最適化

## 技術スタック

### フロントエンド
- **Flutter**: クロスプラットフォーム開発フレームワーク
- **Dart**: プログラミング言語
- **Material Design 3**: UIデザインシステム

### バックエンド
- **Firebase**: 認証、データベース、分析、クラッシュレポート
- **Google Cloud**: AI・機械学習サービス
- **Cloud Firestore**: NoSQLデータベース

### 状態管理
- **Riverpod**: 宣言的な状態管理
- **Provider**: 依存性注入

### ローカルストレージ
- **Hive**: 高速なローカルデータベース
- **SharedPreferences**: 設定データの保存

## セットアップ

### 前提条件
- Flutter SDK 3.2.3以上
- Android Studio / VS Code
- Android SDK API 24以上
- Google Cloud プロジェクト
- Firebase プロジェクト

### インストール

1. リポジトリをクローン
```bash
git clone https://github.com/your-username/wellfin.git
cd wellfin
```

2. 依存関係をインストール
```bash
flutter pub get
```

3. Firebase設定ファイルを配置
```bash
# android/app/google-services.json を配置
# ios/Runner/GoogleService-Info.plist を配置
```

4. Androidアプリをビルド
```bash
flutter build apk --release
```

### 開発環境

```bash
# 開発サーバーを起動
flutter run

# テストを実行
flutter test

# コード分析
flutter analyze
```

### 環境変数設定

アプリでは以下の環境変数を使用して設定をカスタマイズできます：

```bash
# APIキーを設定（必須）
flutter run --dart-define=WELLFIN_API_KEY=your-secret-api-key

# 本番環境のAPIベースURLを指定（オプション）
flutter run --dart-define=PROD_API_BASE_URL=https://your-api-url.com

# リリースビルド時の環境変数設定
flutter build apk \
  --dart-define=WELLFIN_API_KEY=your-secret-api-key \
  --dart-define=PROD_API_BASE_URL=https://wellfin-ai-api-dev-135244043089.asia-northeast1.run.app

# 複数の環境変数を設定
flutter run \
  --dart-define=WELLFIN_API_KEY=your-secret-api-key \
  --dart-define=PROD_API_BASE_URL=https://your-api-url.com \
  --dart-define=API_VERSION=v1
```

#### 利用可能な環境変数

- `WELLFIN_API_KEY`: WellFin AI APIのAPIキー（デフォルト: `dev-secret-key`）
- `PROD_API_BASE_URL`: 本番環境のAPIベースURL（デフォルト: https://wellfin-ai-api-dev-135244043089.asia-northeast1.run.app）

#### APIキー認証について

本アプリは**APIキー認証方式**を採用しており、Firebase認証は使用していません。これにより：

- ✅ **シンプルな認証**: 複雑なOAuth フローが不要
- ✅ **高速な起動**: 認証トークンの取得待ちが不要
- ✅ **安定した接続**: ネットワーク環境に依存しない認証
- ✅ **開発効率**: APIキーの設定のみで即座に利用可能

**重要**: 本番環境では、適切なAPIキーを設定してください。デフォルトの`dev-secret-key`は開発環境専用です。

## プロジェクト構造

```
wellfin/
├── android/                 # Android固有の設定
│   ├── app/
│   │   ├── build.gradle.kts # ビルド設定
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/      # Kotlinコード
├── lib/
│   ├── core/               # コア機能
│   │   ├── config/         # 設定ファイル
│   │   ├── constants/      # 定数
│   │   ├── errors/         # エラーハンドリング
│   │   ├── network/        # ネットワーク関連
│   │   └── utils/          # ユーティリティ
│   ├── features/           # 機能別モジュール
│   │   ├── auth/           # 認証機能
│   │   ├── dashboard/      # ダッシュボード
│   │   ├── tasks/          # タスク管理
│   │   ├── habits/         # 習慣管理
│   │   ├── goals/          # 目標管理
│   │   ├── calendar/       # カレンダー
│   │   ├── analytics/      # 分析機能
│   │   └── ai_agent/       # AIエージェント
│   ├── shared/             # 共有コンポーネント
│   │   ├── models/         # データモデル
│   │   ├── providers/      # 状態管理
│   │   ├── services/       # サービス
│   │   └── widgets/        # 共有ウィジェット
│   └── main.dart           # エントリーポイント
└── pubspec.yaml            # 依存関係
```

## Android固有の使用方法

### AndroidService の使用例

```dart
import 'package:wellfin/shared/services/android_service.dart';

// バイブレーション
await AndroidService.vibrateShort();

// 権限の要求
bool hasPermission = await AndroidService.requestCameraPermission();

// デバイス情報の取得
Map<String, dynamic> deviceInfo = await AndroidService.getDeviceInfo();

// ファイル共有
bool success = await AndroidService.shareText("共有するテキスト");
```

### AndroidWidgets の使用例

```dart
import 'package:wellfin/shared/widgets/android_widgets.dart';

// Android風のスナックバー
AndroidWidgets.showAndroidSnackBar(
  context,
  message: "操作が完了しました",
);

// Android風のダイアログ
AndroidWidgets.showAndroidDialog(
  context: context,
  title: "確認",
  content: "本当に削除しますか？",
  confirmText: "削除",
  cancelText: "キャンセル",
  onConfirm: () => deleteItem(),
);

// Android風のボタン
AndroidWidgets.androidButton(
  text: "保存",
  onPressed: () => saveData(),
  icon: Icon(Icons.save),
);
```

## ビルド設定

### リリースビルド

```bash
# APKファイルをビルド
flutter build apk --release

# App Bundleをビルド（Google Play Store用）
flutter build appbundle --release
```

### デバッグビルド

```bash
flutter build apk --debug
```

## テスト

```bash
# ユニットテスト
flutter test

# ウィジェットテスト
flutter test test/widget_test.dart

# 統合テスト
flutter test integration_test/
```

## デプロイ

### Google Play Store

1. App Bundleをビルド
```bash
flutter build appbundle --release
```

2. Google Play Consoleにアップロード
3. リリースノートとスクリーンショットを追加
4. 段階的ロールアウトを設定

### 内部テスト

```bash
# 内部テスト用APK
flutter build apk --release
```

## トラブルシューティング

### よくある問題

1. **ビルドエラー**
   - `flutter clean` を実行
   - `flutter pub get` を再実行

2. **権限エラー**
   - AndroidManifest.xmlで権限が正しく設定されているか確認
   - 実行時に権限を要求しているか確認

3. **MethodChannelエラー**
   - MainActivity.ktでメソッドが正しく実装されているか確認
   - チャンネル名が一致しているか確認

## 貢献

1. フォークを作成
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。

## サポート

問題や質問がある場合は、[Issues](https://github.com/your-username/wellfin/issues) で報告してください。

## 更新履歴

### v1.0.0
- 初回リリース
- Android最適化機能の実装
- Material Design 3の完全実装
- Firebase統合
- AIエージェント機能
