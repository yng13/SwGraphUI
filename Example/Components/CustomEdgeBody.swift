import SwiftUI
import SwGraphUI

struct CustomEdgeBody: View {
    let context: EdgeRenderContext<String>
    
    var body: some View {
        ZStack {
            // Example of adding a thick glow to the background | 背景に太い光彩を入れる例
            EdgeRenderer(
                segments: context.graphSegments,
                strokeColor: context.strokeColor.opacity(0.2),
                strokeWidth: context.strokeWidth + 4,
                viewport: context.viewport,
                containerSize: context.containerSize,
                animated: context.animated,
                isReconnecting: context.isReconnecting
            )
            
            // Main body | 本体
            EdgeRenderer(
                segments: context.graphSegments,
                strokeColor: context.strokeColor,
                strokeWidth: context.strokeWidth,
                viewport: context.viewport,
                containerSize: context.containerSize,
                animated: context.animated,
                isReconnecting: context.isReconnecting
            )
            
            // Dotted line for patterns in the center | 中心に模様を入れる点線
            if !context.isReconnecting {
                EdgeRenderer(
                    segments: context.graphSegments,
                    strokeColor: .white.opacity(0.5),
                    strokeWidth: 1,
                    viewport: context.viewport,
                    containerSize: context.containerSize,
                    animated: context.animated,
                    isReconnecting: false
                )
                .mask(
                    EdgeRenderer(
                        segments: context.graphSegments,
                        strokeColor: .black,
                        strokeWidth: context.strokeWidth,
                        viewport: context.viewport,
                        containerSize: context.containerSize,
                        animated: false,
                        isReconnecting: false
                    )
                )
            }
        }
    }
}
