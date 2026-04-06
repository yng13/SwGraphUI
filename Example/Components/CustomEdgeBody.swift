import SwiftUI
import SwGraphUI

struct CustomEdgeBody: View {
    let segments: [PathSegment]
    let color: Color
    let width: CGFloat
    let animated: Bool
    let reconnecting: Bool
    
    var body: some View {
        ZStack {
            // 背景に太い光彩を入れる例
            EdgeRenderer(
                segments: segments,
                strokeColor: color.opacity(0.2),
                strokeWidth: width + 4,
                animated: animated,
                isReconnecting: reconnecting
            )
            
            // 本体
            EdgeRenderer(
                segments: segments,
                strokeColor: color,
                strokeWidth: width,
                animated: animated,
                isReconnecting: reconnecting
            )
            
            // 中心に模様を入れる点線
            if !reconnecting {
                EdgeRenderer(
                    segments: segments,
                    strokeColor: .white.opacity(0.5),
                    strokeWidth: 1,
                    animated: animated,
                    isReconnecting: false
                )
                .mask(
                    EdgeRenderer(
                        segments: segments,
                        strokeColor: .black,
                        strokeWidth: width,
                        animated: false,
                        isReconnecting: false
                    )
                )
            }
        }
    }
}
