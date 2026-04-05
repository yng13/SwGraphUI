# M14 Selection Gap

このファイルは、[`reference-divergence.md`](/Users/kentaro/Projects/SwGraphUI/docs/reference-divergence.md) のうち、M14 で直接扱うべき差分だけを切り出した作業メモである。

対象スコープ:

- node selection
- edge selection
- background click による clear
- selection と drag / connect の競合回避

対象外:

- selection rectangle
- multi-selection marquee
- undo / redo
- keyboard shortcut の高度化

## 参照元

- `@xyflow/system`
  - `.reference/xyflow/packages/system/src/styles/init.css`
  - `.reference/xyflow/packages/system/src/styles/base.css`
  - `.reference/xyflow/packages/system/src/xypanzoom/filter.ts`
- `@xyflow/svelte`
  - `.reference/xyflow/packages/svelte/src/lib/components/Selection/Selection.svelte`
  - `.reference/xyflow/packages/svelte/src/lib/components/NodeSelection/NodeSelection.svelte`
  - `.reference/xyflow/packages/svelte/src/lib/components/NodeWrapper/NodeWrapper.svelte`
  - `.reference/xyflow/packages/svelte/src/lib/components/EdgeWrapper/EdgeWrapper.svelte`

## 現状

### すでにあるもの

- `SelectionState`
  - node / edge の selected ID 集合
- `BaseNode.selected`
- `BaseEdge.selected`
- `DefaultNodeView` の selected ハイライト
- `DefaultEdgeView` の selected stroke 差分

### まだ不足しているもの

- node click から `selected` を更新する UI 経路
- edge click から `selected` を更新する UI 経路
- background click による clear
- 選択と drag / connect の優先順位整理
- selection state と `BaseNode.selected` / `BaseEdge.selected` の同期責務の固定

## M14 で埋めるべき差分

### 1. Node Selection

判定: `未追従`

必要なこと:

- ノード click で単一選択
- 既存選択の clear
- 再クリック時の toggle を採るかどうかの判断

初回方針:

- 単一選択を正式スコープにする
- multi-select modifier は後ろに送る

### 2. Edge Selection

判定: `未追従`

必要なこと:

- edge click で単一選択
- node と edge の排他的選択
- `DefaultEdgeView` の selected 見た目反映

初回方針:

- edge も node と同じ単一選択に揃える

### 3. Background Clear

判定: `未追従`

必要なこと:

- canvas 背景 click で selection clear
- pan gesture と競合しない条件設計

初回方針:

- pan は drag
- clear は tap
- `minimumDistance` ベースで役割を分離

### 4. Interaction Priority

判定: `要整理`

必要なこと:

- node drag 開始時に click selection と誤判定しない
- handle drag 開始時に node selection を発火させない
- background pan 開始時に clear と誤判定しない

初回方針:

- click / tap は end phase でのみ確定
- drag が一定距離を超えたら selection/tap をキャンセル

### 5. Selection State Sync

判定: `要整理`

必要なこと:

- `SelectionState.selectedNodeIDs` と `BaseNode.selected` の同期
- `SelectionState.selectedEdgeIDs` と `BaseEdge.selected` の同期

初回方針:

- `GraphStore` を唯一の同期点にする
- runtime state と model flags を同時更新する

## M14 で扱わない差分

- selection rectangle
- lasso / whiteboard 選択
- keyboard shortcut
- z-index の高度な selection mode
- `NodeSelection.svelte` 相当の矩形 UI

## Exit Rule (M14 向け)

- node を click すると単一選択される
- edge を click すると単一選択される
- 背景 click で全解除される
- drag / connect / pan と click selection が誤発火しない
- `DefaultNodeView` / `DefaultEdgeView` の見た目が selection state と一致する
