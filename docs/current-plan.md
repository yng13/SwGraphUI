# current-plan: M14 - Selection & Interaction Refinement

## Goal
ノードおよびエッジの選択機能を実装し、インタラクティブなグラフ操作の基盤を完成させる。また、インタラクション性能の最適化とレイヤー構造の最終調整を行う。

## Included
- **Core Selection State**: 
  - `BaseNode.selected` / `BaseEdge.selected` の状態管理。
  - 単一選択（クリック）、複数選択（Shift + クリック / 矩形選択はM15以降検討）。
  - 背景クリックによる選択解除。
- **UI Feedback**:
  - `DefaultNodeView` における選択時のハイライト（青枠等）。
  - `DefaultEdgeView` における選択時のパススタイリング（太線化、色変更）。
- **Interaction Refinement**:
  - `ConnectionInteractionManager` による一元化されたスクリーン空間スナップ（M13修正により完了）。
  - 選択とドラッグの競合回避ロジック。
- **Reference Scope**:
  - M14 で直接扱う参照乖離は [`m14-selection-gap.md`](/Users/kentaro/Projects/SwGraphUI/docs/m14-selection-gap.md) に限定して管理する。

## Excluded
- **Multi-selection Area (Marquee)**: 矩形ドラッグによる一括選択（M15以降）。
- **Undo/Redo**: 操作の履歴管理。

## Exit Rule
- ノードをクリックした際、正しく `selected` 状態がトグルされ、視覚的に反映されること。
- 背景をクリックした際、すべての選択が解除されること。
- ズーム倍率を `0.5x / 1.0x / 2.0x` と変えても、吸着感（ピクセル距離）が一定であること。

## 完了したマイルストーン
- [x] M13: Connection Interaction (Runtime)
- [x] M12: Edge Rendering & Customization (Core) [Done]
- [x] M10a: Adaptive Example App (IDE Harness)
- [x] M9: Platform Adapters & UI State Synchronization
- [x] M8: Core Interaction & Viewport Commands
- [x] M7: pure coreの実体化
