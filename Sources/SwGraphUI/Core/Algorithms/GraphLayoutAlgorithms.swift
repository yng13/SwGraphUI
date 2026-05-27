import Foundation
import CoreGraphics

/// Defines the direction of automatic layout (named GraphLayoutDirection to avoid conflict with SwiftUI.LayoutDirection). | 自動レイアウトの方向を定義します（SwiftUI.LayoutDirection との衝突を避けるため GraphLayoutDirection と命名）。
public enum GraphLayoutDirection: Sendable, Codable {
    case topToBottom
    case bottomToTop
    case leftToRight
    case rightToLeft
}

/// Options for ranked layout breadth control and optional component packing.
public struct RankedLayoutOptions: Sendable, Codable, Equatable {
    public var direction: GraphLayoutDirection
    public var spacing: Double
    public var maxRankBreadth: Double?
    public var wrappedLaneSpacing: Double
    public var componentGap: Double
    public var packComponents: Bool

    public init(
        direction: GraphLayoutDirection = .topToBottom,
        spacing: Double = 50.0,
        maxRankBreadth: Double? = nil,
        wrappedLaneSpacing: Double = 80.0,
        componentGap: Double = 160.0,
        packComponents: Bool = false
    ) {
        self.direction = direction
        self.spacing = spacing
        self.maxRankBreadth = maxRankBreadth
        self.wrappedLaneSpacing = wrappedLaneSpacing
        self.componentGap = componentGap
        self.packComponents = packComponents
    }
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
        let nodeLayers = assignLayers(nodes: nodes, edges: edges)
        let orderedLayers = orderNodes(nodeLayers: nodeLayers, nodeLookup: nodeLookup)

        return assignCoordinates(
            orderedLayers: orderedLayers,
            nodeLookup: nodeLookup,
            direction: direction,
            spacing: spacing
        )
    }

    /// Performs ranked layout using externally supplied rank and order maps.
    /// The caller is responsible for semantic layer assignment; this algorithm only assigns coordinates.
    public static func layoutRanked<Data: Sendable>(
        nodes: [BaseNode<Data>],
        ranks: [String: Int],
        order: [String: Int] = [:],
        direction: GraphLayoutDirection = .topToBottom,
        spacing: Double = 50.0
    ) -> [String: XYPosition] {
        layoutRanked(
            nodes: nodes,
            ranks: ranks,
            order: order,
            options: RankedLayoutOptions(direction: direction, spacing: spacing)
        )
    }

    /// Performs ranked layout using externally supplied rank and order maps with breadth-cap options.
    public static func layoutRanked<Data: Sendable>(
        nodes: [BaseNode<Data>],
        ranks: [String: Int],
        order: [String: Int] = [:],
        options: RankedLayoutOptions
    ) -> [String: XYPosition] {
        guard !nodes.isEmpty else { return [:] }

        let nodeLookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        let rankedLayers = assignExplicitLayers(nodes: nodes, ranks: ranks)
        let orderedLayers = orderNodes(
            nodeLayers: rankedLayers,
            nodeLookup: nodeLookup,
            explicitOrder: order
        )

        let basePositions: [String: XYPosition]
        if let maxRankBreadth = options.maxRankBreadth {
            basePositions = assignCoordinatesWrapped(
                orderedLayers: orderedLayers,
                nodeLookup: nodeLookup,
                direction: options.direction,
                spacing: options.spacing,
                maxRankBreadth: maxRankBreadth,
                wrappedLaneSpacing: options.wrappedLaneSpacing
            )
        } else {
            basePositions = assignCoordinates(
                orderedLayers: orderedLayers,
                nodeLookup: nodeLookup,
                direction: options.direction,
                spacing: options.spacing
            )
        }

        guard options.packComponents else {
            return basePositions
        }

        let defaultComponents = defaultComponentMap(for: nodes.map(\.id))
        return packComponents(
            positions: basePositions,
            nodes: nodes,
            component: defaultComponents,
            direction: options.direction,
            gap: options.componentGap
        )
    }

    /// Packs already-laid-out components while preserving their internal relative positions.
    public static func packComponents<Data: Sendable>(
        positions: [String: XYPosition],
        nodes: [BaseNode<Data>],
        component: [String: Int],
        direction: GraphLayoutDirection,
        gap: Double
    ) -> [String: XYPosition] {
        guard !positions.isEmpty else { return [:] }

        let nodeLookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        let grouped = groupPositionsByComponent(positions: positions, component: component)
        guard grouped.count > 1 else { return positions }

        let normalized: [(id: Int, positions: [String: XYPosition], width: Double, height: Double)] = grouped.map { entry in
            let bounds = boundsForPositions(entry.positions, nodeLookup: nodeLookup)
            let shifted = entry.positions.mapValues { position in
                XYPosition(x: position.x - bounds.minX, y: position.y - bounds.minY)
            }
            return (entry.id, shifted, bounds.width, bounds.height)
        }.sorted { $0.id < $1.id }

        var packed: [String: XYPosition] = [:]
        switch direction {
        case .topToBottom:
            var cursorX: Double = 0
            for component in normalized {
                for (id, position) in component.positions {
                    packed[id] = XYPosition(x: position.x + cursorX, y: position.y)
                }
                cursorX += component.width + gap
            }

        case .bottomToTop:
            var cursorX: Double = 0
            for component in normalized {
                for (id, position) in component.positions {
                    packed[id] = XYPosition(x: position.x + cursorX, y: position.y)
                }
                cursorX += component.width + gap
            }

        case .leftToRight:
            var cursorY: Double = 0
            for component in normalized {
                for (id, position) in component.positions {
                    packed[id] = XYPosition(x: position.x, y: position.y + cursorY)
                }
                cursorY += component.height + gap
            }

        case .rightToLeft:
            var cursorY: Double = 0
            for component in normalized {
                for (id, position) in component.positions {
                    packed[id] = XYPosition(x: position.x, y: position.y + cursorY)
                }
                cursorY += component.height + gap
            }
        }

        return packed
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

        for edge in edges where edge.sourceEndpoint.nodeID != nil && edge.targetEndpoint.nodeID != nil {
            nodeInDegrees[edge.target, default: 0] += 1
        }

        var queue: [(id: String, layer: Int)] = nodes
            .filter { (nodeInDegrees[$0.id] ?? 0) == 0 }
            .map { ($0.id, 0) }

        var outEdgesMap: [String: [String]] = [:]
        for edge in edges where edge.sourceEndpoint.nodeID != nil && edge.targetEndpoint.nodeID != nil {
            outEdgesMap[edge.source, default: []].append(edge.target)
        }

        var visited = Set<String>()
        var nodeToLayer: [String: Int] = [:]

        while !queue.isEmpty {
            let (id, layer) = queue.removeFirst()
            if visited.contains(id) { continue }
            visited.insert(id)

            nodeToLayer[id] = max(nodeToLayer[id, default: 0], layer)

            if let targets = outEdgesMap[id] {
                for target in targets {
                    queue.append((target, layer + 1))
                }
            }
        }

        for (id, layer) in nodeToLayer {
            layers[layer, default: []].append(id)
        }

        let maxVisitedLayer = nodeToLayer.values.max() ?? 0
        let remaining = nodes.map(\.id).filter { !visited.contains($0) }.sorted()
        for (index, id) in remaining.enumerated() {
            layers[maxVisitedLayer + 1 + index, default: []].append(id)
        }

        return layers
    }

    private static func assignExplicitLayers<Data: Sendable>(
        nodes: [BaseNode<Data>],
        ranks: [String: Int]
    ) -> [Int: [String]] {
        var layers: [Int: [String]] = [:]
        let sortedIDs = nodes.map(\.id).sorted()
        let fallbackBase = (ranks.values.max() ?? -1) + 1

        for (index, id) in sortedIDs.enumerated() {
            let layer = ranks[id] ?? (fallbackBase + index)
            layers[layer, default: []].append(id)
        }

        return layers
    }

    /// Determines the order of nodes within the same layer. | 同一レイヤー内でのノードの並び順を決定します。
    private static func orderNodes<Data: Sendable>(
        nodeLayers: [Int: [String]],
        nodeLookup: [String: BaseNode<Data>],
        explicitOrder: [String: Int] = [:]
    ) -> [Int: [String]] {
        var sortedLayers: [Int: [String]] = [:]
        for (layer, ids) in nodeLayers {
            sortedLayers[layer] = ids.sorted {
                let leftOrder = explicitOrder[$0] ?? .max
                let rightOrder = explicitOrder[$1] ?? .max
                if leftOrder != rightOrder {
                    return leftOrder < rightOrder
                }
                return $0 < $1
            }
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

        for layerIdx in sortedLayerIndices {
            let ids = orderedLayers[layerIdx] ?? []
            let longitudinalOffset = layerOffsets[layerIdx] ?? 0
            let layerBreadth = layerTotalBreadths[layerIdx] ?? 0
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

    private static func assignCoordinatesWrapped<Data: Sendable>(
        orderedLayers: [Int: [String]],
        nodeLookup: [String: BaseNode<Data>],
        direction: GraphLayoutDirection,
        spacing: Double,
        maxRankBreadth: Double,
        wrappedLaneSpacing: Double
    ) -> [String: XYPosition] {
        let sortedLayerIndices = orderedLayers.keys.sorted()
        let ranks: [(layer: Int, lanes: [WrappedLane], totalBreadth: Double, totalDepth: Double)] = sortedLayerIndices.map { layer in
            let lanes = buildWrappedLanes(
                ids: orderedLayers[layer] ?? [],
                nodeLookup: nodeLookup,
                direction: direction,
                spacing: spacing,
                maxRankBreadth: maxRankBreadth
            )
            let totalBreadth = lanes.map(\.breadth).max() ?? 0
            let totalDepth = lanes.enumerated().reduce(0.0) { partial, entry in
                partial + entry.element.depth + (entry.offset < lanes.count - 1 ? wrappedLaneSpacing : 0)
            }
            return (layer, lanes, totalBreadth, totalDepth)
        }

        let maxBreadth = ranks.map(\.totalBreadth).max() ?? 0
        var longitudinalOffset: Double = 0
        var results: [String: XYPosition] = [:]

        for rank in ranks {
            var laneOffset: Double = 0
            for lane in rank.lanes {
                let laneBreadthOffset = (maxBreadth - lane.breadth) / 2.0
                var breadthCursor = laneBreadthOffset

                for id in lane.ids {
                    guard let node = nodeLookup[id] else { continue }
                    let size = getNodeSize(node)

                    switch direction {
                    case .topToBottom:
                        results[id] = XYPosition(x: breadthCursor, y: longitudinalOffset + laneOffset)
                        breadthCursor += size.width + spacing
                    case .bottomToTop:
                        results[id] = XYPosition(x: breadthCursor, y: -(longitudinalOffset + laneOffset))
                        breadthCursor += size.width + spacing
                    case .leftToRight:
                        results[id] = XYPosition(x: longitudinalOffset + laneOffset, y: breadthCursor)
                        breadthCursor += size.height + spacing
                    case .rightToLeft:
                        results[id] = XYPosition(x: -(longitudinalOffset + laneOffset), y: breadthCursor)
                        breadthCursor += size.height + spacing
                    }
                }

                laneOffset += lane.depth + wrappedLaneSpacing
            }

            longitudinalOffset += rank.totalDepth + spacing
        }

        return results
    }

    private struct WrappedLane {
        let ids: [String]
        let breadth: Double
        let depth: Double
    }

    private static func buildWrappedLanes<Data: Sendable>(
        ids: [String],
        nodeLookup: [String: BaseNode<Data>],
        direction: GraphLayoutDirection,
        spacing: Double,
        maxRankBreadth: Double
    ) -> [WrappedLane] {
        guard !ids.isEmpty else { return [] }

        var lanes: [WrappedLane] = []
        var currentIDs: [String] = []
        var currentBreadth: Double = 0
        var currentDepth: Double = 0

        func finishLane() {
            guard !currentIDs.isEmpty else { return }
            lanes.append(WrappedLane(ids: currentIDs, breadth: currentBreadth, depth: currentDepth))
            currentIDs = []
            currentBreadth = 0
            currentDepth = 0
        }

        for id in ids {
            guard let node = nodeLookup[id] else { continue }
            let size = getNodeSize(node)
            let breadth = isVertical(direction) ? size.width : size.height
            let depth = isVertical(direction) ? size.height : size.width
            let proposedBreadth = currentIDs.isEmpty ? breadth : currentBreadth + spacing + breadth

            if !currentIDs.isEmpty, proposedBreadth > maxRankBreadth {
                finishLane()
            }

            if currentIDs.isEmpty {
                currentIDs = [id]
                currentBreadth = breadth
                currentDepth = depth
            } else {
                currentIDs.append(id)
                currentBreadth += spacing + breadth
                currentDepth = max(currentDepth, depth)
            }
        }

        finishLane()
        return lanes
    }

    private static func groupPositionsByComponent(
        positions: [String: XYPosition],
        component: [String: Int]
    ) -> [(id: Int, positions: [String: XYPosition])] {
        let sortedIDs = positions.keys.sorted()
        let fallbackBase = (component.values.max() ?? -1) + 1
        var grouped: [Int: [String: XYPosition]] = [:]

        for (index, id) in sortedIDs.enumerated() {
            let componentID = component[id] ?? (fallbackBase + index)
            grouped[componentID, default: [:]][id] = positions[id]
        }

        return grouped.keys.sorted().map { ($0, grouped[$0] ?? [:]) }
    }

    private static func defaultComponentMap(for ids: [String]) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: ids.sorted().enumerated().map { index, id in
            (id, index)
        })
    }

    private static func isVertical(_ direction: GraphLayoutDirection) -> Bool {
        switch direction {
        case .topToBottom, .bottomToTop:
            return true
        case .leftToRight, .rightToLeft:
            return false
        }
    }

    private static func boundsForPositions<Data: Sendable>(
        _ positions: [String: XYPosition],
        nodeLookup: [String: BaseNode<Data>]
    ) -> (minX: Double, minY: Double, width: Double, height: Double) {
        var minX = Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude

        for (id, position) in positions {
            guard let node = nodeLookup[id] else { continue }
            let size = getNodeSize(node)
            minX = min(minX, position.x)
            minY = min(minY, position.y)
            maxX = max(maxX, position.x + size.width)
            maxY = max(maxY, position.y + size.height)
        }

        if !minX.isFinite || !minY.isFinite || !maxX.isFinite || !maxY.isFinite {
            return (0, 0, 0, 0)
        }

        return (minX, minY, maxX - minX, maxY - minY)
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
