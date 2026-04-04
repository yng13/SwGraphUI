import SwiftUI

/// グラフ内で発生したイベントの通知用
public enum GraphEvent: Sendable {
    case dragStart(nodeIDs: [String])
    case dragUpdate(nodeIDs: [String])
    case dragStop(nodeIDs: [String])
}

/// SwGraphUI のメインビューの骨格。
/// ズーム・パンの適用と、ドラッグ入力の GraphStore へのブリッジを担います。
public struct GraphView<Data: Sendable>: View {
    public let store: GraphStore<Data>
    public var onEvent: ((GraphEvent) -> Void)?
    
    // パン操作の継続的な変化量を計算するための内部用ステート
    @State private var lastPanTranslation: CGSize = .zero
    
    public init(store: GraphStore<Data>, onEvent: ((GraphEvent) -> Void)? = nil) {
        self.store = store
        self.onEvent = onEvent
    }
    
    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                // グラフ内容を表示するコンテナ
                ZStack(alignment: .topLeading) {
                    // 背景 (パン操作用)
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 10, coordinateSpace: .named("viewport_container"))
                                .onChanged { value in
                                    // 前回のイベント位置からの増分を計算 (delta)
                                    let deltaX = value.translation.width - lastPanTranslation.width
                                    let deltaY = value.translation.height - lastPanTranslation.height
                                    
                                    store.pan(by: XYPosition(x: deltaX, y: deltaY))
                                    lastPanTranslation = value.translation
                                }
                                .onEnded { _ in
                                    lastPanTranslation = .zero
                                }
                        )
                    
                    // ノードレイヤー
                    ForEach(store.nodes) { node in
                        NodeView<Data>(node: node)
                            .offset(
                                x: store.absolutePosition(for: node.id).x,
                                y: store.absolutePosition(for: node.id).y
                            )
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("viewport_container"))
                                    .onChanged { value in
                                        // viewport_container は変形「外側」の空間なので
                                        // location は画面上のポイントとして正しく screenToGraph に渡せる
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
                // ビューポート変形の適用 (Scale -> Offset の順)
                // この変形は「内側」の ZStack にのみかかる
                .scaleEffect(store.runtimeState.viewport.viewport.zoom, anchor: .topLeading)
                .offset(x: store.runtimeState.viewport.viewport.x, y: store.runtimeState.viewport.viewport.y)
            }
        }
        // 座標空間定義を「変形の外側」に配置
        .coordinateSpace(name: "viewport_container")
    }
}

/// 開発・検証用の最小限のノード表示
private struct NodeView<Data: Sendable>: View {
    let node: BaseNode<Data>
    
    var body: some View {
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
