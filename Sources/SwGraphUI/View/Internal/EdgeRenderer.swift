import SwiftUI

/// エッジの幾何情報を基に実際の描画を行う View。
/// PathSegment の配列を SwiftUI の Path に変換して描画します。
public struct EdgeRenderer: View {
    public let segments: [PathSegment]
    public let strokeColor: Color
    public let strokeWidth: CGFloat
    public let viewport: Viewport
    public let containerSize: Dimensions
    public let animated: Bool
    public let isReconnecting: Bool
    
    public init(segments: [PathSegment], strokeColor: Color, strokeWidth: CGFloat, viewport: Viewport, containerSize: Dimensions, animated: Bool, isReconnecting: Bool) {
        self.segments = segments
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.viewport = viewport
        self.containerSize = containerSize
        self.animated = animated
        self.isReconnecting = isReconnecting
    }
    
    public var body: some View {
        // 簡易 Culling: セグメントの全点（終点・制御点）から Bounding Box を作り、画面外なら描画スキップ
        if !segments.isEmpty {
            let containerWidth = containerSize.width
            let containerHeight = containerSize.height
            
            // 全点の最大最小を計算
            var minX = CGFloat.infinity
            var minY = CGFloat.infinity
            var maxX = -CGFloat.infinity
            var maxY = -CGFloat.infinity

            for segment in segments {
                for point in segment.points {
                    let p = point.toScreen(viewport: viewport)
                    minX = min(minX, p.x)
                    minY = min(minY, p.y)
                    maxX = max(maxX, p.x)
                    maxY = max(maxY, p.y)
                }
            }
            // マージン (100px) を持たせて判定。完全に画面外なら EmptyView
            if maxX < -100 || minX > containerWidth + 100 || maxY < -100 || minY > containerHeight + 100 {
                return AnyView(EmptyView())
            }
        }

        return AnyView(TimelineView(.animation) { context in
            Path { path in
                for segment in segments {
                    let screenSegment = segment.toScreen(viewport: viewport)
                    switch screenSegment {
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
            .stroke(strokeColor, style: strokeStyle(at: context.date))
        })
    }
    
    private func strokeStyle(at date: Date) -> StrokeStyle {
        let zoom = viewport.zoom
        let scaledWidth = strokeWidth * zoom
        
        let baseShortDash: CGFloat = 5
        let baseLongDash: CGFloat = 10
        let scaledShortDash = baseShortDash * zoom
        let scaledLongDash = baseLongDash * zoom
        
        if isReconnecting {
            return StrokeStyle(
                lineWidth: scaledWidth,
                lineCap: .round,
                dash: [scaledShortDash, scaledShortDash]
            )
        }
        
        if animated {
            let elapsed = date.timeIntervalSinceReferenceDate
            
            // 下記の計算により、スクリーン上で秒速 30px の一定速度を実現
            // dashCycle (Graph space 換算) で割った余りを phase にする
            let speedInGraph: CGFloat = 30 / zoom
            let phase = CGFloat(-elapsed * speedInGraph)
                .truncatingRemainder(dividingBy: baseLongDash + baseShortDash) * zoom
            
            return StrokeStyle(
                lineWidth: scaledWidth,
                lineCap: .round,
                dash: [scaledLongDash, scaledShortDash],
                dashPhase: phase
            )
        } else {
            return StrokeStyle(lineWidth: scaledWidth, lineCap: .round)
        }
    }
}
