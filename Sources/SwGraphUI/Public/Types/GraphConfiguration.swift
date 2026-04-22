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
    
    public init(
        showGrid: Bool = false,
        gridSize: CGFloat = 20,
        backgroundVariant: BackgroundVariant = .dots,
        gridColor: Color = .primary.opacity(0.12)
    ) {
        self.showGrid = showGrid
        self.gridSize = gridSize
        self.backgroundVariant = backgroundVariant
        self.gridColor = gridColor
    }
}
