public struct Connection: Sendable, Equatable {
    public var source: String
    public var target: String
    public var sourceHandle: String?
    public var targetHandle: String?
    public var sourcePosition: Position?
    public var targetPosition: Position?

    public init(
        source: String,
        target: String,
        sourceHandle: String? = nil,
        targetHandle: String? = nil,
        sourcePosition: Position? = nil,
        targetPosition: Position? = nil
    ) {
        self.source = source
        self.target = target
        self.sourceHandle = sourceHandle
        self.targetHandle = targetHandle
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
    }
}

public struct HandleConnection: Sendable, Equatable {
    public var edgeID: String
    public var connection: Connection

    public init(edgeID: String, connection: Connection) {
        self.edgeID = edgeID
        self.connection = connection
    }
}

public struct NodeConnection: Sendable, Equatable {
    public var edgeID: String
    public var connection: Connection

    public init(edgeID: String, connection: Connection) {
        self.edgeID = edgeID
        self.connection = connection
    }
}

public enum ConnectionMode: String, Sendable {
    case strict
    case loose
}
