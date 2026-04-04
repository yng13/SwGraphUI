public struct SelectionState: Sendable, Equatable {
    public private(set) var selectedNodeIDs: Set<String>
    public private(set) var selectedEdgeIDs: Set<String>

    public init(selectedNodeIDs: Set<String> = [], selectedEdgeIDs: Set<String> = []) {
        self.selectedNodeIDs = selectedNodeIDs
        self.selectedEdgeIDs = selectedEdgeIDs
    }

    public mutating func selectNode(id: String) {
        selectedNodeIDs.insert(id)
    }

    public mutating func deselectNode(id: String) {
        selectedNodeIDs.remove(id)
    }

    public mutating func selectEdge(id: String) {
        selectedEdgeIDs.insert(id)
    }

    public mutating func deselectEdge(id: String) {
        selectedEdgeIDs.remove(id)
    }

    public mutating func clear() {
        selectedNodeIDs.removeAll()
        selectedEdgeIDs.removeAll()
    }
}

public struct HoverState: Sendable, Equatable {
    public var hoveredNodeID: String?
    public var hoveredEdgeID: String?

    public init(hoveredNodeID: String? = nil, hoveredEdgeID: String? = nil) {
        self.hoveredNodeID = hoveredNodeID
        self.hoveredEdgeID = hoveredEdgeID
    }
}

public struct DragState: Sendable, Equatable {
    public var draggedNodeIDs: [String]
    public var dragOrigin: XYPosition?
    public var currentPosition: XYPosition?

    public init(draggedNodeIDs: [String] = [], dragOrigin: XYPosition? = nil, currentPosition: XYPosition? = nil) {
        self.draggedNodeIDs = draggedNodeIDs
        self.dragOrigin = dragOrigin
        self.currentPosition = currentPosition
    }

    public var isDragging: Bool {
        !draggedNodeIDs.isEmpty
    }
}

public struct ConnectionInProgressState: Sendable, Equatable {
    public var fromNodeID: String
    public var fromHandleID: String?
    public var fromHandleType: HandleType
    public var currentPointer: XYPosition
    public var targetNodeID: String?
    public var targetHandleID: String?

    public init(
        fromNodeID: String,
        fromHandleID: String? = nil,
        fromHandleType: HandleType,
        currentPointer: XYPosition,
        targetNodeID: String? = nil,
        targetHandleID: String? = nil
    ) {
        self.fromNodeID = fromNodeID
        self.fromHandleID = fromHandleID
        self.fromHandleType = fromHandleType
        self.currentPointer = currentPointer
        self.targetNodeID = targetNodeID
        self.targetHandleID = targetHandleID
    }
}

public struct ConnectionRuntimeState: Sendable, Equatable {
    public var active: ConnectionInProgressState?

    public init(active: ConnectionInProgressState? = nil) {
        self.active = active
    }

    public var isConnecting: Bool {
        active != nil
    }
}

public struct ViewportState: Sendable, Equatable {
    public private(set) var viewport: Viewport

    public init(viewport: Viewport = .init(x: 0, y: 0, zoom: 1)) {
        self.viewport = viewport
    }

    public mutating func setViewport(_ viewport: Viewport) {
        self.viewport = viewport
    }

    public mutating func panBy(x: Double, y: Double) {
        viewport.x += x
        viewport.y += y
    }

    public mutating func zoomTo(_ zoom: Double) {
        viewport.zoom = zoom
    }
}

public struct GraphRuntimeState: Sendable, Equatable {
    public var selection: SelectionState
    public var hover: HoverState
    public var drag: DragState
    public var connection: ConnectionRuntimeState
    public var viewport: ViewportState

    public init(
        selection: SelectionState = .init(),
        hover: HoverState = .init(),
        drag: DragState = .init(),
        connection: ConnectionRuntimeState = .init(),
        viewport: ViewportState = .init()
    ) {
        self.selection = selection
        self.hover = hover
        self.drag = drag
        self.connection = connection
        self.viewport = viewport
    }
}
