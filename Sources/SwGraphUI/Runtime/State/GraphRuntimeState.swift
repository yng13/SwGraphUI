import Foundation

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

    public mutating func toggleNode(id: String) {
        if selectedNodeIDs.contains(id) {
            selectedNodeIDs.remove(id)
        } else {
            selectedNodeIDs.insert(id)
        }
    }

    public mutating func selectEdge(id: String) {
        selectedEdgeIDs.insert(id)
    }

    public mutating func deselectEdge(id: String) {
        selectedEdgeIDs.remove(id)
    }

    public mutating func toggleEdge(id: String) {
        if selectedEdgeIDs.contains(id) {
            selectedEdgeIDs.remove(id)
        } else {
            selectedEdgeIDs.insert(id)
        }
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

    public mutating func clear() {
        hoveredNodeID = nil
        hoveredEdgeID = nil
    }
}

public struct DragState: Sendable, Equatable {
    public var draggedNodes: [NodeDragItem]
    public var currentPointer: XYPosition?

    public init(draggedNodes: [NodeDragItem] = [], currentPointer: XYPosition? = nil) {
        self.draggedNodes = draggedNodes
        self.currentPointer = currentPointer
    }

    public var isDragging: Bool {
        !draggedNodes.isEmpty
    }

    /// ドラッグを開始します（階層構造対応）。
    /// - Parameters:
    ///   - nodes: ドラッグ対象のノード。
    ///   - nodeLookup: 親チェーンを解決するための全ノードマップ。
    ///   - pointer: グラフ空間におけるポインタ座標。
    public mutating func startDrag<Data>(
        nodes: [BaseNode<Data>],
        nodeLookup: [String: BaseNode<Data>],
        pointer: XYPosition
    ) {
        self.draggedNodes = nodes.map { node in
            // 絶対座標を解決した上でオフセットを記録
            let absoluteTopLeft = NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: nodeLookup)
            let distance = pointer - absoluteTopLeft
            return NodeDragItem(id: node.id, lastPosition: absoluteTopLeft, distance: distance)
        }
        self.currentPointer = pointer
    }
    
    /// ドラッグを開始します（既存互換・単一階層用）。
    /// - Warning: 階層構造を持つノードが含まれる場合、このメソッドでは正確なドラッグオフセットが計算されません。
    @available(*, deprecated, message: "Use startDrag(nodes:nodeLookup:pointer:) for hierarchical graphs.")
    public mutating func startDrag<Data>(nodes: [BaseNode<Data>], pointer: XYPosition) {
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        startDrag(nodes: nodes, nodeLookup: lookup, pointer: pointer)
    }

    public mutating func updateDrag(to pointer: XYPosition) {
        self.currentPointer = pointer
    }

    public mutating func stopDrag() {
        self.draggedNodes.removeAll()
        self.currentPointer = nil
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

    public mutating func start(fromNodeID: String, fromHandleID: String?, fromHandleType: HandleType, at position: XYPosition) {
        self.active = .init(fromNodeID: fromNodeID, fromHandleID: fromHandleID, fromHandleType: fromHandleType, currentPointer: position)
    }

    public mutating func update(to position: XYPosition, targetNodeID: String? = nil, targetHandleID: String? = nil) {
        active?.currentPointer = position
        active?.targetNodeID = targetNodeID
        active?.targetHandleID = targetHandleID
    }

    public mutating func end() {
        self.active = nil
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

    public mutating func panBy(dx: Double, dy: Double) {
        self.viewport = ViewportManager.calculatePan(current: viewport, delta: .init(x: dx, y: dy))
    }

    public mutating func zoom(at screenPoint: XYPosition, factor: Double, minZoom: Double = 0.5, maxZoom: Double = 2.0) {
        self.viewport = ViewportManager.calculateZoomAtPoint(
            current: viewport,
            factor: factor,
            at: screenPoint,
            minZoom: minZoom,
            maxZoom: maxZoom
        )
    }
    
    /// 指定された要素が画面内に収まるようにビューポートを調整します（階層構造対応）。
    public mutating func fitView<Data>(
        nodes: [BaseNode<Data>],
        nodeLookup: [String: BaseNode<Data>],
        in size: Dimensions,
        padding: GeometryAlgorithms.Padding = .all(.relative(0.1)),
        minZoom: Double = 0.5,
        maxZoom: Double = 2.0
    ) {
        self.viewport = ViewportManager.calculateFitView(
            nodes: nodes,
            nodeLookup: nodeLookup,
            in: size,
            minZoom: minZoom,
            maxZoom: maxZoom,
            padding: padding
        )
    }
    
    /// 指定された要素が画面内に収まるようにビューポートを調整します（既存互換用）。
    /// - Warning: 階層構造を持つノードが含まれる場合、このメソッドでは正確な Bounds が計算されません。
    @available(*, deprecated, message: "Use fitView(nodes:nodeLookup:in:...) for hierarchical graphs.")
    public mutating func fitView<Data>(
        nodes: [BaseNode<Data>],
        in size: Dimensions,
        padding: GeometryAlgorithms.Padding = .all(.relative(0.1)),
        minZoom: Double = 0.5,
        maxZoom: Double = 2.0
    ) {
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        fitView(nodes: nodes, nodeLookup: lookup, in: size, padding: padding, minZoom: minZoom, maxZoom: maxZoom)
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
