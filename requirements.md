# Requirements - SwGraphUI

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
