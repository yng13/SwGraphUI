import Foundation
import Observation

/// SwGraphUI の状態を統合管理する Observable オブジェクト。
/// stateless な Core ロジックと SwiftUI レイヤーを接続する唯一の正式入口です。
@Observable @MainActor
public final class GraphStore<Data: Sendable> {
    /// グラフを構成するノードの配列
    public var nodes: [BaseNode<Data>]
    /// グラフを構成するエッジの配列
    public var edges: [BaseEdge<Data>]
    /// 選択・ドラッグ・ビューポートなどのランタイム状態
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
    
    /// ノードの高速検索用マップ。派生値として計算。
    public var nodeLookup: [String: BaseNode<Data>] {
        Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
    }
    
    /// 指定されたノードの絶対座標を解決して返します。
    public func absolutePosition(for id: String) -> XYPosition {
        guard let node = nodeLookup[id] else { return .zero }
        return NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: nodeLookup)
    }

    // MARK: - Dragging Actions
    
    /// 指定されたノードのドラッグ操作を開始します。
    /// - Parameters:
    ///   - nodeIDs: ドラッグ対象のノードID（配列）。
    ///   - pointer: ドラッグ開始時点のポインタ座標 (Graph Absolute Space)。
    public func startDragging(nodeIDs: [String], at pointer: XYPosition) {
        let targets = nodes.filter { nodeIDs.contains($0.id) }
        runtimeState.drag.startDrag(nodes: targets, nodeLookup: nodeLookup, pointer: pointer)
        
        // 各ノードの dragging フラグを更新
        for i in 0..<nodes.count {
            if nodeIDs.contains(nodes[i].id) {
                nodes[i].dragging = true
            }
        }
    }
    
    /// ドラッグ中の座標を更新し、ノードの座標に反映します。
    /// - Parameter pointer: 現在のポインタ座標 (Graph Absolute Space)。
    public func updateDragging(to pointer: XYPosition) {
        runtimeState.drag.updateDrag(to: pointer)
        let nextPositions = DragManager.calculateNextPositions(
            draggedNodes: runtimeState.drag.draggedNodes,
            pointer: pointer,
            nodeLookup: nodeLookup
        )
        
        // position の更新（dragging フラグは維持）
        for (id, pos) in nextPositions {
            if let index = nodes.firstIndex(where: { $0.id == id }) {
                nodes[index].position = pos
            }
        }
    }
    
    /// ドラッグ操作を終了します。
    public func stopDragging() {
        let draggedIDs = runtimeState.drag.draggedNodes.map { $0.id }
        runtimeState.drag.stopDrag()
        
        // dragging フラグを解除
        for i in 0..<nodes.count {
            if draggedIDs.contains(nodes[i].id) {
                nodes[i].dragging = false
            }
        }
    }
    
    // MARK: - Viewport Actions
    
    /// ビューポートを平行移動させます。
    /// - Parameter delta: 移動量 (Points)。
    public func pan(by delta: XYPosition) {
        runtimeState.viewport.panBy(dx: delta.x, dy: delta.y)
    }
    
    /// 全ノードが画面に収まるようにビューポートを調整します。
    /// - Parameters:
    ///   - size: ビューポートの表示サイズ (Points)。
    ///   - padding: 余白設定。
    public func fitView(in size: Dimensions, padding: GeometryAlgorithms.Padding = .all(.relative(0.1))) {
        // 常に階層対応版の API を使用
        runtimeState.viewport.fitView(
            nodes: nodes,
            nodeLookup: nodeLookup,
            in: size,
            padding: padding
        )
    }
}
