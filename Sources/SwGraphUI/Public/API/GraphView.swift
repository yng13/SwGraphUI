import SwiftUI

/// グラフ内で発生したイベントの通知用
public enum GraphEvent: Sendable {
    case dragStart(nodeIDs: [String])
    case dragUpdate(nodeIDs: [String])
    case dragStop(nodeIDs: [String])
}

/// SwGraphUI のメインビューの骨格。
/// ズーム・パンの適用と、ドラッグ入力の GraphStore へのブリッジを担います。
public struct GraphView<Data: Sendable, NodeContent: View>: View {
    public let store: GraphStore<Data>
    public let nodeBuilder: (BaseNode<Data>) -> NodeContent
    public var onEvent: ((GraphEvent) -> Void)?
    public var onConnect: ((Connection) -> Void)?
    public var onReconnect: ((String, Connection) -> Void)?
    
    // 修飾キーの状態監視アダプター
    @State private var modifierKeys = ModifierKeysProvider()
    
    // Zoom / Hover 用状態
    @State private var hoverLocation: CGPoint = .zero
    @State private var lastMagnification: CGFloat = 1.0
    #if os(macOS)
    @StateObject private var scrollMonitor = ScrollMonitor()
    #endif
    
    // パンまたは Marquee 操作の継続的な変化量を計算するための内部用ステート
    @State private var lastPanTranslation: CGSize = .zero
    @State private var isMarqueeMode: Bool = false
    
    public init(
        store: GraphStore<Data>,
        onEvent: ((GraphEvent) -> Void)? = nil,
        onConnect: ((Connection) -> Void)? = nil,
        onReconnect: ((String, Connection) -> Void)? = nil,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<Data>) -> NodeContent
    ) {
        self.store = store
        self.onEvent = onEvent
        self.onConnect = onConnect
        self.onReconnect = onReconnect
        self.nodeBuilder = nodeBuilder
    }
    
    public var body: some View {
        let _ = modifierKeys.isShiftPressed // Body のリアクティブ性を確保
        
        ZStack {
            GeometryReader { geometry in
                // ビューポート（グラフ空間）コンテナ
                viewportContainer
                
                // 矩形選択の表示（最前面、ただし座標系は viewport_container / スクリーン座標系）
                if let marquee = store.runtimeState.marquee {
                    MarqueeView(marquee: marquee)
                }
            }
            .coordinateSpace(name: "viewport_container")
        }
        .onAppear {
            _ = modifierKeys.isShiftPressed // 初期アクセスで監視開始
            
            #if os(macOS)
            scrollMonitor.onEvent = { [store, weak scrollMonitor] event in
                let location = scrollMonitor?.location ?? .zero
                if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) {
                    let factor = exp(event.scrollingDeltaY * 0.01) // ホイール量に応じた倍率
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
                    let factor = value.magnification / lastMagnification
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
                    dimensions: Dimensions(width: entry.size.width, height: entry.size.height)
                )
            }
        }
        .onPreferenceChange(HandlePositionPreferenceKey.self) { entries in
            let viewport = store.runtimeState.viewport.viewport
            for entry in entries {
                // スクリーン（viewport_container）座標系をグラフ絶対座標に変換
                let absoluteCenter = entry.viewportCenter.fromScreen(viewport: viewport)
                store.updateHandlePosition(key: entry.key, absolutePosition: absoluteCenter)
            }
        }
    }

    // MARK: - Layer Components

    @ViewBuilder
    private var backgroundLayerPart: some View {
        // ヒットテストを確実にするため、完全に透明ではない色を使用
        Color.black.opacity(0.0001)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("viewport_container"))
                    .onChanged { value in
                        if modifierKeys.isShiftPressed {
                            if !isMarqueeMode {
                                isMarqueeMode = true
                                store.startMarquee(at: value.startLocation)
                            }
                            store.updateMarquee(to: value.location)
                        } else {
                            if !isMarqueeMode {
                                // パン操作
                                let deltaX = value.translation.width - lastPanTranslation.width
                                let deltaY = value.translation.height - lastPanTranslation.height
                                store.pan(by: XYPosition(x: deltaX, y: deltaY))
                                lastPanTranslation = value.translation
                            }
                        }
                    }
                    .onEnded { value in
                        if isMarqueeMode {
                            store.endMarquee(isShiftPressed: true)
                            isMarqueeMode = false
                        } else {
                            // 移動距離が小さい場合は背景タップとみなしてクリア
                            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                            if distance < 5 {
                                store.clearSelection()
                            }
                        }
                        lastPanTranslation = .zero
                    }
            )
    }

    @ViewBuilder
    private var viewportContainer: some View {
        ZStack(alignment: .topLeading) {
            backgroundLayerPart
            
            edgeLayer
            previewLayer
            nodeLayer
            edgeOverlayLayer
        }
        .scaleEffect(store.runtimeState.viewport.viewport.zoom, anchor: .topLeading)
        .offset(x: store.runtimeState.viewport.viewport.x, y: store.runtimeState.viewport.viewport.y)
    }

    @ViewBuilder
    private var edgeLayer: some View {
        ForEach(store.edges) { edge in
            DefaultEdgeView(edge: edge, store: store, modifierKeys: modifierKeys)
        }
    }

    @ViewBuilder
    private var edgeOverlayLayer: some View {
        // Pass 1: 非選択のエッジ（ラベルのみ）
        ForEach(store.edges.filter { !$0.selected }) { edge in
            DefaultEdgeOverlayView(edge: edge, store: store, onReconnect: onReconnect)
        }
        // Pass 2: 選択中のエッジ（ラベル + ハンドルを最前面に）
        ForEach(store.edges.filter { $0.selected }) { edge in
            DefaultEdgeOverlayView(edge: edge, store: store, onReconnect: onReconnect)
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
        ForEach(self.store.nodes) { (node: BaseNode<Data>) in
            NodeMeasurementWrapper(id: node.id, content: self.nodeBuilder(node))
                .offset(
                    x: self.store.absolutePosition(for: node.id).x,
                    y: self.store.absolutePosition(for: node.id).y
                )
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("viewport_container"))
                        .onChanged { [store = self.store, onEvent = self.onEvent] value in
                            let translation = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                            if translation > 4 {
                                let viewport = store.runtimeState.viewport.viewport
                                let graphPointer = XYPosition(x: value.location.x, y: value.location.y).fromScreen(viewport: viewport)
                                
                                if !store.runtimeState.drag.isDragging {
                                    store.startDragging(nodeIDs: [node.id], at: graphPointer)
                                    onEvent?(.dragStart(nodeIDs: [node.id]))
                                } else {
                                    store.updateDragging(to: graphPointer)
                                    onEvent?(.dragUpdate(nodeIDs: [node.id]))
                                }
                            }
                        }
                        .onEnded { [store = self.store, modifierKeys = self.modifierKeys, onEvent = self.onEvent] value in
                            if store.runtimeState.drag.isDragging {
                                store.stopDragging()
                                onEvent?(.dragStop(nodeIDs: [node.id]))
                            } else {
                                // 移動距離が閾値 (4px) 未満だった場合はタップとみなして選択
                                if modifierKeys.isShiftPressed {
                                    store.toggleNodeSelection(node.id)
                                } else {
                                    store.selectNode(node.id)
                                }
                            }
                        }
                )
        }
    }
}

extension GraphView where NodeContent == DefaultNodeView<Data> {
    public init(
        store: GraphStore<Data>,
        onEvent: ((GraphEvent) -> Void)? = nil,
        onConnect: ((Connection) -> Void)? = nil,
        onReconnect: ((String, Connection) -> Void)? = nil
    ) {
        self.init(store: store, onEvent: onEvent, onConnect: onConnect, onReconnect: onReconnect) { node in
            DefaultNodeView(node: node, store: store, onConnect: onConnect)
        }
    }
}

/// グラフライブラリ標準のノード表示
public struct DefaultNodeView<Data: Sendable>: View {
    let node: BaseNode<Data>
    let store: GraphStore<Data>
    let onConnect: ((Connection) -> Void)?
    
    public init(node: BaseNode<Data>, store: GraphStore<Data>, onConnect: ((Connection) -> Void)? = nil) {
        self.node = node
        self.store = store
        self.onConnect = onConnect
    }
    
    public var body: some View {
        VStack {
            Text(node.id)
                .font(.caption)
                .bold()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Self.backgroundColor)
                .shadow(radius: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(node.selected ? Color.primary : Color.gray.opacity(0.3), lineWidth: node.selected ? 3 : 1)
        )
        .shadow(color: Color.black.opacity(node.selected ? 0.2 : 0.1), radius: node.selected ? 5 : 2)
        .overlay(
            HStack {
                // 左側ターゲットハンドル
                HandleView(nodeID: node.id, type: .target, placement: .left, store: store, onConnect: onConnect)
                    .offset(x: -8)
                Spacer()
                // 右側ソースハンドル
                HandleView(nodeID: node.id, type: .source, placement: .right, store: store, onConnect: onConnect)
                    .offset(x: 8)
            }
        )
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

/// ドラッグ中に表示される暫定的な接続線。
struct ConnectionPreviewLine<Data: Sendable>: View {
    let active: ConnectionInProgressState
    let store: GraphStore<Data>
    
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
        
        Path { path in
            path.move(to: CGPoint(x: sourcePos.x, y: sourcePos.y))
            path.addLine(to: CGPoint(x: targetPos.x, y: targetPos.y))
        }
        .stroke(
            active.targetNodeID != nil ? Color.blue : Color.blue.opacity(0.6),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])
        )
    }
}
