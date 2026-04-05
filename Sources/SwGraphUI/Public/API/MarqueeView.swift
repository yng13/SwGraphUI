import SwiftUI

/// 矩形選択（Marquee）の視覚的フィードバックを表示するビュー。
struct MarqueeView: View {
    let marquee: GraphRuntimeState.MarqueeState
    
    var body: some View {
        let rect = marquee.rect
        
        Rectangle()
            .fill(Color.blue.opacity(0.1))
            .overlay(
                Rectangle()
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            // Marquee 自体は操作を邪魔しないようにヒットテストを無効化
            .allowsHitTesting(false)
    }
}
