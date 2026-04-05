# current-plan: Epic 4 & Examples / Edge Enhancements

## Goal
基本的なインタラクション機能（M13-M17）が完了したため、今後はエッジ周辺機能（Reconnect, Label）の実装可否判断や、`xyflow` 準拠の Example アプリ向けサンプル実装（Epic 4）を進めます。

## Proposed Changes

### [Epic 4] 受け入れ用 examples 追加
- Basic interaction 系のサンプル構築
- 任意で Custom Node / Custom Edge 系サンプルの構築

### [M18?] Edge Label / Reconnect 等の拡張機能検討
- `PathSegment` モデルに対するラベル表示の要否・設計。
- 接続済みエッジの再接続（Reconnect）のポインターインタラクション設計。

## Exit Rule
- [ ] **Examples の充実**: 少なくとも `Basic interaction` に相当するサンプルが Example に追加されていること。
- [ ] **ドキュメント同期**: `reference-divergence.md` 上での未追従事項が更新されていること。

## 完了したマイルストーン
- [x] M16: Selection Completion & Keyboard Shortcuts (Core)
- [x] M17: Viewport Zoom Interaction
- [x] M15: Advanced Selection (Multi-select & Marquee)
- [x] M14: Selection & Interaction Refinement (Core)
- [x] M13: Connection Interaction (Runtime)
- [x] M12: Edge Rendering & Customization (Core)
- [x] M10a/10b: Measurement Engine & Adaptive Harness
