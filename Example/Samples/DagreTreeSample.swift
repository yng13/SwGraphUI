import SwiftUI
import SwGraphUI

/// A sample demonstrating automatic layout (hierarchical/tree). | 自動レイアウト（階層型/Tree）のデモンストレーションを行うサンプル。
/// Nodes with complex connectivity can be arranged with a single button. | 複雑な接続関係を持つノード群を、ボタン一つで整列させることができます。
public struct DagreTreeSample: GraphSample {
    public let title = "Dagre Tree Layout"
    public let category: ExampleAppStore.SampleCategory = .layout
    public let description = "Demo of hierarchical layout algorithm. Automatically arranges complex connections. | 階層型レイアウトアルゴリズムのデモ。複雑な接続を自動で整列します。"
    
    public init() {}
    
    @MainActor
    public func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        // Generate initial nodes (placed randomly) | 初期ノードを生成 (バラバラに配置)
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "1", position: .init(x: 10, y: 10), data: "Root", width: 100, height: 40),
            BaseNode(id: "2", position: .init(x: 150, y: 10), data: "Child A", width: 100, height: 40),
            BaseNode(id: "3", position: .init(x: 10, y: 100), data: "Child B", width: 100, height: 40),
            BaseNode(id: "4", position: .init(x: 150, y: 100), data: "Grandchild A1", width: 100, height: 40),
            BaseNode(id: "5", position: .init(x: 300, y: 100), data: "Grandchild A2", width: 100, height: 40),
            BaseNode(id: "6", position: .init(x: 10, y: 200), data: "Grandchild B1", width: 100, height: 40),
            BaseNode(id: "7", position: .init(x: 150, y: 200), data: "Grandchild B2", width: 100, height: 40)
        ]
        
        let edges: [BaseEdge<String>] = [
            BaseEdge(id: "e1-2", source: "1", target: "2", markerEnd: EdgeMarker(type: .arrowClosed)),
            BaseEdge(id: "e1-3", source: "1", target: "3", markerEnd: EdgeMarker(type: .arrowClosed)),
            BaseEdge(id: "e2-4", source: "2", target: "4", markerEnd: EdgeMarker(type: .arrowClosed)),
            BaseEdge(id: "e2-5", source: "2", target: "5", markerEnd: EdgeMarker(type: .arrowClosed)),
            BaseEdge(id: "e3-6", source: "3", target: "6", markerEnd: EdgeMarker(type: .arrowClosed)),
            BaseEdge(id: "e3-7", source: "3", target: "7", markerEnd: EdgeMarker(type: .arrowClosed)),
        ]
        
        graphStore.nodes = nodes
        graphStore.edges = edges
        
        appStore.appendLog(kind: "sample", payload: "Layout: Use 'TB' or 'LR' buttons in the Inspector to arrange nodes.")
    }
}
