# 第5部：開発ガイドライン・参考資料

## 📋 ファイルの役割
このファイルは、WellFinアプリケーションの開発ガイドライン、実装ガイド、参考資料を記載する開発者向けガイドです。
アプリケーションの開発標準と参考情報を管理します。

## 11. 開発ガイドライン・参考資料

### 11.1 実装ガイドライン
- コードスタイル：Dart/Flutter公式スタイルガイドに準拠
- 命名規則：キャメルケース（クラス/メソッド/変数）、定数はスネークケース
- コメント・ドキュメント：DartDoc形式、関数・クラス・重要ロジックに必ず記述
- コミットメッセージ：機能単位で簡潔に、prefix（feat/fix/docs/refactor/test/chore）推奨
- PRレビュー：必ず2名以上でレビュー、CIパス必須
- セキュリティ：APIキー・シークレットは環境変数/Secret Managerで管理、公開NG
- プライバシー：個人情報・センシティブデータは暗号化・アクセス制御を徹底
- テスト：ユニット・ウィジェット・統合・E2EテストをCIで自動化
- デバッグ：Flutter DevTools、Firebase Crashlytics、Cloud Logging活用
- ドキュメント：README、仕様書、APIリファレンス、運用手順を常に最新化

### 11.2 参考資料
- [Flutter公式ドキュメント](https://flutter.dev/docs)
- [Dart公式ガイド](https://dart.dev/guides)
- [Firebase公式ドキュメント](https://firebase.google.com/docs)
- [Google Cloud公式ドキュメント](https://cloud.google.com/docs)
- [Riverpod公式](https://riverpod.dev/)
- [Clean Architecture解説](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html)
- [FlutterFire](https://firebase.flutter.dev/)
- [WellFin開発ノート/リリースノート/運用手順書]
- [Google Cloud AI/Vertex AIリファレンス]
- [GitHubリポジトリ/過去のPR/Issue/設計議論]
- [社内/外部の開発ガイドライン・ベストプラクティス集]

---

*最終更新: 2025年6月28日* 