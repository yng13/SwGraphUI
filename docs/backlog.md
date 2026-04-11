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
- [x] **Milestone 29: Subflows & Nesting [DONE]** (2026-04-09)
    - [x] `zIndex` -> `depth` -> `index` による階層ソート (nodeLayer)
    - [x] `NodePositioningAlgorithms.calculateDepth` の実装
    - [x] `SubflowSample` & `GroupNodeView` の追加
- [x] **Milestone 30: Subflow Constraints & Selection Polish [DONE]** (2026-04-09)
    - [x] M30a: Parent Extent (移動制限) & DragManager 統合
    - [x] M30b: Selection Bounding Box (複数選択枠)
    - [x] 複数選択時の同期移動 (Root node consideration)
- [x] **Milestone 28a: Inspector Density & Dark Mode Polish [DONE]**
    - [x] 脱 List 化 / ScrollView 移行による高密度レイアウト
    - [x] 92pt ラベル幅 Property Grid / 1px アライメント補正
    - [x] 自前 TextField / CompactNumberField による Xcode 質感再現
    - [x] ダークモード視認性修正
- [x] **Milestone 28b: Interaction Polish & Undo Refinement [DONE]** (2026-04-10)
    - [x] Keyboard Interaction: Arrow keys move (1px/10px), Delete, Select All [DONE]
    - [x] Keyboard Focus Guard: TextField 競合回避 [DONE]
    - [x] Undo/Redo: コマンドスタックの実装と品質洗練（選択復元・軽量パス）[DONE]
    - [ ] a11y component 群の棚卸し (後続フェーズへ送る)
- [x] **Milestone 31: Layout Algorithms & Dagre Style [DONE]** (2026-04-09)
    - [x] `GraphLayoutAlgorithms` (Tree/Hierarchy)
    - [x] Rank-based centering / TB-LR support
    - [x] `DagreTreeSample` 統合 & Undo 連携
- [x] **Milestone 32: Runtime Zoom Quality / Crisp Rendering [DONE]** (2026-04-10)
    - [x] ルート `.scaleEffect` 廃止と座標計算ベース描画への移行
    - [x] `BackgroundView` の `Canvas` 描画刷新
    - [x] ノード内要素の直接スケーリング（重レイアウト）
    - [x] エッジラベルの True Crisp 化

## 保留中 (別途指示待ち)
- [ ] Whiteboard 系 example 群 (後順位)
- [ ] Accessibility (A11y) の実機検証・最終 polish (販売前ゲートで再開)

## Epic 5: 拡張機能

- [x] 印刷/PDF エクスポートの要件定義 (`docs/export-strategy.md`)
- [x] PNG エクスポートの要件定義 (`docs/export-strategy.md`)
- [x] export 用レイアウト計算の責務境界を定義 (`PNGExporter`) [DONE]
- [x] PNG を指定 scale で再レンダリングする backend 実装 [DONE]
- [x] PDF/印刷をベクタ優先で出力する backend 方針を定義 (`docs/export-strategy.md`) [DONE]
- [x] 文字ぼやけ回避の品質基準を定義 (`docs/export-strategy.md`) [DONE]
- [x] Example app に export 検証用ボタンを追加 [DONE]

## Epic 6: 品質強化と販売品質への仕上げ

- [x] **Milestone 33a: Accessibility Baseline (Labels & Roles) [DONE]** (2026-04-10)
    - [x] ノード / エッジ / Controls / MiniMap の accessibility label / role / hint 整備
    - [x] 読み上げ優先順位（ariaLabel -> label -> id）の適用
    - [x] 装飾レイヤ・補助入力レイヤの accessibility 除外
- [ ] **Milestone 33b: Accessibility Navigation & Verification [Deferred]**
    - [ ] 支援技術（VoiceOver/Inspector等）による実機レベルのフル検証
    - [ ] キーボードのみでの基本操作成立確認
    - [ ] Inspector / Sidebar を含む focus 順の見直し
    - [ ] Example アプリ検証環境の再整備と確認手順の確立
- [x] **Milestone 34: Regression Matrix Implementation [DONE]** (2026-04-11)
    - [x] Hierarchy x Move x Undo 整合性検証
    - [x] Multi-selection x Delete x Undo 整合性検証
    - [x] Layout x Undo x Redo 決定論的検証
    - [x] Parent Extent x Move x Undo 制約検証
    - [x] Large Graph Smoke (200ノード) 性能基線検証
- [x] **Milestone 35: Large Graph Core Stability & Performance Audit [DONE]**
    - [x] 1,000 node / 999 edge 規模での構築・一括選択・移動・Undo/Redo の Baseline 採取
    - [x] Layout アルゴリズム (Tree) のボトルネック特定と $O(N+E)$ への最適化実証
    - [x] Snapshot アーキテクチャの 1,000ノード級での妥当性確認
- [ ] **Milestone 35b: Large Graph UI & Integrated Load [Deferred]**
    - [ ] UI レベルでの pan / zoom / export の体感性能確認
    - [ ] MiniMap / Background / animated edge の同時負荷検証
    - [ ] 長時間操作時のクラッシュ耐性確認
- [ ] **Milestone 36: Runtime Rendering Polish [Todo]**
    - [ ] custom node 群の高倍率 zoom 監査
    - [ ] edge label / reconnect handle / selection box の高倍率表示確認
    - [ ] Background LOD / phase / accent の見た目最終調整
- [ ] **Milestone 37: Undo/Redo Final QA [Todo]**
    - [ ] move / delete / resize / reconnect / layout / fitView の対称性確認
    - [ ] no-op 操作で履歴が汚れないことの確認
    - [ ] Save/Restore と Undo/Redo の責務分離の再確認
- [ ] **Milestone 38: API & Docs Hardening [Todo]**
    - [ ] public API に product 固有 field が漏れていないことの確認
    - [ ] `current-plan.md` / `reference-divergence.md` / `examples-reference-map.md` の継続同期
    - [ ] Example を受け入れハーネスとして使う手順の明文化

### 直近の次アクション
- [x] Milestone 29 (Subflow Drag Audit) [DONE]
- [x] Epic 5 (PNG Export Implementation) [DONE]
- [x] Milestone 31 (Layout Algorithms & Dagre Tree Style) [DONE]
- [x] Milestone 32 (Crisp Zoom / Coordinate-based Rendering) [DONE]
- [x] Milestone 33a (Accessibility Baseline - Labels & Roles) [DONE]
- [x] Milestone 34 (Regression Matrix Expansion) [DONE]
