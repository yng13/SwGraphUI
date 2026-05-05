public enum HandlePlacementAlgorithms {
    public static let defaultSideInset: Double = 16.0

    public static func borderPosition(
        bounds: Rect,
        placement: Position,
        index: Int,
        count: Int,
        sideInset: Double = defaultSideInset
    ) -> XYPosition {
        let safeCount = max(count, 1)
        let safeIndex = min(max(index, 0), safeCount - 1)
        let t = Double(safeIndex + 1) / Double(safeCount + 1)
        let horizontalInset = min(max(sideInset, 0), max(bounds.width / 2, 0))
        let verticalInset = min(max(sideInset, 0), max(bounds.height / 2, 0))

        switch placement {
        case .left:
            return XYPosition(
                x: bounds.x,
                y: interpolate(start: bounds.y + verticalInset, end: bounds.y + bounds.height - verticalInset, t: t)
            )
        case .right:
            return XYPosition(
                x: bounds.x + bounds.width,
                y: interpolate(start: bounds.y + verticalInset, end: bounds.y + bounds.height - verticalInset, t: t)
            )
        case .top:
            return XYPosition(
                x: interpolate(start: bounds.x + horizontalInset, end: bounds.x + bounds.width - horizontalInset, t: t),
                y: bounds.y
            )
        case .bottom:
            return XYPosition(
                x: interpolate(start: bounds.x + horizontalInset, end: bounds.x + bounds.width - horizontalInset, t: t),
                y: bounds.y + bounds.height
            )
        }
    }

    private static func interpolate(start: Double, end: Double, t: Double) -> Double {
        start + (end - start) * t
    }
}
