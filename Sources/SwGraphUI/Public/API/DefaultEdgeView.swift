import SwiftUI

/// グラフライブラリ標準のエッジ（接続線）表示。
public struct DefaultEdgeView<Data: Sendable>: View {
    let edge: BaseEdge<Data>
    let store: GraphStore<Data>
    let modifierKeys: ModifierKeysProvider
    
    public init(edge: BaseEdge<Data>, store: GraphStore<Data>, modifierKeys: ModifierKeysProvider) {
        self.edge = edge
        self.store = store
        self.modifierKeys = modifierKeys
    }
    
    public var body: some View {
        // Source/Target ノードの存在確認と表示状態のチェック
        if store.node(id: edge.source) != nil,
           store.node(id: edge.target) != nil {
            
            let sourcePosition = edge.sourcePosition ?? .right
            let targetPosition = edge.targetPosition ?? .left
            
            let sourceKey = HandleKey(nodeID: edge.source, handleID: edge.sourceHandle, type: .source, placement: sourcePosition)
            let targetKey = HandleKey(nodeID: edge.target, handleID: edge.targetHandle, type: .target, placement: targetPosition)
            
            let sourceHandlePos = store.resolvedHandlePosition(for: sourceKey)
            let targetHandlePos = store.resolvedHandlePosition(for: targetKey)
            
            let strokeWidth: CGFloat = edge.selected ? 3 : 2

            let baseResult: EdgePathResult = calculatePath(
                source: sourceHandlePos,
                target: targetHandlePos,
                sourcePosition: sourcePosition,
                targetPosition: targetPosition,
                kind: edge.kind,
                curvature: edge.curvature ?? 0.25
            )

            let shortenedSource = shortenedPosition(
                at: sourceHandlePos,
                tangentAngle: baseResult.sourceTangentAngle,
                fallbackPosition: sourcePosition,
                marker: edge.markerStart,
                strokeWidth: strokeWidth,
                isSource: true
            )

            let shortenedTarget = shortenedPosition(
                at: targetHandlePos,
                tangentAngle: baseResult.targetTangentAngle,
                fallbackPosition: targetPosition,
                marker: edge.markerEnd,
                strokeWidth: strokeWidth,
                isSource: false
            )

            // オリジナルの制御点を維持しつつ、端点のみを差し替えたパスを生成
            let adjustedSegments = adjustSegmentsForBackoff(
                baseResult.segments,
                shortenedSource: shortenedSource,
                shortenedTarget: shortenedTarget
            )
            
            return AnyView(ZStack {
                // 1. ヒットエリア（太いパス判定）
                let path = segmentsToPath(adjustedSegments)
                path
                    .stroke(Color.black.opacity(0.0001), lineWidth: 20)
                    .contentShape(path.stroke(lineWidth: 20))
                    .onTapGesture {
                        if modifierKeys.isShiftPressed {
                            store.toggleEdgeSelection(edge.id)
                        } else {
                            store.selectEdge(edge.id)
                        }
                    }

                // 2. 表示用エッジ
                EdgeRenderer(
                    segments: adjustedSegments,
                    strokeColor: edge.selected ? Color.primary : Color.gray,
                    strokeWidth: strokeWidth,
                    animated: edge.animated
                )
                
                // 3. 始点マーカー
                if let marker = edge.markerStart {
                    ArrowHead(
                        at: CGPoint(x: sourceHandlePos.x, y: sourceHandlePos.y),
                        angle: baseResult.sourceTangentAngle.map { Angle(radians: $0 + .pi) } ?? (
                            sourcePosition == .top ? .degrees(270) :
                            sourcePosition == .bottom ? .degrees(90) :
                            sourcePosition == .left ? .degrees(180) : .degrees(0)
                        ),
                        color: edge.selected ? Color.primary : Color.gray,
                        width: marker.width ?? 6.0,
                        height: marker.height ?? 6.0
                    )
                }

                // 4. 終了マーカー（矢印）
                if let marker = edge.markerEnd {
                    ArrowHead(
                        at: CGPoint(x: targetHandlePos.x, y: targetHandlePos.y),
                        angle: baseResult.targetTangentAngle.map { Angle(radians: $0) } ?? (
                            targetPosition == .top ? .degrees(90) :
                            targetPosition == .bottom ? .degrees(270) :
                            targetPosition == .left ? .degrees(0) : .degrees(180)
                        ),
                        color: edge.selected ? Color.primary : Color.gray,
                        width: marker.width ?? 6.0,
                        height: marker.height ?? 6.0
                    )
                }
            })
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private func adjustSegmentsForBackoff(
        _ segments: [PathSegment],
        shortenedSource: XYPosition,
        shortenedTarget: XYPosition
    ) -> [PathSegment] {
        guard !segments.isEmpty else { return [] }
        var result = segments
        
        // 最初の `.move(to:)` を差し替え
        if case .move = result[0] {
            result[0] = .move(to: shortenedSource)
        }
        
        // 最後のセグメントの目的値を差し替え
        let lastIndex = result.count - 1
        switch result[lastIndex] {
        case .line:
            result[lastIndex] = .line(to: shortenedTarget)
        case .bezier(_, let c1, let c2):
            result[lastIndex] = .bezier(to: shortenedTarget, control1: c1, control2: c2)
        case .quadratic(_, let c):
            result[lastIndex] = .quadratic(to: shortenedTarget, control: c)
        case .move:
            break
        }
        return result
    }
    
    private func calculatePath(
        source: XYPosition,
        target: XYPosition,
        sourcePosition: Position,
        targetPosition: Position,
        kind: String?,
        curvature: Double
    ) -> EdgePathResult {
        switch kind {
        case "straight":
            return EdgePathAlgorithms.straightPath(
                sourceX: source.x,
                sourceY: source.y,
                targetX: target.x,
                targetY: target.y
            )
        case "smoothstep":
            return EdgePathAlgorithms.smoothStepPath(
                sourceX: source.x,
                sourceY: source.y,
                sourcePosition: sourcePosition,
                targetX: target.x,
                targetY: target.y,
                targetPosition: targetPosition
            )
        case "step":
            return EdgePathAlgorithms.stepPath(
                sourceX: source.x,
                sourceY: source.y,
                sourcePosition: sourcePosition,
                targetX: target.x,
                targetY: target.y,
                targetPosition: targetPosition
            )
        default: // "bezier" or nil
            return EdgePathAlgorithms.bezierPath(
                sourceX: source.x,
                sourceY: source.y,
                sourcePosition: sourcePosition,
                targetX: target.x,
                targetY: target.y,
                targetPosition: targetPosition,
                curvature: curvature
            )
        }
    }

    private func shortenedPosition(
        at original: XYPosition,
        tangentAngle: Double?,
        fallbackPosition: Position,
        marker: EdgeMarker?,
        strokeWidth: CGFloat,
        isSource: Bool
    ) -> XYPosition {
        guard let marker else { return original }

        let markerLength = marker.width ?? 6.0
        let backoff = markerLength + Double(strokeWidth) / 2

        let unitVector: XYPosition
        if let tangentAngle {
            unitVector = XYPosition(x: cos(tangentAngle), y: sin(tangentAngle))
        } else {
            switch fallbackPosition {
            case .top:
                unitVector = XYPosition(x: 0, y: -1)
            case .bottom:
                unitVector = XYPosition(x: 0, y: 1)
            case .left:
                unitVector = XYPosition(x: -1, y: 0)
            case .right:
                unitVector = XYPosition(x: 1, y: 0)
            }
        }

        // source の場合は unitVector の方向に進む（バックオフ）
        // target の場合は unitVector の逆方向に進む（バックオフ）
        let multiplier = isSource ? 1.0 : -1.0
        return XYPosition(
            x: original.x + unitVector.x * backoff * multiplier,
            y: original.y + unitVector.y * backoff * multiplier
        )
    }

    private func segmentsToPath(_ segments: [PathSegment]) -> Path {
        Path { path in
            for segment in segments {
                switch segment {
                case .move(let to):
                    path.move(to: CGPoint(x: to.x, y: to.y))
                case .line(let to):
                    path.addLine(to: CGPoint(x: to.x, y: to.y))
                case .bezier(let to, let c1, let c2):
                    path.addCurve(
                        to: CGPoint(x: to.x, y: to.y),
                        control1: CGPoint(x: c1.x, y: c1.y),
                        control2: CGPoint(x: c2.x, y: c2.y)
                    )
                case .quadratic(let to, let c):
                    path.addQuadCurve(
                        to: CGPoint(x: to.x, y: to.y),
                        control: CGPoint(x: c.x, y: c.y)
                    )
                }
            }
        }
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
            let upper = rotatedPoint(
                origin: tip,
                localX: -width,
                localY: -height / 2,
                angle: angle.radians
            )
            let lower = rotatedPoint(
                origin: tip,
                localX: -width,
                localY: height / 2,
                angle: angle.radians
            )

            path.move(to: tip)
            path.addLine(to: upper)
            path.addLine(to: lower)
            path.closeSubpath()
        }
        .fill(color)
    }

    private func rotatedPoint(
        origin: CGPoint,
        localX: Double,
        localY: Double,
        angle: Double
    ) -> CGPoint {
        let x = localX * cos(angle) - localY * sin(angle)
        let y = localX * sin(angle) + localY * cos(angle)
        return CGPoint(x: origin.x + x, y: origin.y + y)
    }
}
