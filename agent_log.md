# WellFin 開発セットアップ・トラブル対応ログ（エージェント向けサマリ）

## 概要
- Flutter × Firebase × Google Cloud AI 技術を活用した生産性向上アプリ「WellFin」の開発。
- Docker上でFlutter開発環境を構築し、Firebase認証・Google Cloud連携・AIエージェント機能を段階的に実装。

## 技術スタック
- Flutter（クロスプラットフォーム）
- Firebase（Auth, Firestore, Cloud Functions, FCM, Analytics）
- Google Cloud（Vertex AI, Gemini API, Recommendations AI, Cloud Run等）
- Docker, Java 21, Gradle, Android NDK

## 進行履歴（時系列）
1. **Docker/Javaセットアップ**
    - DockerfileでJava 21導入、Docker ComposeでFlutter開発環境構築。
    - applicationIdを `com.wellfin.aiagent` に変更。
2. **Firebase/Flutter初期設定**
    - FirebaseのAndroidセットアップ。
    - Flutter依存関係を `pubspec.yaml` に追加。
3. **主要機能実装**
    - AIエージェントサービス、認証サービス、ユーザーモデル、タスクモデル、
      認証・ユーザープロバイダー、ログインページ、ダッシュボードページ等を段階的に作成。
4. **トラブル対応**
    - Java 11エラー → Java 21に修正し再ビルド。
    - Flutter依存パッケージ名誤り → 修正後 `flutter pub get` 成功。
    - Gradle実行時ネットワークエラー（Mavenリポジトリ到達不可） → Docker内ネットワーク疎通確認、`curl`で外部接続OK。
    - Flutter依存再取得（`flutter pub get`）、`./gradlew clean`でキャッシュクリア。
    - NDKバージョン警告 → `build.gradle.kts` の `android { ndkVersion = "27.0.12077973" }` 追加推奨。
    - JVMターゲット不一致エラー（Java:1.8、Kotlin:11）発生。build.gradle.ktsでkotlinOptions { jvmTarget = "1.8" } に統一し対応。
5. **現状**
    - 依存関係・ネットワーク問題は解消。
    - Androidビルド・署名証明書取得コマンドが正常に動作する状態。

## 進行履歴（追記）
- Androidビルド時、Firebase Auth等の依存でminSdkVersion 23以上が必要と判明。
- wellfin/android/app/build.gradle.kts の minSdkVersion を 23 に修正。
- 主要なFirebase/Google Cloud/通知系パッケージをLTSバージョンに更新。
- flutter pub getで依存関係を整理。
- flutter_local_notificationsの依存でdesugar_jdk_libs 2.1.4以上が必要となり、build.gradle.ktsでバージョンを2.1.4に修正。
- JVMターゲット不一致エラー（Java:1.8、Kotlin:11）発生。build.gradle.ktsでkotlinOptions { jvmTarget = "1.8" } に統一し対応。
- MainActivityのパッケージ名をcom.wellfin.aiagentに修正。
- lintエラー（SyntheticAccessor）とテストエラーを解決するため、build.gradle.ktsにlint/test設定を追加。
- ビルドエラーに都度対応し、安定化を進行中。
- root build.gradle.ktsのlint設定を削除（KTSでは無効なため）。

### PC再起動後の作業（最新）
- **Dockerコンテナ再起動**: PC再起動により停止していたコンテナを`docker-compose up -d`で再起動。
- **開発環境復旧**: `docker exec -it flutter-app-flutter-1 /bin/bash`でコンテナ内に入り、作業を再開。
- **依存関係更新**: `flutter pub get`でプロジェクトの依存関係を再取得・更新。
- **ビルド成功**: `flutter build apk --debug`でAndroidアプリのビルドが正常に完了。
- **NDK自動設定**: ビルド時にNDK 27.0.12077973が自動的にインストール・設定される。
- **Android SDK更新**: Build-Tools 34とPlatform 34/35が自動的にインストールされる。

## 未解決・注意点
- Android NDKバージョン警告あり（`ndkVersion`指定で対応推奨）。
- 依存パッケージのバージョンアップ未対応（`pub outdated`参照）。
- 今後も新規機能追加・AI連携・CI/CD等の拡張予定。

---
（随時追記）
