# D3 Dependency Analysis

このファイルは、`@xyflow/system` が依存している `d3-*` を、SwGraphUI でどう分解して置き換えるかを整理するための分析メモである。

## 前提

- 参照対象: `/Users/kentaro/Projects/SwGraphUI/.reference/xyflow`
- 固定 commit: `a58568f11bc0e1a1bdca1b3549e959e2e1ca0cdd`
- 対象 package: `@xyflow/system`

## 結論

`d3-*` は AppKit / UIKit の代替ではない。役割は主に以下である。

- 入力イベントの抽象化
- zoom / drag の state machine
- transform の保持と制約
- 補間アニメーション
- pointer 座標取得

SwGraphUI では、これらを一枚で置き換えるのではなく、以下に分解して持つ。

- `Core Algorithms`: transform、bounds、座標変換、制約、補間計算
- `Interaction Engine`: drag / pan / zoom / resize / connect の state machine
- `SwiftUI Adapter`: gesture の受け取り
- `Platform Adapter`: 必要時のネイティブイベント補助

## 依存一覧

### `d3-zoom`

参照箇所:

- `packages/system/src/xypanzoom/XYPanZoom.ts`
- `packages/system/src/xypanzoom/utils.ts`
- `packages/system/src/xypanzoom/eventhandler.ts`
- `packages/system/src/xyminimap/index.ts`
- `packages/system/src/types/panzoom.ts`
- `packages/system/src/types/general.ts`

担っている責務:

- viewport transform の保持
- scale extent, translate extent の制約
- wheel / pinch / drag に対する zoom/pan 振る舞い
- minimap 上の pan / zoom
- zoom lifecycle のイベント配線

SwGraphUI での分解先:

- `Core Model`: `Viewport`, `Transform`
- `Core Algorithms`: viewport 制約、fit、座標変換
- `Interaction Engine`: pan/zoom state machine
- `SwiftUI Adapter`: wheel / pinch / drag gesture 入力

置換方針:

- `ZoomTransform` 型依存は Swift 独自型に置換する
- `zoom().scaleExtent().translateExtent()` のような一体 API は採用しない
- 制約計算と gesture 解釈は分離する

### `d3-drag`

参照箇所:

- `packages/system/src/xydrag/XYDrag.ts`
- `packages/system/src/xyresizer/XYResizer.ts`
- `packages/system/src/types/general.ts`
- `packages/system/src/xyresizer/types.ts`

担っている責務:

- ノードドラッグ開始 / 更新 / 終了
- 複数選択ドラッグ
- リサイズハンドルのドラッグ
- drag threshold の処理

SwGraphUI での分解先:

- `Interaction Engine`: drag / resize state machine
- `Core Algorithms`: snap、extent 制約、child 補正
- `SwiftUI Adapter`: drag gesture 入力

置換方針:

- drag gesture 自体は SwiftUI 側で受ける
- 位置更新、snap、extent 制約は pure Swift に残す
- ノードドラッグとリサイズは gesture は似ていても state machine を分ける

### `d3-selection`

参照箇所:

- `packages/system/src/xydrag/XYDrag.ts`
- `packages/system/src/xypanzoom/XYPanZoom.ts`
- `packages/system/src/xypanzoom/eventhandler.ts`
- `packages/system/src/xyminimap/index.ts`
- `packages/system/src/xyresizer/XYResizer.ts`
- `packages/system/src/types/general.ts`

担っている責務:

- DOM node への behavior 適用
- event target からの pointer 座標取得
- `__zoom` のような selection state 保持
- transition の起点

SwGraphUI での分解先:

- `SwiftUI Adapter`: gesture と view 参照の接続
- `Platform Adapter`: 必要なら pointer 座標取得補助
- `Core State`: DOM 非依存の transform 状態保持

置換方針:

- DOM selection という概念は持ち込まない
- view instance に状態をぶら下げず、Store/State 側に寄せる
- pointer 位置は gesture value と座標変換から計算する

### `d3-interpolate`

参照箇所:

- `packages/system/src/xypanzoom/XYPanZoom.ts`

担っている責務:

- viewport 変更時の補間方式
- smooth / linear の切り替え

SwGraphUI での分解先:

- `Core Algorithms`: 補間関数
- `SwiftUI Adapter`: 実際の animation 適用

置換方針:

- 補間関数は pure Swift で定義する
- animation clock や transaction は SwiftUI 側に委ねる

### `d3-transition`

参照箇所:

- `packages/system/src/xypanzoom/XYPanZoom.ts`
- `packages/system/src/xypanzoom/utils.ts`
- `packages/system/src/types/general.ts`

担っている責務:

- transform 遷移の duration / ease / end callback

SwGraphUI での分解先:

- `Core Algorithms`: ease 関数
- `SwiftUI Adapter`: animation 実行

置換方針:

- `transition()` のような imperative API は持ち込まない
- public API には `duration / ease / interpolate` のような意味だけ残し、実行は SwiftUI / platform に委ねる

## d3 依存の実体別整理

### 1. pure Swift に落とせるもの [移行済み]

- [x] `Viewport` と `Transform` の型
- [x] scale / translate の制約 (`ViewportManager`)
- [x] fit bounds (`ViewportManager`)
- [x] snap to grid (`DragManager`)
- [x] pointer 座標から graph 座標への変換 (`CoordinateAdapter`)
- [ ] 補間関数 (SwiftUI Animation で代用中)
- [ ] auto pan の計算

### 2. state machine として持つべきもの [一部移行済み]

- [x] pan 開始 / 更新 / 終了 (`GraphStore.pan(by:)`)
- [ ] zoom 開始 / 更新 / 終了 (SwiftUI `MagnificationGesture` 直接連動)
- [x] node drag 開始 / 更新 / 終了 (`DragManager`)
- [ ] resize 開始 / 更新 / 終了
- [x] connection drag 開始 / 更新 / 終了 (`ConnectionState`, `ConnectionInteractionManager`, `HandleView`)

### 3. SwiftUI / platform に寄せるべきもの [一部移行済み]

- [x] gesture 入力の取得 (`GraphView`)
- [ ] wheel / trackpad / pinch の OS 差分 (現在 DragGesture による pan のみ)
- [ ] pointer style
- [x] ネイティブ event bridging (GraphView / Example harness の最小統合)

## 重要な設計判断

### 置換単位は「依存」ではなく「責務」

- [x] **Viewport 座標系**: 階層的な View 変形の影響を受けない `viewport_container` を導入し、d3-selection の DOM 位置計算依存を排除した。
- [x] **入力の統制**: View からの生入力を `CoordinateAdapter` で正規化してから Store に送る流れを確立。

避けるべきこと:

- `XYPanZoom` をそのまま Swift に写経する
- `d3-drag` 相当の共通ヘルパーを先に大きく作る
- SwiftUI View の中に transform / selection / connection state を埋め込む

優先すべきこと:

- 先に `ViewportState` と `PanZoomEngine` の責務を分ける
- drag, resize, connect を別 state machine として扱う
- public API は d3 用語ではなく graph UI の意味で定義する

## 現状メモ (M13 時点)

- `d3-drag` 相当:
  - node drag は基礎実装済み
  - connection drag も基礎実装済み
  - resize は未着手
- `d3-zoom` 相当:
  - fitView, pan, viewport transform はある
  - wheel / pinch / trackpad は未着手
- `d3-selection` 相当:
  - view 参照への behavior 適用は行わず、`PreferenceKey` と `CoordinateAdapter` に分解している
- `d3-transition` / `d3-interpolate` 相当:
  - animation / interpolation は最小限で、まだ本格対応していない

## 初期実装への示唆

最初に必要なのは `d3-*` 全置換ではない。以下の最小集合を先に作る。

1. `Viewport` / `Transform` 型
2. viewport 制約計算
3. graph 座標変換
4. node drag state machine
5. pan / zoom state machine
6. snap to grid

この順で進めると、`Basic`, `Drag and Drop`, `Save and Restore`, `Node Resizer`, `Validation` などの土台になる。
