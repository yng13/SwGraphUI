# current-plan: M16 - Selection Completion & Keyboard Shortcuts [IN PROGRESS]

## Goal
矩形選択（Marquee）の機能を `xyflow` 準拠に完成させ、キーボードショートカット（Delete, Cmd+A）を追加する。

## Proposed Changes

### [M16] [GraphStore.swift](file:///Users/kentaro/Projects/SwGraphUI/Sources/SwGraphUI/Runtime/GraphStore.swift)
- `endMarquee(isShiftPressed:)` を接続ノードベースのエッジ選択ロジックへ修正。
- `deleteSelection()` および `selectAll()` の実装。

### [M16] [SwGraphUIExampleApp.swift](file:///Users/kentaro/Projects/SwGraphUI/Example/SwGraphUIExampleApp.swift)
- ショートカットキーのハンドリング追加。

## Exit Rule
- [ ] **エッジ連動選択**: 矩形選択されたノードに接続しているエッジも選択されること。
- [ ] **一括削除**: Deleteキーで選択要素が全消去されること。
- [ ] **全選択**: Cmd+A で全要素が選択されること。
- [ ] **ドキュメント同期**: `reference-divergence.md` の Selection 節が現状と一致すること。

## 完了したマイルストーン
- [x] M15: Advanced Selection (Multi-select & Marquee)
- [x] M14: Selection & Interaction Refinement (Core)
- [x] M13: Connection Interaction (Runtime)
- [x] M12: Edge Rendering & Customization (Core) [Done]
- [x] M10a: Adaptive Example App (IDE Harness)
- [x] M9: Platform Adapters & UI State Synchronization
- [x] M8: Core Interaction & Viewport Commands
- [x] M7: pure coreの実体化
