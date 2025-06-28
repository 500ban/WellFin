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

### 技術スタック
- **フロントエンド**: Flutter (Dart)
- **バックエンド**: Firebase (Auth, Firestore, Functions)
- **AI**: Google Cloud AI (Vertex AI, Gemini API)
- **状態管理**: Riverpod
- **アーキテクチャ**: クリーンアーキテクチャ

## 📚 参考資料
- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [Firebase公式ドキュメント](https://firebase.google.com/docs)
- [開発ログ](./log/agent_log.md)
- [トラブルシューティング履歴](./log/develop_trouble.md)

---

**最終更新**: 2025年6月26日
