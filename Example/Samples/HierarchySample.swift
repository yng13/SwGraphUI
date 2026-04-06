import SwGraphUI

struct HierarchySample: GraphSample {
    let title = "Hierarchy"
    let category: ExampleAppStore.SampleCategory = .hierarchy
    let description = "Parent-child node grouping and nested coordinate systems."
    
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        let p = BaseNode(id: "parent", position: XYPosition(x: 50, y: 50), data: "Parent", width: 400, height: 350)
        let c = BaseNode(id: "child", position: XYPosition(x: 50, y: 50), data: "Child", parentID: "parent", width: 300, height: 250)
        let g = BaseNode(id: "grandchild", position: XYPosition(x: 50, y: 50), data: "Grandchild", parentID: "child", width: 150, height: 50)
        
        graphStore.nodes = [p, c, g]
        graphStore.edges = []
        appStore.appendLog(kind: "hint", payload: "Try connecting Parent -> Child in hierarchy")
    }
}
