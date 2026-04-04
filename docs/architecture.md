# Architecture

## 基本方針

- SwGraphUI は SwiftUI ネイティブなグラフ UI ライブラリとして設計する
- React Flow の概念を写経するのではなく、SwiftUI で自然な API に再構成する
- ただし、examples を再現するために必要な概念互換性は維持する

## 参照実装の見方

- `xyflow` 参照実装には `system`, `react`, `svelte` の層がある前提で調査を進める
- SwiftUI への移植観点では、UI フレームワーク差分の小ささから `svelte` 実装が有力な参照候補になる可能性がある
- 一方で、コアロジックやアルゴリズムは `system` 層の責務も大きいため、UI 層だけを見て移植判断しない
- `system` には `d3-zoom` を含む外部依存が多く含まれる想定であり、SwiftUI gesture, transform, layout, animation でどう再現するかを別途整理する

`d3-*` 依存の分解結果は `d3-dependency-analysis.md` に分離して管理する。
`system / react / svelte` の責務整理は `framework-responsibility-analysis.md` に分離して管理する。
package の将来構成案は `package-layout.md` に分離して管理する。

## 設計原則

- ノード、エッジ、ハンドル、ビューポート、選択状態、接続状態を明示的なモデルとして定義する
- レンダリング層とインタラクション層を分離する
- 組み込みノード/エッジとカスタムノード/エッジを同じ拡張ポイントで扱えるようにする
- examples の再現を通じて API を育てる
- React 固有の仕組みではなく、SwiftUI の state, binding, gesture, layout に寄せる
- 責務境界を先に固定し、状態管理と描画を混線させない
- 実装単位ごとに未実装を宙に浮かせず、その場で閉じるか後続責務へ明示的に送る
- エクスポート系機能は画面描画の副産物として扱わず、出力用レイアウト計算と出力 backend を分離する
- 出力品質は `PDF/印刷はベクタ優先`、`PNG は指定 scale で再レンダリング` を原則とし、拡大時にラスタ文字を引き伸ばさない

## マイルストーン運用

- 各マイルストーンでは、対象範囲の未実装をなるべく残さない
- 今回で閉じない項目は、`後でやる` ではなく、次のどの責務として送るかを明示する
- `残課題` という表現だけで曖昧に終わらせず、`今回で閉じたこと` と `後続へ送る責務` に分けて管理する

## 初期モジュール案

- `Graph`: グラフ全体の状態、ノード、エッジ、座標空間
- `Viewport`: pan, zoom, fit, transform 管理
- `Selection`: 選択、矩形選択、複数選択
- `Connection`: ハンドル接続、検証、プレビュー線
- `Nodes`: 組み込みノード、カスタムノード拡張
- `Edges`: 組み込みエッジ、カスタムエッジ拡張
- `Export`: 印刷、PDF、PNG 出力。viewport 切り出し、全体 fit、出力 scale、背景、余白を管理
- `Examples`: 受け入れ検証用サンプル群
- `Example App`: examples を手元で確認するための SwiftUI 実行 target

責務境界の詳細は `responsibility-boundaries.md` に分離して管理する。

## 非目標

- React 向け API 名や hook 名をそのまま Swift に持ち込むこと
- 初期段階で全 example を同時に実装すること
- まず見た目だけ整えて内部モデルを後回しにすること

## 設計ドキュメントの進め方

- まず examples を機能別に分解する
- 次にコアモデルと拡張ポイントを定義する
- その後、最小の example 群を実装して API の妥当性を検証する
