# current-plan: Epic 4 & Examples / Edge Enhancements

## Goal
基本的なインタラクション機能（M13-M18）が完了したため、今後は `xyflow` 準拠の Example アプリ向けサンプル実装（Epic 4）を中心とした受け入れ確認と、更なる拡張機能（Minimap等）の検討を進めます。

## Proposed Changes

### [Epic 4] 背景とインタラクションの精緻化 (M27-M28)
- [x] M27a: Auto Pan Interaction (Logic & Timer Sync)
- [x] M27b: Background Enhancement (LOD, Variants, Accent) [DONE]
- [x] **Milestone 29: Subflows & Nesting [DONE]** (2026-04-09)
    - [x] `zIndex` -> `depth` -> `index` による階層ソート (nodeLayer)
    - [x] `NodePositioningAlgorithms.calculateDepth` の実装
    - [x] `SubflowSample` & `GroupNodeView` の追加
- [x] **Milestone 30: Subflow Constraints & Selection Polish [DONE]** (2026-04-09)
    - [x] M30a: Parent Extent (移動制限) & DragManager 統合
    - [x] M30b: Selection Bounding Box (複数選択枠)
- [x] **Milestone 28a: Inspector Density & Dark Mode Polish [DONE]**
- [x] M28b: Interaction Polish (Keyboard Support [DONE], Undo/Redo [DONE])
- [ ] M28c: Interaction Polish & A11y (Legacy)

## Exit Rule
- [x] **Examples の充実**: `Basic interaction` (M20: Elements Lifecycle) が実装されていること。
- [x] **高度な Example**: Custom Node / Edge 展示が完了していること (M21)。
- [x] **基盤整備**: Example アプリのモジュール化・独立化が完了していること (M22)。
- [x] **UI Components**: MiniMap / Controls の精緻化 (M23: DONE)。
- [x] **ドキュメント同期**: `reference-divergence.md` 上での未追従事項が更新されていること。

## 完了したマイルストーン
- [x] M30: Subflow Constraints & Selection Polish (2026-04-09)
- [x] M29: Subflows & Nesting (Z-order, Group nodes, Sample) (2026-04-09)
- [x] M28b: Interaction Polish (Undo/Redo) (2026-04-08)
- [x] M28a: Inspector Density & Dark Mode Polish (2026-04-08)
- [x] M27b: Background Enhancement (2026-04-08)
- [x] M27a: Auto Pan Interaction (2026-04-08)
- [x] M26: Snapshots / Save & Restore (2026-04-08)
- [x] M25b: Aspect Ratio & Advanced Resizing (2026-04-08)
- [x] M25a: Node Resizer (Free Resize) (2026-04-08)
- [x] M24: Edge Text / Edge Label の精緻化
- [x] M23: UI Components (MiniMap, Controls) の精緻化
- [x] M22: Example App Refactoring & Modularization
- [x] M21: Custom Node / Edge Showcase
- [x] M20: Elements Lifecycle (Add/Delete/Edit)
- [x] M19: Interactive Showcase & Doc Repair
