# System Migration Order

このファイルは、`@xyflow/system` を SwGraphUI へ移す際の優先順位を、`外部依存の少なさ` と `コア性` の両方で決めるための棚卸しである。

## 方針

移植順は単純なファイル順ではなく、以下の優先度で決める。

1. 外部依存がない
2. 多くの機能から再利用される
3. 公開 examples の基盤になる
4. UI / DOM / d3 に引っ張られない

言い換えると、`葉だから先` ではなく、`軽くてコアだから先` で進める。

## 依存強度の分類

### Tier 0: 依存なしの pure core

特徴:

- `d3-*` 依存なし
- DOM 依存なし
- Swift にそのまま概念移植しやすい

候補:

- `types/utils.ts`
- `types/changes.ts`
- `types/handles.ts`
- `types/edges.ts`
- `utils/connections.ts`
- `utils/edge-toolbar.ts`
- `utils/general.ts`
- `utils/graph.ts`
- `utils/marker.ts`
- `utils/node-toolbar.ts`
- `utils/shallow-node-data.ts`
- `utils/types.ts`
- `utils/edges/bezier-edge.ts`
- `utils/edges/general.ts`
- `utils/edges/positions.ts`
- `utils/edges/smoothstep-edge.ts`
- `utils/edges/straight-edge.ts`

注意:

- `utils/graph.ts` は pure だが広い。初回は必要な関数だけ切り出して移すのがよい。
- `edge-toolbar` や `node-toolbar` は pure ではあるが、初回マイルストーンの優先度は低い。

### Tier 1: 軽依存の core-adjacent

特徴:

- 一部に DOM 型や d3 型が混ざる
- ただし中身の大半は core model に近い

候補:

- `types/nodes.ts`
- `types/general.ts`
- `types/panzoom.ts`

扱い:

- 型全体を一気に移さず、pure な部分と platform 依存部分に分解してから持っていく

具体例:

- `types/nodes.ts` の `NodeBase`, `InternalNodeBase`, `NodeOrigin` は core 候補
- `HTMLDivElement` を含む `InternalNodeUpdate` は後回し
- `types/panzoom.ts` は `Viewport` 周辺の意味は使えるが、`ZoomTransform` 依存は切り離す

### Tier 2: DOM 依存

特徴:

- `Element`, `HTMLDivElement`, `DOMRect`, `window`, `document` に依存する
- SwiftUI 直下または platform adapter 寄り

候補:

- `utils/dom.ts`
- `utils/store.ts`

扱い:

- そのまま移さない
- `計測`, `座標取得`, `handle bounds 取得` などの責務に分ける

### Tier 3: d3 / interaction 依存

特徴:

- `d3-drag`, `d3-zoom`, `d3-selection`, `d3-interpolate`, `d3-transition`
- state machine と gesture の境界にいる

候補:

- `xydrag/*`
- `xypanzoom/*`
- `xyresizer/*`
- `xyminimap/*`

扱い:

- 初回では実装しない
- 先に Core Model / Core Algorithms を固め、その後に Interaction Engine として再設計する

### Tier 4: mixed / facade

特徴:

- 再 export や package の入口

候補:

- `index.ts`
- `types/index.ts`
- `utils/index.ts`
- `constants.ts`

扱い:

- Swift 側のモジュール構造が固まった後で決める

## 初回マイルストーン候補

初回で切るべきなのは、Tier 0 の中でも `高コア性` のあるものに限定する。

### Included

- `types/utils.ts`
- `types/changes.ts`
- `types/handles.ts`
- `types/edges.ts`
- `types/nodes.ts` の pure 部分を分解した core model
- `utils/general.ts` の pure geometry / bounds / transform 系
- `utils/graph.ts` の graph traversal / bounds 系
- `utils/connections.ts`
- `utils/edges/*` の pure path 計算

### Excluded

- `utils/dom.ts`
- `utils/store.ts`
- `xydrag/*`
- `xypanzoom/*`
- `xyresizer/*`
- `xyminimap/*`
- toolbar 系の詳細
- marker の細部

## 初回マイルストーンの狙い

このマイルストーンでは、以下を Swift の pure core として成立させる。

- 座標と矩形の基礎型
- ノード / エッジ / ハンドルの基礎型
- graph traversal
- bounds 計算
- edge path 計算の pure 部分
- 接続関係の pure utility

これで次の interaction 実装の土台を先に固定する。

## この順番がよい理由

- `Basic`, `Feature Overview`, `Custom Node`, `Edge Types`, `Save and Restore` などの土台になる
- d3 / DOM 依存を後回しにできる
- Core Model を先に確定できるので、後から SwiftUI 実装で public API がぶれにくい

### Tier 0: 依存なしの pure core [完了]
- [x] Foundation (Types, Geometry, Bounds)
- [x] Edge Path Core Logic

### Tier 1: 軽依存の core-adjacent [完了]
- [x] Node / Edge Models
- [x] Viewport Transform Logic

### Tier 2: DOM 依存 [SwiftUI Adapter で代替完了]
- [x] Canvas Container (`GraphView`)
- [ ] Measurement Engine (実測値の Core へのフィードバックのみ未完了)

### Tier 3: d3 / interaction 依存 [着手 / M10a 改修中]
- [x] Viewport Pan Interaction (`GraphStore`)
- [ ] Viewport Zoom / Wheel Interaction
- [x] Node Drag Interaction (`DragManager`)
- [ ] Connection Interaction
- [ ] Resizer Interaction

## 現在のフェーズ: Tier 3 Refinement & Adaptive UI

M10a を経て、Viewport の安定性と IDE スタイルのハーネスが構築された。
次の焦点は、Tier 2 の残りである **Measurement Engine** と、Tier 3 の **Connection Interaction** である。

## 実装順の履歴

1. [x] 座標・矩形・変更差分の型
2. [x] Node / Edge / Handle の core model
3. [x] graph / connection の pure utility
4. [x] edge path / bounds 計算
5. [x] viewport model
6. [x] GraphStore による Interaction 統制 (M9-M10a)
7. [ ] Measurement Engine (M10b/11)

## コミット単位

初回マイルストーンが切れた段階で 1 回コミットしてよい。

対象:

- docs の依存分類
- current plan / backlog 更新
- 次に着手する core model 範囲の確定
