public struct BaseNode<Data: Sendable>: Sendable {
    public var id: String
    public var position: XYPosition
    public var data: Data
    public var kind: String?
    public var sourcePosition: Position?
    public var targetPosition: Position?
    public var hidden: Bool
    public var selected: Bool
    public var dragging: Bool
    public var draggable: Bool
    public var selectable: Bool
    public var connectable: Bool
    public var deletable: Bool
    public var dragHandle: String?
    public var width: Double?
    public var height: Double?
    public var initialWidth: Double?
    public var initialHeight: Double?
    public var parentID: String?
    public var zIndex: Int?
    public var extent: CoordinateExtent?
    public var expandParent: Bool
    public var ariaLabel: String?
    public var origin: NodeOrigin?
    public var handles: [NodeHandle]
    public var measured: Dimensions?

    public init(
        id: String,
        position: XYPosition,
        data: Data,
        kind: String? = nil,
        sourcePosition: Position? = nil,
        targetPosition: Position? = nil,
        hidden: Bool = false,
        selected: Bool = false,
        dragging: Bool = false,
        draggable: Bool = true,
        selectable: Bool = true,
        connectable: Bool = true,
        deletable: Bool = true,
        dragHandle: String? = nil,
        width: Double? = nil,
        height: Double? = nil,
        initialWidth: Double? = nil,
        initialHeight: Double? = nil,
        parentID: String? = nil,
        zIndex: Int? = nil,
        extent: CoordinateExtent? = nil,
        expandParent: Bool = false,
        ariaLabel: String? = nil,
        origin: NodeOrigin? = nil,
        handles: [NodeHandle] = [],
        measured: Dimensions? = nil
    ) {
        self.id = id
        self.position = position
        self.data = data
        self.kind = kind
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
        self.hidden = hidden
        self.selected = selected
        self.dragging = dragging
        self.draggable = draggable
        self.selectable = selectable
        self.connectable = connectable
        self.deletable = deletable
        self.dragHandle = dragHandle
        self.width = width
        self.height = height
        self.initialWidth = initialWidth
        self.initialHeight = initialHeight
        self.parentID = parentID
        self.zIndex = zIndex
        self.extent = extent
        self.expandParent = expandParent
        self.ariaLabel = ariaLabel
        self.origin = origin
        self.handles = handles
        self.measured = measured
    }
}

public typealias Node = BaseNode<EmptyPayload>
