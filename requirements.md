# Requirements - SwGraphUI

## [Epic 4] Basic Interaction & Custom Elements (2026-04-06) [DONE]

### 概要
Example アプリに対し、`xyflow/Overview` および `xyflow/Interaction` 相当の受け入れ確認ハーネスを追加するとともに、カスタムノード・エッジのショーケースとアプリ構造のモジュール化を実現する。

### 要件項目
1.  **Overview サンプル**: 各種ノード (Default, Custom)とエッジ (Marker込み) の一覧デモ（完了）。
2.  **Interaction サンプル**: 矩形選択、パン・ズーム、ドラッグ、Overlap、Hierarchy などの状態変化を網羅的にテストできるデモ構成（完了）。
3.  **Custom Showcase (M21)**: Node Toolbar, Color Node, Custom Edge Body などの高度なカスタマイズ実証（完了）。
4.  **Modular Refactoring (M22)**: 「1サンプル 1ソース化」による保守性の向上と、ツリー型サイドバーナビゲーションの導入（完了）。
5.  **ドキュメントとの同期**: 各サンプルが `xyflow` のどの Example の検証ハーネスであるかを `docs/examples-reference-map.md` と `docs/reference-divergence.md` に最新化して明記（完了）。

## [M10b/11] Measurement Engine & View Customization (2026-04-04) [DONE]

### 概要
ノードの実測値同期（Measurement Engine）と、カスタムノードビュー (@ViewBuilder) 対応。

### 要件項目
1.  **Measurement Engine**: `GeometryReader` による自動サイズ測定とストアへの同期（完了）。
2.  **View Customization**: `@ViewBuilder` による外部からのノードビュー注入方式（完了）。
3.  **効率的な更新**: `GraphStore` での差分チェックによる無駄な再描画の抑制（完了）。
4.  **fitView の精度向上**: 実測値に基づいた境界計算の自動適用（完了）。

---

## [M10a-fix] Interaction & Layout Hotfixes (2026-04-04) [DONE]

### 概要
M10a マイルストーンで発生した主要なインタラクションバグの修正と、デスクトップ向けレイアウトのユーザビリティ向上。

### 要件項目
1.  **パン操作の復旧**: ズームやオフセットの状態に関わらず、背景ドラッグでキャンバスがスムーズに移動すること（完了）。
2.  **デスクトップ用デバイダーの改善**: `HSplitView` ベースのレイアウトにより視認性と操作性を向上（完了）。
3.  **リサイズ挙動の最適化**: ウィンドウサイズ変更時に中央のグラフ領域が優先的に伸縮すること（完了）。
4.  **サイドバー表示制御の維持**: 既存の表示/非表示切り替え機能の維持（完了）。

---

## 2026-04-05: M15 Hotfix & M16 Completion

### [M15] 矩形選択の座標修正
- **問題**: 背景ジェスチャを `.local` (トランスフォーム済み空間) で取得していたため、ズーム・パン時に Marquee の表示とマウスがズレていた。
- **解決**: ジェスチャ入力を `viewport_container` (スクリーン空間) に固定。
- **判定**: `GraphStore.endMarquee` にてスクリーン矩形を現在のビューポート状態を用いてグラフ空間に逆変換して判定を行うように修正。

### [M16] 選択機能の完成とズームボタン
- **API**: `GraphStore` に `selectAll()`, `deleteSelection()`, `zoom(at:factor:)` を追加。
- **参照準拠**: 矩形選択時に「選択されたノードに接続しているエッジ」を自動選択するようにロジックを修正。
- **UI**: 右ペイン (InspectorView) にズームボタン (+, -, Fit) を追加。
- **Shortcut**: Example アプリに `@FocusState` と `.onKeyPress` を導入し、キャンバスフォーカス時に `Delete` (削除) および `Cmd+A` (全選択) のショートカットを処理するように実装。`App.commands` を使用したフォールバック用グローバルショートカットも維持。
- **検証**: 全 42 件のテストがパス。ズーム倍率に関わらず正確な矩形選択が可能であることを確認。

---

## [M13] Connection Interaction (2026-04-04) [DONE]

### 概要
ノード間のインタラクティブな接続機能（ドラッグ＆スナップ）の実装。

### 要件項目
1.  **Connection Interaction Manager**: スクリーン座標系での 24px スナップロジック（完了）。
2.  **Validation Logic**: 自己接続、接続不可ノード(`connectable: false`)、非表示ノードの除外（完了）。
3.  **HandleView (Public API)**: カスタムノードでも利用可能な独立したハンドルコンポーネント（完了）。
4.  **Connection Preview Line**: 接続ドラッグ中の直線破線表示と、レイヤー順序の最適化（完了）。
5.  **onConnect Callback**: 接続完了時に `Connection` オブジェクトを外部へ通知する仕組み（完了）。
6.  **Hierarchy Support**: 階層化されたノード (Parent-Child) における絶対座標計算と接続対応（完了）。
7.  **Stability & Test Graduation**: `@MainActor` への完全適応と、実測前ハンドルの推測解決によるロバストな検知（完了）。

---

## [M14] Selection & Interaction Refinement (2026-04-05) [DONE]

### 概要
ノード・エッジの単一選択機能と、既存のインタラクション（ドラッグ、パン）との競合整理。

### 要件項目
1.  **Exclusive Selection**: ノードとエッジの相互排他的な単一選択ロジック（完了）。
2.  **Selection Sync (Source of Truth)**: `GraphStore` を唯一の同期点とし、モデルフラグとランタイム状態をアトミックに更新（完了）。
3.  **Gesture Deconfliction**: `DragGesture` の `minimumDistance: 4` を利用し、ドラッグ開始とクリック（選択）を正確に分離（完了）。
4.  **Edge Hit Area**: 描画線よりも広い（20px）透明なヒットエリアによる、直感的なエッジ選択（完了）。
5.  **Background Clear**: キャンバス背景のタップによる全選択解除（完了）。
6.  **Interaction Integrity**: パン操作やハンドルからの接続開始時に、不必要な選択が発火しない制御（完了）。

---

## ✅ Milestone 15: Advanced Selection (Hotfixed)
- [x] Shift+Click: Multi-selection toggle
- [x] Marquee Selection Fix: ビューポート座標系への完全対応 (Hotfixed in M15)

## ✅ Milestone 16: Selection Completion & Navigation Basics
- [x] Connected Edge Selection: 選択ノード集合に接続しているエッジを包含するようにロジックを修正 (xyflow/Pane.svelte 準拠)
- [x] Keyboard Shortcuts: `Delete` (Delete Selection), `Cmd+A` (Select All)
- [x] Basic Zoom UI: UI Buttons (+, -, Fit) in Inspector
- [x] API: `GraphStore.zoom(at:factor:)`, `deleteSelection()`, `selectAll()`

## ✅ Milestone 17: Zoom & Viewport Interaction

### 概要
ピンチズームおよびマウスホイールによるビューポートの拡大縮小。

### 要件項目
1.  **Magnification Gesture**: トラックパッドのピンチ操作による、カーソル位置を中心としたズーム（完了）。
2.  **Wheel Zoom**: マウスホイールによるキャンバスのパンと、`Cmd` または `Ctrl` ＋ホイールによるズームの分岐（完了）。
3.  **Store API Separation**: `GraphStore.zoom(at:factor:)` にて `ViewportManager` を直接呼び出すことで、責務の分離と `runtimeState.viewport` への暗黙依存の排除（完了）。
4.  **Local Wheel Bridge**: キャンバス内 Hover に連動する `ScrollMonitor` を利用し、グローバルではなく View ローカルでのマウスホイール捕捉を実現（完了）。

## ✅ Milestone 25a: Node Resizer (Free Resize) [DONE]
- [x] **M25a: Node Resizer (Free Resize)**
    - [x] `BaseNode` への `minWidth/Height`, `maxWidth/Height` プロパティの追加。
    - [x] 8方向ハンドルによる自由リサイズロジック (`ResizeCalculation`) の実装。
    - [x] 選択中ノードにリサイズハンドルを表示する `NodeResizer` コンポーネントの実装。
    - [x] リサイズ操作専用の `GraphStore` 更新メソッドによる、自動実測ループとの責務分離。
- [x] **M25b: Aspect Ratio & Advanced Resizing**
    - [x] Corner drag + Shift によるアスペクト比維持リサイズ。
    - [x] 辺（Side）ドラッグの独立性（比率不変）。

---

## ✅ Milestone 18: Edge Reconnection & Polish (Hotfixed) [DONE]

### 概要
エッジの再接続ハンドル表示、データモデル拡張（Label / ReconnectMode）、および視覚的なフィードバックの改善。

### 要件項目
1.  **Data Model Extension**: `BaseEdge` への `label` および `reconnectable` 属性の追加（完了）。
2.  **Reconnection Handles**: ソースおよびターゲット端点でのドラッグハンドルの表示（完了）。
3.  **GraphStore Logic**: 既存エッジを破棄せず端点のみを更新するアトミックな再接続ロジック（完了）。
4.  **Visual Feedback**: ドラッグ中にオリジナルエッジを点線表示にし、プレビュー線と区別。ホバー時のハンドルスケーリングなどの UX 向上（完了）。
5.  **Interaction Integrity**: Z順の最適化とレイヤー分離により、ラベルとハンドルの重なりによる操作不能を解消（完了）。
6.  **Directional Preservation**: ソース側を繋ぎ変えてもエッジの向き（A -> B）が正しく維持されるロジック（完了）。
7.  **Dark Mode Compliance**: アダプティブなラベル背景とログビューの視認性確保（完了）。
8.  **Example App Updates**: Inspector でのエッジ属性編集と、再接続成功時の `onReconnect` ログ出力対応（完了）。

## ✅ Milestone 23: MiniMap & Controls Implementation [DONE]

### 概要
MiniMap および標準コントロールのコンポーネント化、および詳細なインタラクション制御の導入。再監査に基づき、表示精度とレイアウトの安定性を向上。

### 要件項目
- [x] **MiniMap**: グラフ全域の絶対座標を考慮した縮小表示とビューポート同期（完了）。
- [x] **Node Sync**: メインキャンバスのノードサイズと MiniMap 上のサイズを同期（完了）。
- [x] **Controls Panel**: パネルの縦方向サイズ固定によるレイアウト安定化（完了）。
- [x] **Interactivity Control**: ピンチ・スクロール・接続の個別フラグ制御（完了）。
- [x] **Modular Overlays**: `ZStack` 合成による軽量な拡張方式の採用（完了）。

---

---

## ✅ Doc-Polish: Documentation & Log Alignment (2026-04-08) [DONE]

### 概要
M23 完了に伴うドキュメント、進捗管理ファイル、および開発ログの整合性不備を修正。

### 項目
1.  **dev_log.md**: 重複した区切り線 (---) の削除と、テスト件数（合計42件）の正確な記述への更新（完了）。
2.  **docs/reference-divergence.md**: `NodeResizer` の重複記述の削除と、完了済み項目の分類確認（完了）。
3.  **docs/backlog.md**: 「直近の次アクション」が M24 以降を指していることの確認（完了）。
## ✅ Milestone 24: Edge Text / Edge Label の精緻化 (2026-04-08) [DONE]

### 概要
エッジラベルの意匠（背景、パディング、角丸、色）を詳細に制御可能な `EdgeLabelView` を導入し、パス種別に応じた最適な配置を実現。

### 要件項目
1.  **EdgeLabelStyle**: `SwiftUI` 型に依存しない軽量なスタイル定義構造体の導入（完了）。
2.  **EdgeLabelView**: 背景、パディング、角丸をサポートする標準ラベルコンポーネント（完了）。
3.  **Visual Consistency**: macOS での `VisualEffectView` と iOS での `Material` フォールバック対応（完了）。
4.  **Algorithmic Centering**: `step` / `smoothStep` における視覚的なパス中心へのラベル配置調整（完了）。
5.  **Edge Label Showcase**: 多様なスタイルを確認可能な独立したサンプルの追加（完了）。
