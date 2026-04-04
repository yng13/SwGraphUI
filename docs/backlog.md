# Backlog

## Epic 1: 目標と参照元の固定

- [x] `.reference/xyflow` を参照実装としてローカル clone
- [x] `docs` ディレクトリを作成
- [x] 公開 examples 一覧を棚卸し
- [x] examples 確認用 SwiftUI アプリ target を追加
- [x] 公開 examples とローカル `xyflow` route の対応表を作成
- [x] 参照 commit を `docs/reference-lock.md` に固定
- [x] コンポーネント責務境界の初版を定義
- [ ] `system / react / svelte` の責務分割を整理
- [ ] `svelte` を優先参照にする妥当性を評価
- [x] `system` の d3 依存と責務分解を整理
- [x] `system` の core-first 移植順を整理
- [ ] `system` の外部依存全体と SwiftUI 置換方針を整理

## Epic 2: コアモデル設計

- [ ] ノードモデルの型設計
- [ ] エッジモデルの型設計
- [ ] ハンドルと接続ルールの型設計
- [ ] ビューポート座標変換モデルの設計
- [ ] 選択状態とドラッグ状態の設計

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

1. 公開ページの各 example と `.reference/xyflow` 内 source の対応表を作る
2. 初回マイルストーンの core model / pure utility 範囲を Swift 型へ落とす
3. examples を実現するための最小機能集合を抽出する
