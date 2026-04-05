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
    
    // パン操作の継続的な変化量を計算するための内部用ステート
    @State private var lastPanTranslation: CGSize = .zero
    
    public init(
        store: GraphStore<Data>,
        onEvent: ((GraphEvent) -> Void)? = nil,
        onConnect: ((Connection) -> Void)? = nil,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<Data>) -> NodeContent
    ) {
        self.store = store
        self.onEvent = onEvent
        self.onConnect = onConnect
        self.nodeBuilder = nodeBuilder
    }
    
    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    backgroundLayerPart
                    viewportContainer
                }
                .coordinateSpace(name: "viewport_container")
            }
        }
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
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .named("viewport_container"))
                    .onChanged { value in
                        let deltaX = value.translation.width - lastPanTranslation.width
                        let deltaY = value.translation.height - lastPanTranslation.height
                        
                        store.pan(by: XYPosition(x: deltaX, y: deltaY))
                        lastPanTranslation = value.translation
                    }
                    .onEnded { _ in
                        lastPanTranslation = .zero
                    }
            )
    }

    @ViewBuilder
    private var viewportContainer: some View {
        ZStack(alignment: .topLeading) {
            edgeLayer
            previewLayer
            nodeLayer
        }
        .scaleEffect(store.runtimeState.viewport.viewport.zoom, anchor: .topLeading)
        .offset(x: store.runtimeState.viewport.viewport.x, y: store.runtimeState.viewport.viewport.y)
    }

    @ViewBuilder
    private var edgeLayer: some View {
        ForEach(store.edges) { edge in
            DefaultEdgeView(edge: edge, store: store)
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
        ForEach(store.nodes) { node in
            NodeMeasurementWrapper(id: node.id, content: nodeBuilder(node))
                .offset(
                    x: store.absolutePosition(for: node.id).x,
                    y: store.absolutePosition(for: node.id).y
                )
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("viewport_container"))
                        .onChanged { value in
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
                        .onEnded { _ in
                            store.stopDragging()
                            onEvent?(.dragStop(nodeIDs: [node.id]))
                        }
                )
        }
    }
}

extension GraphView where NodeContent == DefaultNodeView<Data> {
    public init(
        store: GraphStore<Data>,
        onEvent: ((GraphEvent) -> Void)? = nil,
        onConnect: ((Connection) -> Void)? = nil
    ) {
        self.init(store: store, onEvent: onEvent, onConnect: onConnect) { node in
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
                .stroke(node.selected ? Color.blue : Color.gray.opacity(0.3), lineWidth: node.selected ? 2 : 1)
        )
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
