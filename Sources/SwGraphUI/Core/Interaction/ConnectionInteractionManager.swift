import Foundation

/// ノード間の接続操作（ドラッグ、スナップ、バリデーション）のロジックを管理するクラス。
public enum ConnectionInteractionManager {
    
    /// 吸着判定の閾値（UIピクセル）。
    /// ズームにかかわらず一定の操作感を提供するため、スクリーン座標系で判定します。
    public static let snapDistance: Double = 24.0
    
    /// 指定されたグラフ空間のポインタ位置付近に吸着対象となるハンドルがあるか検索します。
    /// 
    /// - Parameters:
    ///   - pointerInGraph: グラフ空間での現在のポインタ位置
    ///   - nodes: 検索対象の全ノード
    ///   - nodeLookup: 絶対座標計算のための検索マップ
    ///   - viewport: スクリーン座標への変換に使用する現在のビューポート
    ///   - fromNodeID: 接続開始点のノードID（自己接続防止用）
    /// - Returns: スナップ条件を満たすノードとハンドルのペア（存在する場合）
    public static func findTargetHandle<Data: Sendable>(
        near pointerInGraph: XYPosition,
        in nodes: [BaseNode<Data>],
        nodeLookup: [String: BaseNode<Data>],
        viewport: Viewport,
        fromNodeID: String?
    ) -> (node: BaseNode<Data>, handle: NodeHandle)? {
        let pointerInScreen = pointerInGraph.toScreen(viewport: viewport)
        
        var bestMatch: (node: BaseNode<Data>, handle: NodeHandle)?
        var minDistanceSq = snapDistance * snapDistance
        
        for node in nodes {
            // 基本バリデーション: 非表示、接続不可、または自己接続の除外
            guard !node.hidden, node.connectable else { continue }
            if let fromNodeID, node.id == fromNodeID { continue }
            
            // 階層を考慮した絶対座標を取得
            let absoluteNodePos = NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: nodeLookup)
            
            // 各ノードのハンドルをチェック
            let placements: [Position] = [.top, .bottom, .left, .right]
            
            for placement in placements {
                // ハンドルの位置をグラフ空間の絶対座標で計算
                let handlePosInGraph = calcHandlePosition(
                    absolutePosition: absoluteNodePos,
                    dimensions: node.measured ?? Dimensions(width: 100, height: 50),
                    placement: placement
                )
                let handlePosInScreen = handlePosInGraph.toScreen(viewport: viewport)
                
                let dx = pointerInScreen.x - handlePosInScreen.x
                let dy = pointerInScreen.y - handlePosInScreen.y
                let distSq = dx * dx + dy * dy
                
                if distSq < minDistanceSq {
                    minDistanceSq = distSq
                    bestMatch = (node, NodeHandle(placement: placement, type: .target))
                }
            }
        }
        
        return bestMatch
    }
    
    /// ノードの絶対座標とサイズから、ハンドルのグラフ空間絶対座標を計算します。
    public static func calcHandlePosition(
        absolutePosition: XYPosition,
        dimensions: Dimensions,
        placement: Position
    ) -> XYPosition {
        let w = dimensions.width
        let h = dimensions.height
        let x = absolutePosition.x
        let y = absolutePosition.y
        
        switch placement {
        case .top:    return XYPosition(x: x + w / 2, y: y)
        case .bottom: return XYPosition(x: x + w / 2, y: y + h)
        case .left:   return XYPosition(x: x, y: y + h / 2)
        case .right:  return XYPosition(x: x + w, y: y + h / 2)
        }
    }
}
