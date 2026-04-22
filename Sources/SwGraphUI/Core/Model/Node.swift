public struct NodeOrigin: Sendable, Equatable, Codable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let center = NodeOrigin(x: 0.5, y: 0.5)
    public static let topLeft = NodeOrigin(x: 0, y: 0)
    public static let zero = topLeft
}

public enum NodeExtent: Sendable, Equatable, Codable {
    case parent
    case coordinate(CoordinateExtent)
}

public struct BaseNode<NodeData: Sendable>: Sendable, Identifiable {
    // MARK: - User-defined properties
    public var id: String
    public var position: XYPosition
    public var data: NodeData
    public var kind: String?
    public var sourcePosition: Position?
    public var targetPosition: Position?
    public var parentID: String?
    public var zIndex: Int?
    public var extent: NodeExtent?
    public var expandParent: Bool
    public var ariaLabel: String?
    public var label: String?
    public var origin: NodeOrigin?
    public var handles: [NodeHandle]
    public var connectable: Bool
    public var resizable: Bool

    // MARK: - Library-managed/Interaction state
    public var hidden: Bool
    public var selected: Bool
    public var dragging: Bool
    public var draggable: Bool
    public var selectable: Bool
    public var deletable: Bool
    public var dragHandle: String?
    public var width: Double?
    public var height: Double?
    public var minWidth: Double
    public var minHeight: Double
    public var maxWidth: Double
    public var maxHeight: Double
    public var initialWidth: Double?
    public var initialHeight: Double?
    public var measured: Dimensions?

    public init(
        id: String,
        position: XYPosition,
        data: NodeData,
        kind: String? = nil,
        sourcePosition: Position? = nil,
        targetPosition: Position? = nil,
        parentID: String? = nil,
        zIndex: Int? = nil,
        extent: NodeExtent? = nil,
        expandParent: Bool = false,
        ariaLabel: String? = nil,
        origin: NodeOrigin? = nil,
        handles: [NodeHandle] = [],
        connectable: Bool = true,
        resizable: Bool = true,
        hidden: Bool = false,
        selected: Bool = false,
        dragging: Bool = false,
        draggable: Bool = true,
        selectable: Bool = true,
        deletable: Bool = true,
        dragHandle: String? = nil,
        width: Double? = nil,
        height: Double? = nil,
        minWidth: Double = 10,
        minHeight: Double = 10,
        maxWidth: Double = .infinity,
        maxHeight: Double = .infinity,
        initialWidth: Double? = nil,
        initialHeight: Double? = nil,
        label: String? = nil,
        measured: Dimensions? = nil
    ) {
        self.id = id
        self.position = position
        self.data = data
        self.kind = kind
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
        self.parentID = parentID
        self.zIndex = zIndex
        self.extent = extent
        self.expandParent = expandParent
        self.ariaLabel = ariaLabel
        self.origin = origin
        self.handles = handles
        self.hidden = hidden
        self.selected = selected
        self.dragging = dragging
        self.draggable = draggable
        self.selectable = selectable
        self.connectable = connectable
        self.resizable = resizable
        self.deletable = deletable
        self.dragHandle = dragHandle
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.initialWidth = initialWidth
        self.initialHeight = initialHeight
        self.label = label
        self.measured = measured
    }

    /// Initializer to create a node with minimal configuration. | 最小構成でノードを作成するためのイニシャライザ。
    ///
    /// Only essential properties (id, position, data) are passed as arguments, and others (zIndex, handles, resizable, etc.) use system-defined default values. | 必須項目（id, position, data）のみを引数に取り、それ以外（zIndex, handles, resizable 等）はシステム既定のデフォルト値が適用されます。
    ///
    /// Use the full initializer if detailed configuration is required. | 詳細な初期化が必要な場合は、全引数を網羅したフルイニシャライザを使用してください。
    public init(
        id: String,
        position: XYPosition,
        data: NodeData,
        width: Double? = nil,
        height: Double? = nil
    ) {
        self.init(
            id: id,
            position: position,
            data: data,
            kind: nil,
            sourcePosition: nil,
            targetPosition: nil,
            parentID: nil,
            zIndex: nil,
            extent: nil,
            expandParent: false,
            ariaLabel: nil,
            origin: nil,
            handles: [],
            connectable: true,
            resizable: true,
            hidden: false,
            selected: false,
            dragging: false,
            draggable: true,
            selectable: true,
            deletable: true,
            dragHandle: nil,
            width: width,
            height: height,
            minWidth: 10,
            minHeight: 10,
            maxWidth: .infinity,
            maxHeight: .infinity,
            initialWidth: nil,
            initialHeight: nil,
            label: nil,
            measured: nil
        )
    }
}

extension BaseNode: Codable where NodeData: Codable {
    enum CodingKeys: String, CodingKey {
        case id, position, data, kind
        case sourcePosition, targetPosition, parentID, zIndex, extent
        case expandParent, ariaLabel, label, origin, handles, connectable, resizable
        case hidden, draggable, selectable, deletable, dragHandle
        case width, height, minWidth, minHeight, maxWidth, maxHeight
        case initialWidth, initialHeight
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.position = try container.decode(XYPosition.self, forKey: .position)
        self.data = try container.decode(NodeData.self, forKey: .data)
        self.kind = try container.decodeIfPresent(String.self, forKey: .kind)
        self.sourcePosition = try container.decodeIfPresent(Position.self, forKey: .sourcePosition)
        self.targetPosition = try container.decodeIfPresent(Position.self, forKey: .targetPosition)
        self.parentID = try container.decodeIfPresent(String.self, forKey: .parentID)
        self.zIndex = try container.decodeIfPresent(Int.self, forKey: .zIndex)
        self.extent = try container.decodeIfPresent(NodeExtent.self, forKey: .extent)
        self.expandParent = try container.decode(Bool.self, forKey: .expandParent)
        self.ariaLabel = try container.decodeIfPresent(String.self, forKey: .ariaLabel)
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
        self.origin = try container.decodeIfPresent(NodeOrigin.self, forKey: .origin)
        self.handles = try container.decode([NodeHandle].self, forKey: .handles)
        self.connectable = try container.decode(Bool.self, forKey: .connectable)
        self.resizable = try container.decode(Bool.self, forKey: .resizable)
        self.hidden = try container.decode(Bool.self, forKey: .hidden)
        self.draggable = try container.decode(Bool.self, forKey: .draggable)
        self.selectable = try container.decode(Bool.self, forKey: .selectable)
        self.deletable = try container.decode(Bool.self, forKey: .deletable)
        self.dragHandle = try container.decodeIfPresent(String.self, forKey: .dragHandle)
        self.width = try container.decodeIfPresent(Double.self, forKey: .width)
        self.height = try container.decodeIfPresent(Double.self, forKey: .height)
        self.minWidth = try container.decode(Double.self, forKey: .minWidth)
        self.minHeight = try container.decode(Double.self, forKey: .minHeight)
        self.maxWidth = try container.decodeIfPresent(Double.self, forKey: .maxWidth) ?? .infinity
        self.maxHeight = try container.decodeIfPresent(Double.self, forKey: .maxHeight) ?? .infinity
        self.initialWidth = try container.decodeIfPresent(Double.self, forKey: .initialWidth)
        self.initialHeight = try container.decodeIfPresent(Double.self, forKey: .initialHeight)
        
        // Transient states and runtime calculation values are always initialized with default values | 過渡的状態やランタイム計算値は常にデフォルト値で初期化
        self.selected = false
        self.dragging = false
        self.measured = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(position, forKey: .position)
        try container.encode(data, forKey: .data)
        try container.encodeIfPresent(kind, forKey: .kind)
        try container.encodeIfPresent(sourcePosition, forKey: .sourcePosition)
        try container.encodeIfPresent(targetPosition, forKey: .targetPosition)
        try container.encodeIfPresent(parentID, forKey: .parentID)
        try container.encodeIfPresent(zIndex, forKey: .zIndex)
        try container.encodeIfPresent(extent, forKey: .extent)
        try container.encode(expandParent, forKey: .expandParent)
        try container.encodeIfPresent(ariaLabel, forKey: .ariaLabel)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(origin, forKey: .origin)
        try container.encode(handles, forKey: .handles)
        try container.encode(connectable, forKey: .connectable)
        try container.encode(resizable, forKey: .resizable)
        try container.encode(hidden, forKey: .hidden)
        try container.encode(draggable, forKey: .draggable)
        try container.encode(selectable, forKey: .selectable)
        try container.encode(deletable, forKey: .deletable)
        try container.encodeIfPresent(dragHandle, forKey: .dragHandle)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encode(minWidth, forKey: .minWidth)
        try container.encode(minHeight, forKey: .minHeight)
        
        // encode infinity as nil (null) since it cannot be handled in JSON | infinity は JSON で扱えないため nil (null) としてエンコード
        try container.encode(maxWidth == .infinity ? nil : maxWidth, forKey: .maxWidth)
        try container.encode(maxHeight == .infinity ? nil : maxHeight, forKey: .maxHeight)
        
        try container.encodeIfPresent(initialWidth, forKey: .initialWidth)
        try container.encodeIfPresent(initialHeight, forKey: .initialHeight)
    }
}

public typealias Node = BaseNode<EmptyPayload>

extension BaseNode: Equatable where NodeData: Equatable {
    public static func == (lhs: BaseNode<NodeData>, rhs: BaseNode<NodeData>) -> Bool {
        lhs.id == rhs.id &&
        lhs.position == rhs.position &&
        lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.minWidth == rhs.minWidth &&
        lhs.minHeight == rhs.minHeight &&
        lhs.maxWidth == rhs.maxWidth &&
        lhs.maxHeight == rhs.maxHeight &&
        lhs.selected == rhs.selected &&
        lhs.dragging == rhs.dragging &&
        lhs.draggable == rhs.draggable &&
        lhs.selectable == rhs.selectable &&
        lhs.connectable == rhs.connectable &&
        lhs.resizable == rhs.resizable &&
        lhs.deletable == rhs.deletable &&
        lhs.hidden == rhs.hidden &&
        lhs.parentID == rhs.parentID &&
        lhs.zIndex == rhs.zIndex &&
        lhs.extent == rhs.extent &&
        lhs.expandParent == rhs.expandParent &&
        lhs.origin == rhs.origin &&
        lhs.label == rhs.label &&
        lhs.ariaLabel == rhs.ariaLabel &&
        lhs.data == rhs.data &&
        lhs.handles == rhs.handles
    }
}
