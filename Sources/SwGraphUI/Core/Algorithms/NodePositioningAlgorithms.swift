import Foundation

/// ノードの座標計算（親子変換、Origin考慮、範囲制限）に特化したアルゴリズム。
/// xyflow/system の `calculateNodePosition` および `evaluateAbsolutePosition` に相当するロジックを提供します。
public enum NodePositioningAlgorithms {
    
    /// ノードの座標 (Originを考慮した基準点) から、描画上の左上端 (Top-Left) を算出。
    /// 親ノードの origin は「基準点の復元（左上へのシフト）」にのみ寄与し、子の origin とは独立して扱う。
    /// 注意: このメソッドが返すのは、そのノードが所属する座標空間（親がいれば親基準、いなければグラフ基準）での左上端です。
    public static func getNodePositionWithOrigin<Data>(
        _ node: BaseNode<Data>,
        nodeOrigin: NodeOrigin = .zero
    ) -> XYPosition {
        let origin = node.origin ?? nodeOrigin
        let width = node.measured?.width ?? node.width ?? node.initialWidth ?? 0
        let height = node.measured?.height ?? node.height ?? node.initialHeight ?? 0
        
        return XYPosition(
            x: node.position.x - (width * origin.x),
            y: node.position.y - (height * origin.y)
        )
    }

    /// ノードの絶対的な「描画左上端 (Top-Left)」を親チェーンを遡って算出します。
    /// - Parameters:
    ///   - node: 対象ノード。
    ///   - nodeLookup: 親ノードを検索するためのマップ。
    ///   - defaultOrigin: プロジェクト全体のデフォルト Origin。
    /// - Returns: グラフ空間（絶対座標）における左上端の座標。
    public static func evaluateAbsolutePosition<Data>(
        _ node: BaseNode<Data>,
        nodeLookup: [String: BaseNode<Data>],
        defaultOrigin: NodeOrigin = .zero
    ) -> XYPosition {
        let currentRelativeTopLeft = getNodePositionWithOrigin(node, nodeOrigin: defaultOrigin)
        var currentParentID = node.parentID
        var visited = Set<String>([node.id])
        
        var absoluteTopLeft = currentRelativeTopLeft
        var depth = 0
        let maxDepth = 20
        
        // 親を遡って相対座標を足し込む
        while let parentID = currentParentID, let parent = nodeLookup[parentID] {
            if visited.contains(parentID) || depth >= maxDepth { break } // 循環参照ガード & 最大階層数制限
            visited.insert(parentID)
            depth += 1
            
            // 親ノード自体の（その親基準、またはグラフ基準の）左上端を取得
            let parentRelativeTopLeft = getNodePositionWithOrigin(parent, nodeOrigin: defaultOrigin)
            absoluteTopLeft = absoluteTopLeft + parentRelativeTopLeft
            
            currentParentID = parent.parentID
        }
        
        return absoluteTopLeft
    }

    /// ノード群の包含矩形 (Bounds) を算出。
    /// 親子関係を解決し、すべてのノードを絶対座標空間に展開して結合します。
    public static func getNodesBounds<Data>(
        _ nodes: [BaseNode<Data>],
        nodeLookup: [String: BaseNode<Data>]? = nil,
        nodeOrigin: NodeOrigin = .zero
    ) -> Rect {
        if nodes.isEmpty { return .zero }
        
        // 外部から lookup が与えられない場合は、渡された nodes から一時的に作成する (Convenience)
        let effectiveLookup = nodeLookup ?? Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        
        let rects = nodes.map { node -> Rect in
            let absoluteTopLeft = evaluateAbsolutePosition(node, nodeLookup: effectiveLookup, defaultOrigin: nodeOrigin)
            let width = node.measured?.width ?? node.width ?? node.initialWidth ?? 0
            let height = node.measured?.height ?? node.height ?? node.initialHeight ?? 0
            return Rect(origin: absoluteTopLeft, size: Dimensions(width: width, height: height))
        }
        
        return GeometryAlgorithms.union(of: rects) ?? .zero
    }

    /// 親ノードの絶対座標 (左上基準) を起点とした絶対座標への変換
    /// 親ノードがさらに親を持つ階層構造を考慮し、再帰的に絶対座標を解決します。
    public static func toAbsolutePosition<Data>(
        _ position: XYPosition,
        dimensions: Dimensions = .zero, // 予約用
        parent: BaseNode<Data>?,
        nodeLookup: [String: BaseNode<Data>],
        defaultOrigin: NodeOrigin = .zero
    ) -> XYPosition {
        guard let parent = parent else { return position }
        
        // 親の「真の」絶対位置 (グラフ基準の左上端) を取得
        let parentAbsoluteTopLeft = evaluateAbsolutePosition(parent, nodeLookup: nodeLookup, defaultOrigin: defaultOrigin)
        
        return XYPosition(
            x: position.x + parentAbsoluteTopLeft.x,
            y: position.y + parentAbsoluteTopLeft.y
        )
    }

    /// 親ノードの絶対座標 (左上基準) を基準とした相対座標への変換
    /// 親ノードがさらに親を持つ階層構造を考慮し、再帰的に絶対座標を解決します。
    public static func toRelativePosition<Data>(
        _ absolutePosition: XYPosition,
        dimensions: Dimensions = .zero, // 予約用
        parent: BaseNode<Data>?,
        nodeLookup: [String: BaseNode<Data>],
        defaultOrigin: NodeOrigin = .zero
    ) -> XYPosition {
        guard let parent = parent else { return absolutePosition }
        
        // 親の「真の」絶対位置 (グラフ基準の左上端) を取得
        let parentAbsoluteTopLeft = evaluateAbsolutePosition(parent, nodeLookup: nodeLookup, defaultOrigin: defaultOrigin)
        
        return XYPosition(
            x: absolutePosition.x - parentAbsoluteTopLeft.x,
            y: absolutePosition.y - parentAbsoluteTopLeft.y
        )
    }

    /// SnapGrid を適用します。
    public static func applySnap(
        position: XYPosition,
        snapGrid: SnapGrid
    ) -> XYPosition {
        XYPosition(
            x: snapGrid.width * round(position.x / snapGrid.width),
            y: snapGrid.height * round(position.y / snapGrid.height)
        )
    }

    /// 指定された範囲（Extent）内に座標を制限します。
    public static func clampToExtent(
        _ position: XYPosition,
        extent: CoordinateExtent,
        dimensions: Dimensions
    ) -> XYPosition {
        XYPosition(
            x: Swift.min(Swift.max(position.x, extent.min.x), extent.max.x - dimensions.width),
            y: Swift.min(Swift.max(position.y, extent.min.y), extent.max.y - dimensions.height)
        )
    }

    /// ドラッグ後の次ポジションを計算します（Snap -> Extent の順序を遵守）。
    public static func calculateNextPosition(
        currentPosition: XYPosition,
        dragStartDelta: XYPosition,
        snapGrid: SnapGrid?,
        extent: CoordinateExtent?,
        dimensions: Dimensions
    ) -> XYPosition {
        var next = currentPosition + dragStartDelta
        
        if let snap = snapGrid {
            next = applySnap(position: next, snapGrid: snap)
        }
        
        if let limit = extent {
            next = clampToExtent(next, extent: limit, dimensions: dimensions)
        }
        
        return next
    }
}
