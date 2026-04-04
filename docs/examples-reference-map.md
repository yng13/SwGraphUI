# Examples Reference Map

このファイルは、公開 examples とローカル `xyflow` source の対応関係を管理する。

## 判定ルール

- `一致`: ローカルに同名またはほぼ同義の example source が存在する
- `近似`: 完全一致ではないが、実装調査の起点として使える source が存在する
- `未発見`: 現時点でローカル clone から明確な対応 source を確認できていない

## 公開 examples とローカル source の対応

| Category | Public example | 判定 | ローカル参照 source |
| --- | --- | --- | --- |
| Feature Overview | Feature Overview | 近似 | `.reference/xyflow/examples/react/src/examples/Overview` |
| Nodes | Add Node on Edge Drop | 一致 | `.reference/xyflow/examples/react/src/examples/AddNodeOnEdgeDrop` |
| Nodes | Connection Limit | 未発見 | - |
| Nodes | Custom Nodes | 一致 | `.reference/xyflow/examples/react/src/examples/CustomNode` |
| Nodes | Delete Middle Node | 未発見 | - |
| Nodes | Drag Handle | 一致 | `.reference/xyflow/examples/react/src/examples/DragHandle` |
| Nodes | Easy Connect | 一致 | `.reference/xyflow/examples/react/src/examples/EasyConnect` |
| Nodes | Intersections | 一致 | `.reference/xyflow/examples/react/src/examples/Intersection` |
| Nodes | Node Resizer | 一致 | `.reference/xyflow/examples/react/src/examples/NodeResizer` |
| Nodes | Node Toolbar | 一致 | `.reference/xyflow/examples/react/src/examples/NodeToolbar` |
| Nodes | Proximity Connect | 未発見 | - |
| Nodes | Rotatable Node | 未発見 | - |
| Nodes | Node Position Animation | 未発見 | - |
| Nodes | Stress Test | 一致 | `.reference/xyflow/examples/react/src/examples/Stress` |
| Nodes | Updating Nodes | 一致 | `.reference/xyflow/examples/react/src/examples/UpdateNode` |
| Nodes | Shapes | 未発見 | - |
| Edges | Animating Edges | 近似 | `.reference/xyflow/examples/react/src/examples/Edges` |
| Edges | Custom Connection Line | 一致 | `.reference/xyflow/examples/react/src/examples/CustomConnectionLine` |
| Edges | Custom Edges | 近似 | `.reference/xyflow/examples/react/src/examples/EdgeRenderer` |
| Edges | Delete Edge on Drop | 未発見 | - |
| Edges | Edge Label Renderer | 近似 | `.reference/xyflow/examples/react/src/examples/EdgeRenderer` |
| Edges | Edge Intersection | 未発見 | - |
| Edges | Edge Toolbar | 一致 | `.reference/xyflow/examples/react/src/examples/EdgeToolbar` |
| Edges | Edge Types | 一致 | `.reference/xyflow/examples/react/src/examples/EdgeTypes` |
| Edges | Floating Edges | 一致 | `.reference/xyflow/examples/react/src/examples/FloatingEdges` |
| Edges | Edge Markers | 近似 | `.reference/xyflow/examples/react/src/examples/Edges` |
| Edges | Multi Connection Line | 未発見 | - |
| Edges | Reconnect Edge | 一致 | `.reference/xyflow/examples/react/src/examples/ReconnectEdge` |
| Edges | Simple Floating Edges | 近似 | `.reference/xyflow/examples/react/src/examples/FloatingEdges` |
| Edges | Temporary Edges | 未発見 | - |
| Edges | Editable Edge | 未発見 | - |
| Interaction | Computing Flows | 未発見 | - |
| Interaction | Connection Events | 近似 | `.reference/xyflow/examples/react/src/examples/Interaction` |
| Interaction | Context Menu | 未発見 | - |
| Interaction | Contextual Zoom | 未発見 | - |
| Interaction | Drag and Drop | 一致 | `.reference/xyflow/examples/react/src/examples/DragNDrop` |
| Interaction | Preventing Cycles | 未発見 | - |
| Interaction | Save and Restore | 一致 | `.reference/xyflow/examples/react/src/examples/SaveRestore` |
| Interaction | Touch Device | 一致 | `.reference/xyflow/examples/react/src/examples/TouchDevice` |
| Interaction | Validation | 一致 | `.reference/xyflow/examples/react/src/examples/Validation` |
| Interaction | Helper Lines | 未発見 | - |
| Interaction | Collaborative | 未発見 | - |
| Interaction | Copy and Paste | 未発見 | - |
| Interaction | Undo and Redo | 未発見 | - |
| Subflows & Grouping | Selection Grouping | 未発見 | - |
| Subflows & Grouping | Parent Child Relation | 近似 | `.reference/xyflow/examples/react/src/examples/Subflow` |
| Subflows & Grouping | Sub Flow | 一致 | `.reference/xyflow/examples/react/src/examples/Subflow` |
| Layout | Dagre Tree | 近似 | `.reference/xyflow/examples/react/src/examples/Layouting` |
| Layout | Elkjs Tree | 未発見 | - |
| Layout | Elkjs Multiple Handles | 未発見 | - |
| Layout | Horizontal Flow | 近似 | `.reference/xyflow/examples/react/src/examples/Layouting` |
| Layout | Expand and Collapse | 未発見 | - |
| Layout | Auto Layout | 近似 | `.reference/xyflow/examples/react/src/examples/Layouting` |
| Layout | Force Layout | 未発見 | - |
| Layout | Dynamic Layouting | 未発見 | - |
| Layout | Node Collisions | 未発見 | - |
| Styling | Base Style | 未発見 | - |
| Styling | Dark Mode | 近似 | `.reference/xyflow/examples/react/src/examples/ColorMode` |
| Styling | Tailwind | 未発見 | - |
| Styling | Turbo Flow | 未発見 | - |
| Whiteboard | Eraser Tool | 未発見 | - |
| Whiteboard | Lasso Selection | 未発見 | - |
| Whiteboard | Rectangle | 未発見 | - |
| Whiteboard | Freehand Draw | 未発見 | - |
| Misc | Download Image | 未発見 | - |
| Misc | Server Side Image Creation | 未発見 | - |

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

- 公開 examples 66 件のうち、ローカル route で `一致` とみなせるものは限定的
- layout, whiteboard, misc, Pro examples はローカル route だけでは追いきれない
- 今後は `examples/react` の route だけでなく、`packages/system`, `packages/svelte`, 公開ページ上の example 個票も併用して対応 source を深掘る必要がある
