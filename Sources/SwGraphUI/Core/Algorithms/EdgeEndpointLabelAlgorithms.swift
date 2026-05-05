public enum EdgeEndpointLabelAlgorithms {
    public static let defaultOffset: Double = 14.0

    public static func graphPosition(
        handlePoint: XYPosition,
        placement: Position,
        offset: Double = defaultOffset
    ) -> XYPosition {
        let vector = directionVector(for: placement)
        return XYPosition(
            x: handlePoint.x + vector.x * offset,
            y: handlePoint.y + vector.y * offset
        )
    }

    public static func screenPosition(
        handlePoint: XYPosition,
        placement: Position,
        viewport: Viewport,
        offset: Double = defaultOffset
    ) -> XYPosition {
        graphPosition(handlePoint: handlePoint, placement: placement, offset: offset)
            .toScreen(viewport: viewport)
    }

    private static func directionVector(for placement: Position) -> XYPosition {
        switch placement {
        case .top:
            XYPosition(x: 0, y: -1)
        case .right:
            XYPosition(x: 1, y: 0)
        case .bottom:
            XYPosition(x: 0, y: 1)
        case .left:
            XYPosition(x: -1, y: 0)
        }
    }
}
