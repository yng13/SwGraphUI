import Testing
@testable import SwGraphUI

struct GraphViewportCullingTests {
    @Test
    func visibleGraphRectConvertsScreenMarginToGraphSpace() {
        let rect = GraphViewportCulling.visibleGraphRect(
            viewport: Viewport(x: -100, y: -50, zoom: 2),
            containerSize: Dimensions(width: 800, height: 600),
            screenMargin: 200
        )

        #expect(rect == Rect(x: -50, y: -75, width: 600, height: 500))
    }

    @Test
    func nodeVisibilityUsesExpandedViewport() {
        let node = BaseNode(
            id: "visible",
            position: XYPosition(x: 320, y: 120),
            data: EmptyPayload(),
            width: 120,
            height: 60
        )
        let offscreen = BaseNode(
            id: "offscreen",
            position: XYPosition(x: 1200, y: 1200),
            data: EmptyPayload(),
            width: 120,
            height: 60
        )
        let viewport = Viewport(x: 0, y: 0, zoom: 1)
        let size = Dimensions(width: 800, height: 600)

        #expect(GraphViewportCulling.isNodeVisible(node, absolutePosition: node.position, viewport: viewport, containerSize: size, screenMargin: 120))
        #expect(!GraphViewportCulling.isNodeVisible(offscreen, absolutePosition: offscreen.position, viewport: viewport, containerSize: size, screenMargin: 120))
    }

    @Test
    func edgeVisibilityKeepsLongEdgesCrossingViewport() {
        let viewport = Viewport(x: 0, y: 0, zoom: 1)
        let size = Dimensions(width: 800, height: 600)

        #expect(GraphViewportCulling.isEdgeVisible(
            source: XYPosition(x: -500, y: 300),
            target: XYPosition(x: 1500, y: 300),
            viewport: viewport,
            containerSize: size,
            screenMargin: 0
        ))
        #expect(!GraphViewportCulling.isEdgeVisible(
            source: XYPosition(x: -500, y: -300),
            target: XYPosition(x: 1500, y: -300),
            viewport: viewport,
            containerSize: size,
            screenMargin: 0
        ))
    }
}
