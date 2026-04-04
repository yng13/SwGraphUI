# Examples Inventory

このファイルは [React Flow Examples](https://reactflow.dev/examples) の棚卸し結果をまとめる。

## 参照ソース

- 公開 examples ページ: [https://reactflow.dev/examples](https://reactflow.dev/examples)
- ローカル参照実装: `/Users/kentaro/Projects/SwGraphUI/.reference/xyflow/examples/react/src/App/routes.ts`

## サマリ

- 公開ページの core examples 総数: 66
- 内訳:
  - Feature Overview: 1
  - Nodes: 15
  - Edges: 15
  - Interaction: 13
  - Subflows & Grouping: 3
  - Layout: 9
  - Styling: 4
  - Whiteboard: 4
  - Misc: 2
- 同ページには別枠で `UI` examples も存在する
- ローカル `xyflow` React example routes は 65 件で、公開ページの分類とは一致しない

## Core Examples

### Feature Overview

1. Feature Overview

### Nodes

1. Add Node on Edge Drop
2. Connection Limit
3. Custom Nodes
4. Delete Middle Node
5. Drag Handle
6. Easy Connect
7. Intersections
8. Node Resizer
9. Node Toolbar
10. Proximity Connect
11. Rotatable Node
12. Node Position Animation
13. Stress Test
14. Updating Nodes
15. Shapes

### Edges

1. Animating Edges
2. Custom Connection Line
3. Custom Edges
4. Delete Edge on Drop
5. Edge Label Renderer
6. Edge Intersection
7. Edge Toolbar
8. Edge Types
9. Floating Edges
10. Edge Markers
11. Multi Connection Line
12. Reconnect Edge
13. Simple Floating Edges
14. Temporary Edges
15. Editable Edge

### Interaction

1. Computing Flows
2. Connection Events
3. Context Menu
4. Contextual Zoom
5. Drag and Drop
6. Preventing Cycles
7. Save and Restore
8. Touch Device
9. Validation
10. Helper Lines
11. Collaborative
12. Copy and Paste
13. Undo and Redo

### Subflows & Grouping

1. Selection Grouping
2. Parent Child Relation
3. Sub Flow

### Layout

1. Dagre Tree
2. Elkjs Tree
3. Elkjs Multiple Handles
4. Horizontal Flow
5. Expand and Collapse
6. Auto Layout
7. Force Layout
8. Dynamic Layouting
9. Node Collisions

### Styling

1. Base Style
2. Dark Mode
3. Tailwind
4. Turbo Flow

### Whiteboard

1. Eraser Tool
2. Lasso Selection
3. Rectangle
4. Freehand Draw

### Misc

1. Download Image
2. Server Side Image Creation

## UI Examples

公開ページには core examples とは別に `UI` セクションがある。最終目標に含める場合は、以下も別管理が必要。

### Templates

1. AI Workflow Editor
2. Workflow Editor

### Components

1. Base Node
2. Status Indicator
3. Appendix
4. Tooltip
5. Database Schema
6. Placeholder
7. Labeled Group
8. Base Handle
9. Labeled Handle
10. Button Handle
11. Edge with Button
12. Edge with Node Data
13. Animated SVG Edge
14. Node Search
15. Zoom Slider
16. Zoom Select
17. DevTools

## ローカル参照実装との差分メモ

ローカル `xyflow` の React examples では、以下のように公開ページと粒度や命名が異なる。

- 公開ページにあるが、ローカル route 名と一致しないものがある
- ローカル route にあるが、公開ページの categories に直接対応しない開発用 example がある
- hooks, provider, overview, debug 用 example がローカル route 側に含まれている

このため、SwGraphUI ではまず公開ページ基準で受け入れ一覧を管理し、個別実装時に `.reference/xyflow` の対応 source を探す運用にする。
