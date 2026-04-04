---
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
- 実機（Example）：カスタムノードの動的テキストに応じたサイズ変更が `CodeView` および `fitView` に正しく反映されることを確認。

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
