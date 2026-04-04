# current-plan: M8 - Core Interaction & Viewport Commands

## Goal
UI非依存なインタラクションエンジン（Drag, Zoom, Pan）の核となるロジックの実装。

## Included
- `ViewportState` と `Dimensions` の連動ロジック。
- `fitView` / `centerView` コマンドのCoreアルゴリズム。
- ドラッグ開始/移動/終了のState遷移ロジック（Pure Swift）。

## Excluded
- SwiftUIコンポーネントによる実際の描画。
- プラットフォーム固有のジェスチャ認識（GestureRecognizer等）。

## Exit Rule
- `fitView` が与えられたノード群とパディングに対して、正しいViewportを返すことがユニットテストで証明されていること。
- ドラッグ操作に伴う `BaseNode.position` の更新ロジックが正常に動作すること。
- 宙に浮く未実装を排除し、後続への送り責務が明確であること。
