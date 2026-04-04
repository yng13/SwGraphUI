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
    
    // パン操作の継続的な変化量を計算するための内部用ステート
    @State private var lastPanTranslation: CGSize = .zero
    
    public init(
        store: GraphStore<Data>,
        onEvent: ((GraphEvent) -> Void)? = nil,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<Data>) -> NodeContent
    ) {
        self.store = store
        self.onEvent = onEvent
        self.nodeBuilder = nodeBuilder
    }
    
    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // 背景 (パン操作用) - 固定レイヤーに配置して追従を防ぐ
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

                    // 変形がかかるコンテンツレイヤー
                    ZStack(alignment: .topLeading) {
                        // ノードレイヤー
                        ForEach(store.nodes) { node in
                            NodeMeasurementWrapper(id: node.id, content: nodeBuilder(node))
                                .offset(
                                    x: store.absolutePosition(for: node.id).x,
                                    y: store.absolutePosition(for: node.id).y
                                )
                                .gesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .named("viewport_container"))
                                        .onChanged { value in
                                            let graphPointer = CoordinateAdapter.screenToGraph(
                                                XYPosition(x: value.location.x, y: value.location.y),
                                                viewport: store.runtimeState.viewport.viewport
                                            )
                                            
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
                    .scaleEffect(store.runtimeState.viewport.viewport.zoom, anchor: .topLeading)
                    .offset(x: store.runtimeState.viewport.viewport.x, y: store.runtimeState.viewport.viewport.y)
                }
            }
        }
        // 座標空間定義を「変形の外側」に配置
        .coordinateSpace(name: "viewport_container")
        .onPreferenceChange(NodeSizePreferenceKey.self) { entries in
            for entry in entries {
                store.updateNodeDimensions(
                    id: entry.id,
                    dimensions: Dimensions(width: entry.size.width, height: entry.size.height)
                )
            }
        }
    }
}

extension GraphView where NodeContent == DefaultNodeView<Data> {
    public init(store: GraphStore<Data>, onEvent: ((GraphEvent) -> Void)? = nil) {
        self.init(store: store, onEvent: onEvent) { node in
            DefaultNodeView(node: node)
        }
    }
}

/// グラフライブラリ標準のノード表示
public struct DefaultNodeView<Data: Sendable>: View {
    let node: BaseNode<Data>
    
    public init(node: BaseNode<Data>) {
        self.node = node
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
