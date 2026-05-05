import SwiftUI

/// Rendering context passed to custom edge builders.
/// Exposes both graph-space and screen-space representations to avoid
/// accidental coordinate-space mixups in application code.
public struct EdgeRenderContext<NodeData: Sendable> {
    public let edge: BaseEdge<NodeData>
    public let graphSegments: [PathSegment]
    public let screenSegments: [PathSegment]
    public let screenPath: Path
    public let strokeColor: Color
    public let strokeWidth: CGFloat
    public let dashStyle: EdgeStrokeDash
    public let viewport: Viewport
    public let containerSize: Dimensions
    public let animated: Bool
    public let isReconnecting: Bool

    public init(
        edge: BaseEdge<NodeData>,
        graphSegments: [PathSegment],
        screenSegments: [PathSegment],
        screenPath: Path,
        strokeColor: Color,
        strokeWidth: CGFloat,
        dashStyle: EdgeStrokeDash = .solid,
        viewport: Viewport,
        containerSize: Dimensions,
        animated: Bool,
        isReconnecting: Bool
    ) {
        self.edge = edge
        self.graphSegments = graphSegments
        self.screenSegments = screenSegments
        self.screenPath = screenPath
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.dashStyle = dashStyle
        self.viewport = viewport
        self.containerSize = containerSize
        self.animated = animated
        self.isReconnecting = isReconnecting
    }
}
