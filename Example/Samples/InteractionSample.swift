import SwGraphUI
import Foundation

struct InteractionSample: GraphSample {
    let title = "Interaction Playground"
    let category: ExampleAppStore.SampleCategory = .interaction
    let description = "Test multi-select, marquee selection, hierarchy drag, and overlapping nodes."
    
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        // Hierarchy
        let group = BaseNode(id: "g1", position: XYPosition(x: 50, y: 50), data: "Hierarchy Group", width: 300, height: 250)
        let c1 = BaseNode(id: "c1", position: XYPosition(x: 50, y: 50), data: "Child 1", parentID: "g1")
        let c2 = BaseNode(id: "c2", position: XYPosition(x: 50, y: 150), data: "Child 2", parentID: "g1")
        
        // Overlap
        let o1 = BaseNode(id: "o1", position: XYPosition(x: 400, y: 50), data: "Overlap 1 (Bottom)")
        let o2 = BaseNode(id: "o2", position: XYPosition(x: 430, y: 80), data: "Overlap 2")
        let o3 = BaseNode(id: "o3", position: XYPosition(x: 460, y: 110), data: "Overlap 3 (Top)")
        
        // Floating
        let f1 = BaseNode(id: "f1", position: XYPosition(x: 400, y: 250), data: "Floating Target")
        
        graphStore.nodes = [group, c1, c2, o1, o2, o3, f1]
        
        let e1 = BaseEdge<String>(id: "e-c1-c2", source: "c1", target: "c2", markerEnd: EdgeMarker(type: .arrowClosed), label: "Reconnect Me", reconnectable: .both)
        let e2 = BaseEdge<String>(id: "e-o1-o3", source: "o1", target: "o3", markerEnd: EdgeMarker(type: .arrowClosed), label: "Overlap Edge", reconnectable: .both)
        
        graphStore.edges = [e1, e2]
        
        appStore.appendLog(kind: "sample", payload: "Interaction: Test Multi-select, Marquee (Shift+Drag), Hierarchy Drag, and Overlap")
        appStore.appendLog(kind: "hint", payload: "Try Shift+Drag for Marquee Selection or Cmd+Wheel to Zoom")
    }
}
