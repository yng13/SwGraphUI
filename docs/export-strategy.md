# Export Strategy

## 位置づけ

- 印刷/PDF・PNG エクスポートは拡張フェーズの機能として扱う
- 実装優先度は `Core -> Runtime -> UI` の後段とし、基底フェーズの pure Swift 実装を崩さない
- ただし、後で作り直しにならないよう、出力責務と品質基準は先に固定する

## 対象機能

- 印刷
- PDF エクスポート
- PNG エクスポート

## 前提

- 画面描画用の viewport をそのままキャプチャして拡大する方式は採らない
- 出力時は、対象 bounds、余白、背景、scale、出力範囲を明示的に指定できるようにする
- text は可能な限り再レイアウト・再描画し、既存のラスタ結果を単純拡大しない

## 品質原則

- PDF/印刷:
  - ベクタ出力を優先する
  - テキスト、線、ベジェ、ハンドル、選択矩形は可能な限りベクタとして出す
  - 出力 zoom を上げても文字輪郭がぼやけないことを受け入れ条件にする
- PNG:
  - 画面の低解像度スナップショットを引き伸ばさない
  - 指定 `scale` で再レンダリングする
  - retina 相当以上の scale 指定を可能にする
  - 背景色、透明背景、余白の指定を可能にする

## 設計方針

- `Export` は最低でも以下の責務に分ける
  - `ExportLayout`
    - 対象 node/edge bounds
    - export viewport
    - fit-to-page
    - margin
    - background
  - `ExportOptions`
    - format (`print` / `pdf` / `png`)
    - scale
    - include background
    - include minimap など将来拡張
  - `ExportRenderer`
    - PDF/印刷向け backend
    - PNG 向け backend

- 画面用 `ViewportState` と export 用 viewport は分ける
- export は「現在見えている領域の保存」と「グラフ全体 fit」の両方を扱えるようにする
- backend 実装は platform 差分を含み得るが、export layout 計算自体は pure Swift に置く

## ぼやけ対策

- 禁止:
  - 既存 view の raster snapshot をそのまま拡大して PDF/PNG に流用すること
- 推奨:
  - PDF/印刷は drawing command ベース、またはベクタ互換の描画 backend を使う
  - PNG は export 専用 scale で再描画する
  - text は export 時にも font metrics ベースで再レイアウトされること

## 受け入れ条件の初案

- PDF を 400% 表示しても、ノードラベルの輪郭が著しくぼやけない
- PNG を `scale: 2` 以上で出力したとき、1x 画面スナップショットの単純拡大より文字と線が明瞭である
- export 対象範囲として `current viewport` と `graph bounds` を選べる
- margin, background, scale の指定が API から可能である

## 後続へ送る責務

- `Export` モジュールを package 構成案にどう入れるか
- macOS の印刷/PDF backend を `SwiftUI` / `AppKit` のどこで受けるか
- PNG backend の最初の対応範囲を macOS 限定にするか
