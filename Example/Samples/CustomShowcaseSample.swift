import SwGraphUI
import Foundation

struct CustomShowcaseSample: GraphSample {
    let title = "Custom Showcase"
    let category: ExampleAppStore.SampleCategory = .customShowcase
    let description = "ToolbarNode, ColorNode, and CustomEdgeBody showcase."
    
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        graphStore.nodes = [
            BaseNode(id: "toolbar-node", position: XYPosition(x: 50, y: 150), data: "Select for Toolbar", kind: "toolbar"),
            BaseNode(id: "red-node", position: XYPosition(x: 350, y: 50), data: "Red", kind: "color"),
            BaseNode(id: "blue-node", position: XYPosition(x: 350, y: 250), data: "Blue", kind: "color"),
            BaseNode(id: "custom-v1", position: XYPosition(x: 50, y: 350), data: "Complex CPU Node", kind: "custom"),
            BaseNode(id: "styled-node", position: XYPosition(x: 450, y: 350), data: "Standard Styled")
        ]
        graphStore.edges = [
            BaseEdge<String>(id: "e-custom-edge", source: "toolbar-node", target: "red-node", kind: "custom", markerEnd: EdgeMarker(type: .arrowClosed), label: "Custom Path & Neon", reconnectable: .both),
            BaseEdge<String>(id: "e-red-blue", source: "red-node", target: "blue-node", markerEnd: EdgeMarker(type: .arrowClosed), label: "Default Edge", reconnectable: .both),
            BaseEdge<String>(id: "e-blue-styled", source: "blue-node", target: "styled-node", animated: true, markerEnd: EdgeMarker(type: .arrowClosed), label: "Animated Default", reconnectable: .both)
        ]
        appStore.appendLog(kind: "sample", payload: "Custom Showcase: ToolbarNode, ColorNode, and CustomEdgeBody")
        appStore.appendLog(kind: "hint", payload: "Click 'toolbar-node' to see floating menus. Red/Blue nodes are Custom ColorNodes.")
    }
}
