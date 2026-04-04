import SwiftUI

/// グラフライブラリ標準のエッジ（接続線）表示。
public struct DefaultEdgeView<Data: Sendable>: View {
    let edge: BaseEdge<Data>
    let store: GraphStore<Data>
    
    public init(edge: BaseEdge<Data>, store: GraphStore<Data>) {
        self.edge = edge
        self.store = store
    }
    
    public var body: some View {
        // Source/Target ノードの存在確認と表示状態のチェック
        if let sourceNode = store.nodes.first(where: { $0.id == edge.source }),
           let targetNode = store.nodes.first(where: { $0.id == edge.target }),
           !sourceNode.hidden, !targetNode.hidden {
            
            let sPos = store.absolutePosition(for: edge.source)
            let tPos = store.absolutePosition(for: edge.target)
            
            let sourceHandlePos = NodePositioningAlgorithms.getHandlePosition(
                node: sourceNode,
                handlePlacement: edge.sourcePosition ?? .bottom,
                absPos: sPos
            )
            let targetHandlePos = NodePositioningAlgorithms.getHandlePosition(
                node: targetNode,
                handlePlacement: edge.targetPosition ?? .top,
                absPos: tPos
            )
            
            let targetPosition = edge.targetPosition ?? .top
            let sourcePosition = edge.sourcePosition ?? .bottom
            let strokeWidth: CGFloat = edge.selected ? 3 : 2

            let baseResult: EdgePathResult = calculatePath(
                source: sourceHandlePos,
                target: targetHandlePos,
                sourcePosition: sourcePosition,
                targetPosition: targetPosition,
                kind: edge.kind,
                curvature: edge.curvature ?? 0.25
            )

            let shortenedTarget = shortenedTargetPosition(
                originalTarget: targetHandlePos,
                tangentAngle: baseResult.targetTangentAngle,
                fallbackTargetPosition: targetPosition,
                marker: edge.markerEnd,
                strokeWidth: strokeWidth
            )

            let result: EdgePathResult = calculatePath(
                source: sourceHandlePos,
                target: shortenedTarget,
                sourcePosition: sourcePosition,
                targetPosition: targetPosition,
                kind: edge.kind,
                curvature: edge.curvature ?? 0.25
            )
            
            return AnyView(ZStack {
                EdgeRenderer(
                    segments: result.segments,
                    strokeColor: edge.selected ? Color.blue : Color.gray,
                    strokeWidth: strokeWidth,
                    animated: edge.animated
                )
                
                // 終了マーカー（矢印）
                if let marker = edge.markerEnd {
                    ArrowHead(
                        at: CGPoint(x: targetHandlePos.x, y: targetHandlePos.y),
                        angle: result.targetTangentAngle.map { Angle(radians: $0) } ?? (
                            // 接線が取れない場合のフォールバック（ハンドルの流儀に合わせる）
                            targetPosition == .top ? .degrees(90) :
                            targetPosition == .bottom ? .degrees(270) :
                            targetPosition == .left ? .degrees(0) : .degrees(180)
                        ),
                        color: edge.selected ? Color.blue : Color.gray,
                        width: marker.width ?? 6.0,
                        height: marker.height ?? 6.0
                    )
                }
            })
        } else {
            return AnyView(EmptyView())
        }
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

    private func shortenedTargetPosition(
        originalTarget: XYPosition,
        tangentAngle: Double?,
        fallbackTargetPosition: Position,
        marker: EdgeMarker?,
        strokeWidth: CGFloat
    ) -> XYPosition {
        guard let marker else { return originalTarget }

        let markerLength = marker.width ?? 6.0
        let backoff = markerLength + Double(strokeWidth) / 2

        let unitVector: XYPosition
        if let tangentAngle {
            unitVector = XYPosition(x: cos(tangentAngle), y: sin(tangentAngle))
        } else {
            switch fallbackTargetPosition {
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

        return XYPosition(
            x: originalTarget.x - unitVector.x * backoff,
            y: originalTarget.y - unitVector.y * backoff
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
