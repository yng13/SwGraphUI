# current-plan: M10a - Adaptive Example App (IDE Harness)

## Goal
SwGraphUI の開発・デバッグを加速させるため、macOS / iOS に適応した IDE スタイルの開発用ハーネスを構築し、基本操作（Zoom, Pan, FitView）の安定性を確保する。

## Included
- **Adaptive UI**: macOS 14+ `NavigationSplitView` による 3 カラム構成。
- **Core Interaction Fix**: 
  - `GraphStore.pan(by:)` 経由の統制されたパン操作。
  - `GraphView` における背景ドラッグジェスチャの追加と、独立した座標空間 `viewport_container` の定義。
  - パン操作の感度調整 (`minimumDistance: 10`)。
- **Harness Support**: 
  - `ExampleAppStore` によるサンプル切り替え。
  - キャンバス境界の視覚化 (`border`)。
  - サンプルデータへの暫定寸法付与による `fitView` 精度向上。

## Excluded
- **Measurement Engine**: 描画ノードの実測サイズを `BaseNode.measured` に動的同期する仕組み（M10b/11以降）。
- **Custom View Injection**: `@ViewBuilder` 等を用いたライブラリ外部からのノードビュー注入（M10b以降）。

## Exit Rule
- ズーム倍率に関わらず、ドラッグ中のノードが常にポインタに同期すること。
- 背景ドラッグによるキャンバス移動が、誤操作（クリック、選択）と明確に分離して動作すること。
- `fitView` 実行時に、サンプルノードが完全にキャンバス領域内に収まること。

## 完了したマイルストーン
- [x] M9: Platform Adapters & UI State Synchronization
- [x] M8: Core Interaction & Viewport Commands
- [x] M7: pure coreの実体化
