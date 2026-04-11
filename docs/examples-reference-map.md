# Examples Reference Map

このファイルは、公開 examples とローカル `xyflow` source の対応関係を管理する。

## 判定ルール

- `一致`: ローカル source と SwGraphUI の両方に、同じ責務を確認できる
- `近似`: ローカル source または SwGraphUI 側に、部分的な一致がある
- `未追従`: 参照 source はあるが、SwGraphUI はまだ受け入れ水準に届いていない
- `未発見`: 現時点でローカル clone から明確な対応 source を確認できていない

## 公開 examples とローカル source の対応

| Category | Public example | 判定 | ローカル参照 source | SwGraphUI 実装例 |
| --- | --- | --- | --- | --- |
| Feature Overview | Feature Overview | 近似 | `.reference/xyflow/examples/react/src/examples/Overview` | `OverviewSample.swift` (Reconnect / Label / Marker / MiniMap / Controls の統合確認) |
| Interaction | Lifecycle Demo | 近似 | `.reference/xyflow/examples/react/src/examples/DragNDrop/index.tsx`, `UpdateNode` | `BasicSample.swift` (追加 / 削除 / 編集。HTML D&D 自体は未実装) |
| Nodes | Custom Nodes | 近似 | `.reference/xyflow/examples/react/src/examples/CustomNode` | `CustomShowcaseSample.swift` (Toolbar / Color / CPU 風ノード) |
| Nodes | Node Resizer | 近似 | `.reference/xyflow/examples/react/src/examples/NodeResizer` | `NodeResizerSample.swift` (自由リサイズ + Shift 比率維持) |
| Nodes | Node Toolbar | 近似 | `.reference/xyflow/examples/react/src/examples/NodeToolbar` | `CustomShowcaseSample.swift` (選択時ツールバー) |
| Nodes | Stress Test | 近似 | `.reference/xyflow/examples/react/src/examples/Stress` | `PerformanceMatrixTests.swift` (1,000 node 基線) |
| Subflows & Grouping | Sub Flow | 近似 | `.reference/xyflow/examples/react/src/examples/Subflow` | `SubflowSample.swift` (Z-order / depth sort / parent-child) |
| Interaction | Interaction Playground | 近似 | `.reference/xyflow/examples/react/src/examples/Interaction` | `InteractionSample.swift` |
| Interaction | Save and Restore | 近似 | `.reference/xyflow/examples/react/src/examples/SaveRestore` | `SaveRestoreSample.swift` (JSON Snapshot 形式) |
| Interaction | Undo and Redo | 近似 | `.reference/xyflow/examples/react/src/examples/UndoRedo` | `UndoRefinementTests.swift`, `UndoSymmetryTests.swift`, Example keyboard actions |
| Interaction | Connection Events / Add Edge 相当 | 近似 | `.reference/xyflow/examples/react/src/examples/AddNodeOnEdgeDrop`, `UseConnection`, `UseNodeConnections` | handle 接続, reconnect, `ExampleAppStore.addEdge` |
| Interaction | Contextual Zoom / Touch Device 相当 | 近似 | `.reference/xyflow/examples/react/src/examples/ContextualZoom`, `TouchDevice` | `GraphView` magnification + wheel zoom 実装 |
| Styling | Backgrounds 相当 | 近似 | `.reference/xyflow/examples/react/src/examples/Background` | `BackgroundView.swift` と Example Inspector 設定 |
| Edges | Edge Label Renderer | 近似 | `.reference/xyflow/examples/react/src/examples/EdgeLabelRenderer` | `EdgeLabelSample.swift` |
| Edges | Edge Types | 近似 | `.reference/xyflow/examples/react/src/examples/EdgeTypes` | `CustomShowcaseSample.swift`, `EdgeLabelSample.swift` |
| Edges | Reconnect Edge | 近似 | `.reference/xyflow/examples/react/src/examples/ReconnectEdge` | `OverviewSample.swift` + `UndoSymmetryTests.swift` |
| Edges | Edge Markers | 近似 | `.reference/xyflow/examples/react/src/examples/Markers` | `OverviewSample.swift`, `DefaultEdgeView` |
| Layout | Dagre Tree | 近似 | `.reference/xyflow/examples/react/src/examples/Dagre` | `DagreTreeSample.swift` (内製 tree layout) |
| Misc | Download Image | 近似 | `.reference/xyflow/examples/react/src/examples/DownloadImage` | `PNGExporter`, `PDFExporter`, Example export actions |


## ローカル clone にあるが公開 core examples に直接対応しない route

- `A11y`
- `Backgrounds`
- `Basic`
- `BrokenNodes`
- `CancelConnection`
- `ClickDistance`
- `ControlledUncontrolled`
- `ControlledViewport`
- `CustomMiniMapNode`
- `DefaultEdgeOverwrite`
- `DefaultNodeOverwrite`
- `DefaultNodes`
- `DetachedHandle`
- `DevTools`
- `Empty`
- `Figma`
- `Hidden`
- `InteractiveMinimap`
- `Middlewares`
- `MovingHandles`
- `MultiFlows`
- `MultiSetNodes`
- `NodeSelectionBug`
- `NodeTypeChange`
- `NodeTypesObjectChange`
- `Provider`
- `Redux`
- `SetNodesBatching`
- `Switch`
- `Undirectional`
- `UseConnection`
- `UseKeyPress`
- `UseNodeConnections`
- `UseNodesData`
- `UseNodesInit`
- `UseOnSelectionChange`
- `UseReactFlow`
- `UseUpdateNodeInternals`
- `ZIndexMode`

## 現時点の所見

- SwGraphUI の Example app は、開発ハーネス段階から「受け入れ確認用サンプル群」へ移行している
- `Basic`, `Overview`, `Interaction`, `Custom Showcase`, `MiniMap & Controls`, `Edge Label`, `Node Resizer`, `Save and Restore`, `Dagre Tree`, `Subflow` は現状確認に使える
- `Selection` は interaction / regression test 群で補完されているが、React Flow 公開 examples に対する専用サンプル名ではまだ揃っていない
- `Whiteboard` と UI examples 群は未追従
- `Layout` は `Dagre Tree` 相当の階層型配置を、外部ライブラリに頼らず Swift 内製アルゴリズムで近似実装した
- 今後は `examples/react` の route だけでなく、`packages/system`, `packages/svelte`, 公開ページ上の example 個票も併用して差分を詰める必要がある
