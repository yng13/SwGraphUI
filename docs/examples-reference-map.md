# Examples Reference Map

このファイルは、公開 examples とローカル `xyflow` source の対応関係を管理する。

## 判定ルール

- `一致`: ローカルに同名またはほぼ同義の example source が存在する
- `近似`: 完全一致ではないが、実装調査の起点として使える source が存在する
- `未発見`: 現時点でローカル clone から明確な対応 source を確認できていない

## 公開 examples とローカル source の対応

| Category | Public example | 判定 | ローカル参照 source | SwGraphUI 実装例 |
| --- | --- | --- | --- | --- |
| Feature Overview | Feature Overview | 近似 | `.reference/xyflow/examples/react/src/examples/Overview` | `ExampleAppStore.basic` |
| Nodes | Custom Nodes | 一致 | `.reference/xyflow/examples/react/src/examples/CustomNode` | (M10b で実装予定) |
| Nodes | Stress Test | 一致 | `.reference/xyflow/examples/react/src/examples/Stress` | - |
| Subflows | Sub Flow | 一致 | `.reference/xyflow/examples/react/src/examples/Subflow` | `ExampleAppStore.hierarchy` |
| Interaction | Save and Restore | 近似 | `.reference/xyflow/examples/react/src/examples/SaveRestore` | (M10a で座標不変性を確認段階) |
| Interaction | Overlap Test | - | - | `ExampleAppStore.overlap` |

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
