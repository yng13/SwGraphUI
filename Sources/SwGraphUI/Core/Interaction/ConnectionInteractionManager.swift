import Foundation

/// Class that manages the logic for connection operations between nodes (dragging, snapping, validation). | ノード間の接続操作（ドラッグ、スナップ、バリデーション）のロジックを管理するクラス。
enum ConnectionInteractionManager {

    /// Threshold for snap detection (UI pixels). | 吸着判定の閾値（UIピクセル）。
    /// Judging in the screen coordinate system to provide a consistent operational feel regardless of zoom. | ズームにかかわらず一定の操作感を提供するため、スクリーン座標系で判定します。
    static let snapDistance: Double = 24.0

    /// Information on handles that are candidates for connection (for judgment) | 接続候補となるハンドルの情報（判定用）
    struct HandleCandidate: Sendable, Equatable {
        let key: HandleKey
        let position: XYPosition
        let isHidden: Bool
        let isConnectable: Bool

        init(key: HandleKey, position: XYPosition, isHidden: Bool, isConnectable: Bool) {
            self.key = key
            self.position = position
            self.isHidden = isHidden
            self.isConnectable = isConnectable
        }
    }

    /// Selects the handle closest to the pointer in screen space from the candidates. | スクリーン空間においてポインタに最も近いハンドルを候補から選択します。
    ///
    /// - Parameters:
    ///   - pointerInGraph: Pointer position in graph space | グラフ空間でのポインタ位置
    ///   - candidates: List of resolved handles to be judged | 判定対象となる解決済みハンドルのリスト
    ///   - viewport: Viewport for screen coordinate conversion | スクリーン座標変換用のビューポート
    ///   - threshold: Snapping threshold (default is snapDistance) | 吸着閾値（デフォルトは snapDistance）
    ///   - fromNodeID: Connection start node (to prevent self-connection) | 接続開始ノード（自己接続防止用）
    /// - Returns: Key of the nearest handle satisfying the snap condition | スナップ条件を満たす最も近いハンドルのキー
    static func findNearestHandle(
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
            // Basic validation | 基本バリデーション
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

    /// Searches for a handle to snap to near the specified pointer position in graph space. | 指定されたグラフ空間のポインタ位置付近に吸着対象となるハンドルがあるか検索します。
    /// * For backward compatibility and simple searches | ※ 後方互換性および単純な検索用
    static func findTargetHandle<NodeData: Sendable>(
        near pointerInGraph: XYPosition,
        in nodes: [BaseNode<NodeData>],
        nodeLookup: [String: BaseNode<NodeData>],
        viewport: Viewport,
        fromNodeID: String?
    ) -> (node: BaseNode<NodeData>, handle: NodeHandle)? {
        let pointerInScreen = pointerInGraph.toScreen(viewport: viewport)

        var bestMatch: (node: BaseNode<NodeData>, handle: NodeHandle)?
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

    /// Calculates the absolute graph space coordinates of a handle from the node's absolute coordinates and size. | ノードの絶対座標とサイズから、ハンドルのグラフ空間絶対座標を計算します。
    static func calcHandlePosition(
        absolutePosition: XYPosition,
        dimensions: Dimensions,
        placement: Position
    ) -> XYPosition {
        let w = dimensions.width
        let h = dimensions.height
        let x = absolutePosition.x
        let y = absolutePosition.y

        // Estimated value considering the standard offset (8px) of DefaultNodeView | DefaultNodeView の標準オフセット（8px）を考慮した推測値
        let handleOffset: Double = 8.0

        switch placement {
        case .top:    return XYPosition(x: x + w / 2, y: y - handleOffset)
        case .bottom: return XYPosition(x: x + w / 2, y: y + h + handleOffset)
        case .left:   return XYPosition(x: x - handleOffset, y: y + h / 2)
        case .right:  return XYPosition(x: x + w + handleOffset, y: y + h / 2)
        }
    }
}
