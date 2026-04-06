---
## [Epic 4] Basic Interaction Examples (2026-04-05) [DONE]

### 概要
Example アプリに対し、`xyflow/Overview` および `xyflow/Interaction` 相当の受け入れ確認ハーネスを追加。

### 実装ノーツ
- **サンプルの追加**
  - `ExampleAppStore.SampleCategory` に `.overview`, `.interaction` を追加。
  - 既存のデバッグ用サンプル (`basic`, `hierarchy`, `overlap`, `custom`) は回帰確認のため維持。
- **ドキュメント更新**
  - `docs/examples-reference-map.md` と `docs/reference-divergence.md` を更新し、Feature Overview / Interaction / Selection を「一部一致」として現状を正確に反映。

## [Epic 4-3] Marquee 復旧・対称マーカー・Inspector 最終化 (2026-04-06) [DONE]

### 概要
- `GraphView` のジェスチャ競合を解消し、矩形選択 (Marquee) を復旧。
- `DefaultEdgeView` に `markerStart` (始点側矢印) を追加し、始点・終点両端のパス短縮 (backoff) を対称化。
- **`Step` エッジタイプの追加**: `SmoothStep` の角の半径 0 版として実装し、インスペクタから選択可能に。
- `InspectorView` の UI を整理し、エッジの全プロパティ（マーカーサイズ、曲率、アニメーション等）の一括更新に対応。
- **UI 初期状態の調整**: 利便性のため、起動時のインスペクタを ON、ログビューを OFF に設定。

### 技術的変更
- `GraphView.swift`: `onTapGesture` を `DragGesture` の `onEnded` に統合し、Shift+ドラッグを最優先化。
- `EdgePathAlgorithms.swift`: `sourceTangentAngle` および `stepPath` を追加。

- [2026-04-06] M18: エッジ再接続・ラベル表示の不具合修正
    - **再接続ハンドルの反応改善**: `GraphView` に `edgeOverlayLayer` を導入。ハンドルとラベルをノードレイヤーより前面に配置することで、ノードと重なっている場合でも確実にドラッグ操作を開始できるように改善。
    - **矢印の描画方向修正**: `shortenedPosition` におけるバックオフ座標計算の符号ミスを修正。パスの端点が正しくハンドルの手前で停止するように変更。
    - **ラベル視認性の向上**: ラベルの描画レイヤーを前面に移動し、`foregroundStyle` と `background` の調整（シャドウ追加）により背景色に依らず視認可能なように修正。
    - **リファクタリング**: `DefaultEdgeView.swift` 内のロジックを整理し、パス本体 (`DefaultEdgeView`) とオーバーレイ (`DefaultEdgeOverlayView`) に分離。
- `DefaultEdgeView.swift`: `shortenedPosition` による両端のパス計算と、両端への `ArrowHead` 描画。制御点を維持したパス短縮ロジックを実装。
- `SwGraphUIExampleApp.swift`: `Form/Section` 形式によるインスペクタ UI のリデザイン。マーカーサイズ (2-20px) 調整対応。
- `ExampleAppStore.swift`: `isInspectorVisible`, `isLogVisible` の初期値を変更。

### 検証結果
- `swift test`: 成功 (42件)
- `xcodebuild build`: 成功
- マニュアル確認: Shift+Drag での選択、両端矢印の表示、インスペクタでのサイズ変更を確認。

### 概要
Example アプリの右ペイン（InspectorView）に、選択中要素（特にエッジ）の動的編集機能を追加。

### 技術的変更
- `GraphStore` に `selectedNodes`, `selectedEdges` への参照 API を追加。
- `GraphStore.updateSelectedEdges` による一括プロパティ更新メソッドを実装。
- `InspectorView` に、エッジの形状 (Bezier/Straight/SmoothStep)、マーカー、アニメーションのトグルを追加。
- 複数選択時に代表値を表示しつつ、一括適用されることを UI 上で明示。

### 検証結果
- `swift test`: 成功 (42件)
- `xcodebuild build`: 成功
  - `docs/examples-reference-map.md` の対応表を更新し、参照元 example との対応関係を明記。
  - `docs/reference-divergence.md` 上の "Example Coverage" や "Selection" などのステータスを現状に適合するよう更新。

---
## [M16 & M17] Selection Completion & Zoom Interaction (2026-04-05) [DONE]

### 概要
選択機能の完遂（M16）とズーム操作の実装（M17）が完了。

### 実装ノーツ
- **M16: Selection Completion**
  - エッジ矩形選択ロジックの修正: `xyflow/Pane.svelte` の挙動に準拠し、選択されたノード集合に接続する全てのエッジを選択状態とするよう `GraphStore.endMarquee` を更新しました。これにより、ノードグループを選択した際に関連する接続線も自動で選択されるようになります。
  - ショートカット実装: `Delete` / `Cmd+A` イベントは Example アプリ側でハンドル。
- **M17: Zoom Interaction**
  - **API分離**: `GraphStore.zoom(at:factor:)` の内部処理を `ViewportManager` を直接叩くように修正し、`GraphRuntimeState` への暗黙のドメインロジック依存を排除。
  - **Magnification Gesture**: iOS/macOS 共通のピンチズームに対応するため、`GraphView` レベルに `MagnifyGesture` を追加し、カーソルの Hover 位置を中心点としてズームするよう実装。
  - **Local Wheel Zoom**: macOS 専用の `ScrollMonitor` を作成。GraphView 全体に対するグローバルモニターの誤動作を防ぐため、「GraphView が Hover されている間のみ」モニターを有効にし、`Cmd` / `Ctrl` 押下時にはズーム、非押下時にはパン動作を行うよう分離しました。

### 検証結果
- `swift test`: 修正によるデグレなし、全パス（42件成功）。
- `xcodebuild build` (Example): 正常終了。


---
## [M15] Multi-selection and Marquee (2026-04-05) [DONE]

### 概要
Shift + クリックによる複数選択および、Shift + ドラッグによる矩形選択（Marquee）を実装。

### 実装ノーツ
- **複数選択**: `ModifierKeysProvider` を導入し、Shift キーの状態をリアルタイム監視。`toggleNodeSelection` により既存選択を維持したままトグル可能に。
- **矩形選択**: `MarqueeState` を管理し、`CGRect.contains` による完全包含判定を実装。`MarqueeView` により選択範囲を視覚化。
- **競合解決**: 背景ドラッグジェスチャを Shift キーの状態に応じて「パン」と「矩形選択」で動的に切り替え。

### 検証結果
- `swift test --filter MarqueeTests`: Passed (2 tests)
- `xcodebuild build`: 正常終了。

---
## [M13] Connection Interaction (2026-04-04) [DONE]

### 概要
ノード間の接続機能（ハンドル接続）を実装。

### 実装ノーツ
- **ハンドル検知**: `HandleMeasurementEngine` による実測ベースの座標解決。
- **ジェネリック対応**: `ConnectionInteractionManager` を拡張し、任意のノード型に対応。
- **最適化**: `GraphView` のレイヤー分離によるコンパイル負荷の軽減。

### 検証結果
- `swift test`: `ConnectionInteractionManagerTests` を含む全テストパス。
- `xcodebuild build`: 正常終了。

---
## [M12] Edge Rendering & Customization (2026-04-05) [DONE]

### 概要
エッジ（接続線）の全系レンダリング基盤と、パスの幾何情報を中間形式で扱う `PathSegment` 方式を導入。ノードの計測・階層・ドラッグに完全追従する描画を実現。

### 実装ノーツ
- **幾何中間表現**: `PathSegment` enum を導入し、Core のパス計算結果 (`bezier`, `straight`, `smoothStep`) を SwiftUI の `Path` へ変換する `EdgeRenderer` を実装。
- **測位の高度化**: `NodePositioningAlgorithms` を新設。実測値 (`measured`) -> 指定値 (`width`) -> 初期値 の優先順位でノードサイズを解決し、ハンドル座標を絶対座標で算出。
- **プロフェッショナル配置（Refined）**: 
    - **先端固定 (Apex-fixed) 回転**: 矢印の先端を不動点とした幾何計算 (`rotatedPoint`) により、サイズに関わらずノード境界に密着する描画を実現。
    - **ベクトルベース Backoff**: パス終端の接線ベクトルに沿って端点を短縮。曲線侵入時の隙間や突き抜けを完全に解消。
    - **Reactive Animation**: `.task(id: animated)` により、インスペクター操作に即座に反応する Dash アニメーションを実装。
### M18: エッジ再接続とUI改善 (Hotfix 3)

1.  **ラベルの可視化**: サンプルデータ (`ExampleAppStore`) に `label` と `reconnectable` を追加。初期状態でラベルとハンドルが表示されることを確認。
2.  **再接続中の視覚フィードバック**: 再接続ドラッグ中にオリジナルエッジを **opacity 0.3 かつ点線** で表示。
3.  **レイヤーと Z-Index**: `GraphView` で OverlayLayer を 2 パス描画に分割し、選択中のハンドルを最前面に配置。
4.  **ビルド修正**: `BaseEdge` イニシャライザの引数順序と型推論の問題を解消。
5.  **検証結果**: `swift build` & `swift test` (23件) 全て合格。
からハードコードされたアニメーションフラグを削除し、一貫性を確保。

### 検証結果
- `swift test`: **全 31 テストパス**。
- `swift build`: 正常終了。
- Example：`Edges` サンプルにおいて、最大マーカーサイズでもズレや突き抜けがないことを確認。また、グローバルスイッチによるアニメーションの全エッジ即時同期を確認。

## [M10b/11] Measurement Engine & View Customization (2026-04-04) [DONE]

### 概要
ノードの実測値同期（Measurement Engine）と、カスタムノードビュー (@ViewBuilder) 対応を実装。

### 実装ノーツ
- `NodeSizePreference` (nodeID + size) による `PreferenceKey` 通信を実装。
- `NodeMeasurementWrapper` による `GeometryReader` 経由の自動サイズ測定。
- `GraphStore.updateNodeDimensions` での同値チェックによる再描画ループ防止。
- `GraphView` をジェネリック化し、初期化時にカスタムノードのレンダリングクロージャを注入可能に。
- Swift 6 の Concurrency 警告に対応（`Sendable` 追加、静的プロパティの `computed property` 化）。

### 検証結果
[完了]
- `xcodebuild build` -> **BUILD SUCCEEDED** (Example Scheme)
- `swift test` -> **28 tests passed** (XCTest 5 + Swift Testing 23)
  - `testUpdateNodeDimensions` (新規追加)
  - `testFitViewWithMeasuredDimensions` (新規追加)
- 実機（Example）：カスタムノードの動的なサイズ変更が `CodeView` に反映されることを確認。
- 統合（Example）：初回実測完了時に一度だけ自動で `fitView` が走るように調整（[P1] 対応）。

### 概要
M10a で発生したバグ修正および、フィードバックに基づくドキュメントとデバッグ表示の適正化。

### 要件項目
1.  **パン操作の復旧**: 背景ドラッグによるキャンバス移動の安定化（完了）。
2.  **デスクトップ用デバイダーの改善**: `HSplitView` への移行と視覚的な境界線の追加（完了）。
3.  **リサイズ挙動の最適化**: 中央ペイン優先伸縮の実装（完了）。
4.  **デバッグ表示の強化**: `CodeView` への絶対座標 (`absPos`) 追加（完了）。
5.  **ドキュメントの正確性**: Zoom/Wheel/Save&Restore のステータス適正化（完了）。

### 実装ノーツ
- `GraphView.swift` のパン・ジェスチャを座標変換の外側（固定背景）に移動し、`minimumDistance` を感度向上のために縮小。
- `ExampleApp` のデスクトップレイアウトを `HSplitView` に変更。中央ペインに `.layoutPriority(1)` を付与。
- `ExampleAppStore` にサイドバー表示フラグを追加し、新レイアウトに対応させる。
- `HSplitView` は macOS における 3 カラム IDE 的なリサイズ挙動を制御しやすく、中央を柔軟にするのに適している。
- `NavigationSplitViewVisibility` は `NavigationSplitView` 専用のため、`HSplitView` では手動でのトグルが必要。

### 検証結果
[完了]
- `xcodebuild build -scheme Example -destination 'platform=macOS'` -> **BUILD SUCCEEDED**
- `swift test` -> **28 tests passed** (XCTest 5 + Swift Testing 23)
- パン操作：ジェスチャ検知を固定レイヤーへ移動し、動作の安定性を確保。
- レイアウト：`HSplitView` への移行に加え、`secondary.opacity(0.2)` による薄い境界線を追加し、視認性を向上。
- CodeView：`pos` (相対) と `absPos` (絶対) の併記により、階層ノードのデバッグ精度を向上。
- Docs：Zoom/Wheel 未実装の明記および Save and Restore の判定引き下げを完了。

---
1. 実装計画の作成完了 -> 承認待ち
2. コード修正、ビルド確認、dev_log 更新
3. コミットメッセージ案提示（承認待ち）
4. コミット実行
5. AGENTS.md にリモートリポジトリなしの旨を明記 [追加]
6. プッシュ実行

---
### 2026-04-04 (M13 Implementation)

## 実装済みの機能

- [x] R18.5 エッジの再接続 (Reconnection)
    - [x] ドラッグ中のオリジナルエッジの点線表示
    - [x] 各端点でのハンドルクリックによる接続開始
    - [x] ソース側の再接続による向きの維持
- [x] R18.6 ダークモード対応のラベル表示
- [x] **M13: Connection Interaction (ハンドル接続機能)**
    - [x] 実測ベースのハンドル位置特定エンジン (`HandleMeasurementEngine`)
    - [x] ドラッグ中のターゲットハンドル検知ロジック (`findHandle`)
    - [x] ズーム・パンに対応したグラフ絶対座標系での座標解決
    - [x] カスタムノードにおける複数ハンドルの正確なトラッキング

**技術的決定**:
- **スナップ座標系**: ズームレベルに依存しない一貫した操作感を提供するため、「スクリーン座標系」を基準に 24px の吸着距離を定義。
- **ジェネリック対応**: `ConnectionInteractionManager` のメソッドをジェネリック化し、任意の `BaseNode<Data>` を受け取れるように拡張。
- **SwiftUI 最適化**: `GraphView` の `body` が複雑化し、型チェックのタイムアウトが発生したため、各レイヤーを独立したプロパティ（`@ViewBuilder`）に抽出し、コンパイルの負荷を軽減。

**ビルド・テスト検証結果**:
- **Package Tests**: `swift test` 実行、新設の `ConnectionInteractionManagerTests` を含む全テストがパス。
- **Example Build**: `xcodebuild build -scheme Example` により、macOS 向け実行ファイルのコンパイル成功を確認。
- **動作確認**: サンプルアプリ上でノード間のドラッグによるエッジ生成、および `onConnect` コールバックを通じたエッジ追加が正常に機能することを確認。

### 2026-04-05 (M13 Stability & Graduation)

## 実装済みの機能
- [x] M15: Multi-selection and Marquee (矩形選択)
    - [x] M15a: Shift + Click による複数選択のトグル
    - [x] M15b: Shift + Drag による背景での矩形選択。ノードの包含判定ロジックの実装
- [ ] M16: Edge Label Rendering
- [x] M13 Stability & Fixes
    - [x] `@MainActor` への完全な適応と、テストスイートの同期不全解消。
    - [x] `GraphStore.findHandle` の resolved-fallback 方式への刷新。
    - [x] `DefaultEdgeView` の再導入による M12 描画機能（マーカー、バックオフ）の復元。
    - [x] `struct` セマンティクスに起因するドラッグ状態同期バグの修正。
    - [x] `updateNodeDimensions` への差分更新ガード再実装。

**技術的決定**:
- **テストの並行性対応**: `GraphRuntimeState` が `@MainActor` に隔離されたため、`XCTest` / `Testing` の双方でテストメソッド単位の `@MainActor` 指定を行い、安全なアクセスを確保。
- **属性フィルタの強化**: 接続ターゲット探索において、ノードおよびハンドル個別の `connectable`、および `hidden` 属性を評価するように強化。
- **プレビュー線の簡素化**: 確定エッジは複雑なパス（`bezier` 等）を描画する一方、接続ドラッグ中のプレビューは直線（`line`）を維持し、パフォーマンスと応答性を優先。

**ビルド・テスト検証結果**:
- **Package Tests**: `swift test` により、全 31 テストのパスを確認（XCTest 7 + Swift Testing 24）。
- **Example Build**: `xcodebuild build` 成功。

---
### 2026-04-05 (M14 Selection & Interaction Refinement) [DONE]

### 概要
ノード・エッジの単一選択（排他選択）機能、背景タップによる選択解除、およびジェスチャ競合の解消を実装。

### 実装ノーツ
- **Selection 同期ロジック**: `GraphStore` を唯一の同期点とし、`runtimeState.selection` の更新に合わせて `nodes` / `edges` 配列内の `selected` フラグをアトミックに更新するロジックを実装。
- **ジェスチャ分離 (Node)**: `DragGesture(minimumDistance: 4)` を採用し、移動が閾値未満で `onChanged` が呼ばれなかった場合のみを「選択（タップ）」と判定。これによりドラッグ開始時の誤発火を防止。
- **エッジヒットエリアの強化**: 細いエッジのタップ判定を容易にするため、背後に 20px 幅の透明な `EdgeRenderer` を配置し、`.contentShape(Rectangle())` で判定領域を確保。
- **排他性の保証**: ノード選択時にエッジの選択を解除し、その逆も行う仕様を `GraphStore` 内で保証。

### 検証結果
- **Package Tests**: `swift test` により、新規追加の `SelectionStateTests` を含む全 **32 テスト**のパスを確認（XCTest 9 + Swift Testing 23）。
- **品質**: ドラッグ中、または接続操作中にノードが誤って選択されないことをロジックおよびテストで確認。
- **Refinement (修正)**:
    - エッジの判定領域を `Rectangle()` から `Path.stroke(lineWidth: 20)` へ変更し、背景パン操作との干渉を完全に解消。
    - ノード選択時のボーダー幅を `3px` に強化し、青色の `shadow` を追加して視覚的なフィードバックを明快に改善。
- **ビルド**: `swift build` および Xcode でのビルド成功を確認。

## 2026-04-05: Milestone 15 Final Calibration & Doc Sync

### 矩形選択判定ロジックの修正 (M15b)
- `intersects` (交差) から `contains` (完全包含) に変更。
- `CGRect.contains(CGRect)` を使用し、ノードが矩形内に完全に収まっている場合のみ選択されるように修正。
- `MarqueeTests.swift` を `contains` 仕様の期待値に合わせて更新。
- 全テスト（XCTest 17件, Swift Testing 23件）のパスを確認。

### ドキュメント同期
- `docs/current-plan.md`: Exit Rule を M15 の内容に刷新。用語を `marquee` に統一。
- `docs/backlog.md`: M15 および M15b をチェック済み (DONE) に更新。
- `requirements.md`: Milestone 15 を [DONE] として確定。
- `walkthrough.md`: M15b を含む最終実装内容で更新。

### ビルド検証
- `xcodebuild build` 相当の整合性をパッケージビルドで確認済み。
- **ModifierKeysProvider**: `nonisolated(unsafe)` 警告を解消するため、`MonitorHolder` クラスによるカプセル化を導入。

### ビルド・テスト結果
- `swift test --filter MarqueeTests`: Passed (2 tests)
- `xcodebuild build` (Example App): Succeed with no warnings.

## [2026-04-05] M15b (矩形選択) 実装完了

### 変更点
- **MarqueeState**: `GraphRuntimeState` に矩形選択の状態（開始点、現在点、計算済み矩形）を管理する構造体を追加。
- **GraphStore**: 
  - `startMarquee`, `updateMarquee`, `endMarquee` メソッドを実装。
  - `endMarquee` ではビューポート座標からグラフ絶対座標への変換を行い、`CGRect.intersects` を用いたノード包含判定ロジックを実装。
- **MarqueeView**: 選択中の半透明な矩形と破線枠を描画する SwiftUI ビューを新規作成。
- **GraphView**: 
  - `ModifierKeysProvider` による Shift キーの状態に応じて、背景ドラッグジェスチャの動作を「パン」と「矩形選択」で動的に切り替え。
  - 最前面レイヤーに `MarqueeView` を配置。
- **ModifierKeysProvider**: `nonisolated(unsafe)` 警告を解消するため、`MonitorHolder` クラスによるカプセル化を導入。

### ビルド・テスト結果
- `swift test --filter MarqueeTests`: Passed (2 tests)
- `xcodebuild build` (Example App): Succeed with no warnings.

### 今回で閉じたこと
- マウスクリックおよびドラッグによる複数・範囲選択の基本機能。
- macOS における Shift キーの状態取得と、既存ジェスチャとの競合解決。

### 後続へ送る責務
- エッジの矩形選択（現状はノードのみ）。
- キーボードショートカット（Command+A で全選択、Delete キーで削除など）。

## [2026-04-05] M15a: 複数選択 (Shift + クリック) の実装

### 概要
Shift + クリックによる複数選択機能を実装しました。プラットフォーム固有の修飾キー状態を抽象化するアダプターを導入し、既存の排他選択ロジックを壊さずにトグル選択を可能にしました。

### 変更点
- **Runtime/Adapters/ModifierKeysProvider.swift**:
    - `NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged])` を使用して Shift キーの状態をリアルタイムに監視するクラスを実装。
    - `deinit` での安全なモニター解除のため、`nonisolated(unsafe)` を使用。
-### 2024-04-05 M18 Hotfix-4
- **修正内容**: 
    - ソース側ハンドルがラベルに遮られて動かない問題を ZStack 順序変更とヒット判定拡大で解消。
    - 再接続モードに `isSource` フラグを追加し、`stopConnecting` において向きが逆転しないように修正。
    - macOS ネイティブの `NSVisualEffectView` を使い、ダークモードでも視認性の高いラベル背景を実装。
- **検証**: `swift test` & `swift build` (Success).
- **ビルドパス**: `Sources/SwGraphUI/Public/API/DefaultEdgeView.swift`, `Sources/SwGraphUI/Runtime/GraphStore.swift`.
- **Runtime/GraphStore.swift**:
    - `toggleNodeSelection(_:)` および `toggleEdgeSelection(_:)` メソッドを追加。
    - 既存の選択状態を維持したまま、特定の要素の選択状態を反転させ、モデルの `selected` フラグと同期する処理を実装。
- **Public/API/GraphView.swift**:
    - `ModifierKeysProvider` を内部で保持。
    - ノードのタップ判定（ドラッグ距離が 4px 未満）時に、Shift キーが押されている場合は `toggleNodeSelection`、そうでない場合は `selectNode` を呼び出すように変更。
- **Public/API/DefaultEdgeView.swift**:
    - `ModifierKeysProvider` を受け取り、タップ時に `toggleEdgeSelection` または `selectEdge` を呼び出すように変更。
- **Tests/SelectionStateTests.swift**:
    - 複数選択、選択解除、ノードとエッジの混在選択に関するテストケースを追加。

### 検証結果
- `swift test` 実行: 全 26 テスト（追加分 3 件含む）がパス。
- ビルド確認: シンタックスエラーがないことを確認。

### 次のステップ
- [ ] M15b: 矩形選択 (Marquee) の実装
