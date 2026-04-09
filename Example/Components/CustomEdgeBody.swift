import SwiftUI
import SwGraphUI

struct CustomEdgeBody: View {
    let segments: [PathSegment]
    let color: Color
    let width: CGFloat
    let viewport: Viewport
    let animated: Bool
    let reconnecting: Bool
    
    var body: some View {
        ZStack {
            // 背景に太い光彩を入れる例
            EdgeRenderer(
                segments: segments,
                strokeColor: color.opacity(0.2),
                strokeWidth: width + 4,
                viewport: viewport,
                animated: animated,
                isReconnecting: reconnecting
            )
            
            // 本体
            EdgeRenderer(
                segments: segments,
                strokeColor: color,
                strokeWidth: width,
                viewport: viewport,
                animated: animated,
                isReconnecting: reconnecting
            )
            
            // 中心に模様を入れる点線
            if !reconnecting {
                EdgeRenderer(
                    segments: segments,
                    strokeColor: .white.opacity(0.5),
                    strokeWidth: 1,
                    viewport: viewport,
                    animated: animated,
                    isReconnecting: false
                )
                .mask(
                    EdgeRenderer(
                        segments: segments,
                        strokeColor: .black,
                        strokeWidth: width,
                        viewport: viewport,
                        animated: false,
                        isReconnecting: false
                    )
                )
            }
        }
    }
}
