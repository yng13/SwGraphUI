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

    public static func getNodePositionWithOrigin<Data: Sendable>(node: BaseNode<Data>, nodeOrigin: NodeOrigin = .init(x: 0, y: 0)) -> XYPosition {
        let width = node.width ?? node.measured?.width ?? node.initialWidth ?? 0
        let height = node.height ?? node.measured?.height ?? node.initialHeight ?? 0
        let origin = node.origin ?? nodeOrigin

        return XYPosition(
            x: node.position.x - width * origin.x,
            y: node.position.y - height * origin.y
        )
    }

    public static func getBounds<Data: Sendable>(nodes: [BaseNode<Data>], nodeOrigin: NodeOrigin = .init(x: 0, y: 0)) -> Rect {
        if nodes.isEmpty {
            return Rect(x: 0, y: 0, width: 0, height: 0)
        }

        let rects = nodes.map { node in
            let pos = getNodePositionWithOrigin(node: node, nodeOrigin: nodeOrigin)
            return Rect(
                x: pos.x,
                y: pos.y,
                width: node.width ?? node.measured?.width ?? node.initialWidth ?? 0,
                height: node.height ?? node.measured?.height ?? node.initialHeight ?? 0
            )
        }

        return union(of: rects) ?? Rect(x: 0, y: 0, width: 0, height: 0)
    }

    public enum PaddingValue: Sendable, Equatable {
        case relative(Double)
        case points(Double)

        public func resolve(for axis: Double) -> Double {
            switch self {
            case .relative(let val): axis * val
            case .points(let val): val
            }
        }
    }

    public struct Padding: Sendable, Equatable {
        public var top: PaddingValue
        public var left: PaddingValue
        public var bottom: PaddingValue
        public var right: PaddingValue

        public init(top: PaddingValue, left: PaddingValue, bottom: PaddingValue, right: PaddingValue) {
            self.top = top
            self.left = left
            self.bottom = bottom
            self.right = right
        }

        public static func all(_ value: PaddingValue) -> Padding {
            .init(top: value, left: value, bottom: value, right: value)
        }

        public static func symmetric(vertical: PaddingValue, horizontal: PaddingValue) -> Padding {
            .init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        }
    }

    internal static func calculateAppliedPaddings(bounds: Rect, x: Double, y: Double, zoom: Double, width: Double, height: Double) -> (top: Double, left: Double, bottom: Double, right: Double) {
        let left = (bounds.x * zoom) + x
        let top = (bounds.y * zoom) + y
        let right = width - (bounds.x + bounds.width) * zoom - x
        let bottom = height - (bounds.y + bounds.height) * zoom - y

        return (top: floor(top), left: floor(left), bottom: floor(bottom), right: floor(right))
    }

    public static func getViewportForBounds(
        _ bounds: Rect,
        in size: Dimensions,
        minZoom: Double,
        maxZoom: Double,
        padding: Padding = .all(.relative(0.1))
    ) -> Viewport {
        let pTop = padding.top.resolve(for: size.height)
        let pLeft = padding.left.resolve(for: size.width)
        let pBottom = padding.bottom.resolve(for: size.height)
        let pRight = padding.right.resolve(for: size.width)

        let xZoom = (size.width - (pLeft + pRight)) / bounds.width
        let yZoom = (size.height - (pTop + pBottom)) / bounds.height
        
        let zoom = clamp(Swift.min(xZoom, yZoom), min: minZoom, max: maxZoom)
        
        let boundsCenterX = bounds.x + bounds.width / 2
        let boundsCenterY = bounds.y + bounds.height / 2
        
        let x = size.width / 2 - boundsCenterX * zoom
        let y = size.height / 2 - boundsCenterY * zoom

        // xyflow's logic: re-calculate applied paddings and offset to respect asymmetric padding
        let applied = calculateAppliedPaddings(bounds: bounds, x: x, y: y, zoom: zoom, width: size.width, height: size.height)

        let offsetLeft = Swift.min(applied.left - pLeft, 0)
        let offsetTop = Swift.min(applied.top - pTop, 0)
        let offsetRight = Swift.min(applied.right - pRight, 0)
        let offsetBottom = Swift.min(applied.bottom - pBottom, 0)

        return Viewport(
            x: x - offsetLeft + offsetRight,
            y: y - offsetTop + offsetBottom,
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


