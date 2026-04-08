import SwGraphUI

struct OverviewSample: GraphSample {
    let title = "Feature Overview"
    let category: ExampleAppStore.SampleCategory = .overview
    let description = "Comprehensive gallery of library features: Reconnect, Labels, Markers, and Groups."
    
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        let g1 = BaseNode(id: "g1", position: XYPosition(x: 450, y: 150), data: "Group Node", width: 250, height: 200)
        let c1 = BaseNode(id: "c1", position: XYPosition(x: 50, y: 50), data: "Inside Group", parentID: "g1")
        
        graphStore.nodes = [
            BaseNode(id: "welcome", position: XYPosition(x: 250, y: 0), data: "Overview: Feature Gallery"),
            BaseNode(id: "n-source", position: XYPosition(x: 50, y: 120), data: "Common Source"),
            BaseNode(id: "n-styled", position: XYPosition(x: 250, y: 120), data: "Styled Nodes (Locked)", draggable: false),
            
            BaseNode(id: "n-target1", position: XYPosition(x: 50, y: 350), data: "Bezier (Default)"),
            BaseNode(id: "n-target2", position: XYPosition(x: 250, y: 350), data: "Straight Path"),
            g1, c1
        ]
        
        graphStore.edges = [
            // Bezier
            BaseEdge<String>(id: "e-bez", source: "n-source", target: "n-target1", markerEnd: EdgeMarker(type: .arrowClosed), label: "Bezier & Label", reconnectable: .both),
            // Straight
            BaseEdge<String>(id: "e-str", source: "n-source", target: "n-target2", kind: "straight", markerEnd: EdgeMarker(type: .arrowClosed), label: "Straight Line", reconnectable: .both),
            // SmoothStep to Group Child
            BaseEdge<String>(id: "e-smooth", source: "n-styled", target: "c1", kind: "smoothstep", markerEnd: EdgeMarker(type: .arrowClosed), label: "Smooth Step", reconnectable: .both),
            // Animated Bezier with Start/End Markers
            BaseEdge<String>(id: "e-anim", source: "welcome", target: "n-styled", animated: true, markerStart: EdgeMarker(type: .arrow), markerEnd: EdgeMarker(type: .arrowClosed), label: "Animated Markers", reconnectable: .both)
        ]
        
        // ズーム制限の緩和
        graphStore.runtimeState.interactivity.minZoom = 0.1
        graphStore.runtimeState.interactivity.maxZoom = 4.0
        
        appStore.appendLog(kind: "sample", payload: "Overview: [Reconnect/Label/Marker/Group] showcase")
        appStore.appendLog(kind: "hint", payload: "Try dragging edge ends to RECONNECT, or select nodes to move them.")
    }
}
