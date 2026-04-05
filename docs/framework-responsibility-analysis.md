# Framework Responsibility Analysis

このファイルは、`xyflow` の `system / react / svelte` がそれぞれ何を担当しているかを整理し、SwGraphUI の参照方針を固定するための分析メモである。

## 結論

SwGraphUI では、参照方針を以下で固定する。

- logic reference: `@xyflow/system`
- UI / behavior reference: `@xyflow/svelte`
- React 固有の API 公開面や補助パターンの確認: `@xyflow/react`

つまり、主参照は `system + svelte` とし、`react` は公開 API と example 接続の補助参照として扱う。

## 各 package の責務

### `@xyflow/system`

主な責務:

- framework 非依存の型
- graph utility
- bounds, transform, marker, connection などの計算
- pan/zoom, drag, resize, connect の interaction logic

含むもの:

- `types/*`
- `utils/*`
- `xypanzoom/*`
- `xydrag/*`
- `xyhandle/*`
- `xyresizer/*`
- `xyminimap/*`

SwGraphUI での扱い:

- 最重要の logic reference
- pure Swift に落とせる責務を最優先で移植する

### `@xyflow/react`

主な責務:

- React 向け公開 API
- provider / hooks / context
- React store
- React component tree と DOM 連携
- examples との接続が豊富

構成上の特徴:

- `container`, `components`, `hooks`, `store`, `types`, `additional-components`
- hooks と provider が公開面の中心
- React idiom が強い

SwGraphUI での扱い:

- 主参照にはしない
- 以下の確認に限定して使う
  - 公開 API の意味
  - example がどの機能をどう使っているか
  - React Flow が利用者に何を約束しているか

### `@xyflow/svelte`

主な責務:

- UI 表示と behavior の統合
- container / component / plugin の分離
- store を中心にした state 統合
- `system` への薄い接続

構成上の特徴:

- `container`, `components`, `plugins`, `store`, `hooks`
- UI 構造が React より素直
- provider / hook 文化が React より薄く、描画責務が追いやすい

SwGraphUI での扱い:

- UI / behavior の主参照
- ただし Svelte 固有 reactivity はそのまま模倣しない

## `svelte` を主参照にする妥当性

### 賛成理由

- `system` と `svelte` の境界が比較的読みやすい
- `container / components / plugins / store` の分離が、SwGraphUI の責務境界に近い
- React 固有の context / hook / middleware に引っ張られにくい
- SwiftUI の宣言的 UI に寄せて考えやすい

### 注意点

- Svelte の `$state`, `$derived` は SwiftUI / Observation と完全一致しない
- store class の持ち方はそのまま Swift に移すべきではない
- hooks 名や公開面は React 側のほうが docs / examples と結びついている

### 結論

`svelte` を UI / behavior の主参照にするのは妥当。  
ただし、以下の分担で使うのがよい。

- 振る舞いと描画責務: `svelte`
- algorithm と型: `system`
- 公開 API の意味と examples 接続: `react`

## SwGraphUI への写像

- `system/types` -> `Core/Model`
- `system/utils` -> `Core/Algorithms`
- `system/xydrag`, `xypanzoom`, `xyhandle`, `xyresizer` -> `Core/Interaction`
- `svelte/store` -> `Runtime/State`
- `svelte/container` -> `UI/Container`
- `svelte/components` -> `UI/Components`
- `svelte/plugins` -> `UI/Plugins`
- `react/hooks`, `react/provider` -> public API 検討時の参考資料

## 使い分けルール

### 実装前

- まず `system` の該当型と utility を見る
- 次に `svelte` の container / component / store を見る
- 公開 API の意味が曖昧なときだけ `react` を見る

### 実装中

- logic の根拠は `system`
- UI behavior の根拠は `svelte`
- 利用者向け naming や surface の整合確認は `react`

### 実装後

- edge rendering / marker / animation / label / handle affordance は `system + svelte` を再参照する

## 今後の判断

- もし `svelte` 側にしかない簡便化がある場合でも、`system` と矛盾するなら `system` を優先する
- public API は `react` の hook surface を模倣せず、SwiftUI に自然な形へ再構成する

## 現状の追従状況 (M13 時点)

### `system` に対して揃ってきたもの

- pure core model / geometry / graph utility
- measured size の同期
- edge path 計算
- drag / pan / connection の基礎 state machine

### `svelte` に対して揃ってきたもの

- `GraphView` による canvas container
- node / edge / preview line の基本レイヤー
- handle component の基礎
- Example app による確認用 harness

### まだ差が大きいもの

- selection components
- edge label / reconnect anchor / portal / minimap
- wheel / pinch / keyboard interaction
- whiteboard / advanced UI plugins

### 運用方針

- 今後は `system` の algorithm 差分だけでなく、`svelte` の UI component 差分も [`reference-divergence.md`](/Users/kentaro/Projects/SwGraphUI/docs/reference-divergence.md) で並行管理する
