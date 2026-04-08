import SwiftUI
import SwGraphUI

struct SubflowSample: GraphSample {
    let title = "Subflows & Nesting"
    let category: ExampleAppStore.SampleCategory = .subflow
    let description = "Demonstrates nested nodes and hierarchical rendering order."
    
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        // グループ親ノード
        let parent = BaseNode(
            id: "parent-group",
            position: XYPosition(x: 50, y: 50),
            data: "Group Node (Parent)",
            kind: "group",
            zIndex: -1, // 明示的に背面に
            width: 400,
            height: 300
        )
        
        // 子ノード 1
        let child1 = BaseNode(
            id: "child-1",
            position: XYPosition(x: 20, y: 40),
            data: "Child 1",
            parentID: "parent-group",
            width: 150,
            height: 60
        )
        
        // 子ノード 2
        let child2 = BaseNode(
            id: "child-2",
            position: XYPosition(x: 100, y: 150),
            data: "Child 2",
            parentID: "parent-group",
            width: 150,
            height: 60
        )
        
        // 親なしのノード（重なり確認用）
        let regular = BaseNode(
            id: "regular-node",
            position: XYPosition(x: 400, y: 200),
            data: "Regular Node",
            width: 150,
            height: 60
        )
        
        graphStore.nodes = [parent, child1, child2, regular]
        
        // エッジ
        graphStore.edges = [
            BaseEdge(id: "e1-2", source: "child-1", target: "child-2", markerEnd: EdgeMarker(type: .arrowClosed)),
            BaseEdge(id: "e-p-r", source: "child-2", target: "regular-node", markerEnd: EdgeMarker(type: .arrowClosed))
        ]
        
        appStore.appendLog(kind: "hint", payload: "Drag parent to move children together. Children should stay on top.")
    }
}
