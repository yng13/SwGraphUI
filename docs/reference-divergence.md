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

### 一致 / 受け入れ可

- pure core の型と geometry/bounds/path 計算
- measured node size の同期
- hierarchy を考慮した absolute position 解決
- edge rendering の基本 3 系統 (bezier, straight, smoothstep)
- handle drag による基本的な connection interaction
- screen-space snap による接続候補探索
- wheel / trackpad / pinch を含む zoom interaction (macOS 中心)
- selection rectangle / marquee select
- multi-selection (nodes & edges)
- **edge label** (base rendering)
- **reconnect anchor** (interactive reconnection)

### 意図的差分

- `internals.positionAbsolute` を常時保持せず、必要時に計算 / store で補う構成
- SVG path 文字列主導ではなく `PathSegment` を経由した SwiftUI `Path` 描画
- `GraphStore` を `@Observable @MainActor` の公式入口として採用
- `PaddingValue.relative / .points` による型安全な padding API
- iOS pinch zoom の中心点（hover座標取得不可による (0,0) フォールバック）

### 未着手 / 未完

- whiteboard 系 interaction
- toolbar / portal / minimap
- whiteboard 系 interaction
- keyboard interaction / a11y component 群 (一部 bridge 実装済み)
- auto pan

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

判定: `一部一致`

一致している点:

- node drag
- hierarchy を考慮した drag
- background pan
- pinch zoom (MagnifyGesture)
- wheel zoom (Mac: Cmd/Ctrl + Scroll)
- background drag select (Marquee)

未追従の点:

- iOS でのピンチズームの中心点追従 (意図的差分: 現在 macOS ではカーソル位置基準だが、iOS では hover API の制約により座標が取れないため実質的に左上 `(0,0)` 基準となる)
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
- **reconnect interaction** (既存エッジの端点ドラッグによる更新)

未追従の点:
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
- **edge label** (座標計算と基本表示)
- **reconnect anchor** (選択時のハンドル表示)

未追従の点:

- edge toolbar
- animation の細部

### 5. Selection

参照:

- `.reference/xyflow/packages/svelte/src/lib/components/Selection/Selection.svelte`
- `.reference/xyflow/packages/svelte/src/lib/components/NodeSelection/NodeSelection.svelte`

判定: `一部一致`

内容:

- M14〜M16 にかけて UI と interaction が実装完了 (`selectAll`, `deleteSelection`, Shift+Drag 矩形選択, Connected Edge 選択含む)
- **差異**: `selection on drag` (ドラッグ開始時の選択連動) や、周辺の keyboard/accessibility 連動、複数選択時のバウンディングボックス表示などは未実装。

### 6. Example Coverage

参照:

- `reactflow.dev/examples`
- `.reference/xyflow/examples/react`

判定: `一部一致`

内容:

- Example app は `overview`, `interaction` カテゴリを追加し、基本的な受け入れ確認ハーネスを構築済み
- `Basic`, `Hierarchy`, `Overlap Test`, `Custom & Measure` のデバッグ用テスト配置も維持
- コア機能（Selection, Zoom, Drag, Hierarchy）の動作検証用として「受け入れ可」水準に到達

## 次に詰める優先順位

1. internal cache (`positionAbsolute`, `handleBounds`) の要否再判断
2. auto pan 実装
4. examples coverage の拡張 (Stress Test, Save/Restore 等)
5. A11y / Keyboard interaction の体系的整理
