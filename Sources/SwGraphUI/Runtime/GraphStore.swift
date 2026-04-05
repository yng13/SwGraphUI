import SwiftUI
import Observation

/// グラフの状態管理を担う中心的なクラス。
/// ノード、エッジ、ビューポート、選択状態などを一括管理し、UIへのリアクティブな更新を提供します。
@Observable
@MainActor
public final class GraphStore<Data: Sendable>: Sendable {
    // MARK: - Core State
    public var nodes: [BaseNode<Data>] = []
    public var edges: [BaseEdge<Data>] = []
    
    // MARK: - Runtime State
    public var runtimeState: GraphRuntimeState
    
    public init(
        nodes: [BaseNode<Data>] = [],
        edges: [BaseEdge<Data>] = [],
        runtimeState: GraphRuntimeState = .init()
    ) {
        self.nodes = nodes
        self.edges = edges
        self.runtimeState = runtimeState
    }
    
    // MARK: - Measurement & Positioning API
    
    /// ハンドルの実測座標を更新します。
    public func updateHandlePosition(key: HandleKey, absolutePosition: XYPosition) {
        runtimeState.handleMeasurements.positions[key] = absolutePosition
    }
    
    /// ハンドルの実測座標を取得します（存在すれば）。
    public func measuredHandlePosition(for key: HandleKey) -> XYPosition? {
        runtimeState.handleMeasurements.positions[key]
    }
    
    /// ハンドルの解決済み座標を取得します（実測値を優先し、なければ推測を使用）。
    public func resolvedHandlePosition(for key: HandleKey) -> XYPosition {
        // 1. 実測値があれば最優先
        if let measured = measuredHandlePosition(for: key) {
            return measured
        }
        
        // 2. なければ従来の数学的推測にフォールバック
        guard let node = node(id: key.nodeID) else { return .zero }
        let absPos = absolutePosition(for: key.nodeID)
        return ConnectionInteractionManager.calcHandlePosition(
            absolutePosition: absPos,
            dimensions: node.measured ?? Dimensions(width: 100, height: 50),
            placement: key.placement
        )
    }

    // MARK: - Node Operations
    public func node(id: String) -> BaseNode<Data>? {
        nodes.first { $0.id == id }
    }

    public func updateNodePosition(id: String, position: XYPosition) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            nodes[index].position = position
        }
    }

    public func updateNodeDimensions(id: String, dimensions: Dimensions) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            // 差分ガード：値が同じ場合は更新をスキップして再描画を抑制
            if nodes[index].measured != dimensions {
                nodes[index].measured = dimensions
            }
        }
    }

    public func absolutePosition(for nodeID: String) -> XYPosition {
        guard let node = node(id: nodeID) else { return .zero }
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        return NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: lookup)
    }

    // MARK: - Edge Operations
    public func edge(id: String) -> BaseEdge<Data>? {
        edges.first { $0.id == id }
    }

    public func addEdge(_ edge: BaseEdge<Data>) {
        edges.append(edge)
    }

    // MARK: - Viewport Operations
    public func setViewport(_ viewport: Viewport) {
        runtimeState.viewport.setViewport(viewport)
    }
    
    public func pan(by delta: XYPosition) {
        runtimeState.viewport.panBy(dx: delta.x, dy: delta.y)
    }

    public func fitView(
        in size: Dimensions = Dimensions(width: 800, height: 600),
        padding: GeometryAlgorithms.Padding = .all(.relative(0.1)),
        minZoom: Double = 0.5,
        maxZoom: Double = 2.0
    ) {
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        runtimeState.viewport.fitView(nodes: nodes, nodeLookup: lookup, in: size, padding: padding, minZoom: minZoom, maxZoom: maxZoom)
    }

    // MARK: - Interaction Handlers
    
    // --- Selection ---
    
    /// 指定されたノードを選択状態にします（排他選択）。
    public func selectNode(_ id: String) {
        runtimeState.selection.clear()
        runtimeState.selection.selectNode(id: id)
        
        // モデルフラグの同期
        for i in 0..<nodes.count {
            nodes[i].selected = (nodes[i].id == id)
        }
        for i in 0..<edges.count {
            edges[i].selected = false
        }
    }
    
    /// 指定されたエッジを選択状態にします（排他選択）。
    public func selectEdge(_ id: String) {
        runtimeState.selection.clear()
        runtimeState.selection.selectEdge(id: id)
        
        // モデルフラグの同期
        for i in 0..<nodes.count {
            nodes[i].selected = false
        }
        for i in 0..<edges.count {
            edges[i].selected = (edges[i].id == id)
        }
    }
    
    /// すべての選択を解除します。
    public func clearSelection() {
        runtimeState.selection.clear()
        
        // モデルフラグの同期
        for i in 0..<nodes.count {
            nodes[i].selected = false
        }
        for i in 0..<edges.count {
            edges[i].selected = false
        }
    }
    
    // --- Dragging ---
    public func startDragging(nodeIDs: [String], at pointer: XYPosition) {
        let targets = nodes.filter { nodeIDs.contains($0.id) }
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        runtimeState.drag.startDrag(nodes: targets, nodeLookup: lookup, pointer: pointer)
        
        // ストア内の実体ノードのフラグを更新
        for i in 0..<nodes.count {
            if nodeIDs.contains(nodes[i].id) {
                nodes[i].dragging = true
            }
        }
    }
    
    public func updateDragging(to pointer: XYPosition) {
        runtimeState.drag.updateDrag(to: pointer)
        
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        
        // 実際の座標更新
        for item in runtimeState.drag.draggedNodes {
            if let index = nodes.firstIndex(where: { $0.id == item.id }) {
                let absPos = pointer - item.distance
                
                // 親がいる場合は相対座標に変換、いない場合は絶対座標のまま
                if let parentID = nodes[index].parentID, let parent = lookup[parentID] {
                    nodes[index].position = NodePositioningAlgorithms.toRelativePosition(
                        absPos,
                        parent: parent,
                        nodeLookup: lookup
                    )
                } else {
                    nodes[index].position = absPos
                }
            }
        }
    }
    
    public func stopDragging() {
        runtimeState.drag.stopDrag()
        for i in 0..<nodes.count {
            nodes[i].dragging = false
        }
    }
    
    // --- Connection ---
    
    /// 指定された座標（グラフ空間）に近いハンドルを検索します。
    public func findHandle(near pointer: XYPosition, threshold: Double = ConnectionInteractionManager.snapDistance) -> HandleKey? {
        let viewport = runtimeState.viewport.viewport
        let fromNodeID = runtimeState.connection.active?.fromNodeID
        
        var candidates: [ConnectionInteractionManager.HandleCandidate] = []
        
        for node in nodes {
            // ノードが持つハンドルを特定
            let handleTargets: [(id: String?, type: HandleType, placement: Position, connectable: Bool)]
            if !node.handles.isEmpty {
                handleTargets = node.handles.map { ($0.id, $0.type, $0.placement, $0.isConnectable) }
            } else {
                handleTargets = [
                    (nil, .source, node.sourcePosition ?? .right, true),
                    (nil, .target, node.targetPosition ?? .left, true)
                ]
            }
            
            for target in handleTargets {
                let key = HandleKey(nodeID: node.id, handleID: target.id, type: target.type, placement: target.placement)
                let pos = resolvedHandlePosition(for: key)
                
                candidates.append(.init(
                    key: key,
                    position: pos,
                    isHidden: node.hidden,
                    isConnectable: node.connectable && target.connectable
                ))
            }
        }
        
        return ConnectionInteractionManager.findNearestHandle(
            near: pointer,
            candidates: candidates,
            viewport: viewport,
            threshold: threshold,
            fromNodeID: fromNodeID
        )
    }
    
    public func startConnecting(
        fromNodeID: String,
        fromHandleID: String?,
        fromHandleType: HandleType,
        fromHandlePosition: Position,
        fromPosition: XYPosition,
        at pointer: XYPosition
    ) {
        runtimeState.connection.start(
            fromNodeID: fromNodeID,
            fromHandleID: fromHandleID,
            fromHandleType: fromHandleType,
            fromHandlePosition: fromHandlePosition,
            fromPosition: fromPosition,
            at: pointer
        )
    }
    
    public func updateConnecting(
        to pointer: XYPosition,
        targetNodeID: String? = nil,
        targetHandleID: String? = nil,
        targetHandlePosition: Position? = nil
    ) {
        runtimeState.connection.update(
            to: pointer,
            targetNodeID: targetNodeID,
            targetHandleID: targetHandleID,
            targetHandlePosition: targetHandlePosition
        )
    }
    
    public func stopConnecting() -> Connection? {
        guard let active = runtimeState.connection.active else { return nil }
        var result: Connection? = nil
        
        if let targetNodeID = active.targetNodeID,
           let targetHandlePosition = active.targetHandlePosition {
            result = Connection(
                source: active.fromNodeID,
                target: targetNodeID,
                sourceHandle: active.fromHandleID,
                targetHandle: active.targetHandleID,
                sourcePosition: active.fromHandlePosition,
                targetPosition: targetHandlePosition
            )
        }
        
        runtimeState.connection.end()
        return result
    }

    // --- Hover ---
    public func setHoveredNode(_ id: String?) {
        runtimeState.hover.hoveredNodeID = id
    }
}
