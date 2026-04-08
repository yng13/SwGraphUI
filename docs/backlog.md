# Backlog

## Epic 1: 目標と参照元の固定

- [x] `.reference/xyflow` を参照実装としてローカル clone
- [x] `docs` ディレクトリを作成
- [x] 公開 examples 一覧を棚卸し
- [x] examples 確認用 SwiftUI アプリ target を追加
- [x] 公開 examples とローカル `xyflow` route の対応表を作成
- [x] 参照 commit を `docs/reference-lock.md` に固定
- [x] コンポーネント責務境界の初版を定義
- [x] `system / react / svelte` の責務分割を整理
- [x] `svelte` を優先参照にする妥当性を評価
- [x] `system` の d3 依存と責務分解を整理
- [x] `system` の core-first 移植順を整理
- [x] `system` の外部依存全体と SwiftUI 置換方針を整理
- [x] 将来の package directory 構成案を定義

## Epic 2: コアモデル設計

- [x] `Sources/SwGraphUI` の最小ディレクトリ構成を作成
- [x] 座標・矩形・接続・変更差分の初期型を追加
- [x] ノードモデルの初期型設計
- [x] エッジモデルの初期型設計
- [x] ハンドルと接続ルールの初期型設計
- [x] ビューポート座標変換モデルの初期型設計
- [x] 選択状態とビューポート状態の初期設計
- [x] `GraphNode / GraphEdge` を正規 public 名として固定
- [x] graph / connection / edge path / bounds / viewport utility を追加
- [x] drag / connection / hover
- [x] M9: Platform Adapters & UI State Synchronization
    - [x] `@Observable @MainActor GraphStore` の導入
    - [x] Coordinate conversion adapter (Screen <-> Graph)
    - [x] Viewport Transform & Node Interaction bridge (SwiftUI)
- [x] M8: Core Interaction & Viewport Commands
- [x] `Runtime/State` と `Interaction` の境界を整理 (M8)

## Epic 3: 最小ランタイム実装

- [x] 基本的なノード表示 (M10b)
- [x] 基本的なエッジ表示 (M12)
- [x] pan / zoom (M8/M10a)
- [x] ノード選択 (M14)
- [x] ノードドラッグ (M8/M10a)
- [x] ハンドル接続 (M13)
- [x] **Milestone 14: Selection & Interaction Refinement [Done]**
- [x] **Milestone 12: Edge Rendering & Customization (CORE) [Done]**
- [x] **Milestone 13: Connection Interaction (Runtime) [Done]**

- [x] M14: Selection & Interaction Refinement (Core)
- [x] M15: Advanced Selection (Multi-select & Marquee) [Done]
    - [x] M15a: Shift + Click Multi-selection
    - [x] M15b: Shift + Drag Marquee Selection
    - [x] Selection Sync (runtimeState <-> model.selected)
    - [x] Gesture Refinement (minimumDistance: 0 for reliable tapping)
    - [x] Hit Area Optimization (Path-based hit area for edges)
    - [x] Design (Neutral/No Blue theme)
- [x] **Milestone 16: Selection Completion & Keyboard Shortcuts [DONE]**
    - [x] Edge Marquee Logic Correction (Connected-node based)
    - [x] deleteSelection() / selectAll()
    - [x] Keyboard Shortcuts (Delete, Cmd+A)
- [x] **Milestone 17: Viewport Zoom Interaction [DONE]**
    - [x] Zoom API (Store-level)
    - [x] Magnification Gesture
    - [x] Mouse Wheel Zoom

- **Status**: 完了
- **Goal**: ノードに追従するエッジ描画とカスタム描写。
- **Scope**:
  - `PathSegment`: 中間幾何表現
  - `DefaultEdgeView`: 標準エッジ
  - `EdgeRenderer`: 内部描画エンジン
  - `NodePositioningAlgorithms`: 測位ロジック
- **Validation**: `Edges` サンプルでのドラッグ追従確認。
    - [x] `NodeView` の軽量化と `DefaultNodeView` への移行
    - [x] 初回実測後の自動 fitView 連携（Example App）

- **Milestone 13: Connection Interaction (Runtime) [Done]**
    - [x] Connection Interaction Manager (Screen-space 24px Snap)
    - [x] HandleView (Public API for Custom Nodes)
    - [x] Connection Preview Line (Dashed Line Layer)
    - [x] Validation (Self-connection, Connectable flag, Hidden node exclusion)
    - [x] Hierarchy Support (Recursive absolute position calculation)
    - [x] Stability (MainActor sync, Fallback for unmeasured handles)
    - [x] Unification (Unify GraphStore snapping with manager logic)

## Epic 4: 受け入れ用 examples

- [x] **M10a: Adaptive Example App (IDE Harness)**
    - [x] 3カラムレイアウト (NavigationSplitView)
    - [x] 座標変換領域の固定 (viewport_container)
    - [x] 背景ドラッグによるパン操作の実装
    - [x] サンプルデータへの暫定寸法付与による `fitView` の動作確認
- [x] **M12: Edge Rendering & Customization** (Done)
  - [x] NodePositioningAlgorithms による階層・実測・Origin考慮の測位
  - [x] PathSegment / EdgeGeometry による中間幾何表現の導入
  - [x] DefaultEdgeView (Bezier / Straight / SmoothStep 追従)
  - [x] Arrow Marker サポート
  - [x] GraphView の階層的初期化サポート
- [x] **Milestone 20: Elements Lifecycle (Add/Delete/Edit) [Done]**
- [x] **Milestone 21: Custom Node / Edge Showcase [Done]**
- [x] **Milestone 22: Example App Refactoring & Modularization [Done]** (1サンプル 1ソース化)
- [x] Milestone 23: UI Components (MiniMap, Controls) の精緻化 [Done]
- [x] Milestone 24: Edge Text / Edge Label の精緻化 [Done]
- [x] **Milestone 25a: Node Resizer (Free Resize) [Done]**
- [x] **Milestone 25b: Aspect Ratio & Advanced Resizing [Done]** (2026-04-08)
- [x] **Milestone 26: Save / Restore [DONE]**
    - [x] 現在の graph snapshot の encode / decode 方針を定義 (Codable)
    - [x] Example app に restore 導線を追加 (Inspector & Sample)
    - [x] `examples-reference-map.md` の Save and Restore 対応を更新
- [x] **Milestone 27a: Auto Pan Interaction [DONE]**
    - [x] connect / reconnect / drag 中の auto pan (50fps Timer 方式)
    - [x] Screen space -> Graph space 座標再解決
    - [x] deinit/onDisappear 時の安全な停止処理
- [x] **Milestone 27b: Backgrounds [DONE]**
    - [x] BackgroundView (Grid / Dots / Lines)
    - [x] Dynamic grid scaling (zoom 連動)
    - [x] Background styling API
- [x] **Milestone 28a: Inspector Density & Dark Mode Polish [DONE]**
    - [x] 脱 List 化 / ScrollView 移行による高密度レイアウト
    - [x] 92pt ラベル幅 Property Grid / 1px アライメント補正
    - [x] 自前 TextField / CompactNumberField による Xcode 質感再現
    - [x] ダークモード視認性修正
- [ ] **Milestone 28b: Interaction Polish & A11y**
    - [ ] keyboard interaction (Undo/Redo, Arrow keys move)
    - [ ] a11y component 群の棚卸し
- [ ] Layout 系 example 群
- [ ] UI components 系 example 群
- [ ] Whiteboard 系 example 群 (後順位)

## Epic 5: 拡張機能

- [x] 印刷/PDF エクスポートの要件定義 (`docs/export-strategy.md`)
- [x] PNG エクスポートの要件定義 (`docs/export-strategy.md`)
- [ ] export 用レイアウト計算の責務境界を定義
- [ ] PDF/印刷をベクタ優先で出力する backend 方針を定義
- [ ] PNG を指定 scale で再レンダリングする backend 方針を定義
- [ ] 文字ぼやけ回避の品質基準を定義
- [ ] Example app に export 検証ハーネスを追加

### 直近の次アクション
- [x] Milestone 27a (Auto Pan Interaction) [DONE]
- [x] Milestone 27b (Background Enhancement) [DONE]
    - [x] LOD (ズーム間引き) の実装
    - [x] Dots / Lines / Cross バリアント対応
    - [x] 5x5 メジャーグリッドアクセントの導入
