public enum Position: String, CaseIterable, Sendable {
    case left
    case top
    case right
    case bottom

    public var opposite: Position {
        switch self {
        case .left:
            .right
        case .top:
            .bottom
        case .right:
            .left
        case .bottom:
            .top
        }
    }
}

public struct XYPosition: Sendable, Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct XYZPosition: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct Dimensions: Sendable, Equatable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct Rect: Sendable, Equatable {
    public var origin: XYPosition
    public var size: Dimensions

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = XYPosition(x: x, y: y)
        self.size = Dimensions(width: width, height: height)
    }

    public init(origin: XYPosition, size: Dimensions) {
        self.origin = origin
        self.size = size
    }

    public var x: Double { origin.x }
    public var y: Double { origin.y }
    public var width: Double { size.width }
    public var height: Double { size.height }
}

public struct Box: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var x2: Double
    public var y2: Double

    public init(x: Double, y: Double, x2: Double, y2: Double) {
        self.x = x
        self.y = y
        self.x2 = x2
        self.y2 = y2
    }
}

public struct Viewport: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var zoom: Double

    public init(x: Double, y: Double, zoom: Double) {
        self.x = x
        self.y = y
        self.zoom = zoom
    }
}

public struct Transform: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var zoom: Double

    public init(x: Double, y: Double, zoom: Double) {
        self.x = x
        self.y = y
        self.zoom = zoom
    }
}

public struct CoordinateExtent: Sendable, Equatable {
    public var minimum: XYPosition
    public var maximum: XYPosition

    public init(minimum: XYPosition, maximum: XYPosition) {
        self.minimum = minimum
        self.maximum = maximum
    }

    public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minimum = XYPosition(x: minX, y: minY)
        self.maximum = XYPosition(x: maxX, y: maxY)
    }
}


