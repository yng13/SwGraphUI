import Foundation

/// ビューポート（ズーム・パン）の計算に関する純粋な幾何ロジックを提供します。
public enum ViewportManager {
    
    /// 指定された要素が画面内に収まるようなビューポートを算出します。
    /// - Parameters:
    ///   - nodes: 収めたいノード群。
    ///   - nodeLookup: 親子関係を解決するための全ノードマップ。
    ///   - size: ビューポートを表示するビュー自体の寸法。
    ///   - minZoom: 最小ズーム率。
    ///   - maxZoom: 最大ズーム率。
    ///   - padding: 余白。
    /// - Returns: 計算後のビューポート。
    public static func calculateFitView<Data>(
        nodes: [BaseNode<Data>],
        nodeLookup: [String: BaseNode<Data>]? = nil,
        in size: Dimensions,
        minZoom: Double = 0.5,
        maxZoom: Double = 2.0,
        padding: GeometryAlgorithms.Padding = .all(.relative(0.1))
    ) -> Viewport {
        if nodes.isEmpty {
            return Viewport(x: size.width / 2, y: size.height / 2, zoom: 1.0)
        }
        
        // 1. 親子関係を解決した正確な Bounds を算出
        let bounds = NodePositioningAlgorithms.getNodesBounds(nodes, nodeLookup: nodeLookup)
        
        // 2. GeometryAlgorithms.getViewportForBounds を使用して、Padding 込みの Viewport を算出
        return GeometryAlgorithms.getViewportForBounds(
            bounds,
            in: size,
            minZoom: minZoom,
            maxZoom: maxZoom,
            padding: padding
        )
    }
    
    /// パン（平行移動）を計算します。
    public static func calculatePan(current: Viewport, delta: XYPosition) -> Viewport {
        Viewport(x: current.x + delta.x, y: current.y + delta.y, zoom: current.zoom)
    }
    
    /// 特定の座標を中心としたズームを計算します。
    public static func calculateZoomAtPoint(
        current: Viewport,
        factor: Double,
        at screenPoint: XYPosition,
        minZoom: Double,
        maxZoom: Double
    ) -> Viewport {
        let zoom = Swift.min(Swift.max(current.zoom * factor, minZoom), maxZoom)
        
        let graphPoint = XYPosition(
            x: (screenPoint.x - current.x) / current.zoom,
            y: (screenPoint.y - current.y) / current.zoom
        )
        
        let x = screenPoint.x - graphPoint.x * zoom
        let y = screenPoint.y - graphPoint.y * zoom
        
        return Viewport(x: x, y: y, zoom: zoom)
    }
}
