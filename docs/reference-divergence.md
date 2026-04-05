# Reference Divergence

このファイルは、SwGraphUI の現状実装が `xyflow` 参照実装とどこで一致し、どこで意図的に差分を持ち、どこが未実装として残っているかを管理する。

参照優先順位:

- logic reference: `@xyflow/system`
- UI / behavior reference: `@xyflow/svelte`
- public API / examples usage reference: `@xyflow/react`

## 判定ルール

- `一致`: 参照実装の責務と挙動に概ね追従できている
- `意図的差分`: SwiftUI / Swift 向けに設計変更しているが、責務としては把握できている
- `未追従`: 参照実装にあるが、SwGraphUI では未実装または一部未達
- `要再判断`: 参照に寄せるか、Swift 向けに再設計するかをまだ決め切っていない

## 現状サマリ (M13 時点)

### 一致

- pure core の型と geometry/bounds/path 計算
- measured node size の同期
- hierarchy を考慮した absolute position 解決
- edge rendering の基本 3 系統
  - bezier
  - straight
  - smoothstep
- handle drag による基本的な connection interaction
- screen-space snap による接続候補探索

### 意図的差分

- `internals.positionAbsolute` を常時保持せず、必要時に計算 / store で補う構成
- SVG path 文字列主導ではなく `PathSegment` を経由した SwiftUI `Path` 描画
- `GraphStore` を `@Observable @MainActor` の公式入口として採用
- `PaddingValue.relative / .points` による型安全な padding API

### 未追従

- wheel / trackpad / pinch を含む zoom interaction
- selection rectangle / multi-selection
- reconnect anchor / edge reconnect interaction
- edge label / toolbar / portal / minimap
- whiteboard 系 interaction
- keyboard interaction / a11y component 群

### 要再判断

- `internals.handleBounds` 相当の内部保持をどこまで導入するか
- `positionAbsolute` を恒常キャッシュするか、現状の解決方式を維持するか
- edge label / marker / animation をどこまで core に寄せるか

## 領域別の乖離一覧

### 1. Internal Node Model

参照:

- `.reference/xyflow/packages/system/src/types/nodes.ts`
- `.reference/xyflow/packages/system/src/utils/store.ts`

判定: `意図的差分`

内容:

- 参照実装は `measured`, `positionAbsolute`, `handleBounds` を internal node に保持する
- SwGraphUI は `measured` は保持しているが、absolute position と handle positions は store / runtime 側で補っている

影響:

- 基本機能は実現できる
- selection rect, reconnect, portal, 複雑な handle 解決では再度 internal cache の必要性が出やすい

### 2. Drag / Pan / Zoom

参照:

- `.reference/xyflow/packages/system/src/xydrag/*`
- `.reference/xyflow/packages/system/src/xypanzoom/*`

判定: `未追従`

一致している点:

- node drag
- hierarchy を考慮した drag
- background pan

未追従の点:

- wheel zoom
- pinch zoom
- auto pan
- drag threshold の細部
- selection on drag

### 3. Connection / Handle

参照:

- `.reference/xyflow/packages/system/src/xyhandle/*`
- `.reference/xyflow/packages/svelte/src/lib/components/Handle/Handle.svelte`
- `.reference/xyflow/packages/svelte/src/lib/components/ConnectionLine/ConnectionLine.svelte`

判定: `一部一致`

一致している点:

- handle drag による接続開始 / 更新 / 終了
- preview line
- self-connection 除外
- hidden / connectable の除外
- hierarchy node を含む handle 座標解決

未追従の点:

- reconnect interaction
- strict / loose mode の運用差
- handle bounds ベースのより厳密な hit 判定

### 4. Edge Rendering

参照:

- `.reference/xyflow/packages/system/src/utils/edges/*`
- `.reference/xyflow/packages/svelte/src/lib/components/edges/*`

判定: `一部一致`

一致している点:

- 3 系統の path
- marker end の基本表示
- drag 追随
- custom edge へ広げやすい中間幾何表現

未追従の点:

- edge label
- edge toolbar
- reconnect anchor
- animation の細部

### 5. Selection

参照:

- `.reference/xyflow/packages/svelte/src/lib/components/Selection/Selection.svelte`
- `.reference/xyflow/packages/svelte/src/lib/components/NodeSelection/NodeSelection.svelte`

判定: `未追従`

内容:

- runtime state 上の選択状態はある
- しかし UI と interaction はまだ未着手で、M14 の対象
- 詳細は [`m14-selection-gap.md`](/Users/kentaro/Projects/SwGraphUI/docs/m14-selection-gap.md) を参照

### 6. Example Coverage

参照:

- `reactflow.dev/examples`
- `.reference/xyflow/examples/react`

判定: `未追従`

内容:

- Example app は `Basic`, `Hierarchy`, `Overlap Test`, `Custom & Measure` の確認用ハーネス段階
- 公開 examples 全面対応にはまだ到達していない

## 次に詰める優先順位

1. Selection (`M14`)
2. Zoom / wheel / pinch interaction
3. reconnect と edge label
4. internal cache (`positionAbsolute`, `handleBounds`) の要否再判断
5. examples coverage の拡張
