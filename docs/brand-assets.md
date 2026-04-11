# Brand Assets

SwGraphUI の採用ブランドアセットをここにまとめる。

## Scope summary

- **Included**
  - 公開 package 用の採用ロゴ
  - `SVG` ベースのアイコン 1案と横組み wordmark 1案
  - 運用メモ
- **Excluded**
  - App Store 提出用の書き出し済み PNG セット
  - Web サイト向けモーションロゴ
  - SwiftUI / Xcode asset catalog への組み込み
- **Risks**
  - 実運用では小サイズ視認性の再確認が必要
  - 文字組みは利用先のタイポグラフィと合わせて微調整余地がある
- **Recommended next implementation step**
  - 採用案を 32px / 64px / 128px で視認確認し、必要ならグリッド簡略版を追加する

## デザイン方針

- `Graph` を示すため、3つのノードと接続線を最小構成で使う
- `UI` を示すため、ノードは円ではなく角丸スクエアにする
- Swift らしい軽さは、余白と直線的な整理感で出す
- 説明しすぎない形を優先し、モノクロでも成立することを重視する

## 採用アセット

- `Assets/Brand/swgraphui-logo-blueprint-asymmetric.svg`
  - 採用ロゴマーク
  - 右側ノード群のサイズと位置を崩した非対称構図
- `Assets/Brand/swgraphui-wordmark.svg`
  - `blueprint-asymmetric` に合わせた横組み wordmark
  - 実文字列 `SwGraphUI` を可読な形で組んだ版

## 採用方針

採用案は `swgraphui-logo-blueprint-asymmetric.svg`。

理由:

- 一般的な完全対称の接続ノード記号から少し外せる
- `Graph` の構造性は残しつつ、固有性を持たせやすい
- シャープさと整然さのバランスがよい

## 使い分け

- アイコン用途:
  - `swgraphui-logo-blueprint-asymmetric.svg`
- ドキュメント見出し:
  - `swgraphui-wordmark.svg`
- 技術資料:
  - `swgraphui-logo-blueprint-asymmetric.svg`

## wordmark メモ

- 現在の wordmark は `blueprint-asymmetric` を左に置き、右側に `SwGraphUI` を組んだ版
- 右余白を減らすため、キャンバス幅は内容に合わせて詰めている
- マーク背景は白
- 文字は `text` 要素ベースなので、最終入稿時に完全固定したい場合はアウトライン化を後続で行う
- README や資料用途の初期案としては十分使える

## QA 観点

- 16px では接続線やグリッドが潰れる可能性がある
- 32px では補助グリッドを省いた簡略版が必要になる可能性がある
- 背景透過版が必要なら次段で追加する

## code-reviewer self-review

- **Review summary**
  - ライブラリ本体と責務境界に影響しない、独立したアセット追加に留めた
- **What is good**
  - `SVG` なので公開 package や README へ流用しやすい
  - 案を 1つに固定せず、選定比較できる状態にした
- **What should change now**
  - 必須ではない。採用案が決まったら透過背景版を追加すると使いやすい
- **What can wait**
  - 書き出し PNG、favicon、asset catalog 化
- **Ready for next milestone?**
  - yes
