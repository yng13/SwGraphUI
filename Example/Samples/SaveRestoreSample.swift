import SwiftUI
import SwGraphUI

struct SaveRestoreSample: GraphSample {
    let title = "Save & Restore"
    let category: ExampleAppStore.SampleCategory = .snapshots
    let description = "Demonstrates graph snapshot persistence using JSON (Codable)."

    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        let n1 = BaseNode<String>(
            id: "parent",
            position: XYPosition(x: 0, y: 0),
            data: "Parent Node",
            width: 300,
            height: 200
        )
        
        let n2 = BaseNode<String>(
            id: "child-1",
            position: XYPosition(x: 20, y: 50),
            data: "Child A",
            parentID: "parent",
            width: 100,
            height: 40
        )
        
        let n3 = BaseNode<String>(
            id: "child-2",
            position: XYPosition(x: 150, y: 120),
            data: "Child B",
            parentID: "parent",
            width: 100,
            height: 40
        )
        
        let n4 = BaseNode<String>(
            id: "standalone",
            position: XYPosition(x: 400, y: 100),
            data: "Standalone",
            width: 150,
            height: 80
        )

        let e1 = BaseEdge<String>(
            id: "e1",
            source: "child-1",
            target: "child-2",
            animated: true,
            label: "Internal"
        )
        
        let e2 = BaseEdge<String>(
            id: "e2",
            source: "child-2",
            target: "standalone",
            markerEnd: EdgeMarker(type: .arrowClosed, color: "#4A90E2"),
            label: "Cross-Hierarchy",
            labelStyle: EdgeLabelStyle(textColor: "#4A90E2")
        )

        graphStore.nodes = [n1, n2, n3, n4]
        graphStore.edges = [e1, e2]
        
        appStore.appendLog(kind: "sample", payload: "Snapshots: Try 'Take Snapshot' in the right inspector, move nodes, then 'Restore'.")
    }
}
