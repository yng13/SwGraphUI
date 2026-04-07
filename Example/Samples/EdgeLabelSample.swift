import SwGraphUI
import SwiftUI

struct EdgeLabelSample: GraphSample {
    let title = "Edge Label Showcase"
    let category: ExampleAppStore.SampleCategory = .basic
    let description = "Detailed styles for edge labels: background, padding, and positioning."
    
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        graphStore.nodes = [
            BaseNode(id: "n1", position: XYPosition(x: 50, y: 50), data: "Source"),
            BaseNode(id: "n2", position: XYPosition(x: 350, y: 50), data: "Bezier"),
            BaseNode(id: "n3", position: XYPosition(x: 50, y: 250), data: "Straight"),
            BaseNode(id: "n4", position: XYPosition(x: 350, y: 250), data: "SmoothStep"),
            BaseNode(id: "n5", position: XYPosition(x: 50, y: 450), data: "Step"),
            BaseNode(id: "n6", position: XYPosition(x: 350, y: 450), data: "Custom Style")
        ]
        
        graphStore.edges = [
            // 1. Bezier (Default)
            BaseEdge<String>(
                id: "e1", source: "n1", target: "n2",
                label: "Bezier Label",
                labelStyle: EdgeLabelStyle(bgPadding: 6, bgBorderRadius: 8)
            ),
            // 2. Straight
            BaseEdge<String>(
                id: "e2", source: "n1", target: "n3", kind: "straight",
                label: "Straight Label",
                labelStyle: EdgeLabelStyle(textColor: "#FF5500", bgPadding: 4)
            ),
            // 3. SmoothStep
            BaseEdge<String>(
                id: "e3", source: "n2", target: "n4", kind: "smoothstep",
                label: "SmoothStep Center",
                labelStyle: EdgeLabelStyle(textColor: "#FFFFFF", bgStyle: "#007AFF", bgPadding: 5)
            ),
            // 4. Step
            BaseEdge<String>(
                id: "e4", source: "n3", target: "n5", kind: "step",
                label: "Step Label",
                labelStyle: EdgeLabelStyle(showBg: true, bgPadding: 2)
            ),
            // 5. Custom Styling
            BaseEdge<String>(
                id: "e5", source: "n4", target: "n6",
                label: "Styled: Title Font",
                labelStyle: EdgeLabelStyle(font: "body", fontSize: 14, bgPadding: 8, bgBorderRadius: 20)
            ),
            // 6. No Background
            BaseEdge<String>(
                id: "e6", source: "n5", target: "n6", kind: "straight",
                label: "No Background",
                labelStyle: EdgeLabelStyle(textColor: "#555555", showBg: false)
            )
        ]
        
        appStore.appendLog(kind: "sample", payload: "Edge Label Showcase loaded")
    }
}
