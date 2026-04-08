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
            
            // 共有コードを参考にしたメトリクス計算
            // 画面上での最小間隔を維持するための step を算出する
            let baseScaledGap = max(gap * zoom, 1.0)
            let minScreenSpacing: CGFloat = (variant == .dots) ? 12 : 16
            // 密度ステップ (1, 5, 25... と 5のべき乗にするとメジャーグリッドと整合しやすい)
            var densityStep: Int = 1
            while CGFloat(densityStep) * baseScaledGap < minScreenSpacing {
                densityStep *= 5
            }
            
            let scaledGap = baseScaledGap * CGFloat(densityStep)
            
            // 位相（原点からのズレ）の計算
            let phaseX = positiveModulo(viewport.x, scaledGap)
            let phaseY = positiveModulo(viewport.y, scaledGap)
            
            // 1パスにまとめて描画することでパフォーマンスを向上させる
            var minorPath = Path()
            var majorPath = Path()
            
            // 基準となる論理インデックス
            let baseI = Int(floor(viewport.x / (gap * zoom)))
            let baseJ = Int(floor(viewport.y / (gap * zoom)))
            
            var x = phaseX
            var iCount = 0
            while x <= canvasSize.width + (scaledGap * 2) {
                var y = phaseY
                var jCount = 0
                while y <= canvasSize.height + (scaledGap * 2) {
                    // 現在のセルの論理インデックス (5x5 アクセント判定用)
                    let logicalI = baseI - iCount * densityStep
                    let logicalJ = baseJ - jCount * densityStep
                    let isMajor = (logicalI % 5 == 0) && (logicalJ % 5 == 0)
                    
                    // ドット/クロスの基準サイズ
                    let currentSize = size * (isMajor ? 1.5 : 1.0)
                    
                    switch variant {
                    case .dots:
                        let rect = CGRect(x: x - currentSize/2, y: y - currentSize/2, width: currentSize, height: currentSize)
                        if isMajor { majorPath.addEllipse(in: rect) } else { minorPath.addEllipse(in: rect) }
                        
                    case .lines:
                        break
                        
                    case .cross:
                        let l = currentSize * 2.5 // 十字の長さ
                        let p = Path { p in
                            p.move(to: CGPoint(x: x - l, y: y)); p.addLine(to: CGPoint(x: x + l, y: y))
                            p.move(to: CGPoint(x: x, y: y - l)); p.addLine(to: CGPoint(x: x, y: y + l))
                        }
                        if isMajor { majorPath.addPath(p) } else { minorPath.addPath(p) }
                    }
                    
                    y += scaledGap
                    jCount += 1
                }
                x += scaledGap
                iCount += 1
            }
            
            // 描画実行
            if variant == .lines {
                let lineWidth = size
                var minorLinePath = Path()
                var majorLinePath = Path()
                
                var lx = phaseX
                var iCount = 0
                while lx <= canvasSize.width + (scaledGap * 2) {
                    let logicalI = baseI - iCount * densityStep
                    let isMajor = (logicalI % 5 == 0)
                    if isMajor {
                        majorLinePath.move(to: CGPoint(x: lx, y: 0)); majorLinePath.addLine(to: CGPoint(x: lx, y: canvasSize.height))
                    } else {
                        minorLinePath.move(to: CGPoint(x: lx, y: 0)); minorLinePath.addLine(to: CGPoint(x: lx, y: canvasSize.height))
                    }
                    lx += scaledGap
                    iCount += 1
                }
                
                var ly = phaseY
                var jCount = 0
                while ly <= canvasSize.height + (scaledGap * 2) {
                    let logicalJ = baseJ - jCount * densityStep
                    let isMajor = (logicalJ % 5 == 0)
                    if isMajor {
                        majorLinePath.move(to: CGPoint(x: 0, y: ly)); majorLinePath.addLine(to: CGPoint(x: canvasSize.width, y: ly))
                    } else {
                        minorLinePath.move(to: CGPoint(x: 0, y: ly)); minorLinePath.addLine(to: CGPoint(x: canvasSize.width, y: ly))
                    }
                    ly += scaledGap
                    jCount += 1
                }
                
                context.stroke(minorLinePath, with: .color(patternColor.opacity(0.6)), lineWidth: lineWidth)
                context.stroke(majorLinePath, with: .color(patternColor.opacity(1.0)), lineWidth: lineWidth)
            } else if variant == .cross {
                let lw = size * 0.8
                context.stroke(minorPath, with: .color(patternColor.opacity(0.6)), lineWidth: lw)
                context.stroke(majorPath, with: .color(patternColor.opacity(1.0)), lineWidth: lw * 1.5)
            } else {
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
}
