import SwiftUI

/// エッジの幾何情報を基に実際の描画を行う View。
/// PathSegment の配列を SwiftUI の Path に変換して描画します。
public struct EdgeRenderer: View {
    public let segments: [PathSegment]
    public let strokeColor: Color
    public let strokeWidth: CGFloat
    public let viewport: Viewport
    public let animated: Bool
    public let isReconnecting: Bool
    
    public init(segments: [PathSegment], strokeColor: Color, strokeWidth: CGFloat, viewport: Viewport, animated: Bool, isReconnecting: Bool) {
        self.segments = segments
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.viewport = viewport
        self.animated = animated
        self.isReconnecting = isReconnecting
    }
    
    public var body: some View {
        TimelineView(.animation) { context in
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
        }
    }
    
    private func strokeStyle(at date: Date) -> StrokeStyle {
        let scaledWidth = strokeWidth * viewport.zoom
        let scaledShortDash: CGFloat = 5 * viewport.zoom
        let scaledLongDash: CGFloat = 10 * viewport.zoom
        if isReconnecting {
            return StrokeStyle(
                lineWidth: scaledWidth,
                lineCap: .round,
                dash: [scaledShortDash, scaledShortDash]
            )
        }
        if animated {
            let elapsed = date.timeIntervalSinceReferenceDate
            let dashCycle: CGFloat = scaledLongDash + scaledShortDash
            // ズームにかかわらずスクリーン空間上で秒速 30px (相当) の一定速度で流れるように計算
            // (elapsed * speed / zoom) に zoom を掛けることで、最終的な表示ピクセル速度を固定する
            let speed: CGFloat = 30
            let phase = CGFloat(-elapsed * speed)
                .truncatingRemainder(dividingBy: dashCycle)
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
