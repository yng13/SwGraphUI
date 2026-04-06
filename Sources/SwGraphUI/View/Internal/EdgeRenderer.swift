import SwiftUI

/// エッジの幾何情報を基に実際の描画を行う View。
/// PathSegment の配列を SwiftUI の Path に変換して描画します。
public struct EdgeRenderer: View {
    public let segments: [PathSegment]
    public let strokeColor: Color
    public let strokeWidth: CGFloat
    public let animated: Bool
    public let isReconnecting: Bool
    
    @State private var phase: CGFloat = 0
    
    public init(segments: [PathSegment], strokeColor: Color, strokeWidth: CGFloat, animated: Bool, isReconnecting: Bool) {
        self.segments = segments
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.animated = animated
        self.isReconnecting = isReconnecting
    }
    
    public var body: some View {
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
        .stroke(strokeColor, style: strokeStyle)
        .task(id: animated) {
            if animated {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    phase = -15
                }
            } else {
                withAnimation(.default) {
                    phase = 0
                }
            }
        }
    }
    
    private var strokeStyle: StrokeStyle {
        if isReconnecting {
            return StrokeStyle(lineWidth: strokeWidth, lineCap: .round, dash: [5, 5])
        }
        if animated {
            return StrokeStyle(lineWidth: strokeWidth, lineCap: .round, dash: [10, 5], dashPhase: phase)
        } else {
            return StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
        }
    }
}
