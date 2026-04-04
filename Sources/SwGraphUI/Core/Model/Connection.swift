public struct Connection: Sendable, Equatable {
    public var source: String
    public var target: String
    public var sourceHandle: String?
    public var targetHandle: String?

    public init(source: String, target: String, sourceHandle: String? = nil, targetHandle: String? = nil) {
        self.source = source
        self.target = target
        self.sourceHandle = sourceHandle
        self.targetHandle = targetHandle
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
