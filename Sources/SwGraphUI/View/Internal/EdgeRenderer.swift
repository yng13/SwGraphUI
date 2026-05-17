import SwiftUI

/// View that performs actual drawing based on edge geometric information. | エッジの幾何情報を基に実際の描画を行う View。
/// Converts an array of PathSegments to a SwiftUI Path for rendering. | PathSegment の配列を SwiftUI の Path に変換して描画します。
public struct EdgeRenderer: View {
    public let segments: [PathSegment]
    public let strokeColor: Color
    public let strokeWidth: CGFloat
    public let dashStyle: EdgeStrokeDash
    public let strokeShape: EdgeStrokeShape
    public let viewport: Viewport
    public let containerSize: Dimensions
    public let animated: Bool
    public let isReconnecting: Bool
    
    public init(
        segments: [PathSegment],
        strokeColor: Color,
        strokeWidth: CGFloat,
        dashStyle: EdgeStrokeDash = .solid,
        strokeShape: EdgeStrokeShape = .single,
        viewport: Viewport,
        containerSize: Dimensions,
        animated: Bool,
        isReconnecting: Bool
    ) {
        self.segments = segments
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.dashStyle = dashStyle
        self.strokeShape = strokeShape
        self.viewport = viewport
        self.containerSize = containerSize
        self.animated = animated
        self.isReconnecting = isReconnecting
    }
    
    public var body: some View {
        if !isCulled {
            if animated && !isReconnecting {
                TimelineView(.animation) { context in
                    renderedPathGroup(at: context.date)
                }
            } else {
                renderedPathGroup(at: .now)
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

    @ViewBuilder
    private func renderedPathGroup(at date: Date) -> some View {
        if strokeShape == .double && !isReconnecting {
            ForEach(doubleLineOffsets.indices, id: \.self) { index in
                buildPath(offset: doubleLineOffsets[index])
                    .stroke(strokeColor, style: strokeStyle(at: date, lineWidth: doubleLineWidth))
            }
        } else {
            buildPath()
                .stroke(strokeColor, style: strokeStyle(at: date))
        }
    }

    private func buildPath(offset: CGSize = .zero) -> Path {
        Path { path in
            for segment in segments {
                let s = segment.toScreen(viewport: viewport)
                switch s {
                case .move(let to): path.move(to: shiftedPoint(to, offset: offset))
                case .line(let to): path.addLine(to: shiftedPoint(to, offset: offset))
                case .bezier(let to, let c1, let c2):
                    path.addCurve(
                        to: shiftedPoint(to, offset: offset),
                        control1: shiftedPoint(c1, offset: offset),
                        control2: shiftedPoint(c2, offset: offset)
                    )
                case .quadratic(let to, let c):
                    path.addQuadCurve(
                        to: shiftedPoint(to, offset: offset),
                        control: shiftedPoint(c, offset: offset)
                    )
                }
            }
        }
    }

    private func shiftedPoint(_ point: XYPosition, offset: CGSize) -> CGPoint {
        CGPoint(x: point.x + offset.width, y: point.y + offset.height)
    }
    
    private var doubleLineWidth: CGFloat {
        max(strokeWidth * CGFloat(viewport.zoom) * 0.72, 1)
    }

    private var doubleLineOffsets: [CGSize] {
        guard let first = firstScreenPoint, let last = lastScreenPoint else { return [.zero, .zero] }
        let dx = last.x - first.x
        let dy = last.y - first.y
        let length = max(sqrt(dx * dx + dy * dy), 0.001)
        let normalX = -dy / length
        let normalY = dx / length
        let centerOffset = max(strokeWidth * CGFloat(viewport.zoom) + 2, 4) / 2
        return [
            CGSize(width: normalX * centerOffset, height: normalY * centerOffset),
            CGSize(width: -normalX * centerOffset, height: -normalY * centerOffset)
        ]
    }

    private var firstScreenPoint: CGPoint? {
        segments.first?.target.toScreen(viewport: viewport).cgPoint
    }

    private var lastScreenPoint: CGPoint? {
        segments.last?.target.toScreen(viewport: viewport).cgPoint
    }

    private func strokeStyle(at date: Date, lineWidth: CGFloat? = nil) -> StrokeStyle {
        let zoom = viewport.zoom
        let scaledWidth: CGFloat = lineWidth ?? (strokeWidth * CGFloat(zoom))
        
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

private extension XYPosition {
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
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
