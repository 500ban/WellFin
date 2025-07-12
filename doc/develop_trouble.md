# WellFin 開発トラブルシューティング履歴

## 📋 概要
**プロジェクト**: WellFin - AI Agent Flutterアプリ  
**対象期間**: 2024年12月 - 2025年6月  
**最終更新**: 2025年6月29日

## 🔧 解決済みトラブル

### 1. Java 11エラー → Java 21に更新
**発生時期**: 2024年12月  
**エラー内容**: 
```
Error: A JNI error has occurred, please check your installation and try again
Error: A fatal exception has occurred. Program will exit.
```

**原因**: FlutterがJava 21を要求しているが、Java 11がインストールされていた

**解決方法**:
1. Java 21をインストール
2. `JAVA_HOME`環境変数を更新
3. プロジェクトを再ビルド

**結果**: ✅ 解決済み

### 2. Gradle依存エラー → パッケージ名修正
**発生時期**: 2024年12月  
**エラー内容**:
```
Could not resolve dependencies for project ':app'
```

**原因**: `pubspec.yaml`でパッケージ名の記述ミス

**解決方法**:
1. パッケージ名を正しい形式に修正
2. `flutter pub get`を実行
3. 依存関係を再取得

**結果**: ✅ 解決済み

### 3. JVMターゲット不一致エラー
**発生時期**: 2024年12月  
**エラー内容**:
```
JVM target compatibility should be set to the same Java version
Java: 1.8, Kotlin: 11
```

**原因**: JavaとKotlinのターゲットバージョンが異なる

**解決方法**:
```kotlin
// build.gradle.kts
android {
    kotlinOptions {
        jvmTarget = "1.8"
    }
}
```

**結果**: ✅ 解決済み

### 4. NDK警告 → 自動設定で解決
**発生時期**: 2024年12月  
**エラー内容**:
```
NDK version 27.0.12077973 is not installed
```

**原因**: Android NDKがインストールされていない

**解決方法**:
1. ビルド時に自動的にNDK 27.0.12077973がインストールされる
2. 手動で`ndkVersion`を指定することも可能

**結果**: ✅ 解決済み

### 5. WSL2接続問題 → Windows側開発に移行
**発生時期**: 2025年6月  
**エラー内容**:
```
WSL2（Ubuntu）からWindows側のAndroid Studioエミュレーターが認識されない
```

**試行した解決方法**:
1. adbサーバーの接続先変更
2. Windows側adbサーバーの再起動
3. WSL2側adbクライアントの設定変更
4. パス共有・環境変数設定
5. ネットワークブリッジ設定

**結果**: すべて失敗

**最終解決策**: Windows側でのFlutter開発に移行

**理由**:
- Android Studioエミュレーターとの親和性が最高
- Firebase系パッケージの安定動作
- 公式サポート・ドキュメントが充実
- トラブルシューティングが容易

### 6. Flutter実機デプロイ後のAPI 404エラー（2025年6月29日）
**発生時期**: 2025年6月29日  
**エラー内容**: 
```
AI分析に失敗しました: Exception: Failed to analyze task: 404 - 
<html><head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<title>404 Page not found</title>
</head>
<body text=#000000 bgcolor=#ffffff>
<h1>Error: Page not found</h1>
<h2>The requested URL was not found on this server.</h2>
<h2></h2>
</body></html>
```

**環境差異**:
- **ローカル開発**: 正常動作
- **Android実機**: 404エラーで動作不可

**原因分析**:
1. **プレースホルダーURL使用**: `your-gcp-project-id` がAndroid実機で使用された
2. **環境変数未設定**: 実機では環境変数が未設定でデフォルト値が使用
3. **システム設計ミス**: Cloud Run ServiceからCloud Run Functionsへの変更時の対応不備
4. **重大なセキュリティリスク**: GCPプロジェクトID `[YOUR-GCP-PROJECT-ID]` をソースコードにハードコード

**解決手順**:
1. **Cloud Run Functions動作確認**:
   ```bash
   curl -X GET "https://asia-northeast1-[YOUR-GCP-PROJECT-ID].cloudfunctions.net/wellfin-ai-function/health"
   # ✅ 正常レスポンス確認
   
   curl -X GET "https://asia-northeast1-[YOUR-GCP-PROJECT-ID].cloudfunctions.net/wellfin-ai-function/test-ai"
   # ✅ Vertex AI接続テスト成功
   ```

2. **セキュリティリスク排除**:
   ```dart
   // ❌ 危険: ハードコードされた機密情報
   defaultValue: '[YOUR-GCP-PROJECT-ID]'
   
   // ✅ 安全: 環境変数化
   static String get _baseUrl => const String.fromEnvironment(
     'WELLFIN_API_URL',
     defaultValue: 'http://localhost:8080', // ローカル開発用のみ
   );
   ```

3. **既存ビルドシステム統合**:
   - `config/development/api-config.json` (Git保護済み) の活用
   - `flutter-build.bat` による `--dart-define=WELLFIN_API_URL=...` 設定
   - 既存の完璧なシステムとの統合

4. **実機動作確認**:
   ```bash
   scripts\flutter-build.bat
   # ✅ APKビルド成功
   # ✅ 環境変数正しく設定
   # ✅ 実機でAI機能完全動作
   ```

**技術的教訓**:
- **既存システム理解の重要性**: 独自実装より既存システム活用
- **セキュリティファースト**: 機密情報のGit管理からの除外
- **環境差異の考慮**: ローカル/実機環境の動作差異への対応
- **Infrastructure as Code価値**: 100%自動化による設定漂流防止

**結果**: ✅ 解決済み - Android実機でAI分析機能完全動作

### 7. 実機でのみ発生するダッシュボードUIちらつき・重複描画問題（2025年7月12日）
**発生時期**: 2025年7月  
**エラー内容**:
- ダッシュボード初回表示時、カードが重複・ループして見える、不要な柄が一瞬表示される（実機のみ）
- エミュレーターでは発生しない

**原因分析**:
- 実機ではデータ取得や描画タイミングが遅延しやすく、ローディング状態と本体UIが一瞬重なって描画されていた
- アニメーションやCustomScrollView/SliverListの再描画タイミング差
- エミュレーターは高速なため現象が発生しにくい

**解決方法**:
1. ローディング状態の厳密化
   - データ取得が完了するまで本体UIを絶対に描画しない（userData.whenでnullやloading時はローディングWidgetのみ返す）
2. アニメーションの再描画抑制
   - FadeTransition/SlideTransitionのタイミングを見直し、不要な再描画を防止
3. カードの背景色・影の調整
   - 必要に応じてBoxDecorationや背景色を調整

**結果**: ✅ 完全解決。実機・エミュレーターともに安定したUXを実現

**備考**: 詳細はリリースノートv0.4.2参照

## 🚨 現在の課題

### Google Sign-Inエラー（2025年6月26日現在）
**エラー内容**:
```
⛔ Error signing in with Google: PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

**原因分析**:
- Firebase Consoleでの設定不備
- SHA-1証明書フィンガープリント未追加
- google-services.jsonの設定不備

**解決手順**:
1. **Firebase Console設定**
   - Authentication → Google Sign-in有効化
   - Project Settings → SHA-1フィンガープリント追加

2. **SHA-1フィンガープリント取得**
   ```powershell
   keytool -list -v -alias androiddebugkey -keystore $env:USERPROFILE\.android\debug.keystore -storepass android
   ```

3. **google-services.json更新**
   - Firebase Consoleから新しいファイルをダウンロード
   - `wellfin/android/app/google-services.json` に置き換え

4. **エミュレータ確認**
   - Google Play Services付きエミュレータ使用
   - API Level 30以上推奨

**現在の状況**: 🔄 解決中

## 📝 トラブルシューティングの教訓

### 1. 環境設定の重要性
- **Javaバージョン**: Flutterの要件を事前確認
- **Android SDK**: 最新版の使用を推奨
- **開発環境**: 安定性を優先した選択

### 2. 依存関係の管理
- **パッケージ名**: 正確な記述が重要
- **バージョン管理**: 互換性の確認
- **定期的な更新**: セキュリティと機能向上

### 3. プラットフォーム固有の問題
- **WSL2制限**: GUIアプリ・デバイス認識での制約
- **Firebase依存**: Android/iOSでの動作が前提
- **エミュレータ**: Google Play Servicesの重要性

### 4. 設定ファイルの重要性
- **build.gradle.kts**: Android設定の中心
- **google-services.json**: Firebase設定の要
- **AndroidManifest.xml**: 権限・設定の管理

## 🔍 トラブルシューティング手順

### 基本的な手順
1. **エラーログの詳細確認**
2. **原因の特定**
3. **解決策の検討**
4. **実装とテスト**
5. **結果の記録**

### よく使用するコマンド
```bash
# プロジェクトクリーン
flutter clean

# 依存関係更新
flutter pub get

# デバッグビルド
flutter build apk --debug

# リリースビルド（環境変数設定込み）
scripts\flutter-build.bat

# 実行
flutter run

# 診断
flutter doctor

# Cloud Run Functions動作確認
curl -X GET "https://asia-northeast1-[YOUR-GCP-PROJECT-ID].cloudfunctions.net/wellfin-ai-function/health"

# AI接続テスト
curl -X GET "https://asia-northeast1-[YOUR-GCP-PROJECT-ID].cloudfunctions.net/wellfin-ai-function/test-ai"

# Terraform状態確認
cd terraform && terraform show
```

### 重要な設定ファイル
- `pubspec.yaml`: 依存関係
- `android/app/build.gradle.kts`: Android設定
- `android/app/google-services.json`: Firebase設定
- `android/app/src/main/AndroidManifest.xml`: アプリ設定
- `config/development/api-config.json`: API設定（Git保護済み）
- `scripts/flutter-build.bat`: 環境変数設定込みビルドスクリプト
- `terraform/main.tf`: Infrastructure as Code設定
- `terraform/terraform.tfvars`: GCP設定値（Git保護済み）
- `functions/src/index.js`: Cloud Run Functions エントリーポイント
- `functions/package.json`: Node.js Dependencies

## 📚 参考資料

### 公式ドキュメント
- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [Firebase公式ドキュメント](https://firebase.google.com/docs)
- [Android開発者ドキュメント](https://developer.android.com/docs)
- [Google Cloud Platform ドキュメント](https://cloud.google.com/docs?hl=ja)
- [Cloud Run Functions ドキュメント](https://cloud.google.com/functions/docs?hl=ja)
- [Vertex AI ドキュメント](https://cloud.google.com/vertex-ai/docs?hl=ja)
- [Terraform ドキュメント](https://developer.hashicorp.com/terraform/docs)

### トラブルシューティングガイド
- [Google Play services クライアント認証ガイド](https://developers.google.com/android/guides/client-auth?hl=ja#windows)
- [Cloud Run Functions トラブルシューティング](https://cloud.google.com/functions/docs/troubleshooting?hl=ja)
- [Vertex AI エラー解決ガイド](https://cloud.google.com/vertex-ai/docs/troubleshooting?hl=ja)
- [Terraform トラブルシューティング](https://developer.hashicorp.com/terraform/tutorials/configuration-language/troubleshooting-workflow)

### セキュリティガイド
- [GCP セキュリティベストプラクティス](https://cloud.google.com/security/best-practices?hl=ja)
- [Flutter セキュアコーディング](https://docs.flutter.dev/security)
- [環境変数管理ベストプラクティス](https://12factor.net/config)

### Flutter開発ガイド
- [Flutter Windows インストールガイド](https://docs.flutter.dev/get-started/install/windows)
- [Flutter Android セットアップ](https://docs.flutter.dev/get-started/install/windows#android-setup)
- [Flutter トラブルシューティング](https://docs.flutter.dev/resources/faq)

---

**最終更新**: 2025年6月29日 - Flutter実機デプロイ問題解決追加  
**次回更新**: 新しいトラブル発生時または解決時