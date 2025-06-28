# WellFin 開発トラブルシューティング履歴

## 📋 概要
**プロジェクト**: WellFin - AI Agent Flutterアプリ  
**対象期間**: 2024年12月 - 2025年6月  
**最終更新**: 2025年6月26日

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

# ビルド
flutter build apk --debug

# 実行
flutter run

# 診断
flutter doctor
```

### 重要な設定ファイル
- `pubspec.yaml`: 依存関係
- `android/app/build.gradle.kts`: Android設定
- `android/app/google-services.json`: Firebase設定
- `android/app/src/main/AndroidManifest.xml`: アプリ設定

## 📚 参考資料

### 公式ドキュメント
- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [Firebase公式ドキュメント](https://firebase.google.com/docs)
- [Android開発者ドキュメント](https://developer.android.com/docs)

### トラブルシューティングガイド
- [Google Play services クライアント認証ガイド](https://developers.google.com/android/guides/client-auth?hl=ja#windows)
- [Flutterトラブルシューティング](https://docs.flutter.dev/get-started/install/windows#android-setup)

### コミュニティリソース
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)

## 🔄 更新履歴

| 日付 | 内容 | 状況 |
|------|------|------|
| 2024年12月 | Java 11エラー解決 | ✅ 完了 |
| 2024年12月 | Gradle依存エラー解決 | ✅ 完了 |
| 2024年12月 | JVMターゲット不一致解決 | ✅ 完了 |
| 2024年12月 | NDK警告解決 | ✅ 完了 |
| 2025年6月 | WSL2接続問題解決 | ✅ 完了 |
| 2025年6月26日 | Google Sign-Inエラー対応中 | 🔄 進行中 |

## 2025年6月27日 ビルド・配布トラブル対応

- R8（ProGuard）エラー：Google Play Core関連のMissing classでリリースビルド失敗
  - ProGuardルール追加でも解決せず
  - 一時的にminify/shrinkを無効化し、リリースビルド成功
- デバッグビルドは問題なし
- Firebase App Distributionでテスト配布を推奨
- 本番リリース時はProGuardルール再調整・難読化有効化が必要

---

**最終更新**: 2025年6月26日  
**次回更新**: 新しいトラブル発生時または解決時 