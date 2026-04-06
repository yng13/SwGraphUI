public struct EmptyPayload: Sendable, Equatable, Codable {
    public init() {}
}

public enum MarkerType: String, Sendable {
    case arrow
    case arrowClosed = "arrowclosed"
}

/// エッジの再接続許可モード。
public enum ReconnectMode: String, Sendable, CaseIterable {
    case none
    case source
    case target
    case both
}

public struct EdgeMarker: Sendable, Equatable {
    public var type: MarkerType
    public var color: String?
    public var width: Double?
    public var height: Double?
    public var markerUnits: String?
    public var orient: String?
    public var strokeWidth: Double?

    public init(
        type: MarkerType,
        color: String? = nil,
        width: Double? = nil,
        height: Double? = nil,
        markerUnits: String? = nil,
        orient: String? = nil,
        strokeWidth: Double? = nil
    ) {
        self.type = type
        self.color = color
        self.width = width
        self.height = height
        self.markerUnits = markerUnits
        self.orient = orient
        self.strokeWidth = strokeWidth
    }
}

public enum ConnectionLineType: String, Sendable {
    case bezier = "default"
    case straight
    case step
    case smoothStep = "smoothstep"
    case simpleBezier = "simplebezier"
}

public struct EdgePosition: Sendable, Equatable {
    public var sourceX: Double
    public var sourceY: Double
    public var targetX: Double
    public var targetY: Double
    public var sourcePosition: Position
    public var targetPosition: Position

    public init(
        sourceX: Double,
        sourceY: Double,
        targetX: Double,
        targetY: Double,
        sourcePosition: Position,
        targetPosition: Position
    ) {
        self.sourceX = sourceX
        self.sourceY = sourceY
        self.targetX = targetX
        self.targetY = targetY
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
    }
}

public struct BaseEdge<Data: Sendable>: Sendable, Identifiable {
    // MARK: - User-defined properties
    public var id: String
    public var source: String
    public var target: String
    public var data: Data?
    public var kind: String?
    public var sourceHandle: String?
    public var targetHandle: String?
    public var sourcePosition: Position?
    public var targetPosition: Position?
    public var animated: Bool
    public var markerStart: EdgeMarker?
    public var markerEnd: EdgeMarker?
    public var zIndex: Int?
    public var ariaLabel: String?
    public var interactionWidth: Double?
    public var curvature: Double?
    public var label: String?
    public var reconnectable: ReconnectMode

    // MARK: - Library-managed/Interaction state
    public var hidden: Bool
    public var deletable: Bool
    public var selectable: Bool
    public var selected: Bool

    public init(
        id: String,
        source: String,
        target: String,
        data: Data? = nil,
        kind: String? = nil,
        sourceHandle: String? = nil,
        targetHandle: String? = nil,
        sourcePosition: Position? = nil,
        targetPosition: Position? = nil,
        animated: Bool = false,
        markerStart: EdgeMarker? = nil,
        markerEnd: EdgeMarker? = nil,
        zIndex: Int? = nil,
        ariaLabel: String? = nil,
        interactionWidth: Double? = nil,
        curvature: Double? = nil,
        hidden: Bool = false,
        deletable: Bool = true,
        selectable: Bool = true,
        selected: Bool = false,
        label: String? = nil,
        reconnectable: ReconnectMode = .none
    ) {
        self.id = id
        self.source = source
        self.target = target
        self.data = data
        self.kind = kind
        self.sourceHandle = sourceHandle
        self.targetHandle = targetHandle
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
        self.animated = animated
        self.markerStart = markerStart
        self.markerEnd = markerEnd
        self.zIndex = zIndex
        self.ariaLabel = ariaLabel
        self.interactionWidth = interactionWidth
        self.curvature = curvature
        self.hidden = hidden
        self.deletable = deletable
        self.selectable = selectable
        self.selected = selected
        self.label = label
        self.reconnectable = reconnectable
    }
}

public typealias Edge = BaseEdge<EmptyPayload>

