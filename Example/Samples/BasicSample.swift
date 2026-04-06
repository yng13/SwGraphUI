import SwGraphUI

struct BasicSample: GraphSample {
    let title = "Basic"
    let category: ExampleAppStore.SampleCategory = .basic
    let description = "Simple relationship between two nodes."
    
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        graphStore.nodes = [
            BaseNode(id: "A", position: XYPosition(x: 100, y: 100), data: "Node A", width: 150, height: 50),
            BaseNode(id: "B", position: XYPosition(x: 400, y: 200), data: "Node B", width: 150, height: 50)
        ]
        graphStore.edges = [
            BaseEdge(id: "eA-B", source: "A", target: "B", markerEnd: EdgeMarker(type: .arrowClosed))
        ]
    }
}
