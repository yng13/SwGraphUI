import Foundation
import Observation

/// Class that centrally manages the runtime state (temporary state) of the graph. | グラフの実行時状態（一時的な状態）を一括管理するクラス。

/// Node selection state | ノードの選択状態
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

/// Hover state | ホバー状態
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

/// Drag state | ドラッグ状態
public struct DragState: Sendable, Equatable {
    var draggedNodes: [NodeDragItem]
    public var currentPointer: XYPosition?

    public init() {
        self.draggedNodes = []
        self.currentPointer = nil
    }

    init(draggedNodes: [NodeDragItem], currentPointer: XYPosition? = nil) {
        self.draggedNodes = draggedNodes
        self.currentPointer = currentPointer
    }

    public var isDragging: Bool {
        !draggedNodes.isEmpty
    }

    public mutating func startDrag<NodeData>(
        nodes: [BaseNode<NodeData>],
        nodeLookup: [String: BaseNode<NodeData>],
        pointer: XYPosition
    ) {
        self.draggedNodes = nodes.map { node in
            let absoluteTopLeft = NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: nodeLookup)
            let distance = pointer - absoluteTopLeft
            return NodeDragItem(id: node.id, lastPosition: absoluteTopLeft, distance: distance)
        }
        self.currentPointer = pointer
    }
    
    public mutating func updateDrag(to pointer: XYPosition) {
        self.currentPointer = pointer
    }

    public mutating func stopDrag() {
        self.draggedNodes.removeAll()
        self.currentPointer = nil
    }
}

/// Connection operation mode (new or reconnect) | 接続操作のモード（新規または再接続）
public enum ConnectionActionType: Sendable, Equatable {
    case connect
    case reconnect(edgeID: String, isSource: Bool)
    
    /// ID of the edge being reconnected (nil during new connection) | 再接続中のエッジID（新規接続時はnil）
    public var edgeID: String? {
        if case .reconnect(let id, _) = self { return id }
        return nil
    }
}

/// State of a connection in progress | 進行中の接続状態
public struct ConnectionInProgressState: Sendable, Equatable {
    public var mode: ConnectionActionType
    public var fromNodeID: String
    public var fromHandleID: String?
    public var fromHandleType: HandleType
    public var fromHandlePosition: Position
    public var fromPosition: XYPosition
    public var currentPointer: XYPosition
    public var targetNodeID: String?
    public var targetHandleID: String?
    public var targetHandlePosition: Position?

    public init(
        mode: ConnectionActionType = .connect,
        fromNodeID: String,
        fromHandleID: String? = nil,
        fromHandleType: HandleType,
        fromHandlePosition: Position,
        fromPosition: XYPosition,
        currentPointer: XYPosition,
        targetNodeID: String? = nil,
        targetHandleID: String? = nil,
        targetHandlePosition: Position? = nil
    ) {
        self.mode = mode
        self.fromNodeID = fromNodeID
        self.fromHandleID = fromHandleID
        self.fromHandleType = fromHandleType
        self.fromHandlePosition = fromHandlePosition
        self.fromPosition = fromPosition
        self.currentPointer = currentPointer
        self.targetNodeID = targetNodeID
        self.targetHandleID = targetHandleID
        self.targetHandlePosition = targetHandlePosition
    }
}

/// Runtime state of connection operations | 接続操作の実行時状態
public struct ConnectionState: Sendable, Equatable {
    public var active: ConnectionInProgressState?

    public init(active: ConnectionInProgressState? = nil) {
        self.active = active
    }

    public var isConnecting: Bool {
        active != nil
    }

    public mutating func start(
        fromNodeID: String,
        fromHandleID: String?,
        fromHandleType: HandleType,
        fromHandlePosition: Position,
        fromPosition: XYPosition,
        at pointer: XYPosition,
        mode: ConnectionActionType = .connect
    ) {
        self.active = .init(
            mode: mode,
            fromNodeID: fromNodeID,
            fromHandleID: fromHandleID,
            fromHandleType: fromHandleType,
            fromHandlePosition: fromHandlePosition,
            fromPosition: fromPosition,
            currentPointer: pointer
        )
    }

    public mutating func update(to pointer: XYPosition, targetNodeID: String? = nil, targetHandleID: String? = nil, targetHandlePosition: Position? = nil) {
        guard var activeState = active else { return }
        activeState.currentPointer = pointer
        activeState.targetNodeID = targetNodeID
        activeState.targetHandleID = targetHandleID
        activeState.targetHandlePosition = targetHandlePosition
        self.active = activeState
    }

    public mutating func end() {
        self.active = nil
    }
}

/// Viewport state | ビューポート状態
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
    
    public mutating func fitView<NodeData>(
        nodes: [BaseNode<NodeData>],
        nodeLookup: [String: BaseNode<NodeData>],
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

    /// Converts screen coordinates to coordinates in graph space. | スクリーン座標をグラフ空間の座標に変換します。
    public func toGraphSpace(_ screenPoint: XYPosition) -> XYPosition {
        screenPoint.fromScreen(viewport: viewport)
    }
}

/// State holding the measured coordinates of handles | ハンドルの実測座標を保持する状態
public struct HandleMeasurementState: Sendable, Equatable {
    public internal(set) var positions: [HandleKey: XYPosition] = [:]
    
    public init(positions: [HandleKey: XYPosition] = [:]) {
        self.positions = positions
    }
}

/// State of auto-pan (automatic scrolling) | オートパン（自動スクロール）の状態
public struct AutoPanState: Sendable, Equatable {
    /// Whether auto-pan is currently active | オートパンが現在動作中かどうか
    public var isActive: Bool = false
    /// Current mouse/pointer position (screen coordinate system) | 現在のマウス/ポインタ位置（スクリーン座標系）
    public var mousePosition: XYPosition?
    /// Current calculated velocity (increment amount) | 現在の算出速度（加算量）
    public var velocity: XYPosition = .zero
    /// Dimensions of the drawing container (reference for velocity calculation) | 描画コンテナの寸法（速度計算の基準）
    public var containerSize: Dimensions?
    
    public init(
        isActive: Bool = false,
        mousePosition: XYPosition? = nil,
        velocity: XYPosition = .zero,
        containerSize: Dimensions? = nil
    ) {
        self.isActive = isActive
        self.mousePosition = mousePosition
        self.velocity = velocity
        self.containerSize = containerSize
    }
    
    public mutating func clear() {
        isActive = false
        mousePosition = nil
        velocity = .zero
    }
}

/// Interaction control state | インタラクション制御状態
public struct InteractivityState: Sendable, Equatable {
    public var nodesDraggable: Bool = true
    public var nodesConnectable: Bool = true
    public var elementsSelectable: Bool = true
    public var panOnDrag: Bool
    public var zoomOnScroll: Bool
    public var zoomOnPinch: Bool
    public var minZoom: Double
    public var maxZoom: Double
    
    public init(
        nodesDraggable: Bool = true,
        nodesConnectable: Bool = true,
        elementsSelectable: Bool = true,
        panOnDrag: Bool = true,
        zoomOnScroll: Bool = true,
        zoomOnPinch: Bool = true,
        minZoom: Double = 0.5,
        maxZoom: Double = 2.0
    ) {
        self.nodesDraggable = nodesDraggable
        self.nodesConnectable = nodesConnectable
        self.elementsSelectable = elementsSelectable
        self.panOnDrag = panOnDrag
        self.zoomOnScroll = zoomOnScroll
        self.zoomOnPinch = zoomOnPinch
        self.minZoom = minZoom
        self.maxZoom = maxZoom
    }
}

/// Class that centrally manages the runtime state (temporary state) of the graph. | グラフの実行時状態（一時的な状態）を一括管理するクラス。
@Observable
@MainActor
public final class GraphRuntimeState: Sendable {
    public var selection: SelectionState
    public var hover: HoverState
    public var drag: DragState
    public var connection: ConnectionState
    public var viewport: ViewportState
    public var handleMeasurements: HandleMeasurementState
    public var autoPan: AutoPanState
    public var interactivity: InteractivityState
    
    /// State of marquee selection (Marquee). | 矩形選択（Marquee）の状態。
    public struct MarqueeState: Sendable, Equatable {
        public let startPos: CGPoint
        public var currentPos: CGPoint
        
        /// Rectangular area in the viewport coordinate system. | ビューポート座標系での矩形領域。
        public var rect: CGRect {
            CGRect(
                x: min(startPos.x, currentPos.x),
                y: min(startPos.y, currentPos.y),
                width: abs(startPos.x - currentPos.x),
                height: abs(startPos.y - currentPos.y)
            )
        }
    }
    
    public var marquee: MarqueeState?
    
    /// List of node IDs with determined rendering order (accounting for zIndex and hierarchy). | 描画順序が確定済みのノード ID リスト（zIndex や階層を考慮）。
    public var sortedNodeIDs: [String] = []
    
    /// Cache of absolute coordinates. Internal use to reduce recalculation costs. | 絶対座標のキャッシュ。再計算コストを削減するための内部用。
    public var absolutePositionCache: [String: XYPosition] = [:]
    /// Whether the cache is valid. Becomes false when node positions are changed. | キャッシュが有効かどうか。ノードの位置が変更されたら false になります。
    public var isAbsolutePositionCacheValid: Bool = false
    /// Fallback distance between node border and handle center used by estimated handle positions. | 推測ハンドル座標で使う、ノード境界とハンドル中心の距離。
    public var handleAnchorOffset: Double = 8
    /// Optional graph-space snap grid for manual node dragging. | 手動ノードドラッグ用の graph-space スナップグリッド。
    public var snapGrid: SnapGrid?
    
    public init(
        selection: SelectionState = .init(),
        hover: HoverState = .init(),
        drag: DragState = .init(),
        connection: ConnectionState = .init(),
        viewport: ViewportState = .init(),
        handleMeasurements: HandleMeasurementState = .init(),
        autoPan: AutoPanState = .init(),
        interactivity: InteractivityState = .init(),
        sortedNodeIDs: [String] = [],
        absolutePositionCache: [String: XYPosition] = [:],
        handleAnchorOffset: Double = 8,
        snapGrid: SnapGrid? = nil
    ) {
        self.selection = selection
        self.hover = hover
        self.drag = drag
        self.connection = connection
        self.viewport = viewport
        self.handleMeasurements = handleMeasurements
        self.autoPan = autoPan
        self.interactivity = interactivity
        self.sortedNodeIDs = sortedNodeIDs
        self.absolutePositionCache = absolutePositionCache
        self.isAbsolutePositionCacheValid = false
        self.handleAnchorOffset = handleAnchorOffset
        self.snapGrid = snapGrid
    }
}
