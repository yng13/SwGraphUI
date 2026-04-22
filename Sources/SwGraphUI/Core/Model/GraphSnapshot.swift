import Foundation

/// A snapshot representing the state of the graph at a specific point in time. | グラフの特定の時点の状態を表すスナップショット。
/// Holds minimum data for nodes, edges, and the viewport. | ノード、エッジ、およびビューポートの最小限のデータを保持します。
public struct GraphSnapshot<NodeData: Sendable> {
    /// All nodes in the graph | グラフ内の全ノード
    public let nodes: [BaseNode<NodeData>]
    /// All edges in the graph | グラフ内の全エッジ
    public let edges: [BaseEdge<NodeData>]
    /// Current viewport settings (position and zoom) | 現在のビューポート設定（位置とズーム）
    public let viewport: Viewport

    public init(
        nodes: [BaseNode<NodeData>],
        edges: [BaseEdge<NodeData>],
        viewport: Viewport
    ) {
        self.nodes = nodes
        self.edges = edges
        self.viewport = viewport
    }
}

extension GraphSnapshot: Codable where NodeData: Codable {}
extension GraphSnapshot: Equatable where NodeData: Equatable {}
