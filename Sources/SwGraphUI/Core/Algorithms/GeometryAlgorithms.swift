import Foundation

public enum GeometryAlgorithms {
    public static func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.min(Swift.max(value, minimum), maximum)
    }

    public static func clamp(position: XYPosition, to extent: CoordinateExtent, dimensions: Dimensions = .init(width: 0, height: 0)) -> XYPosition {
        XYPosition(
            x: clamp(position.x, min: extent.minimum.x, max: extent.maximum.x - dimensions.width),
            y: clamp(position.y, min: extent.minimum.y, max: extent.maximum.y - dimensions.height)
        )
    }

    public static func bounds(of first: Box, and second: Box) -> Box {
        Box(
            x: Swift.min(first.x, second.x),
            y: Swift.min(first.y, second.y),
            x2: Swift.max(first.x2, second.x2),
            y2: Swift.max(first.y2, second.y2)
        )
    }

    public static func rectToBox(_ rect: Rect) -> Box {
        Box(x: rect.x, y: rect.y, x2: rect.x + rect.width, y2: rect.y + rect.height)
    }

    public static func boxToRect(_ box: Box) -> Rect {
        Rect(x: box.x, y: box.y, width: box.x2 - box.x, height: box.y2 - box.y)
    }

    public static func overlapArea(between first: Rect, and second: Rect) -> Double {
        let xOverlap = Swift.max(0, Swift.min(first.x + first.width, second.x + second.width) - Swift.max(first.x, second.x))
        let yOverlap = Swift.max(0, Swift.min(first.y + first.height, second.y + second.height) - Swift.max(first.y, second.y))
        return ceil(xOverlap * yOverlap)
    }

    public static func snap(_ position: XYPosition, to grid: (x: Double, y: Double) = (1, 1)) -> XYPosition {
        XYPosition(
            x: grid.x * Foundation.round(position.x / grid.x),
            y: grid.y * Foundation.round(position.y / grid.y)
        )
    }

    public static func pointToRenderer(_ point: XYPosition, transform: Transform, snapToGrid: Bool = false, grid: (x: Double, y: Double) = (1, 1)) -> XYPosition {
        let projected = XYPosition(
            x: (point.x - transform.x) / transform.zoom,
            y: (point.y - transform.y) / transform.zoom
        )
        return snapToGrid ? snap(projected, to: grid) : projected
    }

    public static func rendererToPoint(_ point: XYPosition, transform: Transform) -> XYPosition {
        XYPosition(
            x: point.x * transform.zoom + transform.x,
            y: point.y * transform.zoom + transform.y
        )
    }

    public static func viewportForBounds(
        _ bounds: Rect,
        in size: Dimensions,
        minZoom: Double,
        maxZoom: Double,
        padding: Double = 0.1
    ) -> Viewport {
        let paddingX = Foundation.floor((size.width - size.width / (1 + padding)) * 0.5)
        let paddingY = Foundation.floor((size.height - size.height / (1 + padding)) * 0.5)
        let xZoom = (size.width - paddingX * 2) / bounds.width
        let yZoom = (size.height - paddingY * 2) / bounds.height
        let zoom = clamp(Swift.min(xZoom, yZoom), min: minZoom, max: maxZoom)
        let centerX = bounds.x + bounds.width / 2
        let centerY = bounds.y + bounds.height / 2

        return Viewport(
            x: size.width / 2 - centerX * zoom,
            y: size.height / 2 - centerY * zoom,
            zoom: zoom
        )
    }

    public static func union(of rects: [Rect]) -> Rect? {
        guard let first = rects.first else {
            return nil
        }

        let minX = rects.reduce(first.x) { Swift.min($0, $1.x) }
        let minY = rects.reduce(first.y) { Swift.min($0, $1.y) }
        let maxX = rects.reduce(first.x + first.width) { Swift.max($0, $1.x + $1.width) }
        let maxY = rects.reduce(first.y + first.height) { Swift.max($0, $1.y + $1.height) }

        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
