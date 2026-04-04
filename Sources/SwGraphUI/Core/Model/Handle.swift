public enum HandleType: String, Sendable {
    case source
    case target
}

public struct Handle: Sendable, Equatable {
    public var id: String?
    public var nodeID: String
    public var position: XYPosition
    public var placement: Position
    public var type: HandleType
    public var dimensions: Dimensions

    public init(
        id: String? = nil,
        nodeID: String,
        position: XYPosition,
        placement: Position,
        type: HandleType,
        dimensions: Dimensions
    ) {
        self.id = id
        self.nodeID = nodeID
        self.position = position
        self.placement = placement
        self.type = type
        self.dimensions = dimensions
    }
}

public struct NodeHandle: Sendable, Equatable {
    public var id: String?
    public var placement: Position
    public var type: HandleType

    public init(id: String? = nil, placement: Position, type: HandleType) {
        self.id = id
        self.placement = placement
        self.type = type
    }
}
