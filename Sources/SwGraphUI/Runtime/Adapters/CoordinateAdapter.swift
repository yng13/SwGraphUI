import Foundation

/// Provides mutual conversion between screen coordinates (Screen Space) and graph absolute coordinates (Graph Absolute Space). | 画面座標（Screen Space）とグラフ絶対座標（Graph Absolute Space）の相互変換を提供します。
/// Bridges coordinates obtained from SwiftUI gestures to logical coordinates within the graph. | SwiftUI のジェスチャから得られる座標を、グラフ内の論理座標へと橋渡しします。
public enum CoordinateAdapter {
    
    /// Converts a point on the screen (mouse/touch position, etc.) into coordinates in graph space. | 画面上のポイント（マウス・タッチ位置など）をグラフ空間の座標に変換します。
    /// - Parameters:
    ///   - screenPoint: Local coordinates on the screen. | 画面上のローカル座標。
    ///   - viewport: Current viewport (x, y, zoom). | 現在のビューポート (x, y, zoom)。
    /// - Returns: Coordinates in the absolute graph space. | グラフ絶対空間における座標。
    public static func screenToGraph(
        _ screenPoint: XYPosition,
        viewport: Viewport
    ) -> XYPosition {
        // (Screen - ViewportOffset) / Zoom
        XYPosition(
            x: (screenPoint.x - viewport.x) / viewport.zoom,
            y: (screenPoint.y - viewport.y) / viewport.zoom
        )
    }
    
    /// Converts coordinates on the graph to positions on the screen. | グラフ上の座標を画面上の位置に変換します。
    /// - Parameters:
    ///   - graphPoint: Coordinates in graph space. | グラフ空間の座標。
    ///   - viewport: Current viewport (x, y, zoom). | 現在のビューポート (x, y, zoom)。
    /// - Returns: Local coordinates on the screen. | 画面上のローカル座標。
    public static func graphToScreen(
        _ graphPoint: XYPosition,
        viewport: Viewport
    ) -> XYPosition {
        // Graph * Zoom + ViewportOffset
        XYPosition(
            x: graphPoint.x * viewport.zoom + viewport.x,
            y: graphPoint.y * viewport.zoom + viewport.y
        )
    }
}
