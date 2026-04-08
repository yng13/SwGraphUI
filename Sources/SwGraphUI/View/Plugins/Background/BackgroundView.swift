import SwiftUI

/// グラフの背景にドットやグリッドを表示するコンポーネント
public struct BackgroundView: View {
    let viewport: Viewport
    let gap: CGFloat
    let patternColor: Color
    
    public init(
        viewport: Viewport,
        gap: CGFloat = 20,
        patternColor: Color = Color.gray.opacity(0.2)
    ) {
        self.viewport = viewport
        self.gap = gap
        self.patternColor = patternColor
    }
    
    public var body: some View {
        Canvas { context, size in
            let zoom = viewport.zoom
            let scaledGap = gap * zoom
            
            // ビューポートの開始位置をずらし、パターンの連続性を保つ
            let offsetX = viewport.x.remainder(dividingBy: scaledGap)
            let offsetY = viewport.y.remainder(dividingBy: scaledGap)
            
            context.translateBy(x: offsetX, y: offsetY)
            
            // 見えている範囲を計算（マージンを持たせる）
            let horizontalCount = Int(size.width / scaledGap) + 4
            let verticalCount = Int(size.height / scaledGap) + 4
            
            // ズームが小さすぎても点が見えるように最低サイズを保証
            let baseDotSize = Swift.max(2.0, 2.0 * zoom)
            let majorDotSize = Swift.max(4.0, 4.0 * zoom)
            
            for i in -2...horizontalCount {
                for j in -2...verticalCount {
                    // 論理インデックスを計算
                    let logicalI = Int((viewport.x / scaledGap).rounded(.down)) - i
                    let logicalJ = Int((viewport.y / scaledGap).rounded(.down)) - j
                    
                    let isMajor = (logicalI % 5 == 0) && (logicalJ % 5 == 0)
                    
                    let currentSize = isMajor ? majorDotSize : baseDotSize
                    // 不透明度を大幅にアップ (0.5以上)
                    let opacity = isMajor ? 0.8 : 0.5
                    
                    let rect = CGRect(
                        x: CGFloat(i) * scaledGap - currentSize/2,
                        y: CGFloat(j) * scaledGap - currentSize/2,
                        width: currentSize,
                        height: currentSize
                    )
                    
                    // 単純な primary カラーに近いグレーを使用してコントラストを確保
                    context.fill(Path(ellipseIn: rect), with: .color(patternColor.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
