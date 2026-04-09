import SwiftUI

/// グラフの背景にドットやグリッドを表示するコンポーネント
public struct BackgroundView: View {
    let viewport: Viewport
    /// 基本のグリッド間隔 (デフォルト 20)
    let gap: CGFloat
    /// 描画パターン（ドット、ライン、クロス）
    let variant: BackgroundVariant
    /// ドットの直径または線の太さ
    let size: CGFloat
    /// パターンの基本色
    let patternColor: Color
    
    public init(
        viewport: Viewport,
        gap: CGFloat = 20,
        variant: BackgroundVariant = .dots,
        size: CGFloat? = nil,
        patternColor: Color = Color.primary.opacity(0.32)
    ) {
        self.viewport = viewport
        self.gap = gap
        self.variant = variant
        self.size = size ?? (variant == .dots ? 2.5 : 1.0)
        self.patternColor = patternColor
    }
    
    public var body: some View {
        Canvas { context, canvasSize in
            let zoom = viewport.zoom
            guard zoom > 0.001 else { return } // 極小ズームガード
            
            let baseScaledGap = max(gap * zoom, 1.0)
            let minScreenSpacing: CGFloat = (variant == .dots) ? 12 : 16

            // minor は密度に応じて間引くが、major は常に graph-space の 5x5 基準で別描画する
            var densityStep: Int = 1
            while CGFloat(densityStep) * baseScaledGap < minScreenSpacing {
                densityStep *= 5
            }

            let minorStepGraph = Double(gap) * Double(densityStep)
            let majorStepGraph = Double(gap) * 5.0
            let graphLeft = (-viewport.x) / zoom
            let graphTop = (-viewport.y) / zoom
            let graphRight = graphLeft + canvasSize.width / zoom
            let graphBottom = graphTop + canvasSize.height / zoom

            var minorPath = Path()
            var majorPath = Path()

            if variant == .lines {
                buildLinePaths(
                    minorPath: &minorPath,
                    majorPath: &majorPath,
                    graphLeft: graphLeft,
                    graphTop: graphTop,
                    graphRight: graphRight,
                    graphBottom: graphBottom,
                    minorStepGraph: minorStepGraph,
                    majorStepGraph: majorStepGraph,
                    viewport: viewport,
                    canvasSize: canvasSize
                )
                context.stroke(minorPath, with: .color(patternColor.opacity(0.6)), lineWidth: size)
                context.stroke(majorPath, with: .color(patternColor.opacity(1.0)), lineWidth: size)
            } else {
                buildPointPaths(
                    minorPath: &minorPath,
                    majorPath: &majorPath,
                    graphLeft: graphLeft,
                    graphTop: graphTop,
                    graphRight: graphRight,
                    graphBottom: graphBottom,
                    minorStepGraph: minorStepGraph,
                    majorStepGraph: majorStepGraph,
                    viewport: viewport
                )
            }

            if variant == .cross {
                let lw = size * 0.8
                context.stroke(minorPath, with: .color(patternColor.opacity(0.6)), lineWidth: lw)
                context.stroke(majorPath, with: .color(patternColor.opacity(1.0)), lineWidth: lw * 1.5)
            } else if variant == .dots {
                // Dots
                context.fill(minorPath, with: .color(patternColor.opacity(0.6)))
                context.fill(majorPath, with: .color(patternColor.opacity(1.0)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    
    private func positiveModulo(_ value: Double, _ divisor: Double) -> Double {
        guard divisor > 0 else { return 0 }
        let remainder = value.truncatingRemainder(dividingBy: divisor)
        return remainder >= 0 ? remainder : remainder + divisor
    }

    private func buildPointPaths(
        minorPath: inout Path,
        majorPath: inout Path,
        graphLeft: Double,
        graphTop: Double,
        graphRight: Double,
        graphBottom: Double,
        minorStepGraph: Double,
        majorStepGraph: Double,
        viewport: Viewport
    ) {
        let minorXs = axisValues(start: graphLeft, end: graphRight, step: minorStepGraph)
        let minorYs = axisValues(start: graphTop, end: graphBottom, step: minorStepGraph)
        let majorXs = Set(axisValues(start: graphLeft, end: graphRight, step: majorStepGraph))
        let majorYs = Set(axisValues(start: graphTop, end: graphBottom, step: majorStepGraph))

        for x in minorXs {
            for y in minorYs {
                let isMajor = majorXs.contains(x) && majorYs.contains(y)
                let screenPoint = XYPosition(x: x, y: y).toScreen(viewport: viewport)
                let currentSize = size * (isMajor ? 1.5 : 1.0)

                switch variant {
                case .dots:
                    let rect = CGRect(
                        x: screenPoint.x - Double(currentSize / 2),
                        y: screenPoint.y - Double(currentSize / 2),
                        width: Double(currentSize),
                        height: Double(currentSize)
                    )
                    if isMajor { majorPath.addEllipse(in: rect) } else { minorPath.addEllipse(in: rect) }
                case .cross:
                    let length = Double(currentSize * 2.5)
                    let path = Path { p in
                        p.move(to: CGPoint(x: screenPoint.x - length, y: screenPoint.y))
                        p.addLine(to: CGPoint(x: screenPoint.x + length, y: screenPoint.y))
                        p.move(to: CGPoint(x: screenPoint.x, y: screenPoint.y - length))
                        p.addLine(to: CGPoint(x: screenPoint.x, y: screenPoint.y + length))
                    }
                    if isMajor { majorPath.addPath(path) } else { minorPath.addPath(path) }
                case .lines:
                    break
                }
            }
        }
    }

    private func buildLinePaths(
        minorPath: inout Path,
        majorPath: inout Path,
        graphLeft: Double,
        graphTop: Double,
        graphRight: Double,
        graphBottom: Double,
        minorStepGraph: Double,
        majorStepGraph: Double,
        viewport: Viewport,
        canvasSize: CGSize
    ) {
        let minorXs = axisValues(start: graphLeft, end: graphRight, step: minorStepGraph)
        let minorYs = axisValues(start: graphTop, end: graphBottom, step: minorStepGraph)
        let majorXs = Set(axisValues(start: graphLeft, end: graphRight, step: majorStepGraph))
        let majorYs = Set(axisValues(start: graphTop, end: graphBottom, step: majorStepGraph))

        for x in minorXs {
            let screenX = XYPosition(x: x, y: 0).toScreen(viewport: viewport).x
            if majorXs.contains(x) {
                majorPath.move(to: CGPoint(x: screenX, y: 0))
                majorPath.addLine(to: CGPoint(x: screenX, y: canvasSize.height))
            } else {
                minorPath.move(to: CGPoint(x: screenX, y: 0))
                minorPath.addLine(to: CGPoint(x: screenX, y: canvasSize.height))
            }
        }

        for y in minorYs {
            let screenY = XYPosition(x: 0, y: y).toScreen(viewport: viewport).y
            if majorYs.contains(y) {
                majorPath.move(to: CGPoint(x: 0, y: screenY))
                majorPath.addLine(to: CGPoint(x: canvasSize.width, y: screenY))
            } else {
                minorPath.move(to: CGPoint(x: 0, y: screenY))
                minorPath.addLine(to: CGPoint(x: canvasSize.width, y: screenY))
            }
        }
    }

    private func axisValues(start: Double, end: Double, step: Double) -> [Double] {
        guard step > 0, step.isFinite else { return [] }
        let firstIndex = Int(floor(start / step)) - 1
        let lastIndex = Int(ceil(end / step)) + 1
        return (firstIndex...lastIndex).map { Double($0) * step }
    }
}
