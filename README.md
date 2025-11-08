# KitsuneReader

SwiftUI 製のローカルファースト RSS リーダーです。FeedKit / SwiftSoup / Nuke を利用し、購読データや記事本文、翻訳結果まで端末内に保存します。

## ビルド
1. `KitsuneReader.xcodeproj` を Xcode 15.3 以降で開く
2. 依存ライブラリ (FeedKit / SwiftSoup / Nuke) を Swift Package Manager が自動取得するのを待つ
3. 対象デバイスを iOS 17+ シミュレータまたは実機に設定して実行

## CI
GitHub Actions (macOS 14 ランナー) で `xcodebuild test` を実行するワークフローを追加しました。`main` ブランチへのプッシュや Pull Request で自動的にビルドとテストが走ります。

## 翻訳モデル
- 既定では辞書ベースの軽量翻訳を使用します。
- iOS 18 以降で Apple Translation API が利用可能な場合は自動的に切り替わります。
- 任意で Core ML モデル (`Models/*.mlmodelc`) を追加すると、高精度なローカル翻訳に置き換えられます。
