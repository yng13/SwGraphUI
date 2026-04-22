import SwiftUI

/// View that performs actual drawing based on edge geometric information. | エッジの幾何情報を基に実際の描画を行う View。
/// Converts an array of PathSegments to a SwiftUI Path for rendering. | PathSegment の配列を SwiftUI の Path に変換して描画します。
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
        // Simple Culling: Create a Bounding Box from all points (endpoints, control points) of the segments and skip drawing if outside the screen | 簡易 Culling: セグメントの全点（終点・制御点）から Bounding Box を作り、画面外なら描画スキップ
        if !segments.isEmpty {
            let containerWidth = containerSize.width
            let containerHeight = containerSize.height
            
            // Calculate the minimum and maximum of all points | 全点の最大最小を計算
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
            // Judge with a margin (100px). Returns EmptyView if completely outside the screen | マージン (100px) を持たせて判定。完全に画面外なら EmptyView
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
        
        // M36: Keep the "visual interval" and "spark flow speed" constant in physical pixels across all zoom ranges. | M36: 全ズーム域で「見た目の間隔」と「火花の流れる速度」を物理ピクセルで一定に保つ。
        // Since the Path itself is already converted to screen coordinates (toScreen), no need to multiply the dash array by zoom. | Path 自体が toScreen 済みのため、dash 配列に zoom を掛ける必要はない。
        
        if isReconnecting {
            return StrokeStyle(
                lineWidth: scaledWidth,
                lineCap: .round,
                dash: [baseShortDash, baseShortDash]
            )
        }
        
        if animated {
            let elapsed = date.timeIntervalSinceReferenceDate
            
            // Realize a constant speed of 30px per second on the screen | スクリーン上で秒速 30px の一定速度を実現
            let speed: CGFloat = 30
            let phase = CGFloat(-elapsed * speed)
                .truncatingRemainder(dividingBy: baseLongDash + baseShortDash)
            
            return StrokeStyle(
                lineWidth: scaledWidth,
                lineCap: .round,
                dash: [baseLongDash, baseShortDash],
                dashPhase: phase
            )
        } else {
            return StrokeStyle(lineWidth: scaledWidth, lineCap: .round)
        }
    }
}
