import Foundation

/// ノードの配置およびハンドル座標の算出に関するコアアルゴリズム。
public enum NodePositioningAlgorithms {
    
    /// 特定のノードにおけるハンドルのグラフ空間上の絶対座標を算出します。
    /// - Parameters:
    ///   - node: 対象ノード
    ///   - handlePlacement: ハンドルの配置（Top/Bottom等）
    ///   - absPos: 階層解決済みのノード絶対座標（外部から注入）
    /// - Returns: ハンドルの絶対座標 (XYPosition)
    public static func getHandlePosition<Data: Sendable>(
        node: BaseNode<Data>,
        handlePlacement: Position,
        absPos: XYPosition
    ) -> XYPosition {
        // サイズ解決優先順位: measured -> width/height -> initialWidth/Height -> 0
        let width = node.measured?.width ?? node.width ?? node.initialWidth ?? 0
        let height = node.measured?.height ?? node.height ?? node.initialHeight ?? 0
        
        switch handlePlacement {
        case .top:
            return XYPosition(x: absPos.x + width / 2, y: absPos.y)
        case .bottom:
            return XYPosition(x: absPos.x + width / 2, y: absPos.y + height)
        case .left:
            return XYPosition(x: absPos.x, y: absPos.y + height / 2)
        case .right:
            return XYPosition(x: absPos.x + width, y: absPos.y + height / 2)
        }
    }
    
    /// ノードの絶対座標を解決します（親ノードの座標を再帰的に加算し、Origin を考慮）。
    public static func evaluateAbsolutePosition<Data: Sendable>(
        _ node: BaseNode<Data>,
        nodeLookup: [String: BaseNode<Data>]
    ) -> XYPosition {
        // 現在のノードの Top-Left (相対) を算出
        var position = GeometryAlgorithms.getNodePositionWithOrigin(node: node)
        var currentParentID = node.parentID
        
        // 循環参照ガード: 既に訪問したノードIDを記録
        var visited = Set<String>([node.id])
        
        // 親を遡りながら、各階層の Top-Left を加算
        while let parentID = currentParentID, let parent = nodeLookup[parentID] {
            // 既に訪問した親ならループを中断
            if visited.contains(parentID) { break }
            visited.insert(parentID)
            
            position = position + GeometryAlgorithms.getNodePositionWithOrigin(node: parent)
            currentParentID = parent.parentID
        }
        
        return position
    }
    
    /// 指定された座標にスナップを適用します。
    public static func applySnap(position: XYPosition, snapGrid: SnapGrid) -> XYPosition {
        XYPosition(
            x: snapGrid.width * round(position.x / snapGrid.width),
            y: snapGrid.height * round(position.y / snapGrid.height)
        )
    }

    /// 絶対座標を親ノードに対する相対座標に変換します。
    public static func toRelativePosition<Data: Sendable>(
        _ absolutePosition: XYPosition,
        parent: BaseNode<Data>?,
        nodeLookup: [String: BaseNode<Data>],
        defaultOrigin: NodeOrigin = .zero
    ) -> XYPosition {
        guard let parent = parent else { return absolutePosition }
        let parentAbsPos = evaluateAbsolutePosition(parent, nodeLookup: nodeLookup)
        return absolutePosition - parentAbsPos
    }

    /// 相対座標を階層を考慮した絶対座標に変換します。
    public static func toAbsolutePosition<Data: Sendable>(
        _ relativePosition: XYPosition,
        parent: BaseNode<Data>?,
        nodeLookup: [String: BaseNode<Data>]
    ) -> XYPosition {
        guard let parent = parent else { return relativePosition }
        let parentAbsPos = evaluateAbsolutePosition(parent, nodeLookup: nodeLookup)
        return relativePosition + parentAbsPos
    }

    /// 指定された範囲 (NodeExtent) 内に座標を制限します。
    public static func clampToExtent(
        _ position: XYPosition,
        extent: NodeExtent,
        dimensions: Dimensions,
        containerSize: Dimensions? = nil
    ) -> XYPosition {
        switch extent {
        case .coordinate(let coord):
            return XYPosition(
                x: max(coord.min.x, min(position.x, coord.max.x - dimensions.width)),
                y: max(coord.min.y, min(position.y, coord.max.y - dimensions.height))
            )
        case .parent:
            guard let container = containerSize else { return position }
            return XYPosition(
                x: max(0, min(position.x, container.width - dimensions.width)),
                y: max(0, min(position.y, container.height - dimensions.height))
            )
        }
    }

    /// 複数のノードを含む最小の矩形領域を算出します（階層構造対応）。
    public static func getNodesBounds<Data: Sendable>(
        _ nodes: [BaseNode<Data>],
        nodeLookup: [String: BaseNode<Data>] = [:]
    ) -> Rect {
        if nodes.isEmpty { return .zero }
        
        let nodeRects = nodes.map { node in
            let absPos = evaluateAbsolutePosition(node, nodeLookup: nodeLookup)
            let width = node.measured?.width ?? node.width ?? node.initialWidth ?? 0
            let height = node.measured?.height ?? node.height ?? node.initialHeight ?? 0
            return Rect(origin: absPos, size: Dimensions(width: width, height: height))
        }
        
        return GeometryAlgorithms.union(of: nodeRects) ?? .zero
    }

    /// ノードの階層の深さを算出します（親がいない場合は0）。
    public static func calculateDepth<Data: Sendable>(
        node: BaseNode<Data>,
        nodeLookup: [String: BaseNode<Data>]
    ) -> Int {
        var depth = 0
        var currentParentID = node.parentID
        var visited = Set<String>([node.id])
        
        while let parentID = currentParentID, let parent = nodeLookup[parentID] {
            if visited.contains(parentID) { break }
            visited.insert(parentID)
            depth += 1
            currentParentID = parent.parentID
        }
        
        return depth
    }
}
