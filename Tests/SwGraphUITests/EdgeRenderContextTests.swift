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
                BaseEdge(id: "e1", source: "a", target: "b", strokeStyle: EdgeStrokeStyle(color: "#2563EB", width: 4, dash: .dashed))
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
            #expect(context.strokeWidth == 4)
            #expect(context.dashStyle == .dashed)

            for (graphSegment, screenSegment) in zip(context.graphSegments, context.screenSegments) {
                #expect(graphSegment.toScreen(viewport: context.viewport) == screenSegment)
            }
        }
    }

    @Test
    func selectedStyledEdgeKeepsDashAndGetsWidthEmphasis() {
        let store = GraphStore<EmptyPayload>(
            nodes: [
                BaseNode(id: "a", position: XYPosition(x: 20, y: 30), data: EmptyPayload(), width: 120, height: 60),
                BaseNode(id: "b", position: XYPosition(x: 260, y: 120), data: EmptyPayload(), width: 120, height: 60),
            ],
            edges: [
                BaseEdge(
                    id: "e1",
                    source: "a",
                    target: "b",
                    selected: true,
                    strokeStyle: EdgeStrokeStyle(color: "#2563EB", width: 4, dash: .dotted)
                )
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

        #expect(captured?.dashStyle == .dotted)
        #expect(captured?.strokeWidth == 5)
    }

    @Test
    func edgeContextCarriesDoubleStrokeShape() {
        let store = GraphStore<EmptyPayload>(
            nodes: [
                BaseNode(id: "a", position: XYPosition(x: 20, y: 30), data: EmptyPayload(), width: 120, height: 60),
                BaseNode(id: "b", position: XYPosition(x: 260, y: 120), data: EmptyPayload(), width: 120, height: 60),
            ],
            edges: [
                BaseEdge(
                    id: "e1",
                    source: "a",
                    target: "b",
                    strokeStyle: EdgeStrokeStyle(width: 4, shape: .double)
                )
            ]
        )

        var captured: EdgeRenderContext<EmptyPayload>?
        let view = GraphExportView(
            store: store,
            settings: GraphExportSettings(scale: 1.0, margin: 0, includeBackground: false, isTransparent: true),
            nodeBuilder: { _ in Color.clear.frame(width: 120, height: 60) },
            edgeBuilder: { context in
                captured = context
                return AnyView(EmptyView())
            },
            bounds: Rect(x: 0, y: 0, width: 500, height: 300)
        )

        let renderer = ImageRenderer(content: view)
        #if os(macOS)
        _ = renderer.nsImage
        #else
        _ = renderer.uiImage
        #endif

        #expect(captured?.strokeShape == .double)
    }

    @Test
    func exportContextUsesBoundsTranslatedViewport() {
        let store = GraphStore<EmptyPayload>(
            nodes: [
                BaseNode(id: "a", position: XYPosition(x: 120, y: 400), data: EmptyPayload(), width: 120, height: 60),
                BaseNode(id: "b", position: XYPosition(x: 120, y: 720), data: EmptyPayload(), width: 120, height: 60),
            ],
            edges: [
                BaseEdge(
                    id: "e1",
                    source: "a",
                    target: "b",
                    kind: "smoothstep",
                    sourcePosition: .bottom,
                    targetPosition: .top
                )
            ]
        )

        var captured: EdgeRenderContext<EmptyPayload>?
        let bounds = Rect(x: 100, y: 380, width: 200, height: 420)
        let view = GraphExportView(
            store: store,
            settings: GraphExportSettings(scale: 1.0, margin: 24, includeBackground: false, isTransparent: true),
            nodeBuilder: { _ in Color.clear.frame(width: 120, height: 60) },
            edgeBuilder: { context in
                captured = context
                return AnyView(context.screenPath.stroke(context.strokeColor, lineWidth: context.strokeWidth))
            },
            bounds: bounds
        )

        let renderer = ImageRenderer(content: view)
        #if os(macOS)
        _ = renderer.nsImage
        #else
        _ = renderer.uiImage
        #endif

        #expect(captured != nil)
        #expect(captured?.viewport == Viewport(x: -76, y: -356, zoom: 1.0))
        #expect(captured?.containerSize == Dimensions(width: 248, height: 468))

        if let graphStart = captured?.graphSegments.first?.points.first,
           let screenStart = captured?.screenSegments.first?.points.first {
            #expect(screenStart == graphStart.toScreen(viewport: Viewport(x: -76, y: -356, zoom: 1.0)))
            #expect(screenStart.y < bounds.height)
        }
    }
}
