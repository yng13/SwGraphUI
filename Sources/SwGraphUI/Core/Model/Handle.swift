public enum HandleType: String, Sendable, Codable {
    case source
    case target
    
    public var opposite: HandleType {
        self == .source ? .target : .source
    }
}

public struct Handle: Sendable, Equatable {
    public var id: String?
    public var nodeID: String
    public var position: XYPosition
    public var placement: Position
    public var type: HandleType
    public var dimensions: Dimensions
    public var isConnectable: Bool

    public init(
        id: String? = nil,
        nodeID: String,
        position: XYPosition,
        placement: Position,
        type: HandleType,
        dimensions: Dimensions,
        isConnectable: Bool = true
    ) {
        self.id = id
        self.nodeID = nodeID
        self.position = position
        self.placement = placement
        self.type = type
        self.dimensions = dimensions
        self.isConnectable = isConnectable
    }
}

public struct NodeHandle: Sendable, Equatable, Codable {
    public var id: String?
    public var placement: Position
    public var type: HandleType
    public var isConnectable: Bool

    public init(
        id: String? = nil,
        placement: Position,
        type: HandleType,
        isConnectable: Bool = true
    ) {
        self.id = id
        self.placement = placement
        self.type = type
        self.isConnectable = isConnectable
    }
}
