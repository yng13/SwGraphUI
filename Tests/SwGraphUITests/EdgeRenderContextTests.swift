import Testing
import SwiftUI
@testable import SwGraphUI

@MainActor
struct EdgeRenderContextTests {
    @Test
    func edgeContextCarriesGraphAndScreenGeometry() {
        let store = GraphStore<EmptyPayload>(
            nodes: [
                BaseNode(id: "a", position: XYPosition(x: 20, y: 30), data: EmptyPayload(), width: 120, height: 60),
                BaseNode(id: "b", position: XYPosition(x: 260, y: 120), data: EmptyPayload(), width: 120, height: 60),
            ],
            edges: [
                BaseEdge(id: "e1", source: "a", target: "b")
            ]
        )

        var captured: EdgeRenderContext<EmptyPayload>?

        let view = GraphExportView(
            store: store,
            settings: GraphExportSettings(scale: 1.0, margin: 0, includeBackground: false, isTransparent: true),
            nodeBuilder: { _ in Color.clear.frame(width: 120, height: 60) },
            edgeBuilder: { context in
                captured = context
                return AnyView(context.screenPath.stroke(context.strokeColor, lineWidth: context.strokeWidth))
            },
            bounds: Rect(x: 0, y: 0, width: 500, height: 300)
        )

        let renderer = ImageRenderer(content: view)
        #if os(macOS)
        _ = renderer.nsImage
        #else
        _ = renderer.uiImage
        #endif

        let context = captured
        #expect(context != nil)

        if let context {
            #expect(!context.graphSegments.isEmpty)
            #expect(!context.screenPath.isEmpty)
            #expect(context.screenSegments.count == context.graphSegments.count)
            #expect(context.viewport == .identity)

            for (graphSegment, screenSegment) in zip(context.graphSegments, context.screenSegments) {
                #expect(graphSegment.toScreen(viewport: context.viewport) == screenSegment)
            }
        }
    }
}
