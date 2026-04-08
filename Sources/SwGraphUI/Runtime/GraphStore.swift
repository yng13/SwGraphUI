import SwiftUI
import Observation

/// グラフの状態管理を担う中心的なクラス。
/// ノード、エッジ、ビューポート、選択状態などを一括管理し、UIへのリアクティブな更新を提供します。
@Observable
@MainActor
public final class GraphStore<Data: Sendable>: Sendable {
    // MARK: - Core State
    public var nodes: [BaseNode<Data>] = []
    public var edges: [BaseEdge<Data>] = []
    
    // MARK: - Runtime State
    public var runtimeState: GraphRuntimeState
    
    // MARK: - Interaction State
    private var autoPanTimer: Timer?
    
    // MARK: - Selection Accessors
    public var selectedNodes: [BaseNode<Data>] {
        nodes.filter { $0.selected }
    }
    
    public var selectedEdges: [BaseEdge<Data>] {
        edges.filter { $0.selected }
    }
    
    public init(
        nodes: [BaseNode<Data>] = [],
        edges: [BaseEdge<Data>] = [],
        runtimeState: GraphRuntimeState = .init()
    ) {
        self.nodes = nodes
        self.edges = edges
        self.runtimeState = runtimeState
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
    public func node(id: String) -> BaseNode<Data>? {
        nodes.first { $0.id == id }
    }

    public func updateNodePosition(id: String, position: XYPosition) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            nodes[index].position = position
        }
    }

    /// 自動測定ロジックによってノードの実測サイズを更新します。
    public func updateNodeDimensions(id: String, dimensions: Dimensions) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            // 差分ガード：値が同じ場合は更新をスキップして再描画を抑制
            if nodes[index].measured != dimensions {
                nodes[index].measured = dimensions
            }
        }
    }

    /// リサイズ操作によってノードの寸法と位置を更新します。
    /// このメソッドは自動測定ループとは別に、ユーザーの意図的な変形を即座に反映するために使用します。
    public func updateNodeDimensionsAfterResize(id: String, width: Double, height: Double, position: XYPosition) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            nodes[index].width = width
            nodes[index].height = height
            nodes[index].position = position
            
            // measured も同期。エッジ描画が即座に追従するようにします。
            nodes[index].measured = Dimensions(width: width, height: height)
        }
    }

    public func absolutePosition(for nodeID: String) -> XYPosition {
        guard let node = node(id: nodeID) else { return .zero }
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        return NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: lookup)
    }

    // MARK: - Edge Operations
    public func edge(id: String) -> BaseEdge<Data>? {
        edges.first { $0.id == id }
    }

    public func addEdge(_ edge: BaseEdge<Data>) {
        edges.append(edge)
    }

    // MARK: - Viewport Operations
    public func setViewport(_ viewport: Viewport) {
        runtimeState.viewport.setViewport(viewport)
    }
    
    public func pan(by delta: XYPosition) {
        // 構造体の再代入を明示的に行い、@Observable の通知を確実にする
        var state = runtimeState.viewport
        state.panBy(dx: delta.x, dy: delta.y)
        runtimeState.viewport = state
    }
    
    /// 指定された中心点を基準に拡大・縮小します。
    /// - Parameters:
    ///   - screenPoint: 拡大の基準となるスクリーン上の点（デフォルトはビューポート中心）。
    ///   - factor: 拡大係数（1.0を超える場合は拡大、1.0未満は縮小）。
    public func zoom(at screenPoint: XYPosition? = nil, factor: Double) {
        // デフォルトは中心（仮。本来はサイズが必要だが、一旦 (0,0) を基準にするか呼び出し側で解決）
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

    /// ビューポートを 1.2 倍拡大します。
    public func zoomIn() {
        zoom(factor: 1.2)
    }

    /// ビューポートを 0.8 倍縮小します。
    public func zoomOut() {
        zoom(factor: 0.8)
    }

    public func fitView(
        in size: Dimensions = Dimensions(width: 800, height: 600),
        padding: GeometryAlgorithms.Padding = .all(.relative(0.1))
    ) {
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        runtimeState.viewport.fitView(
            nodes: nodes,
            nodeLookup: lookup,
            in: size,
            padding: padding,
            minZoom: runtimeState.interactivity.minZoom,
            maxZoom: runtimeState.interactivity.maxZoom
        )
    }
    
    // MARK: - Auto Pan Operations
    
    /// コンテナ（キャンバス）の寸法を更新します。
    public func setContainerSize(_ size: Dimensions) {
        runtimeState.autoPan.containerSize = size
    }
    
    /// オートパンを更新し、必要に応じてタイマーを開始します。
    /// - Parameter screenPointer: 「viewport_container」座標系での現在のポインタ位置。
    public func updateAutoPan(at screenPointer: XYPosition) {
        runtimeState.autoPan.mousePosition = screenPointer
        
        guard let containerSize = runtimeState.autoPan.containerSize,
              containerSize.width > 0, containerSize.height > 0 else {
            return
        }
        
        let velocity = AutoPanAlgorithms.calculateVelocity(
            mousePosition: screenPointer,
            containerSize: containerSize,
            speed: 25 // スピードを 15 -> 25 に強化
        )
        
        if velocity != .zero {
            if autoPanTimer == nil {
                startAutoPanTimer()
            }
            runtimeState.autoPan.isActive = true
            runtimeState.autoPan.velocity = velocity
        } else {
            runtimeState.autoPan.isActive = false
            // 速度が0の場合はタイマーは止めず、ポインタが閾値内に戻るのを待つか、
            // インタラクション終了時に止めます。
        }
    }
    
    private func startAutoPanTimer() {
        guard autoPanTimer == nil else { return }
        
        // 50fps (20ms) で更新
        // 直接 RunLoop.main.add することで、ドラッグ中 (.tracking) もタイマーがブロックされないようにする
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
        
        // 最新の速度を再計算
        let velocity = AutoPanAlgorithms.calculateVelocity(
            mousePosition: mousePos,
            containerSize: containerSize,
            speed: 25 // スピードを 15 -> 25 に強化
        )
        
        guard velocity != .zero else {
            runtimeState.autoPan.isActive = false
            return
        }
        
        runtimeState.autoPan.isActive = true
        runtimeState.autoPan.velocity = velocity
        
        // ビューポートを移動
        pan(by: velocity)
        
        // ポインタ・オブジェクトの同期
        // ビューポートが動いた状態で、再度画面上のポインタからグラフ空間の座標を割り出す
        let viewport = runtimeState.viewport.viewport
        let newGraphPointer = mousePos.fromScreen(viewport: viewport)
        
        if runtimeState.drag.isDragging {
            updateDragging(to: newGraphPointer)
        } else if runtimeState.connection.active != nil {
            updateConnecting(to: newGraphPointer)
        } else {
            // インタラクションが見当たらない場合は停止
            stopAutoPanTimer()
        }
    }

    // MARK: - Interaction Handlers
    
    // --- Selection ---
    
    /// 新しいノードを追加し、そのノードを選択状態にします。
    public func addNode(_ node: BaseNode<Data>) {
        nodes.append(node)
        selectNode(node.id)
    }

    /// 選択中の全てのノードを更新します。
    public func updateSelectedNodes(_ transform: (inout BaseNode<Data>) -> Void) {
        for i in 0..<nodes.count {
            if nodes[i].selected {
                transform(&nodes[i])
            }
        }
    }

    /// 指定されたノードを選択状態にします（排他選択）。
    public func selectNode(_ id: String) {
        runtimeState.selection.clear()
        runtimeState.selection.selectNode(id: id)
        
        // モデルフラグの同期
        for i in 0..<nodes.count {
            nodes[i].selected = (nodes[i].id == id)
        }
        for i in 0..<edges.count {
            edges[i].selected = false
        }
    }
    
    /// 指定されたノードの選択状態を反転させます（複数選択用）。
    public func toggleNodeSelection(_ id: String) {
        runtimeState.selection.toggleNode(id: id)
        
        // モデルフラグの同期
        for i in 0..<nodes.count {
            if nodes[i].id == id {
                nodes[i].selected = runtimeState.selection.selectedNodeIDs.contains(id)
            }
        }
    }
    
    /// 指定されたエッジを選択状態にします（排他選択）。
    public func selectEdge(_ id: String) {
        runtimeState.selection.clear()
        runtimeState.selection.selectEdge(id: id)
        
        // モデルフラグの同期
        for i in 0..<nodes.count {
            nodes[i].selected = false
        }
        for i in 0..<edges.count {
            edges[i].selected = (edges[i].id == id)
        }
    }
    
    /// 指定されたエッジの選択状態を反転させます（複数選択用）。
    public func toggleEdgeSelection(_ id: String) {
        runtimeState.selection.toggleEdge(id: id)
        
        // モデルフラグの同期
        for i in 0..<edges.count {
            if edges[i].id == id {
                edges[i].selected = runtimeState.selection.selectedEdgeIDs.contains(id)
            }
        }
    }
    
    /// すべての選択を解除します。
    public func clearSelection() {
        runtimeState.selection.clear()
        
        // モデルフラグの同期
        for i in 0..<nodes.count {
            nodes[i].selected = false
        }
        for i in 0..<edges.count {
            edges[i].selected = false
        }
    }
    
    /// すべてを選択状態にします。
    public func selectAll() {
        for i in 0..<nodes.count {
            nodes[i].selected = true
            runtimeState.selection.selectNode(id: nodes[i].id)
        }
        for i in 0..<edges.count {
            edges[i].selected = true
            runtimeState.selection.selectEdge(id: edges[i].id)
        }
    }
    
    /// 選択されているエッジを一括更新します（プロパティ変更用）。
    /// - Parameter block: 各エッジに適用する更新処理。
    public func updateSelectedEdges(_ block: (inout BaseEdge<Data>) -> Void) {
        for i in 0..<edges.count {
            if edges[i].selected {
                block(&edges[i])
                edges[i].selected = true // 選択状態を強制維持
            }
        }
    }
    
    /// 選択されている要素を削除します。
    public func deleteSelection() {
        let selectedNodeIDs = runtimeState.selection.selectedNodeIDs
        let selectedEdgeIDs = runtimeState.selection.selectedEdgeIDs
        
        // ノードの削除
        nodes.removeAll { selectedNodeIDs.contains($0.id) }
        
        // エッジの削除：選択されているもの、または削除されたノードに紐づくもの
        edges.removeAll { edge in
            selectedEdgeIDs.contains(edge.id) ||
            selectedNodeIDs.contains(edge.source) ||
            selectedNodeIDs.contains(edge.target)
        }
        
        clearSelection()
    }
    
    /// 矩形選択を開始します。
    /// - Parameter pointer: スクリーン座標系での開始位置。
    public func startMarquee(at pointer: CGPoint) {
        stopAutoPanTimer() // 矩形選択中はオートパンを行わない
        runtimeState.marquee = GraphRuntimeState.MarqueeState(startPos: pointer, currentPos: pointer)
    }
    
    /// 矩形選択の範囲を更新します。
    /// - Parameter pointer: スクリーン座標系での現在の位置。
    public func updateMarquee(to pointer: CGPoint) {
        runtimeState.marquee?.currentPos = pointer
    }
    
    /// 矩形選択を終了し、範囲内の要素を選択します。
    /// - Parameter isShiftPressed: Shiftキーが押されているか。
    public func endMarquee(isShiftPressed: Bool) {
        guard let marquee = runtimeState.marquee else { return }
        let viewport = runtimeState.viewport.viewport
        
        // スクリーン矩形をグラフ空間（絶対座標）矩形に変換
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
        
        // 1. ノードの判定
        for i in 0..<nodes.count {
            let node = nodes[i]
            let absPos = NodePositioningAlgorithms.evaluateAbsolutePosition(node, nodeLookup: lookup)
            let size = node.measured ?? Dimensions(width: 100, height: 50)
            let nodeRect = CGRect(x: absPos.x, y: absPos.y, width: size.width, height: size.height)
            
            if graphMarqueeRect.contains(nodeRect) {
                if isShiftPressed {
                    // Shiftありの場合は既存の状態に関わらず「追加」
                    // (XYFlowのデフォルト挙動に合わせる。トグルではなく包含されたらON)
                    runtimeState.selection.selectNode(id: node.id)
                    nodes[i].selected = true
                } else {
                    runtimeState.selection.selectNode(id: node.id)
                    nodes[i].selected = true
                }
            }
        }
        
        // 2. エッジの判定 (xyflow 準拠: 選択ノード集合に接続しているエッジを選択)
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
        
        runtimeState.marquee = nil
    }
    
    // --- Dragging ---
    public func startDragging(nodeIDs: [String], at pointer: XYPosition) {
        let targets = nodes.filter { nodeIDs.contains($0.id) }
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        runtimeState.drag.startDrag(nodes: targets, nodeLookup: lookup, pointer: pointer)
        
        // ストア内の実体ノードのフラグを更新
        for i in 0..<nodes.count {
            if nodeIDs.contains(nodes[i].id) {
                nodes[i].dragging = true
            }
        }
    }
    
    public func updateDragging(to pointer: XYPosition) {
        // オートパンの更新（ポインタ位置はスクリーン座標として扱う。
        // updateDragging 引数の pointer はすでに fromScreen 済みの場合があるため、
        // GraphStore.updateAutoPan は別途 DragGesture 等から直接 screen 座標を受け取る運用にするか、
        // ここで再逆変換するかを検討。
        // 今回は呼び出し側の GraphView で store.updateAutoPan を呼ぶ。
        
        runtimeState.drag.updateDrag(to: pointer)
        
        let lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        
        // 実際の座標更新
        for item in runtimeState.drag.draggedNodes {
            if let index = nodes.firstIndex(where: { $0.id == item.id }) {
                let absPos = pointer - item.distance
                
                // 親がいる場合は相対座標に変換、いない場合は絶対座標のまま
                if let parentID = nodes[index].parentID, let parent = lookup[parentID] {
                    nodes[index].position = NodePositioningAlgorithms.toRelativePosition(
                        absPos,
                        parent: parent,
                        nodeLookup: lookup
                    )
                } else {
                    nodes[index].position = absPos
                }
            }
        }
    }
    
    public func stopDragging() {
        stopAutoPanTimer()
        runtimeState.drag.stopDrag()
        for i in 0..<nodes.count {
            nodes[i].dragging = false
        }
    }
    
    // --- Connection ---
    
    /// 指定された座標（グラフ空間）に近いハンドルを検索します。
    public func findHandle(near pointer: XYPosition, threshold: Double = ConnectionInteractionManager.snapDistance) -> HandleKey? {
        let viewport = runtimeState.viewport.viewport
        let fromNodeID = runtimeState.connection.active?.fromNodeID
        
        var candidates: [ConnectionInteractionManager.HandleCandidate] = []
        
        for node in nodes {
            // ノードが持つハンドルを特定
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
        
        return ConnectionInteractionManager.findNearestHandle(
            near: pointer,
            candidates: candidates,
            viewport: viewport,
            threshold: threshold,
            fromNodeID: fromNodeID
        )
    }
    
    public func startConnecting(
        fromNodeID: String,
        fromHandleID: String?,
        fromHandleType: HandleType,
        fromHandlePosition: Position,
        fromPosition: XYPosition,
        at pointer: XYPosition,
        mode: ConnectionActionType = .connect
    ) {
        runtimeState.connection.start(
            fromNodeID: fromNodeID,
            fromHandleID: fromHandleID,
            fromHandleType: fromHandleType,
            fromHandlePosition: fromHandlePosition,
            fromPosition: fromPosition,
            at: pointer,
            mode: mode
        )
    }
    
    public func updateConnecting(
        to pointer: XYPosition,
        targetNodeID: String? = nil,
        targetHandleID: String? = nil,
        targetHandlePosition: Position? = nil
    ) {
        // Viewport が動いている場合でも、引数の pointer (Graph space) に基づき状態を更新
        runtimeState.connection.update(
            to: pointer,
            targetNodeID: targetNodeID,
            targetHandleID: targetHandleID,
            targetHandlePosition: targetHandlePosition
        )
    }
    
    @discardableResult
    public func stopConnecting() -> Connection? {
        guard let active = runtimeState.connection.active else { return nil }
        
        print("[DEBUG] Reconnect Stop attempt: mode=\(active.mode), targetNode=\(active.targetNodeID ?? "nil")")
        
        var result: Connection? = nil
        
        if let targetNodeID = active.targetNodeID,
           let targetHandlePosition = active.targetHandlePosition {
            // mode に応じて source/target の実体を正しく構成
            switch active.mode {
            case .connect:
                result = Connection(
                    source: active.fromNodeID,
                    target: targetNodeID,
                    sourceHandle: active.fromHandleID,
                    targetHandle: active.targetHandleID,
                    sourcePosition: active.fromHandlePosition,
                    targetPosition: targetHandlePosition
                )
            case .reconnect(_, let isSource):
                if isSource {
                    // ソース側をドラッグ中：
                    // 移動端（マウス位置）が新しい「ソース」、固定端が既存の「ターゲット」
                    result = Connection(
                        source: targetNodeID,
                        target: active.fromNodeID,
                        sourceHandle: active.targetHandleID,
                        targetHandle: active.fromHandleID,
                        sourcePosition: targetHandlePosition,
                        targetPosition: active.fromHandlePosition
                    )
                } else {
                    // ターゲット側をドラッグ中：
                    // 固定端が既存の「ソース」、移動端（マウス位置）が新しい「ターゲット」
                    result = Connection(
                        source: active.fromNodeID,
                        target: targetNodeID,
                        sourceHandle: active.fromHandleID,
                        targetHandle: active.targetHandleID,
                        sourcePosition: active.fromHandlePosition,
                        targetPosition: targetHandlePosition
                    )
                }
            }
        }
        
        if let conn = result, case .reconnect(let edgeID, _) = active.mode {
            updateEdgeConnection(id: edgeID, newConnection: conn)
        }
        
        stopAutoPanTimer()
        runtimeState.connection.end()
        return result
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

    /// すべてのインタラクション状態（オートパンのタイマー等を含む）を強制停止します。
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

    public func setNodesDraggable(_ draggable: Bool) {
        runtimeState.interactivity.nodesDraggable = draggable
    }

    public func setNodesConnectable(_ connectable: Bool) {
        runtimeState.interactivity.nodesConnectable = connectable
    }

    public func setElementsSelectable(_ selectable: Bool) {
        runtimeState.interactivity.elementsSelectable = selectable
    }

    public func setPanOnDrag(_ panOnDrag: Bool) {
        runtimeState.interactivity.panOnDrag = panOnDrag
    }

    public func setZoomOnScroll(_ enabled: Bool) {
        runtimeState.interactivity.zoomOnScroll = enabled
    }
    
    public func setZoomOnPinch(_ enabled: Bool) {
        runtimeState.interactivity.zoomOnPinch = enabled
    }
}

extension GraphStore where Data: Codable {
    /// 現在のグラフの状態（ノード、エッジ、ビューポート）のスナップショットを取得します。
    /// Data が Codable に準拠している必要があります。
    public func snapshot() -> GraphSnapshot<Data> {
        GraphSnapshot(
            nodes: nodes,
            edges: edges,
            viewport: runtimeState.viewport.viewport
        )
    }

    /// スナップショットを適用してグラフの状態を復元します。
    /// 適用時、選択状態、ドラッグ状態、接続中の操作などのランタイム状態はすべてクリアされます。
    public func apply(snapshot: GraphSnapshot<Data>) {
        // 1. Core State の置換
        self.nodes = snapshot.nodes
        self.edges = snapshot.edges
        
        // 2. Viewport の復元
        self.setViewport(snapshot.viewport)
        
        // 3. Runtime Interaction State のクリーンアップ
        // 選択の解除
        clearSelection()
        // ドラッグ状態の強制終了
        stopDragging()
        // 接続操作の強制終了
        runtimeState.connection.end()
        // ホバーの解除
        setHoveredNode(nil)
        // 矩形選択の解除
        runtimeState.marquee = nil
        
        // ハンドル計測値はリセット（復元後の再描画で再計測される）
        runtimeState.handleMeasurements.positions.removeAll()
    }
}
