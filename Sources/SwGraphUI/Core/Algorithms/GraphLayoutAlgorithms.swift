import Foundation
import CoreGraphics

/// Defines the direction of automatic layout (named GraphLayoutDirection to avoid conflict with SwiftUI.LayoutDirection). | 自動レイアウトの方向を定義します（SwiftUI.LayoutDirection との衝突を避けるため GraphLayoutDirection と命名）。
public enum GraphLayoutDirection: Sendable, Codable {
    case topToBottom
    case bottomToTop
    case leftToRight
    case rightToLeft
}

/// Utility providing hierarchical (Tree/DAG) automatic layout algorithms. | 階層型（Tree/DAG 向け）自動レイアウトアルゴリズムを提供するユーティリティ。
/// Accepts graph structures without circular references (Tree or DAG) and calculates positions considering node spacing and sizes. | 循環参照のないグラフ構造（Tree または DAG）を受け入れ、ノード間隔とノードサイズを考慮した配置を算出します。
public enum GraphLayoutAlgorithms {
    /// Converts a center-based position into the top-left origin used by `BaseNode.position`.
    public static func centerToTopLeft(_ center: XYPosition, size: Dimensions) -> XYPosition {
        XYPosition(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2
        )
    }

    /// Converts a top-left origin into a center-based position.
    public static func topLeftToCenter(_ origin: XYPosition, size: Dimensions) -> XYPosition {
        XYPosition(
            x: origin.x + size.width / 2,
            y: origin.y + size.height / 2
        )
    }
    
    /// Performs a simple hierarchical layout and calculates new recommended coordinates for each node. | シンプルな階層型レイアウトを実行し、各ノードの新しい推奨座標を算出します。
    /// - Parameters:
    ///   - nodes: Target nodes (currently assuming a flat set where parentID == nil) | 対象ノード群（現在は parentID == nil のフラットな集合を想定）
    ///   - edges: Connection edges | 接続エッジ群
    ///   - direction: Layout direction | レイアウトの方向
    ///   - spacing: Minimum spacing between nodes | ノード間の最低間隔
    /// - Returns: A map of new recommended coordinates keyed by node ID | ノードIDをキーとした新しい推奨座標のマップ
    public static func layoutNodesTreeStyle<Data: Sendable>(
        nodes: [BaseNode<Data>],
        edges: [BaseEdge<Data>],
        direction: GraphLayoutDirection = .topToBottom,
        spacing: Double = 50.0
    ) -> [String: XYPosition] {
        guard !nodes.isEmpty else { return [:] }
        
        let nodeLookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        
        // 1. Layer division (Ranking) | 1. レイヤー分割 (Ranking)
        let nodeLayers = assignLayers(nodes: nodes, edges: edges)
        
        // 2. Ordering determination (Ordering / sibling arrangement) | 2. 順序決定 (Ordering / sibling arrangement)
        let orderedLayers = orderNodes(nodeLayers: nodeLayers, nodeLookup: nodeLookup)
        
        // 3. Coordinate assignment | 3. 座標割り当て (Coordinate Assignment)
        return assignCoordinates(
            orderedLayers: orderedLayers,
            nodeLookup: nodeLookup,
            direction: direction,
            spacing: spacing
        )
    }
    
    // MARK: - Internal Phases
    
    /// Divides nodes into layers (ranks) based on dependencies (edges). | ノードを依存関係（エッジ）に基づいて階層（ランク）に分割します。
    private static func assignLayers<Data: Sendable>(
        nodes: [BaseNode<Data>],
        edges: [BaseEdge<Data>]
    ) -> [Int: [String]] {
        var layers: [Int: [String]] = [:]
        var nodeInDegrees: [String: Int] = [:]
        
        for node in nodes {
            nodeInDegrees[node.id] = 0
        }
        
        for edge in edges {
            nodeInDegrees[edge.target, default: 0] += 1
        }
        
        // Root (In-degree == 0) to layer 0 | Root (In-degree == 0) をレイヤー 0 に
        var queue: [(id: String, layer: Int)] = nodes
            .filter { (nodeInDegrees[$0.id] ?? 0) == 0 }
            .map { ($0.id, 0) }
        
        // 1.5 Construction of adjacency list (O(E)) | 1.5 隣接リストの構築 (O(E))
        var outEdgesMap: [String: [String]] = [:]
        for edge in edges {
            outEdgesMap[edge.source, default: []].append(edge.target)
        }
        
        // 2. BFS/DFS-like layer determination (O(N+E)) | 2. BFS/DFS 的な階層決定 (O(N+E))
        var visited = Set<String>()
        var nodeToLayer: [String: Int] = [:]
        
        while !queue.isEmpty {
            let (id, layer) = queue.removeFirst()
            if visited.contains(id) { continue }
            visited.insert(id)
            
            nodeToLayer[id] = max(nodeToLayer[id, default: 0], layer)
            
            // Search in O(d) using the adjacency list | 隣接リストを使用して O(d) で探索
            if let targets = outEdgesMap[id] {
                for target in targets {
                    queue.append((target, layer + 1))
                }
            }
        }
        
        for (id, layer) in nodeToLayer {
            layers[layer, default: []].append(id)
        }
        
        return layers
    }
    
    /// Determines the order of nodes within the same layer. | 同一レイヤー内でのノードの並び順を決定します。
    private static func orderNodes<Data: Sendable>(
        nodeLayers: [Int: [String]],
        nodeLookup: [String: BaseNode<Data>]
    ) -> [Int: [String]] {
        var sortedLayers: [Int: [String]] = [:]
        for (layer, ids) in nodeLayers {
            sortedLayers[layer] = ids.sorted() // Sort by ID for deterministic behavior | 決定的挙動のため ID ソート
        }
        return sortedLayers
    }
    
    /// Calculates final coordinates based on layers and order, taking node sizes into account. | レイヤーと順序に基づき、ノードサイズを考慮した最終座標を計算します。
    private static func assignCoordinates<Data: Sendable>(
        orderedLayers: [Int: [String]],
        nodeLookup: [String: BaseNode<Data>],
        direction: GraphLayoutDirection,
        spacing: Double
    ) -> [String: XYPosition] {
        var results: [String: XYPosition] = [:]
        
        var layerOffsets: [Int: Double] = [:]
        var currentOffset: Double = 0
        
        let sortedLayerIndices = orderedLayers.keys.sorted()
        
        for layerIdx in sortedLayerIndices {
            let ids = orderedLayers[layerIdx] ?? []
            var maxLayerBreadth: Double = 0
            
            for id in ids {
                guard let node = nodeLookup[id] else { continue }
                let size = getNodeSize(node)
                
                switch direction {
                case .topToBottom, .bottomToTop:
                    maxLayerBreadth = max(maxLayerBreadth, size.height)
                case .leftToRight, .rightToLeft:
                    maxLayerBreadth = max(maxLayerBreadth, size.width)
                }
            }
            
            layerOffsets[layerIdx] = currentOffset
            currentOffset += maxLayerBreadth + spacing
        }
        
        // 1. Calculate minimum required occupancy width (Breadth) for each layer | 1. 各レイヤーの必要最小限の占有幅（Breadth）を計算
        var layerTotalBreadths: [Int: Double] = [:]
        var maxBreadth: Double = 0
        
        for layerIdx in sortedLayerIndices {
            let ids = orderedLayers[layerIdx] ?? []
            var currentLayerBreadth: Double = 0
            for (i, id) in ids.enumerated() {
                guard let node = nodeLookup[id] else { continue }
                let size = getNodeSize(node)
                switch direction {
                case .topToBottom, .bottomToTop:
                    currentLayerBreadth += size.width
                case .leftToRight, .rightToLeft:
                    currentLayerBreadth += size.height
                }
                if i < ids.count - 1 {
                    currentLayerBreadth += spacing
                }
            }
            layerTotalBreadths[layerIdx] = currentLayerBreadth
            maxBreadth = max(maxBreadth, currentLayerBreadth)
        }
        
        // 2. Coordinate assignment | 2. 座標割り当て
        for layerIdx in sortedLayerIndices {
            let ids = orderedLayers[layerIdx] ?? []
            let longitudinalOffset = layerOffsets[layerIdx] ?? 0
            let layerBreadth = layerTotalBreadths[layerIdx] ?? 0
            
            // Starting offset for centering the whole | 全体の中央に寄せるための開始オフセット
            var lateralOffset: Double = (maxBreadth - layerBreadth) / 2.0
            
            for id in ids {
                guard let node = nodeLookup[id] else { continue }
                let size = getNodeSize(node)
                
                switch direction {
                case .topToBottom:
                    results[id] = XYPosition(x: lateralOffset, y: longitudinalOffset)
                    lateralOffset += size.width + spacing
                case .bottomToTop:
                    results[id] = XYPosition(x: lateralOffset, y: -longitudinalOffset)
                    lateralOffset += size.width + spacing
                case .leftToRight:
                    results[id] = XYPosition(x: longitudinalOffset, y: lateralOffset)
                    lateralOffset += size.height + spacing
                case .rightToLeft:
                    results[id] = XYPosition(x: -longitudinalOffset, y: lateralOffset)
                    lateralOffset += size.height + spacing
                }
            }
        }
        
        return results
    }
    
    private static func getNodeSize<Data: Sendable>(_ node: BaseNode<Data>) -> Dimensions {
        if let measured = node.measured { return measured }
        if let w = node.width, let h = node.height { return Dimensions(width: w, height: h) }
        return Dimensions(
            width: node.initialWidth ?? 0,
            height: node.initialHeight ?? 0
        )
    }
}
