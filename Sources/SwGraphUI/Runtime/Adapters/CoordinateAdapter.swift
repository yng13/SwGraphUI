import Foundation

/// 画面座標（Screen Space）とグラフ絶対座標（Graph Absolute Space）の相互変換を提供します。
/// SwiftUI のジェスチャから得られる座標を、グラフ内の論理座標へと橋渡しします。
public enum CoordinateAdapter {
    
    /// 画面上のポイント（マウス・タッチ位置など）をグラフ空間の座標に変換します。
    /// - Parameters:
    ///   - screenPoint: 画面上のローカル座標。
    ///   - viewport: 現在のビューポート (x, y, zoom)。
    /// - Returns: グラフ絶対空間における座標。
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
    
    /// グラフ上の座標を画面上の位置に変換します。
    /// - Parameters:
    ///   - graphPoint: グラフ空間の座標。
    ///   - viewport: 現在のビューポート (x, y, zoom)。
    /// - Returns: 画面上のローカル座標。
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
