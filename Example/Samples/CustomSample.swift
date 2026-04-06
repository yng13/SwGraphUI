import SwGraphUI

struct CustomSample: GraphSample {
    let title = "Custom & Measure"
    let category: ExampleAppStore.SampleCategory = .custom
    let description = "Custom node types and measurement-based layout."
    
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        graphStore.nodes = [
            BaseNode(id: "Short", position: XYPosition(x: 50, y: 50), data: "Short", kind: "custom"),
            BaseNode(id: "CPU-Node", position: XYPosition(x: 450, y: 150), data: "CPU Logic Node", kind: "custom"),
            BaseNode(id: "Default", position: XYPosition(x: 150, y: 350), data: "Standard Node")
        ]
        graphStore.edges = []
        appStore.appendLog(kind: "hint", payload: "Custom nodes have purple handles")
    }
}
