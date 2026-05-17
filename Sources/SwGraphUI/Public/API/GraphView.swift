import SwiftUI

/// For notification of events occurring within the graph | グラフ内で発生したイベントの通知用
public enum GraphEvent: Sendable {
    case dragStart(nodeIDs: [String])
    case dragUpdate(nodeIDs: [String])
    case dragStop(nodeIDs: [String])
}

/// Skeleton of the main view of SwGraphUI. | SwGraphUI のメインビューの骨格。
/// Responsibilities include applying zoom/pan and bridging drag inputs to the GraphStore. | ズーム・パンの適用と、ドラッグ入力の GraphStore へのブリッジを担います。
public struct GraphView<NodeData: Sendable, NodeContent: View>: View {
    public let store: GraphStore<NodeData>
    public let nodeBuilder: (BaseNode<NodeData>) -> NodeContent
    private let edgeBuilder: (EdgeRenderContext<NodeData>) -> AnyView
    public let backgroundBuilder: (() -> AnyView)?
    public let configuration: GraphConfiguration
    public var onEvent: ((GraphEvent) -> Void)?

    public var onConnect: ((Connection) -> Void)?
    public var onReconnect: ((String, Connection) -> Void)?
    
    // Adapter for monitoring modifier key states | 修飾キーの状態監視アダプター
    @State private var modifierKeys = ModifierKeysProvider()
    
    // State for Zoom / Hover | Zoom / Hover 用状態
    @State private var hoverLocation: CGPoint = .zero
    @State private var lastMagnification: CGFloat = 1.0
    #if os(macOS)
    @StateObject private var scrollMonitor = ScrollMonitor()
    #endif
    
    // Internal state for calculating continuous changes in pan or marquee operations | パンまたは Marquee 操作の継続的な変化量を計算するための内部用ステート
    @State private var lastPanTranslation: CGSize = .zero
    
    private enum BackgroundInteractionMode {
        case undecided
        case marquee
        case pan
    }
    @State private var backgroundInteractionMode: BackgroundInteractionMode = .undecided
    
    public init(
        store: GraphStore<NodeData>,
        configuration: GraphConfiguration = .init(),
        onEvent: ((GraphEvent) -> Void)? = nil,
        onConnect: ((Connection) -> Void)? = nil,
        onReconnect: ((String, Connection) -> Void)? = nil,
        edgeBuilder: ((BaseEdge<NodeData>, [PathSegment], Color, CGFloat, Viewport, Dimensions, Bool, Bool) -> AnyView)? = nil,
        edgeContextBuilder: ((EdgeRenderContext<NodeData>) -> AnyView)? = nil,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<NodeData>) -> NodeContent,
        backgroundBuilder: (() -> AnyView)? = nil
    ) {
        self.store = store
        self.configuration = configuration
        self.onEvent = onEvent
        self.onConnect = onConnect
        self.onReconnect = onReconnect
        self.nodeBuilder = nodeBuilder
        self.backgroundBuilder = backgroundBuilder
        if let edgeContextBuilder {
            self.edgeBuilder = edgeContextBuilder
        } else if let edgeBuilder {
            self.edgeBuilder = { context in
                edgeBuilder(
                    context.edge,
                    context.graphSegments,
                    context.strokeColor,
                    context.strokeWidth,
                    context.viewport,
                    context.containerSize,
                    context.animated,
                    context.isReconnecting
                )
            }
        } else {
            self.edgeBuilder = { context in
                AnyView(
                    EdgeRenderer(
                        segments: context.graphSegments,
                        strokeColor: context.strokeColor,
                        strokeWidth: context.strokeWidth,
                        dashStyle: context.dashStyle,
                        strokeShape: context.strokeShape,
                        viewport: context.viewport,
                        containerSize: context.containerSize,
                        animated: context.animated,
                        isReconnecting: context.isReconnecting
                    )
                )
            }
        }
    }

    
    public var body: some View {
        let _ = modifierKeys.isShiftPressed // Ensure the body is reactive to Shift key presses | Body のリアクティブ性を確保
        
        ZStack {
            GeometryReader { geometry in
                if let backgroundBuilder {
                    backgroundBuilder()
                } else if configuration.showGrid {
                    BackgroundView(
                        viewport: store.runtimeState.viewport.viewport,
                        gap: configuration.gridSize,
                        variant: configuration.backgroundVariant,
                        patternColor: configuration.gridColor
                    )
                }
                
                // Viewport (graph space) container | ビューポート（グラフ空間）コンテナ
                viewportContainer
                
                // Marquee selection display (frontmost, but coordinate system is viewport_container / screen coordinates) | 矩形選択の表示（最前面、ただし座標系は viewport_container / スクリーン座標系）
                if let marquee = store.runtimeState.marquee {
                    MarqueeView(marquee: marquee)
                }
            }
            .coordinateSpace(name: "viewport_container")
            .onAppear {
                // Sync initial size | 初期サイズの同期
                // * Referencing geometry directly within GeometryReader and calling the store carries a risk of infinite loops, | ※ GeometryReader 内部で geometry を直接参照して store を叩くと無限ループのリスクがあるため、
                // so normally this is kept to one-way notifications. | 本来は一方向の通知に留めます。
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            store.setContainerSize(Dimensions(width: geometry.size.width, height: geometry.size.height))
                        }
                        .onChange(of: geometry.size) { _, newValue in
                            store.setContainerSize(Dimensions(width: newValue.width, height: newValue.height))
                        }
                }
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Graph Canvas | グラフキャンバス")
        .onAppear {
            _ = modifierKeys.isShiftPressed // Start monitoring on initial access | 初期アクセスで監視開始
            
            #if os(macOS)
            scrollMonitor.onEvent = { [store, weak scrollMonitor] event in
                guard store.runtimeState.interactivity.zoomOnScroll else { return nil }
                
                let location = scrollMonitor?.location ?? .zero
                if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) {
                    let factor = exp(event.scrollingDeltaY * 0.01) // Magnification factor according to scroll amount | ホイール量に応じた倍率
                    let center = XYPosition(x: location.x, y: location.y)
                    store.zoom(at: center, factor: factor)
                    return nil
                } else {
                    store.pan(by: XYPosition(x: event.scrollingDeltaX, y: event.scrollingDeltaY))
                    return nil
                }
            }
            #endif
        }
        .onHover { isHovering in
            #if os(macOS)
            scrollMonitor.isHovering = isHovering
            #endif
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                self.hoverLocation = location
                #if os(macOS)
                scrollMonitor.location = location
                #endif
            case .ended:
                break
            }
        }
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    guard store.runtimeState.interactivity.zoomOnPinch else { return }
                    guard value.magnification.isFinite, value.magnification > 0 else { return }
                    guard lastMagnification.isFinite, lastMagnification > 0 else {
                        lastMagnification = max(value.magnification, 1.0)
                        return
                    }
                    let factor = value.magnification / lastMagnification
                    guard factor.isFinite, factor > 0 else { return }
                    let center = XYPosition(x: hoverLocation.x, y: hoverLocation.y)
                    store.zoom(at: center, factor: factor)
                    lastMagnification = value.magnification
                }
                .onEnded { _ in
                    lastMagnification = 1.0
                }
        )
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(.secondarySystemBackground))
        #endif
        .onPreferenceChange(NodeSizePreferenceKey.self) { entries in
            for entry in entries {
                store.updateNodeDimensions(
                    id: entry.id,
                    dimensions: Dimensions(
                        width: Double(entry.size.width),
                        height: Double(entry.size.height)
                    )
                )
            }
        }
        .onPreferenceChange(HandlePositionPreferenceKey.self) { entries in
            let viewport = store.runtimeState.viewport.viewport
            for entry in entries {
                // Convert screen (viewport_container) coordinates to absolute graph coordinates | スクリーン（viewport_container）座標系をグラフ絶対座標に変換
                let absoluteCenter = entry.viewportCenter.fromScreen(viewport: viewport)
                store.updateHandlePosition(key: entry.key, absolutePosition: absoluteCenter)
            }
        }
        .onDisappear {
            store.cancelInteractions()
        }
        .onAppear {
            store.runtimeState.handleAnchorOffset = configuration.handleStyle.anchorOffset
            store.parallelEdgeLanesEnabled = configuration.parallelEdgeLanesEnabled
            store.parallelEdgeLaneSpacing = configuration.parallelEdgeLaneSpacing
            store.setSnapGrid(configuration.snapGrid)
        }
        .onChange(of: configuration.handleStyle) { _, newValue in
            store.runtimeState.handleAnchorOffset = newValue.anchorOffset
        }
        .onChange(of: configuration.parallelEdgeLanesEnabled) { _, newValue in
            store.parallelEdgeLanesEnabled = newValue
        }
        .onChange(of: configuration.parallelEdgeLaneSpacing) { _, newValue in
            store.parallelEdgeLaneSpacing = newValue
        }
        .onChange(of: configuration.snapGrid) { _, newValue in
            store.setSnapGrid(newValue)
        }
        .environment(store)
    }

    // MARK: - Layer Components | レイヤーコンポーネント

    @ViewBuilder
    private var backgroundLayerPart: some View {
        // Use a color that is not completely transparent to ensure hit testing | ヒットテストを確実にするため、完全に透明ではない色を使用
        Color.black.opacity(0.0001)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("viewport_container"))
                    .onChanged { value in
                        if backgroundInteractionMode == .undecided {
                            // Check the state of the Shift key at the start of operation to determine and lock the mode | 操作開始時に Shift キーの状態を見てモードを確定・ロックする
                            if modifierKeys.isShiftPressed && store.runtimeState.interactivity.elementsSelectable {
                                backgroundInteractionMode = .marquee
                                store.startMarquee(at: value.startLocation)
                            } else if store.runtimeState.interactivity.panOnDrag {
                                // Lock to pan if movement exceeds a certain amount to distinguish from a simple tap | 単なるタップと区別するため、一定以上の移動で pan にロックする
                                let translation = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                                if translation > 5 {
                                    backgroundInteractionMode = .pan
                                }
                            }
                        }
                        
                        // Execute processing according to the locked mode | ロックされたモードに従って処理を実行
                        switch backgroundInteractionMode {
                        case .marquee:
                            store.updateMarquee(to: value.location)
                        case .pan:
                            let deltaX = value.translation.width - lastPanTranslation.width
                            let deltaY = value.translation.height - lastPanTranslation.height
                            store.pan(by: XYPosition(x: deltaX, y: deltaY))
                            lastPanTranslation = value.translation
                        case .undecided:
                            break
                        }
                    }
                    .onEnded { value in
                        switch backgroundInteractionMode {
                        case .marquee:
                            store.endMarquee(isShiftPressed: true)
                        case .pan:
                            break
                        case .undecided:
                            // Clear selection if no movement (tap) and element selection is allowed | 移動なし（タップ）かつ要素選択が許可されている場合、選択クリア
                            if store.runtimeState.interactivity.elementsSelectable {
                                store.clearSelection()
                            }
                        }
                        
                        // Reset | リセット
                        backgroundInteractionMode = .undecided
                        lastPanTranslation = .zero
                    }
            )
    }

    @ViewBuilder
    private var viewportContainer: some View {
        let vp = store.runtimeState.viewport.viewport
        ZStack(alignment: .topLeading) {
            backgroundLayerPart
            
            GraphLayerStack(
                store: store,
                nodeBuilder: nodeBuilder,
                edgeBuilder: edgeBuilder,
                onConnect: onConnect,
                onReconnect: onReconnect,
                modifierKeys: modifierKeys,
                containerSize: store.runtimeState.autoPan.containerSize ?? Dimensions(width: 800, height: 600),
                viewportCullingEnabled: configuration.viewportCullingEnabled,
                viewportCullingMargin: configuration.viewportCullingMargin,
                nodeWrapper: { node, content in
                    AnyView(NodeGestureWrapper(node: node, store: self.store, onEvent: self.onEvent, modifierKeys: self.modifierKeys, content: content))
                }
            )
            .environment(\.graphZoomLevel, vp.zoom)
            .environment(\.graphHandleStyle, configuration.handleStyle)
        }
    }
}

/// Wrapper view that encapsulates gesture operations for each node, managing mode locking and selection intent. | 各ノードのジェスチャー操作をカプセル化し、モードのロックと選択意図を管理するラッパービュー。
/// 
internal struct NodeGestureWrapper<NodeData: Sendable>: View {
    let node: BaseNode<NodeData>
    let store: GraphStore<NodeData>
    let onEvent: ((GraphEvent) -> Void)?
    let modifierKeys: ModifierKeysProvider?
    let content: AnyView
    
    // State to lock the intent at the start of operation | 操作開始時の意図をロックするためのステート
    @State private var selectionIntent: SelectionIntent = .replace
    private enum SelectionIntent { case replace, toggle }
    
    private enum NodeInteractionMode { case undecided, drag, click }
    @State private var interactionMode: NodeInteractionMode = .undecided

    var body: some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("viewport_container"))
                    .onChanged { value in
                        if interactionMode == .undecided {
                            // Lock the selection intent (toggle or replace) based on Shift state at start | 開始時に Shift の状態を見て選択意図（トグルか置換か）を固定
                            selectionIntent = (modifierKeys?.isShiftPressed == true) ? .toggle : .replace
                            
                            // Transition to drag mode if the translation distance exceeds a threshold | 移動距離が閾値を超えたらドラッグモードへ移行
                            let translation = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                            if translation > 4 {
                                interactionMode = .drag
                                startDragging(at: value.location)
                            }
                        } else if interactionMode == .drag {
                            updateDragging(to: value.location)
                        }
                    }
                    .onEnded { value in
                        if interactionMode == .drag {
                            stopDragging()
                        } else {
                            // Click judgment: Execute selection based on the captured intent | クリック判定: キャプチャされた意図に基づいて選択を実行
                            performSelection()
                        }
                        
                        // Reset | リセット
                        interactionMode = .undecided
                    }
            )
    }
    
    private func startDragging(at location: CGPoint) {
        guard store.runtimeState.interactivity.nodesDraggable else { return }
        let viewport = store.runtimeState.viewport.viewport
        let graphPointer = XYPosition(x: location.x, y: location.y).fromScreen(viewport: viewport)
        
        // Dragging support for multiple selection | 複数選択時のドラッグ対応
        let dragNodeIDs: [String] = node.selected ? Array(store.runtimeState.selection.selectedNodeIDs) : [node.id]
        store.startDragging(nodeIDs: dragNodeIDs, at: graphPointer)
        onEvent?(.dragStart(nodeIDs: dragNodeIDs))
    }
    
    private func updateDragging(to location: CGPoint) {
        let viewport = store.runtimeState.viewport.viewport
        let graphPointer = XYPosition(x: location.x, y: location.y).fromScreen(viewport: viewport)
        store.updateAutoPan(at: XYPosition(x: location.x, y: location.y))
        store.updateDragging(to: graphPointer)
        onEvent?(.dragUpdate(nodeIDs: [node.id]))
    }
    
    private func stopDragging() {
        let draggedIDs = store.runtimeState.drag.draggedNodes.map { $0.id }
        store.stopDragging()
        onEvent?(.dragStop(nodeIDs: draggedIDs))
    }
    
    private func performSelection() {
        guard store.runtimeState.interactivity.elementsSelectable else { return }
        if selectionIntent == .toggle {
            store.toggleNodeSelection(node.id)
        } else {
            store.selectNode(node.id)
        }
    }
}

/// Shared stack combining graph rendering layers (edges, nodes, preview). | グラフの描画レイヤー（エッジ、ノード、プレビュー）をまとめた共有スタック。
/// Used both in interactive GraphView and static export. | インタラクティブな GraphView と、静的なエクスポートの両方で使用されます。
internal struct GraphLayerStack<NodeData: Sendable, NodeContent: View>: View {
    let store: GraphStore<NodeData>
    let nodeBuilder: (BaseNode<NodeData>) -> NodeContent
    let edgeBuilder: (EdgeRenderContext<NodeData>) -> AnyView
    let onConnect: ((Connection) -> Void)?
    let onReconnect: ((String, Connection) -> Void)?
    let modifierKeys: ModifierKeysProvider?
    let containerSize: Dimensions
    let viewportCullingEnabled: Bool
    let viewportCullingMargin: Double
    let nodeWrapper: (BaseNode<NodeData>, AnyView) -> AnyView
    
    @Environment(\.graphRenderingViewport) private var renderingViewport
    @Environment(\.isGraphExporting) private var isGraphExporting
    
    init(
        store: GraphStore<NodeData>,
        nodeBuilder: @escaping (BaseNode<NodeData>) -> NodeContent,
        edgeBuilder: @escaping (EdgeRenderContext<NodeData>) -> AnyView,
        onConnect: ((Connection) -> Void)?,
        onReconnect: ((String, Connection) -> Void)?,
        modifierKeys: ModifierKeysProvider?,
        containerSize: Dimensions,
        viewportCullingEnabled: Bool,
        viewportCullingMargin: Double,
        nodeWrapper: @escaping (BaseNode<NodeData>, AnyView) -> AnyView
    ) {
        self.store = store
        self.nodeBuilder = nodeBuilder
        self.edgeBuilder = edgeBuilder
        self.onConnect = onConnect
        self.onReconnect = onReconnect
        self.modifierKeys = modifierKeys
        self.containerSize = containerSize
        self.viewportCullingEnabled = viewportCullingEnabled
        self.viewportCullingMargin = viewportCullingMargin
        self.nodeWrapper = nodeWrapper
    }

    private var activeViewport: Viewport {
        renderingViewport ?? store.runtimeState.viewport.viewport
    }

    private var shouldCullViewport: Bool {
        viewportCullingEnabled && !isGraphExporting
    }

    private var visibleNodeIDs: [String] {
        let sortedIDs = store.runtimeState.sortedNodeIDs
        guard shouldCullViewport else { return sortedIDs }

        let lookup = store.nodeLookup
        return sortedIDs.filter { id in
            guard let node = lookup[id] else { return false }
            if node.selected { return true }
            return GraphViewportCulling.isNodeVisible(
                node,
                absolutePosition: store.absolutePosition(for: node.id),
                viewport: activeViewport,
                containerSize: containerSize,
                screenMargin: viewportCullingMargin
            )
        }
    }

    private var visibleEdges: [BaseEdge<NodeData>] {
        guard shouldCullViewport else { return store.edges }

        return store.edges.filter { edge in
            if edge.selected { return true }
            guard let source = resolvedHandlePoint(for: edge, role: .source),
                  let target = resolvedHandlePoint(for: edge, role: .target) else {
                return false
            }
            return GraphViewportCulling.isEdgeVisible(
                source: source,
                target: target,
                viewport: activeViewport,
                containerSize: containerSize,
                screenMargin: viewportCullingMargin
            )
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            edgeLayer
            previewLayer
            nodeLayer
            automaticHandleLayer
            selectionBoxLayer
            edgeOverlayLayer
        }
    }
    
    @ViewBuilder
    private var selectionBoxLayer: some View {
        SelectionBoxView(store: store)
    }
    
    @ViewBuilder
    private var edgeLayer: some View {
        ForEach(visibleEdges) { edge in
            DefaultEdgeView(
                edge: edge,
                store: store,
                onReconnect: onReconnect,
                modifierKeys: modifierKeys ?? ModifierKeysProvider(),
                containerSize: containerSize,
                edgeBodyBuilder: edgeBuilder
            )
        }
    }

    // Single-pass partition: unselected first, selected on top | 1パスで分離: 非選択→選択の順で前面に重ねる
    private var partitionedOverlayEdges: (unselected: [BaseEdge<NodeData>], selected: [BaseEdge<NodeData>]) {
        var unselected: [BaseEdge<NodeData>] = []
        var selected: [BaseEdge<NodeData>] = []
        for edge in visibleEdges {
            if edge.selected { selected.append(edge) } else { unselected.append(edge) }
        }
        return (unselected, selected)
    }

    @ViewBuilder
    private var edgeOverlayLayer: some View {
        let parts = partitionedOverlayEdges
        let endpointLabelCollisionCache = EdgeEndpointLabelCollisionCache.build(
            store: store,
            edges: parts.unselected + parts.selected,
            viewport: activeViewport
        )
        ForEach(parts.unselected) { edge in
            DefaultEdgeOverlayView(
                edge: edge,
                store: store,
                onReconnect: onReconnect,
                containerSize: containerSize,
                endpointLabelCollisionCache: endpointLabelCollisionCache
            )
        }
        ForEach(parts.selected) { edge in
            DefaultEdgeOverlayView(
                edge: edge,
                store: store,
                onReconnect: onReconnect,
                containerSize: containerSize,
                endpointLabelCollisionCache: endpointLabelCollisionCache
            )
        }
    }

    @ViewBuilder
    private var previewLayer: some View {
        if let active = store.runtimeState.connection.active {
            ConnectionPreviewLine(active: active, store: store)
        }
    }

    @ViewBuilder
    private var nodeLayer: some View {
        let lookup = store.nodeLookup
        
        ForEach(visibleNodeIDs, id: \.self) { id in
            if let node = lookup[id] {
                let absolutePos = self.store.absolutePosition(for: node.id)
                let viewport = self.activeViewport
                let screenPos = absolutePos.toScreen(viewport: viewport)
                
                let content = NodeMeasurementWrapper(id: node.id, content: self.nodeBuilder(node))
                    .offset(x: screenPos.x, y: screenPos.y)
                
                nodeWrapper(node, AnyView(content))
            }
        }
    }

    @ViewBuilder
    private var automaticHandleLayer: some View {
        if !isGraphExporting {
            let viewport = self.activeViewport
            let lookup = store.nodeLookup
            ForEach(visibleNodeIDs, id: \.self) { nodeID in
                if let node = lookup[nodeID] {
                ForEach(node.handles.filter { $0.placementMode == .automaticPeerSide }, id: \.stableID) { handle in
                    let placement = store.resolvedNodeHandlePlacement(nodeID: node.id, handleID: handle.id, type: handle.type)
                    let key = HandleKey(nodeID: node.id, handleID: handle.id, type: handle.type, placement: placement)
                    let screenPosition = store.resolvedHandlePosition(for: key).toScreen(viewport: viewport)

                    HandleView<NodeData>(
                        nodeID: node.id,
                        handleID: handle.id,
                        type: handle.type,
                        placement: placement,
                        store: store,
                        onConnect: onConnect,
                        onReconnect: onReconnect
                    )
                    .position(x: screenPosition.x, y: screenPosition.y)
                    .zIndex(1)
                }
                }
            }
        }
    }

    private enum VisibleEdgeEndpointRole {
        case source
        case target
    }

    private func resolvedHandlePoint(for edge: BaseEdge<NodeData>, role: VisibleEdgeEndpointRole) -> XYPosition? {
        guard store.node(id: edge.source) != nil, store.node(id: edge.target) != nil else { return nil }
        let resolved = store.resolvedEdgePositions(for: edge)
        switch role {
        case .source:
            let key = HandleKey(nodeID: edge.source, handleID: edge.sourceHandle, type: .source, placement: resolved.source)
            return store.resolvedHandlePosition(for: key)
        case .target:
            let key = HandleKey(nodeID: edge.target, handleID: edge.targetHandle, type: .target, placement: resolved.target)
            return store.resolvedHandlePosition(for: key)
        }
    }
}

private extension NodeHandle {
    var stableID: String {
        [
            id ?? "__default__",
            type.rawValue,
            placement.rawValue,
            placementMode.rawValue
        ].joined(separator: "|")
    }
}

extension GraphView where NodeContent == DefaultNodeView<NodeData> {
    public init(
        store: GraphStore<NodeData>,
        onEvent: ((GraphEvent) -> Void)? = nil,
        onConnect: ((Connection) -> Void)? = nil,
        onReconnect: ((String, Connection) -> Void)? = nil
    ) {
        self.init(store: store, onEvent: onEvent, onConnect: onConnect, onReconnect: onReconnect, nodeBuilder: { node in
            DefaultNodeView(node: node, store: store, onConnect: onConnect)
        }, backgroundBuilder: {
            AnyView(GraphBackgroundViewWrapper(store: store))
        })
    }
}

/// Wrapper for Viewport resolution in background rendering | 背景描画の Viewport 解決用ラッパー
private struct GraphBackgroundViewWrapper<NodeData: Sendable>: View {
    let store: GraphStore<NodeData>
    @Environment(\.graphRenderingViewport) private var renderingViewport
    
    var body: some View {
        let viewport = renderingViewport ?? store.runtimeState.viewport.viewport
        AnyView(BackgroundView(viewport: viewport))
    }
}

/// Standard node display for the graph library | グラフライブラリ標準のノード表示
public struct DefaultNodeView<NodeData: Sendable>: View {
    let node: BaseNode<NodeData>
    let store: GraphStore<NodeData>
    let onConnect: ((Connection) -> Void)?
    
    public init(node: BaseNode<NodeData>, store: GraphStore<NodeData>, onConnect: ((Connection) -> Void)? = nil) {
        self.node = node
        self.store = store
        self.onConnect = onConnect
    }

    @Environment(\.graphZoomLevel) private var zoomLevel
    @Environment(\.graphRenderingViewport) private var renderingViewport
    @Environment(\.graphHandleStyle) private var handleStyle

    public var body: some View {
        let zoomScale = max(CGFloat(zoomLevel), 0.0001)
        let nodeWidth = node.width.map { CGFloat($0) * zoomScale }
        let nodeHeight = node.height.map { CGFloat($0) * zoomScale }
        
        VStack {
            Text(node.label ?? node.id)
                .font(.system(size: 12 * zoomScale, weight: .bold))
        }
        .padding(10 * zoomScale)
        .frame(width: nodeWidth, height: nodeHeight)
        .background(
            RoundedRectangle(cornerRadius: 5 * zoomScale)
                .fill(Self.backgroundColor)
                .shadow(radius: zoomLevel > 1.0 ? 0 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5 * zoomScale)
                .stroke(node.selected ? Color.primary : Color.gray.opacity(0.3), lineWidth: node.selected ? 3 : 1)
        )
        .shadow(
            color: Color.black.opacity(node.selected ? (zoomLevel > 1.0 ? 0 : 0.2) : (zoomLevel > 1.0 ? 0 : 0.1)),
            radius: node.selected ? (zoomLevel > 1.0 ? 0 : 5) : (zoomLevel > 1.0 ? 0 : 2)
        )
        .overlay(
            HStack {
                // Left target handle | 左側ターゲットハンドル
                HandleView<NodeData>(nodeID: node.id, type: .target, placement: .left, store: store, onConnect: onConnect)
                    .offset(x: -CGFloat(handleStyle.anchorOffset) * zoomScale)
                Spacer()
                // Right source handle | 右側ソースハンドル
                HandleView<NodeData>(nodeID: node.id, type: .source, placement: .right, store: store, onConnect: onConnect)
                    .offset(x: CGFloat(handleStyle.anchorOffset) * zoomScale)
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(node.ariaLabel ?? node.label ?? node.id)
        .accessibilityAddTraits(node.selected ? [.isSelected] : [])
        .accessibilityHint(node.selectable ? "Double tap to select | ダブルタップで選択" : "")
    }
    
    private static var backgroundColor: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #else
        return Color.white
        #endif
    }
}

/// Provisionary connection line displayed during dragging. | ドラッグ中に表示される暫定的な接続線。
struct ConnectionPreviewLine<NodeData: Sendable>: View {
    let active: ConnectionInProgressState
    let store: GraphStore<NodeData>
    
    @Environment(\.graphRenderingViewport) private var renderingViewport
    
    var body: some View {
        let sourceKey = HandleKey(nodeID: active.fromNodeID, handleID: active.fromHandleID, type: active.fromHandleType, placement: active.fromHandlePosition)
        let sourcePos = store.resolvedHandlePosition(for: sourceKey)
        
        let targetPos: XYPosition = {
            if let targetNodeID = active.targetNodeID, let targetPlacement = active.targetHandlePosition {
                let targetType = active.fromHandleType.opposite
                let targetKey = HandleKey(nodeID: targetNodeID, handleID: active.targetHandleID, type: targetType, placement: targetPlacement)
                return store.resolvedHandlePosition(for: targetKey)
            } else {
                return active.currentPointer
            }
        }()
        
        // Prioritize viewport used for rendering | 描画用のビューポートを優先
        let viewport = renderingViewport ?? store.runtimeState.viewport.viewport
        let sourceScreen = sourcePos.toScreen(viewport: viewport)
        let targetScreen = targetPos.toScreen(viewport: viewport)
        
        Path { path in
            path.move(to: CGPoint(x: sourceScreen.x, y: sourceScreen.y))
            path.addLine(to: CGPoint(x: targetScreen.x, y: targetScreen.y))
        }
        .stroke(
            active.targetNodeID != nil ? Color.blue : Color.blue.opacity(0.6),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])
        )
        .accessibilityHidden(true)
    }
}
