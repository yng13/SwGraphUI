import SwiftUI
import Observation

/// グラフの状態管理を担う中心的なクラス。
/// ノード、エッジ、ビューポート、選択状態などを一括管理し、UIへのリアクティブな更新を提供します。
@Observable
@MainActor
public final class GraphStore<NodeData: Sendable>: Sendable {
    // MARK: - Core State
    public var nodes: [BaseNode<NodeData>] = [] {
        didSet {
            if !suspendAutomaticOrderRecalculation {
                recalculateSortedNodeIDs()
            }
            runtimeState.isAbsolutePositionCacheValid = false
        }
    }
    public var edges: [BaseEdge<NodeData>] = []
    
    // MARK: - Runtime State
    public var runtimeState: GraphRuntimeState
    
    // MARK: - Interaction State
    private var autoPanTimer: Timer?
    private var suspendAutomaticOrderRecalculation = false
    
    // MARK: - Undo/Redo State
    public var undoManager: UndoManager?
    private var dragStartSnapshot: GraphSnapshot<NodeData>?
    private var resizeStartSnapshot: GraphSnapshot<NodeData>?
    
    // MARK: - Selection Accessors
    public var selectedNodes: [BaseNode<NodeData>] {
        nodes.filter { $0.selected }
    }
    
    public var selectedEdges: [BaseEdge<NodeData>] {
        edges.filter { $0.selected }
    }
    
    public var nodeLookup: [String: BaseNode<NodeData>] {
        Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
    }
    
    public init(
        nodes: [BaseNode<NodeData>] = [],
        edges: [BaseEdge<NodeData>] = [],
        runtimeState: GraphRuntimeState = .init(),
        undoManager: UndoManager? = nil
    ) {
        self.nodes = nodes
        self.edges = edges
        self.runtimeState = runtimeState
        self.undoManager = undoManager
        
        recalculateSortedNodeIDs()
    }

    private func withNodeOrderRecalculationSuspended(_ body: () -> Void) {
        let previous = suspendAutomaticOrderRecalculation
        suspendAutomaticOrderRecalculation = true
        body()
        suspendAutomaticOrderRecalculation = previous
    }

    private func nodeOrderSignature(for node: BaseNode<NodeData>) -> String {
        [
            node.id,
            node.parentID ?? "",
            String(node.zIndex ?? 0),
            node.kind ?? "",
            String(node.hidden)
        ].joined(separator: "|")
    }
    
    // MARK: - Measurement & Positioning API
    
    /// ハンドルの実測座標を更新します。
    public func updateHandlePosition(key: HandleKey, absolutePosition: XYPosition) {
        runtimeState.handleMeasurements.positions[key] = absolutePosition
    }
    
    /// ハンドルの実測座標を取得します（存在すれば）。
    public func measuredHandlePosition(for key: HandleKey) -> XYPosition? {
        runtimeState.handleMeasurements.positions[key]
    }
    
    /// ハンドルの解決済み座標を取得します（実測値を優先し、なければ推測を使用）。
    public func resolvedHandlePosition(for key: HandleKey) -> XYPosition {
        // 1. 実測値があれば最優先
        if let measured = measuredHandlePosition(for: key) {
            return measured
        }
        
        // 2. なければ従来の数学的推測にフォールバック
        guard let node = node(id: key.nodeID) else { return .zero }
        let absPos = absolutePosition(for: key.nodeID)
        return ConnectionInteractionManager.calcHandlePosition(
            absolutePosition: absPos,
            dimensions: node.measured ?? Dimensions(width: 100, height: 50),
            placement: key.placement
        )
    }

    // MARK: - Node Operations
    public func node(id: String) -> BaseNode<NodeData>? {
        nodes.first { $0.id == id }
    }

    public func updateNodePosition(id: String, position: XYPosition) {
        let lookup = self.nodeLookup
        if let node = lookup[id], let index = nodes.firstIndex(where: { $0.id == id }) {
            // 指定された相対座標を絶対座標に変換してから制約を適用
            let targetAbsPos = NodePositioningAlgorithms.toAbsolutePosition(
                position,
                parent: node.parentID.flatMap { lookup[$0] },
                nodeLookup: lookup
            )
            
            // 常に制約を適用
            let constrainedPos = DragManager.applyConstraints(
                to: targetAbsPos,
                node: node,
                nodeLookup: lookup,
                applySnap: false
            )
            
            withNodeOrderRecalculationSuspended {
                nodes[index].position = constrainedPos
            }
            runtimeState.isAbsolutePositionCacheValid = false
        }
    }

    /// 自動測定ロジックによってノードの実測サイズを更新します。
    public func updateNodeDimensions(id: String, dimensions: Dimensions) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            // 差分ガード：値が同じ場合は更新をスキップして再描画を抑制
            if nodes[index].measured != dimensions {
                withNodeOrderRecalculationSuspended {
                    nodes[index].measured = dimensions
                }
            }
        }
    }

    /// リサイズ操作によってノードの寸法と位置を更新します。
    /// - Parameters:
    ///   - id: 更新対象ノード ID
    ///   - width: リサイズ後の幅
    ///   - height: リサイズ後の高さ
    ///   - position: リサイズ後の位置
    public func updateNodeDimensionsAfterResize(id: String, width: Double, height: Double, position: XYPosition) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            withNodeOrderRecalculationSuspended {
                nodes[index].width = width
                nodes[index].height = height
                nodes[index].position = position
                
                // measured も同期。
                nodes[index].measured = Dimensions(width: width, height: height)
            }
            runtimeState.isAbsolutePositionCacheValid = false
        }
    }
    
    public func startResizing(id: String) {
        self.resizeStartSnapshot = self.snapshot()
    }
    
    /// リサイズ操作を確定し、実効変化がある場合のみ Undo 履歴を登録します。
    public func stopResizing() {
        if let before = resizeStartSnapshot {
            let after = self.snapshot()
            let hasChanged = zip(before.nodes, after.nodes).contains { b, a in
                let dx = (a.position.x - b.position.x)
                let dy = (a.position.y - b.position.y)
                let dw = (a.width ?? 0) - (b.width ?? 0)
                let dh = (a.height ?? 0) - (b.height ?? 0)
                // 座標またはサイズに有意な差（0.1px 以上の変化）があるか
                return (dx * dx + dy * dy > 0.01) || (abs(dw) > 0.1) || (abs(dh) > 0.1)
            } || before.nodes.count != after.nodes.count
            
            if hasChanged {
                registerUndo(title: "ノードのリサイズ", snapshot: before)
            }
        }
        self.resizeStartSnapshot = nil
    }

    public func absolutePosition(for nodeID: String) -> XYPosition {
        if !runtimeState.isAbsolutePositionCacheValid {
            recalculateAbsolutePositions()
        }
        return runtimeState.absolutePositionCache[nodeID] ?? .zero
    }

    /// 全ノードの絶対座標を一括計算してキャッシュします。
    public func recalculateAbsolutePositions() {
        let lookup = self.nodeLookup
        var cache: [String: XYPosition] = [:]
        
        let sortedIDs = runtimeState.sortedNodeIDs
        // トポロジカル順に近い順序（sortedNodeIDs は深さ考慮済み）で辿れば効率的
        for id in sortedIDs {
            if let node = lookup[id] {
                cache[id] = NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: lookup)
            }
        }
        
        runtimeState.absolutePositionCache = cache
        runtimeState.isAbsolutePositionCacheValid = true
    }

    // MARK: - Edge Operations
    public func edge(id: String) -> BaseEdge<NodeData>? {
        edges.first { $0.id == id }
    }

    public func addEdge(_ edge: BaseEdge<NodeData>) {
        edges.append(edge)
    }

    // MARK: - Viewport Operations
    public func setViewport(_ viewport: Viewport) {
        guard viewport.x.isFinite, viewport.y.isFinite, viewport.zoom.isFinite, viewport.zoom > 0 else { return }
        runtimeState.viewport.setViewport(viewport)
    }
    
    public func pan(by delta: XYPosition) {
        var state = runtimeState.viewport
        state.panBy(dx: delta.x, dy: delta.y)
        runtimeState.viewport = state
    }
    
    public func zoom(at screenPoint: XYPosition? = nil, factor: Double) {
        guard factor.isFinite, factor > 0 else { return }
        let center = screenPoint ?? .zero
        let newViewport = ViewportManager.calculateZoomAtPoint(
            current: runtimeState.viewport.viewport,
            factor: factor,
            at: center,
            minZoom: runtimeState.interactivity.minZoom,
            maxZoom: runtimeState.interactivity.maxZoom
        )
        runtimeState.viewport.setViewport(newViewport)
    }

    public func zoomIn() {
        zoom(factor: 1.2)
    }

    public func zoomOut() {
        zoom(factor: 0.8)
    }

    public func fitView(
        in size: Dimensions = Dimensions(width: 800, height: 600),
        padding: GeometryAlgorithms.Padding = .all(.relative(0.1))
    ) {
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        let prevViewport = runtimeState.viewport.viewport
        
        runtimeState.viewport.fitView(
            nodes: nodes,
            nodeLookup: lookup,
            in: size,
            padding: padding,
            minZoom: runtimeState.interactivity.minZoom,
            maxZoom: runtimeState.interactivity.maxZoom
        )
        
        if runtimeState.viewport.viewport != prevViewport {
            registerViewportUndo(title: "表示範囲を調整", previousViewport: prevViewport)
        }
    }
    
    // MARK: - Auto Pan Operations
    public func setContainerSize(_ size: Dimensions) {
        runtimeState.autoPan.containerSize = size
    }
    
    public func updateAutoPan(at screenPointer: XYPosition) {
        guard screenPointer.x.isFinite, screenPointer.y.isFinite else { return }
        runtimeState.autoPan.mousePosition = screenPointer
        
        guard let containerSize = runtimeState.autoPan.containerSize,
              containerSize.width > 0, containerSize.height > 0 else {
            return
        }
        
        let velocity = AutoPanAlgorithms.calculateVelocity(
            mousePosition: screenPointer,
            containerSize: containerSize,
            speed: 25
        )
        
        if velocity != .zero {
            if autoPanTimer == nil {
                startAutoPanTimer()
            }
            runtimeState.autoPan.isActive = true
            runtimeState.autoPan.velocity = velocity
        } else {
            runtimeState.autoPan.isActive = false
        }
    }
    
    private func startAutoPanTimer() {
        guard autoPanTimer == nil else { return }
        let timer = Timer(timeInterval: 0.02, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.handleAutoPanTick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        autoPanTimer = timer
    }
    
    private func stopAutoPanTimer() {
        autoPanTimer?.invalidate()
        autoPanTimer = nil
        runtimeState.autoPan.clear()
    }
    
    private func handleAutoPanTick() {
        guard let mousePos = runtimeState.autoPan.mousePosition,
              let containerSize = runtimeState.autoPan.containerSize else {
            stopAutoPanTimer()
            return
        }
        
        let velocity = AutoPanAlgorithms.calculateVelocity(
            mousePosition: mousePos,
            containerSize: containerSize,
            speed: 25
        )
        
        guard velocity != .zero else {
            runtimeState.autoPan.isActive = false
            return
        }
        
        runtimeState.autoPan.isActive = true
        runtimeState.autoPan.velocity = velocity
        pan(by: velocity)
        
        let viewport = runtimeState.viewport.viewport
        let newGraphPointer = mousePos.fromScreen(viewport: viewport)
        
        if runtimeState.drag.isDragging {
            updateDragging(to: newGraphPointer)
        } else if runtimeState.connection.active != nil {
            updateConnecting(to: newGraphPointer)
        } else {
            stopAutoPanTimer()
        }
    }

    // MARK: - Interaction Handlers --- Selection ---
    
    public func addNode(_ node: BaseNode<NodeData>) {
        nodes.append(node)
        recalculateSortedNodeIDs()
        selectNode(node.id)
    }

    public func updateSelectedNodes(_ transform: (inout BaseNode<NodeData>) -> Void) {
        let selectedIDs = Set(nodes.filter(\.selected).map(\.id))
        let before = Dictionary(
            uniqueKeysWithValues: nodes
                .filter { selectedIDs.contains($0.id) }
                .map { ($0.id, nodeOrderSignature(for: $0)) }
        )

        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                if nodes[i].selected {
                    transform(&nodes[i])
                }
            }
        }

        let after = Dictionary(
            uniqueKeysWithValues: nodes
                .filter { selectedIDs.contains($0.id) }
                .map { ($0.id, nodeOrderSignature(for: $0)) }
        )
        if before != after {
            recalculateSortedNodeIDs()
        }
    }

    public func selectNode(_ id: String) {
        runtimeState.selection.clear()
        runtimeState.selection.selectNode(id: id)
        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                nodes[i].selected = (nodes[i].id == id)
            }
            for i in 0..<edges.count {
                edges[i].selected = false
            }
        }
    }
    
    public func toggleNodeSelection(_ id: String) {
        runtimeState.selection.toggleNode(id: id)
        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                if nodes[i].id == id {
                    nodes[i].selected = runtimeState.selection.selectedNodeIDs.contains(id)
                }
            }
        }
    }
    
    public func selectEdge(_ id: String) {
        runtimeState.selection.clear()
        runtimeState.selection.selectEdge(id: id)
        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                nodes[i].selected = false
            }
            for i in 0..<edges.count {
                edges[i].selected = (edges[i].id == id)
            }
        }
    }
    
    public func toggleEdgeSelection(_ id: String) {
        runtimeState.selection.toggleEdge(id: id)
        for i in 0..<edges.count {
            if edges[i].id == id {
                edges[i].selected = runtimeState.selection.selectedEdgeIDs.contains(id)
            }
        }
    }
    
    public func clearSelection() {
        runtimeState.selection.clear()
        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                nodes[i].selected = false
            }
            for i in 0..<edges.count {
                edges[i].selected = false
            }
        }
    }
    
    public func selectAll() {
        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                nodes[i].selected = true
                runtimeState.selection.selectNode(id: nodes[i].id)
            }
            for i in 0..<edges.count {
                edges[i].selected = true
                runtimeState.selection.selectEdge(id: edges[i].id)
            }
        }
    }

    public func moveSelectedNodes(by offset: XYPosition) {
        guard runtimeState.interactivity.nodesDraggable else { return }
        if offset == .zero { return }
        
        let beforeSnapshot = self.snapshot()
        let selectedNodeIDs = runtimeState.selection.selectedNodeIDs
        let lookup = self.nodeLookup
        
        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                let node = nodes[i]
                guard selectedNodeIDs.contains(node.id) && node.draggable else { continue }
                
                if let parentID = node.parentID, selectedNodeIDs.contains(parentID) {
                    continue
                }
                
                let currentAbsPos = NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: lookup)
                let targetAbsPos = currentAbsPos + offset
                
                let constrainedPos = DragManager.applyConstraints(
                    to: targetAbsPos,
                    node: node,
                    nodeLookup: lookup,
                    snapGrid: nil,
                    applySnap: false
                )
                
                if nodes[i].position != constrainedPos {
                    nodes[i].position = constrainedPos
                }
            }
        }
        runtimeState.isAbsolutePositionCacheValid = false
        
        // 移動量に有意な差（0.1px 以上の変化）があるノードが1つでもあるか
        let significantMove = nodes.contains { n in
            guard selectedNodeIDs.contains(n.id) else { return false }
            let old = beforeSnapshot.nodes.first(where: { $0.id == n.id })?.position ?? n.position
            let dx = abs(n.position.x - old.x)
            let dy = abs(n.position.y - old.y)
            return dx > 0.1 || dy > 0.1
        }
        
        if significantMove {
            registerUndo(title: "ノードの移動", snapshot: beforeSnapshot, ignoringViewport: true)
        }
    }
    
    public func updateSelectedEdges(_ block: (inout BaseEdge<NodeData>) -> Void) {
        for i in 0..<edges.count {
            if edges[i].selected {
                block(&edges[i])
                edges[i].selected = true
            }
        }
    }
    
    public func deleteSelection() {
        let selectedNodeIDs = runtimeState.selection.selectedNodeIDs
        let selectedEdgeIDs = runtimeState.selection.selectedEdgeIDs
        if selectedNodeIDs.isEmpty && selectedEdgeIDs.isEmpty { return }

        let before = self.snapshot()
        nodes.removeAll { selectedNodeIDs.contains($0.id) }
        edges.removeAll { edge in
            selectedEdgeIDs.contains(edge.id) ||
            selectedNodeIDs.contains(edge.source) ||
            selectedNodeIDs.contains(edge.target)
        }
        
        // 実際に削除された要素がある場合のみ登録
        if nodes.count != before.nodes.count || edges.count != before.edges.count {
            registerUndo(title: "要素の削除", snapshot: before, ignoringViewport: true)
            recalculateSortedNodeIDs()
            runtimeState.isAbsolutePositionCacheValid = false
        }
        clearSelection()
    }
    
    public func startMarquee(at pointer: CGPoint) {
        stopAutoPanTimer()
        runtimeState.marquee = GraphRuntimeState.MarqueeState(startPos: pointer, currentPos: pointer)
    }
    
    public func updateMarquee(to pointer: CGPoint) {
        runtimeState.marquee?.currentPos = pointer
    }
    
    public func endMarquee(isShiftPressed: Bool) {
        guard let marquee = runtimeState.marquee else { return }
        let viewport = runtimeState.viewport.viewport
        let screenRect = marquee.rect
        let graphMarqueeRect = CGRect(
            x: (screenRect.origin.x - viewport.x) / viewport.zoom,
            y: (screenRect.origin.y - viewport.y) / viewport.zoom,
            width: screenRect.width / viewport.zoom,
            height: screenRect.height / viewport.zoom
        )
        
        if !isShiftPressed {
            clearSelection()
        }
        
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                let node = nodes[i]
                let absPos = NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: lookup)
                let size = node.measured ?? Dimensions(width: 100, height: 50)
                let nodeRect = CGRect(x: absPos.x, y: absPos.y, width: size.width, height: size.height)
                
                if graphMarqueeRect.contains(nodeRect) {
                    runtimeState.selection.selectNode(id: node.id)
                    nodes[i].selected = true
                }
            }
            
            let selectedNodeIDs = runtimeState.selection.selectedNodeIDs
            if !selectedNodeIDs.isEmpty {
                for i in 0..<edges.count {
                    let edge = edges[i]
                    if selectedNodeIDs.contains(edge.source) || selectedNodeIDs.contains(edge.target) {
                        runtimeState.selection.selectEdge(id: edge.id)
                        edges[i].selected = true
                    }
                }
            }
        }
        runtimeState.marquee = nil
    }
    
    // --- Dragging ---
    public func startDragging(nodeIDs: [String], at pointer: XYPosition) {
        self.dragStartSnapshot = self.snapshot()
        let targets = nodes.filter { nodeIDs.contains($0.id) }
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        runtimeState.drag.startDrag(nodes: targets, nodeLookup: lookup, pointer: pointer)
        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                if nodeIDs.contains(nodes[i].id) {
                    nodes[i].dragging = true
                }
            }
        }
    }
    
    public func updateDragging(to pointer: XYPosition) {
        runtimeState.drag.updateDrag(to: pointer)
        let lookup = self.nodeLookup
        let nextPositions = DragManager.calculateNextPositions(
            draggedNodes: runtimeState.drag.draggedNodes,
            pointer: pointer,
            nodeLookup: lookup,
            snapGrid: nil
        )
        withNodeOrderRecalculationSuspended {
            for (id, pos) in nextPositions {
                if let index = nodes.firstIndex(where: { $0.id == id }) {
                    nodes[index].position = pos
                }
            }
        }
        runtimeState.isAbsolutePositionCacheValid = false
    }
    
    public func stopDragging() {
        stopAutoPanTimer()
        if let before = dragStartSnapshot {
            let after = self.snapshot()
            let hasMoved = zip(before.nodes, after.nodes).contains { b, a in
                b.id != a.id || b.position != a.position
            } || before.nodes.count != after.nodes.count
            if hasMoved {
                registerUndo(title: "ノードの移動", snapshot: before)
            }
        }
        self.dragStartSnapshot = nil
        runtimeState.drag.stopDrag()
        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                nodes[i].dragging = false
            }
        }
    }
    
    /// 特定のノードを新しい座標に移動させます。
    ///
    /// インスペクターからの直接入力など「決定的な移動」に使用します。
    /// 内部で制約適用、Undo登録、およびキャッシュ無効化が自動で行われます。
    public func updateNodePosition(id: String, to newRelativePosition: XYPosition, title: String = "ノードの移動") {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        let node = nodes[index]
        let currentPosition = node.position
        
        // 有意な差がない場合はスキップ
        guard abs(currentPosition.x - newRelativePosition.x) > 0.01 || abs(currentPosition.y - newRelativePosition.y) > 0.01 else { return }
        
        let before = self.snapshot()
        let lookup = self.nodeLookup

        // 重要: DragManager.applyConstraints は第一引数に「目標とする絶対座標」を期待する。
        // 引数 newRelativePosition は（親子関係にかかわらず）ノードの position プロパティの目標値なので、
        // これを絶対座標に変換してから渡す必要がある。
        let parent = node.parentID.flatMap { lookup[$0] }
        let targetAbsPos = NodePositioningAlgorithms.toAbsolutePosition(newRelativePosition, parent: parent, nodeLookup: lookup)
        
        let constrainedPos = DragManager.applyConstraints(
            to: targetAbsPos,
            node: node,
            nodeLookup: lookup,
            snapGrid: nil,
            applySnap: false
        )
        
        withNodeOrderRecalculationSuspended {
            nodes[index].position = constrainedPos
            runtimeState.isAbsolutePositionCacheValid = false
        }
        
        registerUndo(title: title, snapshot: before, ignoringViewport: true)
    }
    
    // --- Connection ---
    public func findHandle(near pointer: XYPosition, threshold: Double = ConnectionInteractionManager.snapDistance) -> HandleKey? {
        let viewport = runtimeState.viewport.viewport
        let fromNodeID = runtimeState.connection.active?.fromNodeID
        var candidates: [ConnectionInteractionManager.HandleCandidate] = []
        
        for node in nodes {
            let handleTargets: [(id: String?, type: HandleType, placement: Position, connectable: Bool)]
            if !node.handles.isEmpty {
                handleTargets = node.handles.map { ($0.id, $0.type, $0.placement, $0.isConnectable) }
            } else {
                handleTargets = [
                    (nil, .source, node.sourcePosition ?? .right, true),
                    (nil, .target, node.targetPosition ?? .left, true)
                ]
            }
            for target in handleTargets {
                let key = HandleKey(nodeID: node.id, handleID: target.id, type: target.type, placement: target.placement)
                let pos = resolvedHandlePosition(for: key)
                candidates.append(.init(
                    key: key,
                    position: pos,
                    isHidden: node.hidden,
                    isConnectable: node.connectable && target.connectable
                ))
            }
        }
        return ConnectionInteractionManager.findNearestHandle(near: pointer, candidates: candidates, viewport: viewport, threshold: threshold, fromNodeID: fromNodeID)
    }
    
    public func startConnecting(fromNodeID: String, fromHandleID: String?, fromHandleType: HandleType, fromHandlePosition: Position, fromPosition: XYPosition, at pointer: XYPosition, mode: ConnectionActionType = .connect) {
        runtimeState.connection.start(fromNodeID: fromNodeID, fromHandleID: fromHandleID, fromHandleType: fromHandleType, fromHandlePosition: fromHandlePosition, fromPosition: fromPosition, at: pointer, mode: mode)
    }
    
    public func updateConnecting(to pointer: XYPosition, targetNodeID: String? = nil, targetHandleID: String? = nil, targetHandlePosition: Position? = nil) {
        runtimeState.connection.update(to: pointer, targetNodeID: targetNodeID, targetHandleID: targetHandleID, targetHandlePosition: targetHandlePosition)
    }
    
    @discardableResult
    public func stopConnecting() -> Connection? {
        guard let active = runtimeState.connection.active else { return nil }
        let beforeSnapshot = self.snapshot()
        var result: Connection? = nil
        
        if let targetNodeID = active.targetNodeID, let targetHandlePosition = active.targetHandlePosition {
            switch active.mode {
            case .connect:
                result = Connection(source: active.fromNodeID, target: targetNodeID, sourceHandle: active.fromHandleID, targetHandle: active.targetHandleID, sourcePosition: active.fromHandlePosition, targetPosition: targetHandlePosition)
            case .reconnect(let edgeID, let isSource):
                let existingEdge = edge(id: edgeID)
                if isSource {
                    result = Connection(
                        source: targetNodeID,
                        target: active.fromNodeID,
                        sourceHandle: active.targetHandleID,
                        targetHandle: existingEdge != nil ? existingEdge?.targetHandle : active.fromHandleID,
                        sourcePosition: targetHandlePosition,
                        targetPosition: existingEdge != nil ? existingEdge?.targetPosition : active.fromHandlePosition
                    )
                } else {
                    result = Connection(
                        source: active.fromNodeID,
                        target: targetNodeID,
                        sourceHandle: existingEdge != nil ? existingEdge?.sourceHandle : active.fromHandleID,
                        targetHandle: active.targetHandleID,
                        sourcePosition: existingEdge != nil ? existingEdge?.sourcePosition : active.fromHandlePosition,
                        targetPosition: targetHandlePosition
                    )
                }
            }
        }
        
        if let conn = result {
            if case .reconnect(let edgeID, _) = active.mode {
                let existing = edge(id: edgeID)
                let isNoOp = existing.map { e in
                    e.source == conn.source &&
                    e.target == conn.target &&
                    e.sourceHandle == conn.sourceHandle &&
                    e.targetHandle == conn.targetHandle &&
                    e.sourcePosition == conn.sourcePosition &&
                    e.targetPosition == conn.targetPosition
                } ?? false
                
                if isNoOp {
                    // 実効的な変化がない場合は nil を返し、Undo 登録も行わない
                    result = nil
                } else {
                    updateEdgeConnection(id: edgeID, newConnection: conn)
                }
            }
        }
        
        stopAutoPanTimer()
        if let conn = result {
            let actionName = (active.mode == .connect) ? "エッジの追加" : "接続の変更"
            registerUndo(title: actionName, snapshot: beforeSnapshot)
        }
        runtimeState.connection.end()
        return result
    }

    public func applyLayout(direction: GraphLayoutDirection = .topToBottom, spacing: Double = 50.0) {
        let beforeSnapshot = self.snapshot()
        let newPositions = GraphLayoutAlgorithms.layoutNodesTreeStyle(nodes: nodes, edges: edges, direction: direction, spacing: spacing)
        
        var hasChanged = false
        withNodeOrderRecalculationSuspended {
            for i in 0..<nodes.count {
                if let newPos = newPositions[nodes[i].id], nodes[i].position != newPos {
                    nodes[i].position = newPos
                    hasChanged = true
                }
            }
        }
        
        if hasChanged {
            registerUndo(title: "レイアウトの適用", snapshot: beforeSnapshot, ignoringViewport: true)
            runtimeState.isAbsolutePositionCacheValid = false
        }
    }

    private func updateEdgeConnection(id: String, newConnection: Connection) {
        if let index = edges.firstIndex(where: { $0.id == id }) {
            var edge = edges[index]
            edge.source = newConnection.source
            edge.target = newConnection.target
            edge.sourceHandle = newConnection.sourceHandle
            edge.targetHandle = newConnection.targetHandle
            edge.sourcePosition = newConnection.sourcePosition
            edge.targetPosition = newConnection.targetPosition
            edges[index] = edge
        }
    }

    public func cancelInteractions() {
        stopAutoPanTimer()
        stopDragging()
        _ = stopConnecting()
        runtimeState.marquee = nil
    }
    
    // MARK: - Hover ---
    public func setHoveredNode(_ id: String?) {
        runtimeState.hover.hoveredNodeID = id
    }

    // --- Interactivity ---
    public func setNodesDraggable(_ draggable: Bool) { runtimeState.interactivity.nodesDraggable = draggable }
    public func setNodesConnectable(_ connectable: Bool) { runtimeState.interactivity.nodesConnectable = connectable }
    public func setElementsSelectable(_ selectable: Bool) { runtimeState.interactivity.elementsSelectable = selectable }
    public func setPanOnDrag(_ panOnDrag: Bool) { runtimeState.interactivity.panOnDrag = panOnDrag }
    public func setZoomOnScroll(_ enabled: Bool) { runtimeState.interactivity.zoomOnScroll = enabled }
    public func setZoomOnPinch(_ enabled: Bool) { runtimeState.interactivity.zoomOnPinch = enabled }

    // MARK: - Undo Support Methods
    
    private func syncSelectionFromModel() {
        runtimeState.selection.clear()
        for node in nodes where node.selected {
            runtimeState.selection.selectNode(id: node.id)
        }
        for edge in edges where edge.selected {
            runtimeState.selection.selectEdge(id: edge.id)
        }
    }
    
    private func registerViewportUndo(title: String, previousViewport: Viewport) {
        guard let undoManager = undoManager else { return }
        undoManager.registerUndo(withTarget: self) { target in
            let currentVP = target.runtimeState.viewport.viewport
            target.registerViewportUndo(title: title, previousViewport: currentVP)
            target.setViewport(previousViewport)
        }
        if !undoManager.isUndoing && !undoManager.isRedoing {
            undoManager.setActionName(title)
        }
    }
    
    private func registerUndo(title: String, snapshot: GraphSnapshot<NodeData>, ignoringViewport: Bool = true) {
        guard let undoManager = undoManager else { return }
        if !undoManager.isUndoing && !undoManager.isRedoing {
            undoManager.setActionName(title)
        }

        undoManager.registerUndo(withTarget: self) { target in
            target.apply(snapshot: snapshot, title: title, shouldRegisterUndo: true, ignoringViewport: ignoringViewport, restoringSelection: true)
        }
    }

    public func snapshot() -> GraphSnapshot<NodeData> {
        GraphSnapshot(nodes: nodes, edges: edges, viewport: runtimeState.viewport.viewport)
    }

    public func apply(
        snapshot: GraphSnapshot<NodeData>,
        title: String? = nil,
        shouldRegisterUndo: Bool = false,
        ignoringViewport: Bool = false,
        restoringSelection: Bool = false
    ) {
        if shouldRegisterUndo, let currentTitle = title {
            registerUndo(title: currentTitle, snapshot: self.snapshot(), ignoringViewport: ignoringViewport)
        }
        self.nodes = snapshot.nodes
        self.edges = snapshot.edges
        if !ignoringViewport {
            self.setViewport(snapshot.viewport)
        }
        if restoringSelection {
            syncSelectionFromModel()
        } else {
            clearSelection()
        }
        stopDragging()
        runtimeState.connection.end()
        setHoveredNode(nil)
        runtimeState.marquee = nil
        runtimeState.handleMeasurements.positions.removeAll()
        recalculateSortedNodeIDs()
    }
    
    // MARK: - Performance Cache Overrides
    
    /// 描画順序（zIndex、階層）を事前に計算してキャッシュします。
    public func recalculateSortedNodeIDs() {
        let lookup = self.nodeLookup
        let indexedNodes = self.nodes.enumerated().map { ($0, $1) }
        
        self.runtimeState.sortedNodeIDs = indexedNodes.sorted { (a, b) in
            let (idxA, nodeA) = a
            let (idxB, nodeB) = b
            
            // 1. zIndex
            let zA = nodeA.zIndex ?? 0
            let zB = nodeB.zIndex ?? 0
            if zA != zB { return zA < zB }
            
            // 2. 階層の深さ (親を先に、子を後に)
            let depthA = NodePositioningAlgorithms.calculateDepth(node: nodeA, nodeLookup: lookup)
            let depthB = NodePositioningAlgorithms.calculateDepth(node: nodeB, nodeLookup: lookup)
            if depthA != depthB { return depthA < depthB }
            
            // 3. 安定ソート
            return idxA < idxB
        }.map { $0.1.id }
    }
}

extension GraphStore where NodeData: Codable {
    public func apply(snapshot: GraphSnapshot<NodeData>) {
        apply(snapshot: snapshot, shouldRegisterUndo: false)
    }
}
