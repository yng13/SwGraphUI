# Requirements - SwGraphUI

## [M35] Large Graph Stability & Performance Audit (2026-04-11) [DONE]

### 概要
1,000ノード規模の大規模グラフにおける基本操作のパフォーマンスベースラインを取得。既存の Snapshot アーキテクチャの妥当性を検証し、レイアウト計算のボトルネックを解消した。

### 要件項目
1.  **Baseline 取得**: MacBook Air M4 環境において 1,000ノード/999エッジ構成での構築、選択、移動、Undo/Redo、Layout の基準時間を計測（完了）。
2.  **アーキテクチャ妥当性検証**: 現在の Snapshot (Value Semantic 参照コピー) が 1,000ノード級で無視できるコスト (0.01ms) であることを実証（完了）。
3.  **Layout ボトルネック解消**: $O(N^2)$ になっていたレイアウト計算を $O(N+E)$ へ最適化し、1,000ノード級でも 30ms 前後の完走を確保（完了）。
4.  **SLA 設定方針**: 本マイルストーンで得た数値を基準とし、M36 以降で正式なパフォーマンス保証値（SLA）を固定する。

## [M30] Subflow Constraints & Selection Polish (2026-04-09) [DONE]

### 概要
Subflow（入れ子構造）における実用的な制約の実装と、複数選択時の視覚的フィードバックの向上。

### 要件項目
1.  **M30a: Parent Extent (移動制限)**: 子ノードが親の枠外に出られないようにする移動制限機能。
    - `extent: .parent` のサポート。
    - `DragManager` を `GraphStore` のドラッグ計算の共通経路として統合。
    - 親サイズ未確定時の fallback 処理。
2.  **M30b: Selection Bounding Box (複数選択枠)**: 複数ノード選択時に全体を囲む中立的なデザインの枠を表示。
    - 2つ以上のノード選択時に表示。
    - 絶対座標ベースでの包含矩形計算。
    - オーバーレイ（最前面）での描画。

## [M33a] Accessibility Baseline (Labels & Roles) (2026-04-11) [DONE]

### 概要
SwGraphUI ライブラリとして、ノード・エッジ・Controls・MiniMap に対する基礎的なアクセシビリティ情報を整備した。販売品質に向けた第一段階として、ラベル・ロール・ヒントの実装を完了し、装飾レイヤを accessibility tree から除外した。

### 要件項目
1.  **要素ラベル整備**: ノード・エッジ・Controls・MiniMap に対して `accessibilityLabel` を付与すること（完了）。
2.  **優先順位ロジック**: ノードおよびエッジ関連の読み上げ名は `ariaLabel -> label -> id` を優先順として解決すること（完了）。
3.  **状態ヒント**: 選択状態や基本的な操作可能性をヒント/trait として公開すること（完了）。
4.  **装飾レイヤ除外**: 背景、選択枠、接続プレビュー、補助入力ブリッジ等を accessibility 対象から除外すること（完了）。
5.  **検証範囲の限定**: Accessibility Inspector / VoiceOver による実機レベルの完全検証は、本マイルストーンの完了条件には含めない。Example アプリ側の検証環境課題があるため、販売前の品質ゲート（M33b）で継続する（保留）。

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

---

## ✅ Milestone 26: Snapshots / Save & Restore (2026-04-08) [DONE]

### 概要
グラフの全状態（ノード、エッジ、ビューポート）を JSON 形式でシリアライズ・保存し、任意のタイミングで完全に復元できる機能を実装。

### 要件項目
1.  **Core models Codable**: `BaseNode`, `BaseEdge`, `Viewport` 等の全てのコア幾何モデルに `Codable` 準拠を追加（完了）。
2.  **Transient state exclusion**: `selected`, `dragging`, `measured` 等の実行時の一時的な状態をシリアライズから除外（完了）。
3.  **GraphSnapshot**: 最小限の 永続化データセットを保持するコンポジットモデルの導入（完了）。
4.  **GraphStore API**: `snapshot()` で現在の状態をキャプチャし、`apply(snapshot:)` で安全に復元する API を提供（完了）。
5.  **State Reset Logic**: スナップショット復元時に、接続ドラッグ中や矩形選択中などの過渡的なランタイム状態を強制リセットして不整合を防止（完了）。
6.  **Example Integration**: インスペクターからスナップショットの保存・復元ができる操作ボタンと、専用サンプルコードの提供（完了）。

---

## ✅ Milestone 27a: Auto Pan Interaction (2026-04-08) [DONE]

### 概要
ノードのドラッグやハンドルの接続操作中に、ポインタがキャンバス端に近づいた際にビューポートを自動的にスクロールさせる機能を実装。

### 要件項目
1.  **AutoPanAlgorithms**: キャンバス端からの距離に応じた線形な速度計算ロジックの実装（完了）。
2.  **AutoPanState**: 実行時のポインタ位置、速度、コンテナサイズを管理する状態の導入（完了）。
3.  **GraphStore Integration**: `Timer` (50fps) ベースの自動スクロールループと、移動中のポインタ・オブジェクト座標の再計算同期（完了）。
4.  **UI Integration**: `GraphView`, `HandleView`, `ReconnectAnchor` からの画面座標通知フックの追加（完了）。
5.  **Stop Conditions**: ドラッグ・接続の終了、矩形選択の開始、およびビューの非表示 (`onDisappear`) 時のタイマー停止処理（完了）。
6.  **Verification**: 速度計算ロジックの単体テストをパスし、実機ビルドでスムーズな追従を確認（完了）。

---

## ✅ Milestone 28b: Interaction Polish (Undo/Redo) (2026-04-08) [DONE]

### 概要
ユーザー操作（ノードのドラッグ、削除、リサイズ、接続）に対する Undo/Redo 機能の精緻化と、ビューポート状態の保護。

### 要件項目
1.  **Viewport Preservation**: コンテンツの Undo/Redo 時に現在のビューポート（ズーム・パン）の状態が維持されること（完了）。
2.  **No-op Guard**: 移動量ゼロのドラッグや、空の選択状態での削除など、状態に変化を与えない操作が Undo 履歴に積まれないこと（完了）。
3.  **Redo Consistency**: Undo 時に登録される Redo アクションにおいても、Viewport 保護設定が正しく継承されること（完了）。
4.  **
---

## [Epic 5] High-Quality PNG Export (2026-04-09) [DONE]

### 概要
表示中のグラフ全体（または特定領域）を、解像度（1x, 2x, 3x）や背景有無を指定して高品質なPNG画像として書き出す機能を実装。

### 要件項目
1.  **PNGExporter**: `ImageRenderer` ベースの書き出しエンジン。
2.  **GraphExportSettings**: スケール、マージン、背景色（透明/不透明）、グリッド有無の制御。
3.  **GraphLayerStack**: 描画ロジックを `GraphView` と `GraphExportView` で共有し、表示の一貫性を確保。
4.  **isGraphExporting (Environment)**: エクスポート時にハンドルやツールバー等のインタラクティブ要素を自動的に非表示にする制御。
5.  **Bounds Calculation**: ノードボックスとエッジ接続点を包含する絶対座標ベースの動的な描画範囲計算。
6.  **Background Control**: 画面上のグリッド設定（Dots/Lines/Cross）を維持しつつ、ダークモードに適応した背景描画。
7.  **PDF Export (Vector Output)**: `ImageRenderer` を利用したベクター形式の PDF 出力。
    - 境界計算ロジックの共有 (`GraphExportSupport`)。
    - シングルページかつ透過/単色背景のサポート。
    - PDF マジックナンバーを含む整合性の保証。

---

## [M31] Layout Examples (Dagre Tree etc.) (2026-04-09) [DONE]

### 概要
複雑な接続関係を持つグラフを自動で整列させる階層型レイアウトエンジンの実装と、Example App への統合。

### 要件項目
1.  **GraphLayoutAlgorithms 強化**:
    - 階層（ランク）ごとのセンタリングロジックの実装。
    - TB (Top to Bottom) / LR (Left to Right) 各方向への対応。
    - ノードサイズ（実測値優先）を考慮した正確な配置計算。
2.  **IDE 統合 (DagreTreeSample)**:
    - 共通の `GraphStore` への統合と `GraphSample` プロトコル準拠。
    - インスペクターからのレイアウト実行機能。
    - レイアウト変更時のスムーズなアニメーション遷移と `fitView` 追従。
3.  **Undo/Redo 連携**:
    - レイアウト適用を 1 つのアクションとして Undo 履歴に登録。

## [M32] Runtime Zoom Quality / Coordinate-Based Crisp Rendering (2026-04-10) [DONE]

### 概要
`GraphView` のルート Transform（全体拡大）を廃止し、全ての描画要素の座標計算を「スクリーン座標系」での直接計算に移行することで、ズーム中も常に鮮明なテキストとベクタ線（Crisp Rendering）を実現する。

### 要件項目
1.  **[x] Coordinate-Based Transformation**:
    - [x] `GraphView` ルルートの `.scaleEffect`, `.offset` を廃止し、ラスタライズの発生源を断つ。
    - [x] 全ての描画レイヤー（Node, Edge, SelectionBox, Preview, ReconnectHandle）を一斉にスクリーン座標系での配置に移行。
2.  **[x] Geometry Infrastructure**:
    - [x] `Geometry.swift` に `Dimensions`, `Rect`, `PathSegment` 用の `toScreen(viewport:)` ヘルパーを拡充。
    - [x] 変換精度の単体テスト（`GeometryTests.swift`）による品質担保。
3.  **[x] Purpose-Specific Line Widths**:
    - [x] エッジ（Edge）: ズームに追従して太くなる（`width * zoom`）。
    - [x] オーバーレイ（SelectionBox, Marquee）: 常に鮮明な 1px（ヘアライン）を維持。
4.  **[x] Adaptive Content Strategy**:
    - [x] ノード内部のスケーリングを個別適用し、ボケの発生を段階的に評価。
    - [x] エッジラベルはスクリーン空間での再レイアウト（再描画）を優先し、フォント品質を最大化。
5.  **[x] Interaction Integrity**:
    - [x] 座標変換の移行後も、ドラッグ、接続、矩形選択のポインタ精度が 1ピクセル単位で維持されること。

## [M28b] Undo/Redo Interaction Polish (2026-04-10) [DONE]

### 概要
Undo/Redo 実行時の要素状態（選択）とビューポートの保存ロジックを精緻化し、実用的な編集ワークフローを実現する。

### 要件項目
1.  **[x] Selection Persistence**:
    - [x] Undo/Redo 復元後、モデルの `selected` フラグから実行時状態を再構築し、操作対象の選択を維持。
2.  **[x] Viewport Undo (Lightweight)**:
    - [x] `fitView` 操作を Undo 可能にする一方、他の要素データには干渉しない軽量な復元経路を確保。
3.  **[x] Linguistic Consistency (Japanese)**:
    - [x] **COMPLETED**: 選択解除状態での `Undo` 後の選択復元ロジック（`syncSelectionFromModel`）。
    - [x] **COMPLETED**: `fitView` 専用の軽量 Undo パス（`registerViewportUndo`）。
    - [x] **COMPLETED**: Undo アクション名の日本語化（「ノードの移動」「表示範囲を調整」等）。
    - [x] **COMPLETED**: `apply(snapshot:)` における Undo と一般ロードの副作用分離（`restoringSelection` フラグ）。
    - [x] **COMPLETED**: `moveSelectedNodes` における no-op ガード（履歴汚染防止）。
    - [x] **COMPLETED**: ユニットテストによる回帰防止（`UndoRefinementTests.swift`）。
4.  **[x] Interaction Stability**:
    - [x] Undo -> Redo の往復において、選択状態と座標の整合性が 100% 維持されること。

## Milestone 33a: Accessibility Baseline (Labels & Roles)
1.  **[x] Labels & Roles Implementation**:
    - [x] ノード / エッジ / コントロール / ミニマップに対する日本語ラベルの付与。
    - [x] 読み上げ優先順位（`ariaLabel` -> `label` -> `id`）の適用。
2.  **[x] Element Visibility**:
    - [x] グラフコンテナの識別（`.contain`）と、子要素の適切な集約（`.combine`）。
    - [x] **NOTE**: 検証ツール（Inspector）の環境問題により、ツールベースの自動検証は保留中（コード実装ベースでの完了）。

## Milestone 33b: Accessibility Navigation & Verification (Deferred)
1.  **[ ] Focus & Navigation**:
    - [ ] Tab 順の最適化とキャンバス内のフォーカス管理。
2.  **[ ] Full Validation**:
    - [ ] 支援技術（VoiceOver/Inspector等）による実機レベルのフル検証。

## Milestone 34: Regression Matrix Implementation [DONE]
1.  **[x] Complex Interaction Testing**:
    - [x] **Hierarchy x Move x Undo**: 階層構造における座標復元の整合性検証。
    - [x] **Multi-selection x Delete x Undo**: モデルと `runtimeState` の二重選択整合性検証。
    - [x] **Layout x Undo x Redo**: レイアウト適用後の決定論的な座標復元検証。
    - [x] **Parent Extent x Move x Undo**: 親境界制約下での移動と Undo/Redo の安全性検証。
    - [x] **Large Graph Smoke**: 200ノード規模での基本操作（全選択移動・レイアウト）の動作検証。
2.  **[x] Testing Stability**:
    - [x] テスト環境における `UndoManager` のグルーピング挙動制御の確立。
