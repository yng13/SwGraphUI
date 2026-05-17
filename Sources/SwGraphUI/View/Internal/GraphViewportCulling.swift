import Foundation

internal enum GraphViewportCulling {
    static func visibleGraphRect(
        viewport: Viewport,
        containerSize: Dimensions,
        screenMargin: Double
    ) -> Rect? {
        guard viewport.zoom.isFinite, viewport.zoom > 0,
              viewport.x.isFinite, viewport.y.isFinite,
              containerSize.width.isFinite, containerSize.height.isFinite,
              containerSize.width > 0, containerSize.height > 0,
              screenMargin.isFinite else {
            return nil
        }

        let margin = max(screenMargin, 0)
        return Rect(
            x: (-viewport.x - margin) / viewport.zoom,
            y: (-viewport.y - margin) / viewport.zoom,
            width: (containerSize.width + margin * 2) / viewport.zoom,
            height: (containerSize.height + margin * 2) / viewport.zoom
        )
    }

    static func nodeRect<NodeData: Sendable>(
        for node: BaseNode<NodeData>,
        absolutePosition: XYPosition
    ) -> Rect {
        let dimensions = GraphAlgorithms.nodeDimensions(for: node)
        let origin = node.origin ?? .topLeft
        return Rect(
            x: absolutePosition.x - dimensions.width * origin.x,
            y: absolutePosition.y - dimensions.height * origin.y,
            width: dimensions.width,
            height: dimensions.height
        )
    }

    static func isNodeVisible<NodeData: Sendable>(
        _ node: BaseNode<NodeData>,
        absolutePosition: XYPosition,
        viewport: Viewport,
        containerSize: Dimensions,
        screenMargin: Double
    ) -> Bool {
        guard let visibleRect = visibleGraphRect(
            viewport: viewport,
            containerSize: containerSize,
            screenMargin: screenMargin
        ) else {
            return true
        }
        return intersects(nodeRect(for: node, absolutePosition: absolutePosition), visibleRect)
    }

    static func isEdgeVisible(
        source: XYPosition,
        target: XYPosition,
        viewport: Viewport,
        containerSize: Dimensions,
        screenMargin: Double
    ) -> Bool {
        guard let visibleRect = visibleGraphRect(
            viewport: viewport,
            containerSize: containerSize,
            screenMargin: screenMargin
        ) else {
            return true
        }

        let minX = min(source.x, target.x)
        let minY = min(source.y, target.y)
        let width = max(abs(target.x - source.x), 1)
        let height = max(abs(target.y - source.y), 1)
        return intersects(Rect(x: minX, y: minY, width: width, height: height), visibleRect)
    }

    static func intersects(_ lhs: Rect, _ rhs: Rect) -> Bool {
        let lhsMaxX = lhs.x + max(lhs.width, 0)
        let lhsMaxY = lhs.y + max(lhs.height, 0)
        let rhsMaxX = rhs.x + max(rhs.width, 0)
        let rhsMaxY = rhs.y + max(rhs.height, 0)

        return lhs.x <= rhsMaxX
            && lhsMaxX >= rhs.x
            && lhs.y <= rhsMaxY
            && lhsMaxY >= rhs.y
    }
}
