# flutter-sample

## 環境情報

### 開発環境

- Flutter: 最新版
- Dart: 最新版
- OS: Linux (WSL2)

### 必要なツール

- Docker
- VS Code / Cursor
- Git
- Android Studio

### セットアップ手順

1. コンテナの起動

```bash
docker compose up
```

2. 依存関係のインストール

```bash
docker compose exec flutter bash -c "cd /workspace/wellfin && flutter pub get"
```

3. アプリケーションの実行

```bash
docker compose exec flutter bash -c "cd /workspace/wellfin && flutter run"
```

### 開発環境の構築

1. このリポジトリをクローン

```bash
git clone [リポジトリURL]
```

2. プロジェクトディレクトリに移動

```bash
cd flutter-sample
```

3. 依存関係のインストール

```bash
flutter pub get
```
