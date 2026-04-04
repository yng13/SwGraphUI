import SwiftUI

/// SwGraphUI のメインビューの骨格。
/// ズーム・パンの適用と、ドラッグ入力の GraphStore へのブリッジを担います。
public struct GraphView<Data: Sendable>: View {
    public let store: GraphStore<Data>
    
    public init(store: GraphStore<Data>) {
        self.store = store
    }
    
    public var body: some View {
        GeometryReader { geometry in
            // グラフ全体を表示するコンテナ
            ZStack(alignment: .topLeading) {
                // 背景 (パン操作などの拡張用)
                Color.clear
                    .contentShape(Rectangle())
                
                // ノードレイヤー
                ForEach(store.nodes) { node in
                    NodeView<Data>(node: node)
                        .offset(
                            x: store.absolutePosition(for: node.id).x,
                            y: store.absolutePosition(for: node.id).y
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .named("graph_space"))
                                .onChanged { value in
                                    let graphPointer = CoordinateAdapter.screenToGraph(
                                        XYPosition(x: value.location.x, y: value.location.y),
                                        viewport: store.runtimeState.viewport.viewport
                                    )
                                    
                                    if !store.runtimeState.drag.isDragging {
                                        store.startDragging(nodeIDs: [node.id], at: graphPointer)
                                    } else {
                                        store.updateDragging(to: graphPointer)
                                    }
                                }
                                .onEnded { _ in
                                    store.stopDragging()
                                }
                        )
                }
            }
            .coordinateSpace(name: "graph_space")
            // ビューポート変形の適用 (Scale -> Offset の順)
            .scaleEffect(store.runtimeState.viewport.viewport.zoom, anchor: .topLeading)
            .offset(x: store.runtimeState.viewport.viewport.x, y: store.runtimeState.viewport.viewport.y)
        }
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
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(radius: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(node.selected ? Color.blue : Color.gray.opacity(0.3), lineWidth: node.selected ? 2 : 1)
        )
    }
}
