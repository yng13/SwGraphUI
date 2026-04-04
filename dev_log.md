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
- **データクリーンアップ**: サンプルデータからハードコードされたアニメーションフラグを削除し、一貫性を確保。

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
5. プッシュ案提示（承認待ち）
6. プッシュ実行
