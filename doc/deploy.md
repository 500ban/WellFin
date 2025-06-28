# WellFin - デプロイ手順書

## 🚀 デプロイコマンド集

### **1. APKビルド**

#### **デバッグビルド（開発・テスト用）**
```bash
flutter build apk --debug
```
**出力**: `build/app/outputs/flutter-apk/app-debug.apk`

#### **リリースビルド（本番配布用）**
```bash
flutter build apk --release
```
**出力**: `build/app/outputs/flutter-apk/app-release.apk`

#### **App Bundle（Google Play Store用）**
```bash
flutter build appbundle --release
```
**出力**: `build/app/outputs/bundle/release/app-release.aab`

### **2. Firebase App Distribution（テスト配布）**

#### **テスト配布実行**
```bash
firebase appdistribution:distribute "build/app/outputs/flutter-apk/app-release.apk" \
  --app "1:933043164976:android:97bcddf0bc4d976dd65af5" \
  --groups "testers" \
  --release-notes "WellFin v1.0.0 - タスク管理機能実装"
```

#### **テスター管理**
```bash
# テスター一覧表示
firebase appdistribution:testers:list --app "1:933043164976:android:97bcddf0bc4d976dd65af5"

# テスター追加
firebase appdistribution:testers:add "testers" "test@example.com" --app "1:933043164976:android:97bcddf0bc4d976dd65af5"
```

### **3. Google Play Store（本番配布）**

#### **App Bundleアップロード**
```bash
# 1. App Bundleビルド
flutter build appbundle --release

# 2. Google Play Consoleに手動アップロード
# https://play.google.com/console
```

### **4. Web版デプロイ（オプション）**

#### **Webビルド**
```bash
flutter build web --release
```

#### **Firebase Hostingデプロイ**
```bash
# Firebase Hosting初期化（初回のみ）
firebase init hosting

# デプロイ
firebase deploy --only hosting
```

## 📋 デプロイ前チェックリスト

### **ビルド前確認**
- [ ] `pubspec.yaml`のバージョン更新
- [ ] `release_notes.txt`の更新
- [ ] テスト実行: `flutter test`
- [ ] コード分析: `flutter analyze`

### **Firebase設定確認**
- [ ] `firebase.json`の設定確認
- [ ] `.firebaserc`のプロジェクトID確認
- [ ] Firebase Consoleでアプリ登録済み
- [ ] テスターグループ設定済み

### **セキュリティ確認**
- [ ] APIキーがGitにコミットされていない
- [ ] 機密情報が含まれていない
- [ ] プロダクション用の設定になっている

## 🔧 トラブルシューティング

### **R8エラー（リリースビルド失敗）**
```bash
# ProGuard無効化でビルド
flutter build apk --release --no-shrink
```

### **Firebase CLIエラー**
```bash
# Node.jsバージョン確認
node --version  # v20以上必要

# Firebase CLI再インストール
npm install -g firebase-tools
```

### **テスター招待エラー**
```bash
# Firebase Consoleで手動設定
# https://console.firebase.google.com/project/wellfin-72698/appdistribution
```

## 📊 デプロイ履歴

### **2025年6月27日 - v1.0.0**
- **機能**: タスク管理機能実装
- **ビルド**: リリースAPK（60.0MB）
- **配布**: Firebase App Distribution成功
- **アプリID**: `1:933043164976:android:97bcddf0bc4d976dd65af5`
- **Firebase Console**: https://console.firebase.google.com/project/wellfin-72698/appdistribution

## 🎯 推奨ワークフロー

### **開発段階**
1. 機能実装
2. デバッグビルド: `flutter build apk --debug`
3. エミュレータ/実機テスト
4. コードレビュー

### **テスト配布**
1. リリースビルド: `flutter build apk --release`
2. Firebase App Distribution配布
3. テスターからのフィードバック収集
4. バグ修正・改善

### **本番リリース**
1. App Bundleビルド: `flutter build appbundle --release`
2. Google Play Consoleアップロード
3. 審査申請
4. 公開

## 📚 参考リンク

- [Flutter公式ドキュメント](https://docs.flutter.dev/deployment/android)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [Google Play Console](https://play.google.com/console)
- [Firebase Console](https://console.firebase.google.com/project/wellfin-72698) 