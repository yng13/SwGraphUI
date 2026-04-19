import SwiftUI

/// ノードの接続端点（ハンドル）を表示し、ドラッグによる接続操作を提供するコンポーネント。
/// カスタムノード内でも自由に配置可能です。
public struct HandleView<NodeData: Sendable>: View {
    public let nodeID: String
    public let handleID: String?
    public let type: HandleType
    public let placement: Position
    public let store: GraphStore<NodeData>
    public let onConnect: ((Connection) -> Void)?
    public let onReconnect: ((String, Connection) -> Void)?
    
    // ヒットエリア拡大用の定数
    private let hitAreaPadding: CGFloat = 8
    private let handleSize: CGFloat = 6
    @Environment(\.graphZoomLevel) private var zoomLevel
    @Environment(\.isGraphExporting) private var isGraphExporting
    
    public init(
        nodeID: String,
        handleID: String? = nil,
        type: HandleType,
        placement: Position,
        store: GraphStore<NodeData>,
        onConnect: ((Connection) -> Void)? = nil,
        onReconnect: ((String, Connection) -> Void)? = nil
    ) {
        self.nodeID = nodeID
        self.handleID = handleID
        self.type = type
        self.placement = placement
        self.store = store
        self.onConnect = onConnect
        self.onReconnect = onReconnect
    }
    
    public var body: some View {
        let visibleSize = handleSize * max(CGFloat(zoomLevel), 0.0001)
        Circle()
            .fill(Color.gray.opacity(0.8))
            .frame(width: visibleSize, height: visibleSize)
            .padding(hitAreaPadding) // ヒットエリアを拡大
            .contentShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: visibleSize, height: visibleSize)
            )
            .background(
                GeometryReader { geometry in
                    let frame = geometry.frame(in: .named("viewport_container"))
                    let viewportCenter = XYPosition(
                        x: frame.midX,
                        y: frame.midY
                    )
                    
                    Color.clear
                        .preference(
                            key: HandlePositionPreferenceKey.self,
                            // エクスポート中は座標報告を抑制し、ライブデータの破壊を防ぐ
                            value: isGraphExporting ? [] : [
                                HandleMeasurementEntry(
                                    key: HandleKey(nodeID: nodeID, handleID: handleID, type: type, placement: placement),
                                    viewportCenter: viewportCenter
                                )
                            ]
                        )
                }
            )
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("viewport_container"))
                    .onChanged { value in
                        guard store.runtimeState.interactivity.nodesConnectable else { return }
                        let viewport = store.runtimeState.viewport.viewport
                        let pointerInGraph = XYPosition(x: value.location.x, y: value.location.y).fromScreen(viewport: viewport)
                        
                        if !store.runtimeState.connection.isConnecting {
                            // 開始時にハンドルのグラフ絶対座標を解決して開始
                            // 測定値がある場合はそれを優先し、なければ推測値（Fallback）を使用
                            let key = HandleKey(nodeID: nodeID, handleID: handleID, type: type, placement: placement)
                            let handlePos = store.resolvedHandlePosition(for: key)
                            
                            store.startConnecting(
                                fromNodeID: nodeID,
                                fromHandleID: handleID,
                                fromHandleType: type,
                                fromHandlePosition: placement,
                                fromPosition: handlePos,
                                at: pointerInGraph
                            )
                        } else {
                            // オートパンへの通知 (Screen space)
                            store.updateAutoPan(at: XYPosition(x: value.location.x, y: value.location.y))
                            
                            let targetKey = store.findHandle(near: pointerInGraph)
                            store.updateConnecting(
                                to: pointerInGraph,
                                targetNodeID: targetKey?.nodeID,
                                targetHandleID: targetKey?.handleID,
                                targetHandlePosition: targetKey?.placement
                            )
                        }
                    }
                    .onEnded { _ in
                        // 再接続 (reconnect) の場合は GraphStore 内部で更新が完結しているため、
                        // 外部の onConnect コールバック（新規追加用）を呼ばないように制御する。
                        let active = store.runtimeState.connection.active
                        let mode = active?.mode
                        
                        if let connection = store.stopConnecting() {
                            if case .connect = mode {
                                onConnect?(connection)
                            } else if case .reconnect(let edgeID, _) = mode {
                                onReconnect?(edgeID, connection)
                            }
                        }
                    }
            )
    }
}
