import Foundation

/// グラフの特定の時点の状態を表すスナップショット。
/// ノード、エッジ、およびビューポートの最小限のデータを保持します。
public struct GraphSnapshot<NodeData: Sendable> {
    /// グラフ内の全ノード
    public let nodes: [BaseNode<NodeData>]
    /// グラフ内の全エッジ
    public let edges: [BaseEdge<NodeData>]
    /// 現在のビューポート設定（位置とズーム）
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
