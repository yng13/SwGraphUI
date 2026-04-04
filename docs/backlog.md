# Backlog

## Epic 1: 目標と参照元の固定

- [x] `.reference/xyflow` を参照実装としてローカル clone
- [x] `docs` ディレクトリを作成
- [x] 公開 examples 一覧を棚卸し
- [x] examples 確認用 SwiftUI アプリ target を追加
- [x] 公開 examples とローカル `xyflow` route の対応表を作成
- [x] 参照 commit を `docs/reference-lock.md` に固定
- [x] コンポーネント責務境界の初版を定義
- [x] `system / react / svelte` の責務分割を整理
- [x] `svelte` を優先参照にする妥当性を評価
- [x] `system` の d3 依存と責務分解を整理
- [x] `system` の core-first 移植順を整理
- [x] `system` の外部依存全体と SwiftUI 置換方針を整理
- [x] 将来の package directory 構成案を定義

## Epic 2: コアモデル設計

- [x] `Sources/SwGraphUI` の最小ディレクトリ構成を作成
- [x] 座標・矩形・接続・変更差分の初期型を追加
- [x] ノードモデルの初期型設計
- [x] エッジモデルの初期型設計
- [x] ハンドルと接続ルールの初期型設計
- [x] ビューポート座標変換モデルの初期型設計
- [x] 選択状態とビューポート状態の初期設計
- [x] `GraphNode / GraphEdge` を正規 public 名として固定
- [x] graph / connection / edge path / bounds / viewport utility を追加
- [x] drag / connection / hover を含む runtime state を追加
- [/] `Core/Interaction` の責務境界を定義 (M8)
- [/] `Runtime/State` と `Interaction` の境界を整理 (M8)

## Epic 3: 最小ランタイム実装

- [ ] 基本的なノード表示
- [ ] 基本的なエッジ表示
- [/] pan / zoom (Core logic only in M8)
- [ ] ノード選択
- [/] ノードドラッグ (Core logic only in M8)
- [ ] ハンドル接続

## Epic 4: 受け入れ用 examples

- [ ] Feature Overview
- [ ] Basic interaction 相当 example 群
- [ ] Custom Node / Edge 系 example 群
- [ ] Layout 系 example 群
- [ ] Whiteboard 系 example 群
- [ ] UI components 系 example 群

## Epic 5: 拡張機能

- [x] 印刷/PDF エクスポートの要件定義 (`docs/export-strategy.md`)
- [x] PNG エクスポートの要件定義 (`docs/export-strategy.md`)
- [ ] export 用レイアウト計算の責務境界を定義
- [ ] PDF/印刷をベクタ優先で出力する backend 方針を定義
- [ ] PNG を指定 scale で再レンダリングする backend 方針を定義
- [ ] 文字ぼやけ回避の品質基準を定義
- [ ] Example app に export 検証ハーネスを追加

## 直近の次アクション (M8: Core Interaction)

1. `Core/Interaction` における Drag/Zoom/Pan の状態遷移エンジンを設計する
2. `GraphRuntimeState` から Interaction ロジックを分離し、副作用（座標更新）の適用タイミングを整理する
3. `fitView` / `centerView` の Core アルゴリズムを完成させる
