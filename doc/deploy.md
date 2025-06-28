# WellFin デプロイガイド

## 📋 ファイルの役割
このファイルは、WellFinアプリケーションのデプロイ手順とリリースプロセスを記載する実用的なデプロイガイドです。
開発環境から本番環境への安全なデプロイ設定を管理します。

## 🚀 デプロイ手順

### 11. Firebase設定

#### 2.1 Firebaseプロジェクトの初期化
```bash
# Firebase CLIのインストール
npm install -g firebase-tools

# Firebaseにログイン
firebase login

# プロジェクトの初期化
firebase init

# 選択項目:
# - Firestore: データベース
# - Authentication: 認証
# - Storage: ファイルストレージ
# - Functions: サーバーレス関数
# - Hosting: Webホスティング
```

#### 2.2 Firestoreセキュリティルールの設定
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザー認証チェック
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // ユーザー自身のデータのみアクセス可能
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // ユーザーコレクション
    match /users/{userId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }
    
    // タスクコレクション
    match /users/{userId}/tasks/{taskId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }
    
    // 習慣コレクション
    match /users/{userId}/habits/{habitId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }
  }
}
```

#### 2.3 Storageセキュリティルールの設定
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Google Cloud AI設定

#### 3.1 Vertex AI APIの有効化
```bash
# Vertex AI APIの有効化
gcloud services enable aiplatform.googleapis.com

# Gemini APIの有効化
gcloud services enable generativelanguage.googleapis.com

# Natural Language APIの有効化
gcloud services enable language.googleapis.com

# Recommendations AIの有効化
gcloud services enable recommendationsengine.googleapis.com
```

#### 3.2 サービスアカウントの作成
```bash
# サービスアカウントの作成
gcloud iam service-accounts create wellfin-ai-service \
    --display-name="WellFin AI Service Account"

# 必要な権限の付与
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:wellfin-ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:wellfin-ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
    --role="roles/ml.developer"
```

#### 3.3 APIキーの生成
```bash
# APIキーの生成
gcloud auth application-default login

# サービスアカウントキーの作成
gcloud iam service-accounts keys create wellfin-ai-key.json \
    --iam-account=wellfin-ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

### 4. Flutterアプリのビルド

#### 4.1 依存関係の確認
```bash
# 依存関係の更新
flutter pub get

# 依存関係の確認
flutter pub deps
```

#### 4.2 アプリのビルド
```bash
# Android APKのビルド
flutter build apk --release

# Android App Bundleのビルド（Google Play用）
flutter build appbundle --release

# iOSのビルド（macOS環境が必要）
flutter build ios --release

# Webのビルド
flutter build web --release
```

### 5. デプロイ実行

#### 5.1 Firebaseへのデプロイ
```bash
# Firestoreセキュリティルールのデプロイ
firebase deploy --only firestore:rules

# Storageセキュリティルールのデプロイ
firebase deploy --only storage

# Cloud Functionsのデプロイ
firebase deploy --only functions

# Webアプリのデプロイ
firebase deploy --only hosting
```

#### 5.2 Google Cloud Runへのデプロイ
```bash
# Dockerイメージのビルド
docker build -t gcr.io/$GOOGLE_CLOUD_PROJECT/wellfin-api .

# Google Container Registryへのプッシュ
docker push gcr.io/$GOOGLE_CLOUD_PROJECT/wellfin-api

# Cloud Runへのデプロイ
gcloud run deploy wellfin-api \
    --image gcr.io/$GOOGLE_CLOUD_PROJECT/wellfin-api \
    --platform managed \
    --region $GOOGLE_CLOUD_REGION \
    --allow-unauthenticated
```

## 📋 リリースプロセス

### 1. デプロイ前チェックリスト

#### ビルド前確認
- [ ] `pubspec.yaml`のバージョン更新
- [ ] `release_notes.md`の更新
- [ ] テスト実行: `flutter test`
- [ ] コード分析: `flutter analyze`

#### Firebase設定確認
- [ ] `firebase.json`の設定確認
- [ ] `.firebaserc`のプロジェクトID確認
- [ ] Firebase Consoleでアプリ登録済み
- [ ] テスターグループ設定済み

#### セキュリティ確認
- [ ] APIキーがGitにコミットされていない
- [ ] 機密情報が含まれていない
- [ ] プロダクション用の設定になっている

#### 機能確認
- [ ] 習慣管理機能の動作確認
- [ ] タスク管理機能の動作確認
- [ ] Firestore連携の確認
- [ ] UI/UXの確認

### 2. リリース手順

#### 2.1 テスト配布（Firebase App Distribution）

- ドキュメント
  - https://firebase.google.com/docs/app-distribution/android/distribute-cli?hl=ja

```bash
# リリースビルド
cd wellfin
flutter build apk --release --build-name={バージョン名}
```

- デプロイ

```
cd ..
# Firebase App Distribution配布
firebase appdistribution:distribute "wellfin/build/app/outputs/flutter-apk/app-release.apk" \
  --app "1:933043164976:android:97bcddf0bc4d976dd65af5" \
  --groups "testers" \
  --release-notes-file "doc/release_notes.md"
```

#### 2.2 本番リリース（Google Play Store）
```bash
# App Bundleビルド
flutter build appbundle --release

# Google Play Consoleに手動アップロード
# https://play.google.com/console
```

#### 2.3 Web版リリース（オプション）
```bash
# Webビルド
flutter build web --release

# Firebase Hostingデプロイ
firebase deploy --only hosting
```

### 3. デプロイ後確認

#### 機能確認
- [ ] ダッシュボード機能の動作確認
- [ ] タスク管理機能の動作確認
- [ ] 習慣管理機能の動作確認
- [ ] Firestore連携の確認

#### パフォーマンス確認
- [ ] ダッシュボード初期読み込み < 3秒
- [ ] タスクリスト読み込み < 2秒
- [ ] 習慣リスト読み込み < 2秒
- [ ] タスク完了操作 < 1秒

#### エラー監視
```bash
# Firebase Console でログを確認
# https://console.firebase.google.com/project/your-project-id/logs

# Firebase Crashlytics でクラッシュレポートを確認
# https://console.firebase.google.com/project/your-project-id/crashlytics
```

## 🎯 推奨ワークフロー

### 開発段階
1. 機能実装
2. デバッグビルド: `flutter build apk --debug`
3. エミュレータ/実機テスト
4. コードレビュー

### テスト配布
1. リリースビルド: `flutter build apk --release`
2. Firebase App Distribution配布
3. テスターからのフィードバック収集
4. バグ修正・改善

### 本番リリース
1. App Bundleビルド: `flutter build appbundle --release`
2. Google Play Consoleアップロード
3. 審査申請
4. 公開

## 📚 参考リンク

- [Flutter公式ドキュメント](https://docs.flutter.dev/deployment/android)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [Google Play Console](https://play.google.com/console)
- [Firebase Console](https://console.firebase.google.com/project/wellfin-72698)

---

*最終更新: 2025年6月28日* 