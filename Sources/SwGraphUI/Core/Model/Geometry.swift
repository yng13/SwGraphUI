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
    public static let zero = XYPosition(x: 0, y: 0)

    public static func + (lhs: XYPosition, rhs: XYPosition) -> XYPosition {
        XYPosition(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: XYPosition, rhs: XYPosition) -> XYPosition {
        XYPosition(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
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
    
    public static let zero = Dimensions(width: 0, height: 0)
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

    public static let zero = Rect(origin: .zero, size: .zero)
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

public struct SnapGrid: Sendable, Equatable {
    public var width: Double
    public var height: Double
    
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
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
    public var min: XYPosition
    public var max: XYPosition

    public init(min: XYPosition, max: XYPosition) {
        self.min = min
        self.max = max
    }

    public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.min = XYPosition(x: minX, y: minY)
        self.max = XYPosition(x: maxX, y: maxY)
    }
}


