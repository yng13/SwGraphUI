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
| Feature Overview | Feature Overview | 近似 | `.reference/xyflow/examples/react/src/examples/Overview` | `OverviewSample.swift` (M19: Reconnect/Label/Marker統合) |
| Interaction | Lifecycle Demo | 近似 | `.reference/xyflow/examples/react/src/examples/DragNDrop/index.tsx`, `UpdateNode` | `BasicSample.swift` (M20/22: 追加/削除/編集。D&Dは未実装) |
| Nodes | Custom Nodes | 部分一致 | `.reference/xyflow/examples/react/src/examples/CustomNode` | `CustomShowcaseSample.swift` (M21: Toolbar/Color/CPUノード) |
| Nodes | Stress Test | 未追従 | `.reference/xyflow/examples/react/src/examples/Stress` | - |
| Subflows | Sub Flow | 近似 | `.reference/xyflow/examples/react/src/examples/Subflow` | `HierarchySample.swift` |
| Interaction | Interaction (Playground) | 一部一致 | `.reference/xyflow/examples/react/src/examples/Interaction` | `InteractionSample.swift` (M22: サンプル独立化) |
| Interaction | Save and Restore | 未追従 | `.reference/xyflow/examples/react/src/examples/SaveRestore` | - |
| Interaction | Connection Events / Add Edge 相当 | 近似 | `.reference/xyflow/examples/react/src/examples/AddNodeOnEdgeDrop`, `UseConnection`, `UseNodeConnections` | M13 の handle 接続 + `ExampleAppStore.addEdge` |
| Interaction | Overlap Test | 近似 | - | `OverlapSample.swift` |
| Edges | Edge Types | 部分一致 | `.reference/xyflow/examples/react/src/examples/EdgeTypes` | `CustomShowcaseSample.swift` (M21: CustomEdgeBody) |


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

- SwGraphUI の Example app は、まだ examples 完成品ではなく開発ハーネス段階である
- `Basic`, `Hierarchy`, `Custom & Measure`, `Edges` は受け入れ用の最小確認例として使える
- `Save and Restore`, `Selection`, `Layout`, `Whiteboard`, `UI components` は未追従
- 今後は `examples/react` の route だけでなく、`packages/system`, `packages/svelte`, 公開ページ上の example 個票も併用して差分を詰める必要がある
