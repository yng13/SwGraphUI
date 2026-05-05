public struct EmptyPayload: Sendable, Equatable, Codable {
    public init() {}
}

public enum MarkerType: String, Sendable, Codable {
    case arrow
    case arrowClosed = "arrowclosed"
}

/// Reconnection mode for edges. | エッジの再接続許可モード。
public enum ReconnectMode: String, Sendable, CaseIterable, Codable {
    case none
    case source
    case target
    case both
}

public struct EdgeMarker: Sendable, Equatable, Codable {
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

public enum ConnectionLineType: String, Sendable, Codable {
    case bezier = "default"
    case straight
    case step
    case smoothStep = "smoothstep"
    case simpleBezier = "simplebezier"
}

public struct EdgeLabelStyle: Sendable, Equatable, Codable {
    public var textColor: String?
    public var font: String?
    public var fontSize: Double?
    public var showBg: Bool
    public var bgStyle: String?
    public var bgPadding: Double
    public var bgBorderRadius: Double

    public static let `default` = EdgeLabelStyle()

    public init(
        textColor: String? = nil,
        font: String? = nil,
        fontSize: Double? = nil,
        showBg: Bool = true,
        bgStyle: String? = nil,
        bgPadding: Double = 6.0,
        bgBorderRadius: Double = 4.0
    ) {
        self.textColor = textColor
        self.font = font
        self.fontSize = fontSize
        self.showBg = showBg
        self.bgStyle = bgStyle
        self.bgPadding = bgPadding
        self.bgBorderRadius = bgBorderRadius
    }
}

public enum EdgeStrokeDash: Sendable, Equatable, Codable {
    case solid
    case dashed
    case dotted
    case custom([Double])

    public static let `default`: EdgeStrokeDash = .solid

    public var pattern: [Double] {
        switch self {
        case .solid:
            []
        case .dashed:
            [10, 5]
        case .dotted:
            [1, 5]
        case .custom(let values):
            values.filter { $0 > 0 }
        }
    }
}

public struct EdgeStrokeStyle: Sendable, Equatable, Codable {
    /// CSS-like color token, for example "#2563EB". | CSS 風の色トークン（例: "#2563EB"）。
    public var color: String?
    /// Graph-space stroke width. Runtime rendering scales it by viewport zoom. | グラフ座標系の線幅。ランタイム描画時は viewport zoom で拡大されます。
    public var width: Double?
    /// Static dash style. Animation is handled separately by `BaseEdge.animated`. | 静的な破線スタイル。アニメーションは `BaseEdge.animated` とは独立して扱われます。
    public var dash: EdgeStrokeDash

    public static let `default` = EdgeStrokeStyle()

    public init(
        color: String? = nil,
        width: Double? = nil,
        dash: EdgeStrokeDash = .solid
    ) {
        self.color = color
        self.width = width
        self.dash = dash
    }
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

public struct BaseEdge<NodeData: Sendable>: Sendable, Identifiable {
    // MARK: - User-defined properties
    public var id: String
    public var source: String
    public var target: String
    public var data: NodeData?
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
    public var labelStyle: EdgeLabelStyle
    public var strokeStyle: EdgeStrokeStyle?
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
        data: NodeData? = nil,
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
        labelStyle: EdgeLabelStyle = .default,
        strokeStyle: EdgeStrokeStyle? = nil,
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
        self.labelStyle = labelStyle
        self.strokeStyle = strokeStyle
        self.reconnectable = reconnectable
    }

    /// Initializer to create an edge with minimal configuration. | 最小構成でエッジを作成するためのイニシャライザ。
    ///
    /// Only connection info (id, source, target) and data are specified, and other properties (marker, animated, zIndex, etc.) use default values. | 接続情報（id, source, target）およびデータのみを指定し、その他（marker, animated, zIndex等）はデフォルト値が適用されます。
    ///
    /// Use the full initializer if advanced configuration is required. | 高度な設定が必要な場合は、フルイニシャライザを使用してください。
    public init(
        id: String,
        source: String,
        target: String,
        data: NodeData? = nil
    ) {
        self.init(
            id: id,
            source: source,
            target: target,
            data: data,
            kind: nil,
            sourceHandle: nil,
            targetHandle: nil,
            sourcePosition: nil,
            targetPosition: nil,
            animated: false,
            markerStart: nil,
            markerEnd: nil,
            zIndex: nil,
            ariaLabel: nil,
            interactionWidth: nil,
            curvature: nil,
            hidden: false,
            deletable: true,
            selectable: true,
            selected: false,
            label: nil,
            labelStyle: .default,
            strokeStyle: nil,
            reconnectable: .none
        )
    }
}

extension BaseEdge: Codable where NodeData: Codable {
    enum CodingKeys: String, CodingKey {
        case id, source, target, data, kind
        case sourceHandle, targetHandle, sourcePosition, targetPosition
        case animated, markerStart, markerEnd, zIndex, ariaLabel
        case interactionWidth, curvature, label, labelStyle, strokeStyle, reconnectable
        case hidden, deletable, selectable
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.source = try container.decode(String.self, forKey: .source)
        self.target = try container.decode(String.self, forKey: .target)
        self.data = try container.decodeIfPresent(NodeData.self, forKey: .data)
        self.kind = try container.decodeIfPresent(String.self, forKey: .kind)
        self.sourceHandle = try container.decodeIfPresent(String.self, forKey: .sourceHandle)
        self.targetHandle = try container.decodeIfPresent(String.self, forKey: .targetHandle)
        self.sourcePosition = try container.decodeIfPresent(Position.self, forKey: .sourcePosition)
        self.targetPosition = try container.decodeIfPresent(Position.self, forKey: .targetPosition)
        self.animated = try container.decode(Bool.self, forKey: .animated)
        self.markerStart = try container.decodeIfPresent(EdgeMarker.self, forKey: .markerStart)
        self.markerEnd = try container.decodeIfPresent(EdgeMarker.self, forKey: .markerEnd)
        self.zIndex = try container.decodeIfPresent(Int.self, forKey: .zIndex)
        self.ariaLabel = try container.decodeIfPresent(String.self, forKey: .ariaLabel)
        self.interactionWidth = try container.decodeIfPresent(Double.self, forKey: .interactionWidth)
        self.curvature = try container.decodeIfPresent(Double.self, forKey: .curvature)
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
        self.labelStyle = try container.decode(EdgeLabelStyle.self, forKey: .labelStyle)
        self.strokeStyle = try container.decodeIfPresent(EdgeStrokeStyle.self, forKey: .strokeStyle)
        self.reconnectable = try container.decode(ReconnectMode.self, forKey: .reconnectable)
        self.hidden = try container.decode(Bool.self, forKey: .hidden)
        self.deletable = try container.decode(Bool.self, forKey: .deletable)
        self.selectable = try container.decode(Bool.self, forKey: .selectable)
        
        // Transient states are always initialized with default values | 過渡的状態は常にデフォルト値で初期化
        self.selected = false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(source, forKey: .source)
        try container.encode(target, forKey: .target)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(kind, forKey: .kind)
        try container.encodeIfPresent(sourceHandle, forKey: .sourceHandle)
        try container.encodeIfPresent(targetHandle, forKey: .targetHandle)
        try container.encodeIfPresent(sourcePosition, forKey: .sourcePosition)
        try container.encodeIfPresent(targetPosition, forKey: .targetPosition)
        try container.encode(animated, forKey: .animated)
        try container.encodeIfPresent(markerStart, forKey: .markerStart)
        try container.encodeIfPresent(markerEnd, forKey: .markerEnd)
        try container.encodeIfPresent(zIndex, forKey: .zIndex)
        try container.encodeIfPresent(ariaLabel, forKey: .ariaLabel)
        try container.encodeIfPresent(interactionWidth, forKey: .interactionWidth)
        try container.encodeIfPresent(curvature, forKey: .curvature)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encode(labelStyle, forKey: .labelStyle)
        try container.encodeIfPresent(strokeStyle, forKey: .strokeStyle)
        try container.encode(reconnectable, forKey: .reconnectable)
        try container.encode(hidden, forKey: .hidden)
        try container.encode(deletable, forKey: .deletable)
        try container.encode(selectable, forKey: .selectable)
    }
}

public typealias Edge = BaseEdge<EmptyPayload>

extension BaseEdge: Equatable where NodeData: Equatable {
    public static func == (lhs: BaseEdge<NodeData>, rhs: BaseEdge<NodeData>) -> Bool {
        lhs.id == rhs.id &&
        lhs.source == rhs.source &&
        lhs.target == rhs.target &&
        lhs.data == rhs.data &&
        lhs.kind == rhs.kind &&
        lhs.sourceHandle == rhs.sourceHandle &&
        lhs.targetHandle == rhs.targetHandle &&
        lhs.sourcePosition == rhs.sourcePosition &&
        lhs.targetPosition == rhs.targetPosition &&
        lhs.animated == rhs.animated &&
        lhs.markerStart == rhs.markerStart &&
        lhs.markerEnd == rhs.markerEnd &&
        lhs.zIndex == rhs.zIndex &&
        lhs.ariaLabel == rhs.ariaLabel &&
        lhs.interactionWidth == rhs.interactionWidth &&
        lhs.curvature == rhs.curvature &&
        lhs.label == rhs.label &&
        lhs.labelStyle == rhs.labelStyle &&
        lhs.strokeStyle == rhs.strokeStyle &&
        lhs.reconnectable == rhs.reconnectable &&
        lhs.hidden == rhs.hidden &&
        lhs.deletable == rhs.deletable &&
        lhs.selectable == rhs.selectable &&
        lhs.selected == rhs.selected
    }
}
