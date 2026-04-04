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
- [ ] `system` の外部依存全体と SwiftUI 置換方針を整理
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
- [ ] `Core/Interaction` の責務境界を定義
- [ ] `Runtime/State` と `Interaction` の境界を整理

## Epic 3: 最小ランタイム実装

- [ ] 基本的なノード表示
- [ ] 基本的なエッジ表示
- [ ] pan / zoom
- [ ] ノード選択
- [ ] ノードドラッグ
- [ ] ハンドル接続

## Epic 4: 受け入れ用 examples

- [ ] Feature Overview
- [ ] Basic interaction 相当 example 群
- [ ] Custom Node / Edge 系 example 群
- [ ] Layout 系 example 群
- [ ] Whiteboard 系 example 群
- [ ] UI components 系 example 群

## 直近の次アクション

1. `Core/Interaction` の責務と対象 state を定義する
2. `Runtime/State` と `Interaction` の境界を切る
3. interaction engine の最小実装に入る
