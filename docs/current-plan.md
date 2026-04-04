# current-plan: M8 - Core Interaction & Viewport Commands

## Goal
UI非依存なインタラクションエンジン（Drag, Zoom, Pan）の核となるロジックの実装。

## Included
- `ViewportState` と `Dimensions` の連動ロジック。
- `fitView` / `centerView` コマンドのCoreアルゴリズム（GeometryAlgorithms の拡張）。
- ドラッグ開始/移動/終了のState遷移ロジック（Pure Swift）。

## Excluded
- SwiftUIコンポーネントによる実際の描画（M9以降）。
- プラットフォーム固有のジェスチャ認識（GestureRecognizer等）。

## Exit Rule
- `fitView` が与えられたノード群とパディングに対して、期待通りのViewportを返すことがプロパティベースのテストで証明されていること。
- ドラッグ操作に伴う `BaseNode.position` の更新ロジックが正常に動作し、`DragState` が正確に遷移すること。
- 宙に浮く未実装を排除し、後続への送り責務（例：プラットフォームアダプタへの通知）が明確であること。

## 完了したマイルストーン
- [x] M7: pure coreの実体化 (Base models, Geometry Algorithms, Runtime State helpers)
    - [x] Codexレビューに基づく修正 (PaddingValue, smoothStepPath 準拠, 幾何検証テスト)

## 後続に固定した拡張テーマ
- 印刷/PDF・PNG エクスポートは拡張フェーズで扱う
- 出力品質要件は `docs/export-strategy.md` を source とする
