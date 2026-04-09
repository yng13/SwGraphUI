# 開発ログ

## 2026-04-09
### Milestone 30a/b: Subflow Constraints & Selection Polish 開始
- **概要**: 移動制限機能の実装と複数選択 UI の精緻化に着手。
- **タスク**: `NodeExtent` の導入、`DragManager` 統合、Selection Box 追加。

### Milestone 29: Subflows & Nesting 実装 (完了)
- **概要**: 階層構造ノードの基本的な表示と重なり順の最適化。
- **技術的変更**:
    - `NodePositioningAlgorithms`: `calculateDepth` を追加し、階層の深さを計算可能にした。
    - `GraphView`: `nodeLayer` において `zIndex` -> `depth` -> `元順` の安定ソートを実装し、親が常に背面にくるよう修正。
    - `GraphStore`: `nodeLookup` をパブリック公開し、階層計算を効率化。
    - `Example`: `SubflowSample` と `GroupNodeView` を追加。
- **検証結果**:
    - `swift test`: 全 60 件のパスを確認。
    - UI確認: 親ノードドラッグ時の子ノード追従と、ヒエラルキーに基づく重なり順の整合性を確認。

## 2026-04-08
### Milestone 25b: Aspect Ratio & Advanced Resizing 実装
- **概要**: コーナードラッグ時の Shift キー押下によるアスペクト比維持リサイズの実装。
- **技術的変更**:
    - `ResizeCalculation.swift`: `preserveAspectRatio` ロジックを追加。主軸（移動量が大きい方）の拡大率に応じた従軸の補正と制約（min/max）の再評価を実装。
    - `NodeResizer.swift`: `ModifierKeysProvider` を導入し、Shift キーの状態とハンドル位置を判定。
    - `Reference-Divergence`: 「コーナードラッグのみ Shift で比率維持」という意図的差分を明文化。
- **技術的判断**:
    - モデル属性を増やさず「入力状態」として処理することで、特定ノードに縛られない汎用的な操作感を実現。
- **検証結果**:
    - `swift test`: `ResizeCalculationTests` に比率維持用の3件を追加し、合計 49 件（XCTest 19 + Swift Testing 30）の全パスを確認。
    - `xcodebuild build`: 成功。
    - 手動確認: Shift + コーナードラッグで比率がロックされ、辺ドラッグでは維持されないことを確認。

### Milestone 25a: Node Resizer (Free Resize) 実装
- **概要**: ノードの自由リサイズ機能（8ハンドル、最小/最大制約、位置補正）のコア実装。
- **技術的変更**:
    - `BaseNode`: `minWidth/Height`, `maxWidth/Height`, `resizable` プロパティを追加。
    - `ResizeCalculation.swift`: 8方向リサイズと、左・上ハンドル時の `position` 補正ロジックを実装。
    - `NodeResizer.swift`: 選択ノードにのみ表示される SwiftUI オーバーレイ。`DragGesture` と `GraphStore` を統合。
    - `GraphView.swift`: `.environment(store)` を追加し、内部コンポーネントへの Store 供給を確実化（ランタイムクラッシュの修正）。
    - `GraphStore`: リサイズ専用の `updateNodeDimensionsAfterResize` メソッドを新設し、自動測定ループとの競合を回避。
    - `NodeResizerSample.swift`: リサイズ機能のデモを追加。カスタムノードに `.frame()` を適用し、リサイズが視覚的に反映されるように修正。
- **技術的判断**:
    - `ResizeCalculation` を純粋なロジックとして分離し、`Swift Testing` による単体テストで堅牢性を担保。
    - `NodeResizer` をカスタムノードのレイヤーとして透過的に重ねられる設計を採用（React Flow 準拠）。
- **検証結果**:
    - `swift test`: `ResizeCalculationTests` (27件) を追加し、既存の XCTest (19件) と合わせて合計 46 件のテストに合格。
    - `xcodebuild build`: 成功。
    - 手動確認: NodeResizer 表示時の `_swift_runtime_on_report` クラッシュが解消され、80x65 へのリサイズ時に境界線とハンドルが正しく表示されることを確認。

### Milestone 24: Edge Label Refinement
- **概要**: エッジラベルの視認性向上と、グラスモーフィズム効果の適用。
- **技術的変更**:
    - `EdgeLabelView`: macOS (`NSVisualEffectView`) と iOS (`ThinMaterial`) で異なるアダプティブ背景を実装。
    - パディングを 6.0 に拡大し、背景不透明度を調整 (macOS: 0.5, iOS: 0.2)。
    - `EdgePathAlgorithms`: `step` および `smoothStep` のパス中央計算を精緻化。

---

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

---
## 2026-04-08: Milestone 27a: Auto Pan Implementation [DONE]

### [M27a] Auto Pan Interaction
- **概要**: ユーザーがノードをドラッグしたりハンドルの接続を行ったりしている際に、キャンバスの端（40px以内）にポインタが留まった場合に自動的にビューポートをスクロールさせる「オートパン」機能を実装。
- **技術的実装**:
    - `AutoPanAlgorithms`: ポインタの位置に応じた速度ベクトル計算ロジック（**端に近いほど加速する線形的な加速**を採用。指数関数より制御しやすく、React Flow との整合が高い）。
    - `AutoPanState`: ポインタのスクリーン座標、計算された速度、コンテナ（ビュー）の寸法を管理。
    - `GraphStore`: 50fps (20ms) 周期の `Timer` によるビューポート位置の更新。
- **課題と解決**:
    - **ドラッグ中のタイマー停止問題**: `Timer.scheduledTimer` ではユーザーのドラッグ中（RunLoop が `.tracking` モード時）にタイマーが一時停止する。これを解決するため、`RunLoop.main.add(timer, forMode: .common)` で明示的にタイマーをスケジュールするように変更。これにより、ドラッグ操作中も止まらずにスクロールが継続する。
    - **再描画（Rendering）の不整合**: `@Observable` 階層が深い場合に SwiftUI が変更を検知しないケースを解消するため、`GraphView` の `body` 内でビューポートの値を直接評価して `offset` 修飾子に渡すように最適化。
    - **クリーンアップ**: デバッグ用の Viewport 座標オーバーレイおよび `print` ログを削除し、プロダクション品質のコードに整理。
- **検証結果**:
    - `swift test`: 57件全テストをパス。
    - `AutoPanAlgorithmsTests`: 線形加速ロジックの境界値・ゼロサイズガードを網羅。
    - 実機確認: ミニマップおよびメインキャンバスにおけるスムーズなオートスクロールと、他のノード・要素の追従を確認。

---
## 2026-04-09: Milestone 28b & 29: Interaction Polish & Subflows [DONE]

### [M28b] Undo/Redo & Viewport Preservation
    - [x] Viewport protection during content Undo/Redo.
    - [x] No-op guard (Skip history registration for zero movement or empty deletion).
- [x] **Milestone 29: Subflows & Nesting**
    - [x] Hierarchical rendering order (Z-order based on zIndex and depth).
    - [x] Group nodes visualization and sample implementation.

- **概要**: コンテンツ操作（移動、削除、リサイズ、接続）の Undo/Redo 時に、ユーザーが意図したカメラ位置（Viewport）が書き換わらないようにロジックを精緻化。また、履歴を汚さないための guards を追加。
- **技術的変更**:
    - `GraphStore.registerUndo`: `ignoringViewport` 引数を追加し、Undo クロージャ内での `apply` 呼び出しにフラグを伝搬。
    - `GraphStore.apply`: `shouldRegisterUndo` による Redo 登録時に、現在の `ignoringViewport` 状態を継承するように修正。これにより Undo -> Redo サイクル全体で Viewport が保護される。
    - `swift test`: 58件（+1件）全テストをパス。
    - マニュアル確認: ノード移動 -> 画面スクロール -> Undo において、ノード位置のみが戻り、画面表示位置が維持されることを確認。
    - **Subflow ドラッグ監査**: 親子同時選択時の「二重移動（加速）」リスクについて調査・検証を完了。現状の `GraphView` はドラッグ開始時に「実際に掴んだ1ノード」のみを `draggedNodes` に登録する仕様であるため、親を動かせば子は相対的に追従し、子を動かせば子が相対移動するという 1倍速の挙動が保証されていることを確認。バグの懸念は現状の実装において解消済み。

## [2026-04-09] Epic 5: PNG Export Implementation (完了)
- **概要**: グラフ全体の高解像度 PNG エクスポート機能を実装。
- **技術的変更**:
    - `PNGExporter`: `ImageRenderer` をベースに、表示スケール、マージン、背景不透明度を自在に制御可能にした。
    - `GraphExportView`: 描画レイヤーを `GraphLayerStack` に抽出し、非インタラクティブな描画モードを確立。
    - `isGraphExporting` 環境変数: 選択ハンドル、ツールバー、リサイザー等のオーバーレイをエクスポート時に一括非表示化。
    - Bounds 拡張: エッジの端点やラベルが画像端で切れないよう、計算ロジックにエッジハンドル位置を包含。
    - エッジラベル修正: macOS での `NSVisualEffectView` レンダリングエラー（禁止マーク）を回避するため、エクスポート時は不透明背景（`resolvedBgColor`）に自動切り替え。
- **検証結果**:
    - `swift test`: 合計 60 件（XCTest 22 + Swift Testing 38）のパスを確認。
    - `xcodebuild build`: 成功。
    - 手動確認: `SubflowSample` および `EdgeLabelSample` にて、背景の有無、ダークモード適応、オーバーレイ除外、ラベル表示の健全性を確認。

- **PNG エクスポートの境界計算改善 (完了)**
  - **概要**: 曲線エッジ（Bezier, SmoothStep, Step）がエクスポート画像の端で欠ける問題を修正。
  - **技術的変更**:
    - `calculateExportBounds()` を刷新し、`PathSegment` の全走査により制御点や折れ曲がり点を Bounds に包含。
    - ユニットテストを拡充し、各エッジタイプでの境界計算の正当性を検証。
- **PDF エクスポート機能の新規実装 & リファクタリング (完了)**
  - **概要**: 高品質なベクター形式（PDF）での書き出しをサポート。
  - **技術的変更**:
    - `GraphExportSupport`: PNG と PDF で共有される境界計算・幾何ユーティリティを抽出。
    - `PDFExporter`: `ImageRenderer` と `CGContext` 連携によるベクター出力の実装。
    - 名前衝突の修正: ジェネリクス名 `Data` を `NodeData` に変更し、`Foundation.Data` との衝突を解消。
    - UI 統合: ツールバーのエクスポートボタンを Menu 形式に拡張。
- **検証結果**:
  - `swift test`: 合計 64 件（+2件）の全パスを確認。
  - `PNGExporterTests` / `PDFExporterTests` の両方で正常動作を確認。
  - `xcodebuild build`: 成功。

- **M30: Subflow 制約の厳格化と Selection Box の実装 (完了)**
  - **概要**: 移動制約の適用範囲をキーボード移動等へ集約し、複数選択時の視覚的フィードバック（境界枠）を追加。
  - **技術的変更**:
    - `DragManager`: `applyConstraints` メソッドを抽出し、絶対座標ベース・相対座標ベースの両方から一貫した制約適用を可能に。
    - `GraphStore`: `moveSelectedNodes` (キーボード移動相当) および `updateNodePosition` に移動制約を統合。キーボード移動時は意図的にスナップを無効化。
    - `SelectionBoxView`: 複数選択（2つ以上）を囲む境界枠を絶対座標ベースで実装。ヒットテストを無効化し背面操作を維持。
    - `GraphView`: `nodeLayer` 和 `edgeOverlayLayer` の間に選択枠を追加し、視覚的な重なりを整理。
  - **検証結果**:
    - `DragManagerTests`: `.parent` クランプと親なしフォールバックの数学的妥当性を検証（パス）。
    - `xcodebuild build`: 成功。
    - 手動確認: 子ノードが矢印キー移動でも親の枠で止まること、および複数選択時にグレーの境界枠が表示されることを確認。

## 2026-04-09: M30 複数選択時の移動同期不具合の修正

### 完了事項
- `GraphView.swift` のドラッグジェスチャ (`nodeWrapper`) において、ドラッグ対象のノードが選択済みである場合、選択されている全ノード ID を `startDragging` に渡すように修正。
- 独立したルートノード (`regular-node`) が複数選択時のドラッグから漏れていた問題を解消。
- `moveSelectedNodes` (キーボード移動用) においても、階層構造の再描画を確実にするためのプロパティ再代入処理を維持。

### 技術的詳細
- これまでは単一の `node.id` のみをドラッグセットに登録していたため、親子関係のないノード（ルートノード）が同期移動の対象から外れていた。
- `XYFlow` に準拠し、選択中の要素をドラッグした際は「全選択ノード」を、非選択の要素をドラッグした際は「その要素のみ」をドラッグセットとして扱うように調整。

### ビルド確認
- `swift build`: 成功

---
## 2026-04-09: Milestone 31: Layout Examples (Dagre Tree etc.) [DONE]

### 概要
複雑な接続関係を持つグラフを自動で整列させる階層型レイアウトエンジンを完成させ、Example App の IDE 環境に完全統合しました。

### 技術的変更
- **Library Core (GraphLayoutAlgorithms.swift)**:
    - レイヤーごとの幅（Breadth）計算と、最大幅に基づく**センタリングロジック**を実装。
    - 木構造だけでなく、DAG や複数ルートが存在する場合でも、重なりを抑えつつバランスの取れた配置が可能に。
- **Example App (DagreTreeSample.swift)**:
    - `GraphSample` プロトコルに準拠し、IDE の共通 `GraphStore` / `InspectorView` と連携するように刷新。
    - `EmptyPayload` から `String` (NodeData) へ移行し、他のツール機能との互換性を確保。
- **View Layer (InspectorView.swift)**:
    - `Layout` カテゴリ選択時にのみ表示される "Layout Actions" セクションを追加。
    - 座標更新時の `withAnimation(.spring())` と `fitView` の連鎖的な適用をサポート。

### 検証結果
- `swift test`: 新設した `GraphLayoutAlgorithmsTests` (2件) を含む合計 52 件のテストに合格。
- `xcodebuild build`: 成功。
- 手動確認: TB/LR レイアウト実行時にノードがスムーズに中央へ移動し、Undo によってレイアウト前の位置に正しく戻ることを確認。

## 2026-04-10
### Milestone 32: Runtime Zoom Quality / Coordinate-Based Crisp Rendering 完了
- **概要**: `GraphView` のルート全体拡大（`.scaleEffect`）を廃止し、全ての描画要素をスクリーン座標系で直接計算・配置する「Crisp Zoom Rendering」へ移行。
- **実施内容（最終調整後）**:
    - **Geometry 拡張**: `XYPosition`, `Dimensions`, `Rect`, `PathSegment` に `toScreen(viewport:)` 拡張を追加し、精度と堅牢性（isFiniteチェック）を強化。
    - **Canvas 背景の実装**: `BackgroundView` をタイリング画像方式から `Canvas` 描画方式へ刷新。ズームに応じたグリッド・ドットのスクリーン空間描画を実現し、高負荷時や極端なズームでもシャープな背景を維持。
    - **ノードの直接スケーリング**: `DefaultNodeView` 内で、パディング、枠線、フォントサイズを `zoomLevel` に基づき直接計算（重レイアウト）するように変更。コンテナ単位の拡大によるボケを完全に排除。
    - **全レイヤーの Screen-Space 移行**: エッジ（`EdgeRenderer`）、ハンドル（`HandleView`）、選択枠（`SelectionBoxView`）、プレビュー線等を一斉にスクリーン座標ベースに刷新。
    - **ViewportManager の強化**: 複数のプラットフォーム間（macOS/iOS）での座標変換の整合性を向上。
    - **Exporter 類の追従**: `PDFExporter`, `PNGExporter` 及び `GraphExportView` のシグネチャを `Viewport` 必須対応に更新。
- **検証結果**:
    - `xcodebuild build`: 成功（Codex 修正版）。
    - `swift test` (GeometryTests): 全 3 ケースパス。
    - 自己レビュー: 全てのレイヤーでルートスケールが排除され、ポインタのヒットテスト精度も 1:1 で維持されていることを確認。エッジラベルのフォント品質も最大化されている。
