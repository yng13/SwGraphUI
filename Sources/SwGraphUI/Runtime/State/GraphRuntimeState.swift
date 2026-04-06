import Foundation
import Observation

/// 
/// グラフの実行時状態（一時的な状態）を一括管理するクラス。
/// 

/// ノードの選択状態
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

/// ホバー状態
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

/// ドラッグ状態
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

    public mutating func startDrag<Data>(
        nodes: [BaseNode<Data>],
        nodeLookup: [String: BaseNode<Data>],
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

/// 接続操作のモード（新規または再接続）
public enum ConnectionActionType: Sendable, Equatable {
    case connect
    case reconnect(edgeID: String, isSource: Bool)
    
    /// 再接続中のエッジID（新規接続時はnil）
    public var edgeID: String? {
        if case .reconnect(let id, _) = self { return id }
        return nil
    }
}

/// 進行中の接続状態
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

/// 接続操作の実行時状態
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

/// ビューポート状態
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
}

/// ハンドルの実測座標を保持する状態
public struct HandleMeasurementState: Sendable, Equatable {
    public internal(set) var positions: [HandleKey: XYPosition] = [:]
    
    public init(positions: [HandleKey: XYPosition] = [:]) {
        self.positions = positions
    }
}

/// グラフの実行時状態（一時的な状態）を一括管理するクラス。
@Observable
@MainActor
public final class GraphRuntimeState: Sendable {
    public var selection: SelectionState
    public var hover: HoverState
    public var drag: DragState
    public var connection: ConnectionState
    public var viewport: ViewportState
    public var handleMeasurements: HandleMeasurementState
    
    /// 矩形選択（Marquee）の状態。
    public struct MarqueeState: Sendable, Equatable {
        public let startPos: CGPoint
        public var currentPos: CGPoint
        
        /// ビューポート座標系での矩形領域。
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
    
    public init(
        selection: SelectionState = .init(),
        hover: HoverState = .init(),
        drag: DragState = .init(),
        connection: ConnectionState = .init(),
        viewport: ViewportState = .init(),
        handleMeasurements: HandleMeasurementState = .init()
    ) {
        self.selection = selection
        self.hover = hover
        self.drag = drag
        self.connection = connection
        self.viewport = viewport
        self.handleMeasurements = handleMeasurements
    }
}
