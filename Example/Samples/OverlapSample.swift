import SwGraphUI

struct OverlapSample: GraphSample {
    let title = "Overlap Test"
    let category: ExampleAppStore.SampleCategory = .overlap
    let description = "Overlapping nodes testing Z-Index and selection order."
    
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        graphStore.nodes = (1...5).map { i in
            BaseNode(id: "Node\(i)", position: XYPosition(x: Double(i * 40), y: Double(i * 40)), data: "Overlapping \(i)", width: 150, height: 50)
        }
        graphStore.edges = []
    }
}
