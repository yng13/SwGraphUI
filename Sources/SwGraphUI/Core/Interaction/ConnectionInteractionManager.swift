import Foundation

/// ノード間の接続操作（ドラッグ、スナップ、バリデーション）のロジックを管理するクラス。
public enum ConnectionInteractionManager {
    
    /// 吸着判定の閾値（UIピクセル）。
    /// ズームにかかわらず一定の操作感を提供するため、スクリーン座標系で判定します。
    public static let snapDistance: Double = 24.0
    
    /// 接続候補となるハンドルの情報（判定用）
    public struct HandleCandidate: Sendable, Equatable {
        public let key: HandleKey
        public let position: XYPosition
        public let isHidden: Bool
        public let isConnectable: Bool
        
        public init(key: HandleKey, position: XYPosition, isHidden: Bool, isConnectable: Bool) {
            self.key = key
            self.position = position
            self.isHidden = isHidden
            self.isConnectable = isConnectable
        }
    }

    /// スクリーン空間においてポインタに最も近いハンドルを候補から選択します。
    /// 
    /// - Parameters:
    ///   - pointerInGraph: グラフ空間でのポインタ位置
    ///   - candidates: 判定対象となる解決済みハンドルのリスト
    ///   - viewport: スクリーン座標変換用のビューポート
    ///   - threshold: 吸着閾値（デフォルトは snapDistance）
    ///   - fromNodeID: 接続開始ノード（自己接続防止用）
    /// - Returns: スナップ条件を満たす最も近いハンドルのキー
    public static func findNearestHandle(
        near pointerInGraph: XYPosition,
        candidates: [HandleCandidate],
        viewport: Viewport,
        threshold: Double = snapDistance,
        fromNodeID: String? = nil
    ) -> HandleKey? {
        let pointerInScreen = pointerInGraph.toScreen(viewport: viewport)
        let thresholdSq = threshold * threshold
        
        var bestMatch: (key: HandleKey, distSq: Double)? = nil
        
        for candidate in candidates {
            // 基本バリデーション
            guard !candidate.isHidden && candidate.isConnectable else { continue }
            if let fromNodeID, candidate.key.nodeID == fromNodeID { continue }
            
            let handlePosInScreen = candidate.position.toScreen(viewport: viewport)
            let dx = pointerInScreen.x - handlePosInScreen.x
            let dy = pointerInScreen.y - handlePosInScreen.y
            let distSq = dx * dx + dy * dy
            
            if distSq < thresholdSq {
                if bestMatch == nil || distSq < bestMatch!.distSq {
                    bestMatch = (candidate.key, distSq)
                }
            }
        }
        
        return bestMatch?.key
    }
    
    /// 指定されたグラフ空間のポインタ位置付近に吸着対象となるハンドルがあるか検索します。
    /// ※ 後方互換性および単純な検索用
    public static func findTargetHandle<Data: Sendable>(
        near pointerInGraph: XYPosition,
        in nodes: [BaseNode<Data>],
        nodeLookup: [String: BaseNode<Data>],
        viewport: Viewport,
        fromNodeID: String?
    ) -> (node: BaseNode<Data>, handle: NodeHandle)? {
        // 既存の findTargetHandle も共通ロジックに寄せる（任意）が、
        // 今回の GraphStore 統合では findNearestHandle を主導線とする。
        
        // 簡易実装として以前のロジックを維持しつつ、もし必要なら findNearestHandle にリダイレクト可能
        // 現時点では GraphStore 側の統合を優先。
        let pointerInScreen = pointerInGraph.toScreen(viewport: viewport)
        
        var bestMatch: (node: BaseNode<Data>, handle: NodeHandle)?
        var minDistanceSq = snapDistance * snapDistance
        
        for node in nodes {
            guard !node.hidden, node.connectable else { continue }
            if let fromNodeID, node.id == fromNodeID { continue }
            
            let absoluteNodePos = NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: nodeLookup)
            let placements: [Position] = [.top, .bottom, .left, .right]
            
            for placement in placements {
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
        
        // DefaultNodeView の標準オフセット（8px）を考慮した推測値
        let handleOffset: Double = 8.0
        
        switch placement {
        case .top:    return XYPosition(x: x + w / 2, y: y - handleOffset)
        case .bottom: return XYPosition(x: x + w / 2, y: y + h + handleOffset)
        case .left:   return XYPosition(x: x - handleOffset, y: y + h / 2)
        case .right:  return XYPosition(x: x + w + handleOffset, y: y + h / 2)
        }
    }
}
