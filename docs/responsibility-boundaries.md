# Responsibility Boundaries

このファイルは、SwGraphUI の各コンポーネント責務境界を先に固定するための設計メモである。

## 目的

- viewport, selection, drag, connect, render の責務混線を防ぐ
- pure Swift のコア層と、将来の SwiftUI / platform adapter 層を分離する
- `@xyflow/system` と `@xyflow/svelte` を参照しつつ、SwGraphUI 側の境界を先に決める

## 参照実装から見える大枠

### `@xyflow/system`

責務の中心は以下に分かれている。

- `types`: ノード、エッジ、変更差分、viewport、handle などの共通型
- `utils`: グラフ探索、bounds、marker、toolbar 位置、接続補助
- `xypanzoom`: pan / zoom 制御
- `xydrag`: ノードドラッグ制御
- `xyhandle`: 接続開始、接続中、接続確定、接続検証
- `xyresizer`: ノードリサイズ
- `xyminimap`: minimap 用の補助

### `@xyflow/svelte`

責務の中心は以下に分かれている。

- `store`: UI 状態と interaction state の保持
- `container`: ルートコンテナと描画統合
- `components`: node / edge / handle / portal などの表示部品
- `plugins`: controls, background, minimap, toolbar, resizer
- `hooks`: store 操作と購読のための API

## SwGraphUI の責務境界

### 1. Core Model

責務:

- ノード、エッジ、ハンドル、ポート、座標、bounds、viewport などの基礎型定義
- 変更差分の表現
- 直列化可能な graph state の表現

含むもの:

- `Node`
- `Edge`
- `Handle`
- `Viewport`
- `GraphSnapshot`
- `NodeChange`, `EdgeChange`

含めないもの:

- gesture
- SwiftUI View
- platform event

### 2. Core State

責務:

- グラフの実行時 state を保持する
- 選択、hover、drag、connect、viewport の状態遷移を扱う
- 純粋な state mutation と query を提供する

含むもの:

- `SelectionState`
- `ConnectionState`
- `DragState`
- `ViewportState`
- 内部 lookup

含めないもの:

- 描画ロジック
- gesture recognizer
- アニメーション実行

### 3. Core Algorithms

責務:

- state や model に対する純粋関数を提供する
- hit test、座標変換、bounds 計算、接続検証、visible elements 判定を扱う

含むもの:

- bounds 計算
- graph traversal
- handle 検索
- marker 幾何
- toolbar 配置計算
- viewport fit 計算

含めないもの:

- DOM 依存処理
- SwiftUI dependency

### 4. Interaction Engine

責務:

- platform から届いた入力を Core State のイベントへ変換する
- pan / zoom / drag / connect / resize の state machine を持つ

含むもの:

- pointer down / move / up の解釈
- selection drag 開始 / 更新 / 終了
- node drag 開始 / 更新 / 終了
- connection drag 開始 / 更新 / 終了
- viewport gesture の解釈

含めないもの:

- 具体的な `DragGesture` や `MagnificationGesture`
- AppKit / UIKit イベント

補足:

- `@xyflow/system` の `xydrag`, `xyhandle`, `xypanzoom`, `xyresizer` はこの層の主参照

### 5. Rendering Contract

責務:

- 描画層が Core から何を受け取るかを定義する
- node / edge / overlay / toolbar / connection preview の描画入力を定義する

含むもの:

- layout 済み edge 情報
- 表示順序
- 可視要素の抽出結果
- overlay 描画用情報

含めないもの:

- 実際の SwiftUI View 実装

### 6. SwiftUI Adapter

責務:

- Core / Interaction Engine / Rendering Contract を SwiftUI に接続する
- gesture, layout, preference, animation を SwiftUI で実現する

含むもの:

- `GraphView`
- `NodeView`
- `EdgeView`
- overlay layers
- SwiftUI gestures

含めないもの:

- graph algorithm 本体
- 永続化ロジック

### 7. Platform Adapter

責務:

- SwiftUI だけでは足りない platform 差分を閉じ込める
- cursor, clipboard, hover, focus, scroll event, image export などを扱う

含むもの:

- AppKit / UIKit bridge
- pointer style
- clipboard
- 画像出力

含めないもの:

- Core Model
- Core State

### 8. Example App

責務:

- examples の確認 UI
- ライブラリ本体の受け入れ検証
- デバッグ表示やサンプル切り替え

含むもの:

- example browser
- example metadata
- 検証用 UI

含めないもの:

- ライブラリの本質的ロジック

## 依存方向

依存は一方向に制限する。

`Example App` -> `SwiftUI Adapter` -> `Rendering Contract` / `Interaction Engine` -> `Core State` / `Core Algorithms` -> `Core Model`

`Platform Adapter` は `SwiftUI Adapter` から利用される補助層として扱う。

## 初期に混ぜないもの

- Node の見た目定義と Node selection state
- Edge path 計算と Edge View の描画コード
- Viewport transform state と gesture 実装
- public API と Example app 専用 field
- graph data model と UI 用一時 state

## 初期モジュールへの割り当て

- `Graph`: Core Model の入口
- `Viewport`: Core Model + Core State + Core Algorithms の一部
- `Selection`: Core State + Interaction Engine
- `Connection`: Core State + Interaction Engine + Core Algorithms
- `Nodes`: Rendering Contract + SwiftUI Adapter
- `Edges`: Rendering Contract + SwiftUI Adapter
- `Examples`: Example App

## 次段階で決めること

- Core State を値型中心で持つか、参照型ストアで持つか
- Rendering Contract を内部専用にするか、一部 public にするか
- viewport / drag / connect を別 engine に分けるか、統合 interaction engine にするか
- minimap, toolbar, resizer を plugin 扱いにするか、標準機能に含めるか
