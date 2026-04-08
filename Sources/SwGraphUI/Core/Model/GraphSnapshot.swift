import Foundation

/// グラフの特定の時点の状態を表すスナップショット。
/// ノード、エッジ、およびビューポートの最小限の永続化可能データを保持します。
public struct GraphSnapshot<Data: Sendable & Codable>: Codable {
    /// グラフ内の全ノード
    public let nodes: [BaseNode<Data>]
    /// グラフ内の全エッジ
    public let edges: [BaseEdge<Data>]
    /// 現在のビューポート設定（位置とズーム）
    public let viewport: Viewport

    public init(
        nodes: [BaseNode<Data>],
        edges: [BaseEdge<Data>],
        viewport: Viewport
    ) {
        self.nodes = nodes
        self.edges = edges
        self.viewport = viewport
    }
}
