import SwiftUI

/// View that performs actual drawing based on edge geometric information. | エッジの幾何情報を基に実際の描画を行う View。
/// Converts an array of PathSegments to a SwiftUI Path for rendering. | PathSegment の配列を SwiftUI の Path に変換して描画します。
public struct EdgeRenderer: View {
    public let segments: [PathSegment]
    public let strokeColor: Color
    public let strokeWidth: CGFloat
    public let dashStyle: EdgeStrokeDash
    public let viewport: Viewport
    public let containerSize: Dimensions
    public let animated: Bool
    public let isReconnecting: Bool
    
    public init(segments: [PathSegment], strokeColor: Color, strokeWidth: CGFloat, dashStyle: EdgeStrokeDash = .solid, viewport: Viewport, containerSize: Dimensions, animated: Bool, isReconnecting: Bool) {
        self.segments = segments
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.dashStyle = dashStyle
        self.viewport = viewport
        self.containerSize = containerSize
        self.animated = animated
        self.isReconnecting = isReconnecting
    }
    
    public var body: some View {
        if !isCulled {
            if animated && !isReconnecting {
                TimelineView(.animation) { context in
                    buildPath().stroke(strokeColor, style: strokeStyle(at: context.date))
                }
            } else {
                buildPath().stroke(strokeColor, style: strokeStyle(at: .now))
            }
        }
    }

    // Simple Culling: Build bounding box from all segment points and skip if fully off-screen | 簡易 Culling: セグメント全点から BB を構築し、完全画面外なら描画スキップ
    private var isCulled: Bool {
        guard !segments.isEmpty else { return false }
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for segment in segments {
            for point in segment.points {
                let p = point.toScreen(viewport: viewport)
                minX = min(minX, p.x); minY = min(minY, p.y)
                maxX = max(maxX, p.x); maxY = max(maxY, p.y)
            }
        }
        return maxX < -100 || minX > containerSize.width + 100 || maxY < -100 || minY > containerSize.height + 100
    }

    private func buildPath() -> Path {
        Path { path in
            for segment in segments {
                let s = segment.toScreen(viewport: viewport)
                switch s {
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
    
    private func strokeStyle(at date: Date) -> StrokeStyle {
        let zoom = viewport.zoom
        let scaledWidth = strokeWidth * zoom
        
        let baseShortDash: CGFloat = 5
        let animatedDefaultDash: [CGFloat] = [10, 5]
        
        // Configured dash patterns represent graph-space style, so scale them with the viewport after path screen conversion.
        
        if isReconnecting {
            return StrokeStyle(
                lineWidth: scaledWidth,
                lineCap: .round,
                dash: [baseShortDash, baseShortDash]
            )
        }

        let configuredDash = dashStyle.cgPattern
        let scaledConfiguredDash = EdgeDashPatternResolver.scaledDashPattern(configuredDash, zoom: zoom)
        
        if animated {
            let elapsed = date.timeIntervalSinceReferenceDate
            
            // Realize a constant speed of 30px per second on the screen | スクリーン上で秒速 30px の一定速度を実現
            let speed: CGFloat = 30
            let phase = CGFloat(-elapsed * speed)
                .truncatingRemainder(dividingBy: dashCycleLength(scaledConfiguredDash.isEmpty ? animatedDefaultDash : scaledConfiguredDash))
            
            return StrokeStyle(
                lineWidth: scaledWidth,
                lineCap: .round,
                dash: scaledConfiguredDash.isEmpty ? animatedDefaultDash : scaledConfiguredDash,
                dashPhase: phase
            )
        } else if !scaledConfiguredDash.isEmpty {
            return StrokeStyle(
                lineWidth: scaledWidth,
                lineCap: .round,
                dash: scaledConfiguredDash
            )
        } else {
            return StrokeStyle(lineWidth: scaledWidth, lineCap: .round)
        }
    }

    private func dashCycleLength(_ pattern: [CGFloat]) -> CGFloat {
        max(pattern.reduce(0, +), 1)
    }
}

enum EdgeDashPatternResolver {
    static func scaledDashPattern(_ pattern: [CGFloat], zoom: Double) -> [CGFloat] {
        guard zoom.isFinite, zoom > 0 else { return pattern }
        return pattern.map { $0 * CGFloat(zoom) }
    }
}

private extension EdgeStrokeDash {
    var cgPattern: [CGFloat] {
        pattern.map { CGFloat($0) }
    }
}
