import SwiftUI

/// Structure that manages graph display settings | グラフの表示設定を管理する構造体
public struct GraphConfiguration {
    /// Whether to display grids or dots | グリッドやドットを表示するかどうか
    public var showGrid: Bool
    /// Grid interval | グリッドの間隔
    public var gridSize: CGFloat
    /// Background pattern (lines, dots, cross) | 背景のパターン（ライン、ドット、クロス）
    public var backgroundVariant: BackgroundVariant
    /// Color of the pattern | パターンの色
    public var gridColor: Color
    /// Built-in handle size, hit target, and anchor offset settings | 組み込みハンドルのサイズ、ヒット領域、アンカーオフセット設定
    public var handleStyle: GraphHandleStyle
    /// Optional graph-space snap grid used for manual node dragging | 手動ノードドラッグ時に使う graph-space のスナップグリッド
    public var snapGrid: SnapGrid?
    
    public init(
        showGrid: Bool = false,
        gridSize: CGFloat = 20,
        backgroundVariant: BackgroundVariant = .dots,
        gridColor: Color = .primary.opacity(0.12),
        handleStyle: GraphHandleStyle = .default,
        snapGrid: SnapGrid? = nil
    ) {
        self.showGrid = showGrid
        self.gridSize = gridSize
        self.backgroundVariant = backgroundVariant
        self.gridColor = gridColor
        self.handleStyle = handleStyle
        self.snapGrid = snapGrid
    }

    /// Convenience factory for square grid snapping. | 正方グリッド用の簡易スナップ設定。
    public static func gridSnap(_ size: Double) -> SnapGrid {
        SnapGrid(width: size, height: size)
    }
}
