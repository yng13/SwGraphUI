---
## [Epic 4] Milestone 21: Custom Node / Edge Showcase (2026-04-06) [DONE]

### 概要
ノード・エッジのカスタマイズ性を実証する「Custom Showcase」を実装。パブリック API を拡張し、再接続やラベル等の基本機能を維持したまま意匠（ツールバー、動的配色、カスタムパス）を柔軟に変更可能にした。

### 技術的変更
- **Library Layer (GraphView / DefaultEdgeView)**
    - `edgeBuilder` を導入し、エッジ本体の View を外部注入可能に。
    - `DefaultEdgeView` をリファクタリングし、ヒット判定・マーカー・オーバーレイを共通部品として維持しつつ、描画本体 (`edgeBodyBuilder`) のみを作替可能にする構成を採用。
- **Example App (Showcase Components)**
    - `ToolbarNodeView`: 選択時にノード上部にフローティングメニュー（削除・編集）を表示。副作用を Example 側のロジックに閉じ込める合成 View 方式を採用。
    - `ColorNodeView`: ノードデータに応じた動的な配色を行うコンポーネント。
    - `CustomEdgeBody`: エッジ本体に光彩効果や中心点線を重層的に適用するカスタムレンダリング例。
- **Example App (Showcase Integration)**
    - `SampleCategory.customShowcase` を追加し、上記コンポーネントを組み合わせたギャラリーを構築。

### 検証結果
- `swift test` によるビルドパスおよび、マニュアルによるカスタム要素の再接続・選択挙動の正常性を確認。
- デザイン面での拡張性と、コアロジック（接続・スナップ）の堅牢性の両立を実証。

---
## [Epic 4] Milestone 20: Elements Lifecycle (Add/Remove/Update) (2026-04-06) [DONE]

### 概要
要素の動的な生成、一括削除、およびデータの直接編集機能を実装し、実用的な編集ワークフローを実証。

### 技術的変更
- **GraphStore (Core)**
    - `addNode(_:)`, `updateSelectedNodes(_:)` をパブリック API として追加。
    - 新規追加時に自動でそのノードのみを選択状態へ移行するロジックをカプセル化。
- **ExampleApp (UI)**
    - サイドバーに「Add Node」ボタンを追加。表示領域中央（スクリーン座標）からグラフ座標への逆変換を行い、正確な位置への配置を実現。
    - インスペクターに「Delete Selected」および「Save Snapshot (JSON ログ出力)」を実装。
    - ノード・エッジのラベル (data, label) 編集フィールドを整備。

### 検証結果
- ズーム・パン状態でのノード配置精度、削除後の整合性、および JSON ログの正常出力を確認。

---
## [Epic 4] Milestone 19: Interactive Showcase & Doc Repair (2026-04-06) [DONE]

### 概要
これまでに実装した全機能を俯瞰・確認できる「Feature Overview」サンプルの刷新と、開発記録の整合性回復。

### 実装ノーツ
- **ExampleAppStore.swift / SwGraphUIExampleApp.swift**
    - `overview` サンプルを「機能ギャラリー」として刷新。ベジェ/直線/ステップ各1本、ラベル、再接続ハンドル、両端マーカー、1組のグループを配置。
    - `addEdge` メソッドを更新し、新規エッジにデフォルトで `.both` 再接続属性を付与。
    - インスペクターに **Viewport 操作（Zoom In/Out, FitView）** ボタンを追加し、中心基準の操作に対応。
    - ユーザー向けに再接続や操作を促すヒントログを追加。
- **ドキュメント更新**
    - `dev_log.md`: Milestone 18 の記録を統合し、フォーマットをカノニカルな状態へ改善。
    - `docs/examples-reference-map.md`: Feature Overview の進捗ステータスを更新。

---
## [Epic 4] Milestone 18: Edge Reconnection & Snap Improvements (2026-04-06) [DONE]

### 概要
エッジの再接続機能の実装、ラベル視認性の向上、および操作感の一貫性確保。

### 実装ノーツ
- **エッジ再接続 (Reconnection)**
    - `DefaultEdgeOverlayView` を導入し、エッジ端点に再接続用ハンドルを表示。
    - 再接続ドラッグ中にオリジナルエッジを「点線 + 透過」で維持表示するガイド機能を実装。
    - 再接続時のスナップ距離を `ConnectionInteractionManager.snapDistance` (24.0) に統一。
- **エッジラベル (Edge Label)**
    - 背景に `NSVisualEffectView` (macOS) を使用したアダプティブ背景を導入。
    - ラベルの描画レイヤーを最前面（OverlayLayer）に移動し、ノードとの重なりによる遮蔽を解消。
- **UI/UX 改善**
    - 中央カラムのレイアウト優先度を調整し、グラフ：ソースの比率を 3:1 に最適化。
    - 矢印（マーカー）の描画符号ミスを修正し、バックオフ計算を適正化。

### 検証結果
- `swift test`: 42件全パス。
- マニュアル確認: 始点・終点両側の再接続、ラベルのダークモード視認性、スナップ挙動を確認。

---
## [Epic 4-3] Marquee 復旧・対称マーカー・Inspector 最終化 (2026-04-06) [DONE]

### 概要
- `GraphView` のジェスチャ競合を解消し、矩形選択 (Marquee) を復旧。
- `DefaultEdgeView` に `markerStart` を追加し、始点・終点両端のパス短縮 (backoff) を対称化。
- `InspectorView` の UI を整理。エッジの全プロパティ（マーカーサイズ、曲率、アニメーション等）の一括更新に対応。

### 技術的変更
- `GraphView.swift`: `onTapGesture` を `DragGesture` の `onEnded` に統合し、Shift+ドラッグを最優先化。
- `EdgePathAlgorithms.swift`: `sourceTangentAngle` および `stepPath` を追加。

---
## [M16 & M17] Selection Completion & Zoom Interaction (2026-04-05) [DONE]

### 概要
選択機能の完遂（M16）とズーム操作の実装（M17）。

### 実装ノーツ
- **M16: Selection Completion**: 選択されたノード集合に接続する全てのエッジを自動選択するロジックを実装。
- **M17: Zoom Interaction**: `ViewportManager` を介した座標変換の整理、および macOS 専用の `ScrollMonitor` による Cmd+Wheel ズームの実装。

---
## [M15] Multi-selection and Marquee (2026-04-05) [DONE]

### 概要
Shift + クリックによる複数選択および、Shift + ドラッグによる矩形選択の実装。

### 実装ノーツ
- **複数選択**: `ModifierKeysProvider` による Shift キー状態の監視とトグル選択。
- **矩形選択**: `MarqueeView` による視覚化と、`CGRect.contains` による包含判定。

---
## [M13] Connection Interaction (2026-04-04) [DONE]

### 概要
ノード間のハンドル接続機能を実装。

### 実装ノーツ
- **ハンドル検知**: `HandleMeasurementEngine` による実測ベースの座標解決。
- **吸着ロジック**: スクリーン座標系基準の 24px スナップ距離の実装。

---
## [M12] Edge Rendering & Customization (2026-04-05) [DONE]

### 概要
エッジレンダリング基盤と `PathSegment` 中間形式の導入。

### 実装ノーツ
- **幾何中間表現**: `bezier`, `straight`, `smoothStep` の SwiftUI.Path 変換。
- **Professional Positioning**: 先端固定回転 (`rotatedPoint`) とベクトルベースのパス短縮 (Backoff)。

---
## [M10b/11] Measurement Engine & View Customization (2026-04-04) [DONE]

### 概要
ノード実測値同期（Measurement Engine）と、カスタムノードビュー (@ViewBuilder) 対応。

---
## [M10a] Layout & IDE Harness (2026-04-04) [DONE]

### 概要
Example アプリの 3 カラム IDE レイアウト、パン・ズーム基盤、およびデバッグ用 `CodeView` の実装。

---
## [Epic 4] Milestone 23: MiniMap & Controls の実装と洗練 (2026-04-07) [DONE]

### 概要
グラフ補助ツールとしての MiniMap と操作パネルを作成し、表示の不整合やレイアウトのガタつきを解消。また、`InteractivityState` による詳細なジェスチャ制御を導入。

### 技術的変更
- **Component Refinement**
    - `DefaultNodeView`: モデルの `width/height` プロパティを反映。メイン画面と MiniMap のサイズ同期。
    - `ControlsView`: パネルの縦伸び問題を `.fixedSize()` で修正。
    - `MiniMapView`: `NodeOrigin` を反映させ、階層ノードの絶対位置計算を正確化。`.clipped()` を追加。
- **Interactivity & Zoom Refinement**
    - `zoomOnScroll` と `zoomOnPinch` を分離。
    - `InteractivityState` に `minZoom` / `maxZoom` を追加し、ハードコードを廃止。
    - `nodesConnectable` フラグによる接続ガードを実装。

### 検証結果
- `swift test`: 合計42件全パス (XCTest 19件 + Swift Testing 23件)。
- マニュアル確認: `Feature Overview` および `MiniMap & Controls` サンプルでの `fitView` 正常動作（グラフ全体の表示）を確認。

---
## [Epic 4] Milestone 24: Edge Text / Edge Label の精緻化 (2026-04-08) [DONE]

### 概要
エッジラベルの意匠（背景、パディング、角丸、色）を詳細に制御可能な `EdgeLabelView` を導入し、パス種別に応じた最適な配置を実現。モデル層を軽量に保ちつつ、OS ごとのプレミアムな外観（macOS: VisualEffect, iOS: ThinMaterial）をサポートした。

### 技術的変更
- **Core Model (Edge.swift)**
    - `EdgeLabelStyle` 構造体を定義。`SwiftUI.Font` や `Color` を直接持たず、シリアライズ可能な文字列トークンや数値でスタイル（textColor, backgroundStyle, padding, cornerRadius）を表現。
- **View Layer (Internal / Public)**
    - `EdgeLabelView`: スタイル定義に基づき背景とテキストを描画するコンポーネントを新設。
    - `SwiftUIUtils`: macOS 用の `VisualEffectView` と汎用的な `Color(hex:)` イニシャライザを共有部品として統合。
    - `DefaultEdgeView`: `DefaultEdgeOverlayView` で `EdgeLabelView` を使用するようにリファクタリング。
- **Algorithms (EdgePathAlgorithms.swift)**
    - `step` / `smoothStep` における `labelX/Y` 計算を、パスの幾何学的中心ではなく「視覚的な中心（主セグメントの中点）」に調整。
- **Example App (Showcase)**
    - `EdgeLabelSample`: 異なるパス種別とスタイルの組み合わせを網羅した独立したショーケースを追加。

### 検証結果
- `swift test`: 合計42件全パス。
- マニュアル確認: `Edge Label Showcase` にて、ダークモード/ライトモード、および各パス種別におけるラベルの視認性と配置の整合性を確認。
