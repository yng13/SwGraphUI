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
            nodes[index].measured = dimensions
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
    public func selectNode(_ id: String) {
        runtimeState.selection.selectNode(id: id)
    }
    
    public func clearSelection() {
        runtimeState.selection.clear()
    }
    
    // --- Dragging ---
    public func startDragging(nodeIDs: [String], at pointer: XYPosition) {
        let targets = nodes.filter { nodeIDs.contains($0.id) }
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        runtimeState.drag.startDrag(nodes: targets, nodeLookup: lookup, pointer: pointer)
    }
    
    public func updateDragging(to pointer: XYPosition) {
        runtimeState.drag.updateDrag(to: pointer)
        
        // 実際の座標更新
        for item in runtimeState.drag.draggedNodes {
            if let index = nodes.firstIndex(where: { $0.id == item.id }) {
                let newPos = pointer - item.distance
                // 親がいない場合はそのまま、親がいる場合は相対座標に変換
                if let _ = nodes[index].parentID {
                    // 親座標を解決して相対位置を求める
                    nodes[index].position = newPos
                } else {
                    nodes[index].position = newPos
                }
            }
        }
    }
    
    public func stopDragging() {
        runtimeState.drag.stopDrag()
    }
    
    // --- Connection ---
    
    /// 指定された座標（グラフ空間）に近いハンドルを検索します。
    public func findHandle(near pointer: XYPosition, threshold: Double = 20.0) -> HandleKey? {
        var closest: (key: HandleKey, dist: Double)? = nil
        
        for (key, pos) in runtimeState.handleMeasurements.positions {
            let dist = pointer.distance(to: pos)
            if dist < threshold {
                if closest == nil || dist < closest!.dist {
                    closest = (key, dist)
                }
            }
        }
        
        return closest?.key
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
