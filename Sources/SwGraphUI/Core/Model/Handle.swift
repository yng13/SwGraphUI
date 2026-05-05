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

public enum NodeHandlePlacementMode: String, Sendable, CaseIterable, Codable {
    /// Use `placement` as an explicit side and prefer measured custom `HandleView` coordinates when available. | `placement` を明示的な辺として扱い、実測されたカスタム `HandleView` 座標を優先します。
    case explicit
    /// Resolve the side from the peer node direction, then place the handle on the node bounds. | 接続先ノード方向から辺を解決し、ノード境界上にハンドルを配置します。
    case automaticPeerSide
}

public struct NodeHandle: Sendable, Equatable, Codable {
    public var id: String?
    public var placement: Position
    public var type: HandleType
    public var isConnectable: Bool
    public var placementMode: NodeHandlePlacementMode

    public init(
        id: String? = nil,
        placement: Position,
        type: HandleType,
        isConnectable: Bool = true,
        placementMode: NodeHandlePlacementMode = .explicit
    ) {
        self.id = id
        self.placement = placement
        self.type = type
        self.isConnectable = isConnectable
        self.placementMode = placementMode
    }

    enum CodingKeys: String, CodingKey {
        case id, placement, type, isConnectable, placementMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.placement = try container.decode(Position.self, forKey: .placement)
        self.type = try container.decode(HandleType.self, forKey: .type)
        self.isConnectable = try container.decodeIfPresent(Bool.self, forKey: .isConnectable) ?? true
        self.placementMode = try container.decodeIfPresent(NodeHandlePlacementMode.self, forKey: .placementMode) ?? .explicit
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(placement, forKey: .placement)
        try container.encode(type, forKey: .type)
        try container.encode(isConnectable, forKey: .isConnectable)
        try container.encode(placementMode, forKey: .placementMode)
    }
}
