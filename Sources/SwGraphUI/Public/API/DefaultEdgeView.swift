import SwiftUI
#if os(macOS)
import AppKit
#endif

/// グラフライブラリ標準のエッジ（接続線）表示。
/// ノードの背面に配置されるパス本体を担当します。
public struct DefaultEdgeView<Data: Sendable>: View {
    let edge: BaseEdge<Data>
    let store: GraphStore<Data>
    let onReconnect: ((String, Connection) -> Void)?
    let modifierKeys: ModifierKeysProvider?
    let edgeBodyBuilder: (([PathSegment], Color, CGFloat, Bool, Bool) -> AnyView)?

    
    public init(
        edge: BaseEdge<Data>,
        store: GraphStore<Data>,
        onReconnect: ((String, Connection) -> Void)? = nil,
        modifierKeys: ModifierKeysProvider? = nil,
        edgeBodyBuilder: (([PathSegment], Color, CGFloat, Bool, Bool) -> AnyView)? = nil
    ) {
        self.edge = edge
        self.store = store
        self.onReconnect = onReconnect
        self.modifierKeys = modifierKeys
        self.edgeBodyBuilder = edgeBodyBuilder
    }

    
    public var body: some View {
        if let (sourcePos, targetPos, sourceHandlePos, targetHandlePos) = resolvePositions() {
            let strokeWidth: CGFloat = edge.selected ? 3 : 2

            let baseResult = EdgePathAlgorithms.calculatePath(
                source: sourceHandlePos,
                target: targetHandlePos,
                sourcePosition: sourcePos,
                targetPosition: targetPos,
                kind: edge.kind,
                curvature: edge.curvature ?? 0.25
            )

            let shortenedSource = DefaultEdgeViewUtils.shortenedPosition(
                at: sourceHandlePos,
                tangentAngle: baseResult.sourceTangentAngle,
                marker: edge.markerStart,
                strokeWidth: strokeWidth,
                isSource: true
            )

            let shortenedTarget = DefaultEdgeViewUtils.shortenedPosition(
                at: targetHandlePos,
                tangentAngle: baseResult.targetTangentAngle,
                marker: edge.markerEnd,
                strokeWidth: strokeWidth,
                isSource: false
            )

            let isReconnecting = {
                if let active = store.runtimeState.connection.active,
                   case .reconnect(let id, _) = active.mode,
                   id == edge.id {
                    return true
                }
                return false
            }()

            let adjustedSegments = DefaultEdgeViewUtils.adjustSegmentsForBackoff(
                baseResult.segments,
                shortenedSource: shortenedSource,
                shortenedTarget: shortenedTarget
            )
            
            let path = DefaultEdgeViewUtils.segmentsToPath(adjustedSegments)

            return AnyView(ZStack {
                // 1. ヒットエリア（太いパス判定）
                path
                    .stroke(Color.black.opacity(0.0001), lineWidth: 20)
                    .contentShape(path.stroke(lineWidth: 20))
                    .onTapGesture {
                        if modifierKeys?.isShiftPressed == true {
                            store.toggleEdgeSelection(edge.id)
                        } else {
                            store.selectEdge(edge.id)
                        }
                    }

                // 2. 表示用エッジ
                Group {
                    if let edgeBodyBuilder = edgeBodyBuilder {
                        edgeBodyBuilder(
                            adjustedSegments,
                            edge.selected ? (isReconnecting ? Color.blue : Color.primary) : Color.gray,
                            strokeWidth,
                            edge.animated && !isReconnecting,
                            isReconnecting
                        )
                    } else {
                        EdgeRenderer(
                            segments: adjustedSegments,
                            strokeColor: edge.selected ? (isReconnecting ? Color.blue : Color.primary) : Color.gray,
                            strokeWidth: strokeWidth,
                            animated: edge.animated && !isReconnecting,
                            isReconnecting: isReconnecting
                        )
                    }
                }

                .opacity(isReconnecting ? 0.3 : 1.0)
                
                // 3. 始点マーカー
                if let marker = edge.markerStart {
                    ArrowHead(
                        at: CGPoint(x: sourceHandlePos.x, y: sourceHandlePos.y),
                        angle: baseResult.sourceTangentAngle.map { Angle(radians: $0 + .pi) } ?? (
                            sourcePos == .top ? .degrees(270) :
                            sourcePos == .bottom ? .degrees(90) :
                            sourcePos == .left ? .degrees(180) : .degrees(0)
                        ),
                        color: edge.selected ? Color.primary : Color.gray,
                        width: marker.width ?? 6.0,
                        height: marker.height ?? 6.0
                    )
                    .opacity(isReconnecting ? 0.3 : 1.0)
                }

                // 4. 終了マーカー（矢印）
                if let marker = edge.markerEnd {
                    ArrowHead(
                        at: CGPoint(x: targetHandlePos.x, y: targetHandlePos.y),
                        angle: baseResult.targetTangentAngle.map { Angle(radians: $0) } ?? (
                            targetPos == .top ? .degrees(90) :
                            targetPos == .bottom ? .degrees(270) :
                            targetPos == .left ? .degrees(0) : .degrees(180)
                        ),
                        color: edge.selected ? Color.primary : Color.gray,
                        width: marker.width ?? 6.0,
                        height: marker.height ?? 6.0
                    )
                    .opacity(isReconnecting ? 0.3 : 1.0)
                }
            })
        } else {
            return AnyView(EmptyView())
        }
    }

    private func resolvePositions() -> (Position, Position, XYPosition, XYPosition)? {
        guard store.node(id: edge.source) != nil, store.node(id: edge.target) != nil else { return nil }
        
        let sourcePos = edge.sourcePosition ?? .right
        let targetPos = edge.targetPosition ?? .left
        
        let sourceKey = HandleKey(nodeID: edge.source, handleID: edge.sourceHandle, type: .source, placement: sourcePos)
        let targetKey = HandleKey(nodeID: edge.target, handleID: edge.targetHandle, type: .target, placement: targetPos)
        
        return (sourcePos, targetPos, store.resolvedHandlePosition(for: sourceKey), store.resolvedHandlePosition(for: targetKey))
    }
}

/// エッジのオーバーレイ（ラベル、再接続ハンドル）を表示。
/// ノードの前面に配置されることを想定しています。
public struct DefaultEdgeOverlayView<Data: Sendable>: View {
    let edge: BaseEdge<Data>
    let store: GraphStore<Data>
    var onReconnect: ((String, Connection) -> Void)? = nil
    
    public init(edge: BaseEdge<Data>, store: GraphStore<Data>, onReconnect: ((String, Connection) -> Void)? = nil) {
        self.edge = edge
        self.store = store
        self.onReconnect = onReconnect
    }
    
    public var body: some View {
        if store.node(id: edge.source) != nil, store.node(id: edge.target) != nil {
            let sourcePos = edge.sourcePosition ?? .right
            let targetPos = edge.targetPosition ?? .left
            let sourceKey = HandleKey(nodeID: edge.source, handleID: edge.sourceHandle, type: .source, placement: sourcePos)
            let targetKey = HandleKey(nodeID: edge.target, handleID: edge.targetHandle, type: .target, placement: targetPos)
            let sourceHandlePos = store.resolvedHandlePosition(for: sourceKey)
            let targetHandlePos = store.resolvedHandlePosition(for: targetKey)

            let baseResult = EdgePathAlgorithms.calculatePath(
                source: sourceHandlePos,
                target: targetHandlePos,
                sourcePosition: sourcePos,
                targetPosition: targetPos,
                kind: edge.kind,
                curvature: edge.curvature ?? 0.25
            )

            ZStack {
                // 1. ラベル表示
                if let label = edge.label, !label.isEmpty {
                    EdgeLabelView(label: label, style: edge.labelStyle)
                        .position(x: baseResult.labelX, y: baseResult.labelY)
                }

                // 2. 再接続ハンドル（ラベルより前面へ）
                if edge.selected {
                    let sourceKey = HandleKey(nodeID: edge.source, handleID: edge.sourceHandle, type: .source, placement: edge.sourcePosition ?? .right)
                    let targetKey = HandleKey(nodeID: edge.target, handleID: edge.targetHandle, type: .target, placement: edge.targetPosition ?? .left)
                    let sourceHandlePos = store.resolvedHandlePosition(for: sourceKey)
                    let targetHandlePos = store.resolvedHandlePosition(for: targetKey)

                    if edge.reconnectable == .source || edge.reconnectable == .both {
                        ReconnectAnchor(
                            edge: edge,
                            handleType: .source,
                            position: CGPoint(x: sourceHandlePos.x, y: sourceHandlePos.y),
                            store: store,
                            onReconnect: onReconnect
                        )
                        .zIndex(100)
                    }
                    if edge.reconnectable == .target || edge.reconnectable == .both {
                        ReconnectAnchor(
                            edge: edge,
                            handleType: .target,
                            position: CGPoint(x: targetHandlePos.x, y: targetHandlePos.y),
                            store: store,
                            onReconnect: onReconnect
                        )
                        .zIndex(100)
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}

// 共通ユーティリティを内部クラスに集約
private struct DefaultEdgeViewUtils {
    static func shortenedPosition(
        at original: XYPosition,
        tangentAngle: Double?,
        marker: EdgeMarker?,
        strokeWidth: CGFloat,
        isSource: Bool
    ) -> XYPosition {
        guard let marker = marker, let angle = tangentAngle else { return original }
        
        let backoff = (marker.width ?? 6.0) + strokeWidth
        let dx = cos(angle) * backoff
        let dy = sin(angle) * backoff
        
        if isSource {
            // Source はパスの進行方向へ移動して短縮
            return XYPosition(x: original.x + dx, y: original.y + dy)
        } else {
            // Target はパスの進行方向の逆へ移動して短縮
            return XYPosition(x: original.x - dx, y: original.y - dy)
        }
    }

    static func adjustSegmentsForBackoff(
        _ segments: [PathSegment],
        shortenedSource: XYPosition,
        shortenedTarget: XYPosition
    ) -> [PathSegment] {
        guard !segments.isEmpty else { return [] }
        var result = segments
        if case .move = result[0] {
            result[0] = .move(to: shortenedSource)
        }
        let lastIndex = result.count - 1
        switch result[lastIndex] {
        case .line: result[lastIndex] = .line(to: shortenedTarget)
        case .bezier(_, let c1, let c2): result[lastIndex] = .bezier(to: shortenedTarget, control1: c1, control2: c2)
        case .quadratic(_, let c): result[lastIndex] = .quadratic(to: shortenedTarget, control: c)
        case .move: break
        }
        return result
    }

    static func segmentsToPath(_ segments: [PathSegment]) -> Path {
        Path { path in
            for segment in segments {
                switch segment {
                case .move(let to): path.move(to: CGPoint(x: to.x, y: to.y))
                case .line(let to): path.addLine(to: CGPoint(x: to.x, y: to.y))
                case .bezier(let to, let c1, let c2):
                    path.addCurve(to: CGPoint(x: to.x, y: to.y), control1: CGPoint(x: c1.x, y: c1.y), control2: CGPoint(x: c2.x, y: c2.y))
                case .quadratic(let to, let c):
                    path.addQuadCurve(to: CGPoint(x: to.x, y: to.y), control: CGPoint(x: c.x, y: c.y))
                }
            }
        }
    }
}

/// 再接続のためのドラッグハンドル
struct ReconnectAnchor<Data: Sendable>: View {
    let edge: BaseEdge<Data>
    let handleType: HandleType
    let position: CGPoint
    let store: GraphStore<Data>
    let onReconnect: ((String, Connection) -> Void)?
    
    @State private var isHovering = false
    
    var body: some View {
        let isConnecting = store.runtimeState.connection.isConnecting
        let isActive = store.runtimeState.connection.active?.mode.edgeID == edge.id
        // ドラッグ中のもう片方のハンドルは半透明にする
        let opacity = (isConnecting && !isActive) ? 0.3 : 1.0
        
        Circle()
            .fill(isHovering || isActive ? Color.blue : Color.blue.opacity(0.6))
            .frame(width: isHovering || isActive ? 12 : 8, height: isHovering || isActive ? 12 : 8)
            .scaleEffect(isHovering || isActive ? 1.2 : 1.0)
            .animation(.spring(response: 0.2), value: isHovering || isActive)
            .opacity(opacity)
            .padding(12) // ヒットエリア
            .contentShape(Circle())
            .position(position)
            .onHover { inside in
                isHovering = inside
                #if os(macOS)
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
                #endif
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("viewport_container"))
                    .onChanged { value in
                        guard store.runtimeState.interactivity.nodesConnectable else { return }
                        let viewport = store.runtimeState.viewport.viewport
                        let graphPointer = XYPosition(x: value.location.x, y: value.location.y).fromScreen(viewport: viewport)
                        
                        if !store.runtimeState.connection.isConnecting {
                            let isReconnectingSource = (handleType == .source)
                            let fixedNodeID = isReconnectingSource ? edge.target : edge.source
                            let fixedHandleID = isReconnectingSource ? edge.targetHandle : edge.sourceHandle
                            let fixedHandleType: HandleType = isReconnectingSource ? .target : .source
                            let fixedPlacement = isReconnectingSource ? (edge.targetPosition ?? .left) : (edge.sourcePosition ?? .right)
                            
                            print("[DEBUG] Reconnect Start: handleType=\(handleType), isSource=\(isReconnectingSource), fixedNode=\(fixedNodeID), fixedHandleType=\(fixedHandleType)")

                            let fixedKey = HandleKey(nodeID: fixedNodeID, handleID: fixedHandleID, type: fixedHandleType, placement: fixedPlacement)
                            let fixedPos = store.resolvedHandlePosition(for: fixedKey)
                            
                            store.startConnecting(
                                fromNodeID: fixedNodeID,
                                fromHandleID: fixedHandleID,
                                fromHandleType: fixedHandleType,
                                fromHandlePosition: fixedPlacement,
                                fromPosition: fixedPos,
                                at: graphPointer,
                                mode: .reconnect(edgeID: edge.id, isSource: isReconnectingSource)
                            )
                        } else {
                            if let nearest = store.findHandle(near: graphPointer, threshold: ConnectionInteractionManager.snapDistance) {
                                store.updateConnecting(
                                    to: graphPointer,
                                    targetNodeID: nearest.nodeID,
                                    targetHandleID: nearest.handleID,
                                    targetHandlePosition: nearest.placement
                                )
                            } else {
                                store.updateConnecting(to: graphPointer)
                            }
                        }
                    }
                    .onEnded { _ in
                        let active = store.runtimeState.connection.active
                        let mode = active?.mode
                        
                        if let connection = store.stopConnecting() {
                            if case .reconnect(let edgeID, _) = mode {
                                onReconnect?(edgeID, connection)
                            }
                        }
                    }
            )
    }
}

private struct ArrowHead: View {
    let at: CGPoint
    let angle: Angle
    let color: Color
    let width: Double
    let height: Double
    
    var body: some View {
        Path { path in
            let tip = at
            let upper = rotatedPoint(origin: tip, localX: -width, localY: -height / 2, angle: angle.radians)
            let lower = rotatedPoint(origin: tip, localX: -width, localY: height / 2, angle: angle.radians)
            path.move(to: tip)
            path.addLine(to: upper)
            path.addLine(to: lower)
            path.closeSubpath()
        }
        .fill(color)
    }

    private func rotatedPoint(origin: CGPoint, localX: Double, localY: Double, angle: Double) -> CGPoint {
        let x = localX * cos(angle) - localY * sin(angle)
        let y = localX * sin(angle) + localY * cos(angle)
        return CGPoint(x: origin.x + x, y: origin.y + y)
    }
}


extension EdgePathAlgorithms {
    // 既存の calculatePath への公開アクセスをサポート
    static func calculatePath(
        source: XYPosition,
        target: XYPosition,
        sourcePosition: Position,
        targetPosition: Position,
        kind: String?,
        curvature: Double
    ) -> EdgePathResult {
        switch kind {
        case "straight": return straightPath(sourceX: source.x, sourceY: source.y, targetX: target.x, targetY: target.y)
        case "smoothstep": return smoothStepPath(sourceX: source.x, sourceY: source.y, sourcePosition: sourcePosition, targetX: target.x, targetY: target.y, targetPosition: targetPosition)
        case "step": return stepPath(sourceX: source.x, sourceY: source.y, sourcePosition: sourcePosition, targetX: target.x, targetY: target.y, targetPosition: targetPosition)
        default: return bezierPath(sourceX: source.x, sourceY: source.y, sourcePosition: sourcePosition, targetX: target.x, targetY: target.y, targetPosition: targetPosition, curvature: curvature)
        }
    }
}
