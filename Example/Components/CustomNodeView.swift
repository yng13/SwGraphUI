import SwiftUI
import SwGraphUI

struct CustomNodeView: View {
    let node: BaseNode<String>
    let store: GraphStore<String>
    let onConnect: ((Connection) -> Void)?
    @Environment(\.graphZoomLevel) private var zoomLevel
    
    var body: some View {
        let scale = max(CGFloat(zoomLevel), 0.0001)
        VStack(spacing: 0) {
            // Top handle | 上ハンドル
            HandleView(nodeID: node.id, type: .target, placement: .top, store: store, onConnect: onConnect)
                .padding(.bottom, -3 * scale) // So that the handle center overlaps with the node edge | ハンドルの中心がノードの端に重なるように
            
            VStack(spacing: 8 * scale) {
                Text("CUSTOM NODE")
                    .font(.system(size: 8 * scale, weight: .black))
                    .foregroundColor(.purple.opacity(0.8))
                
                HStack(spacing: 0) {
                    // Left handle | 左ハンドル
                    HandleView(nodeID: node.id, type: .target, placement: .left, store: store, onConnect: onConnect)
                    
                    VStack(spacing: 12 * scale) {
                        Image(systemName: "cpu")
                            .font(.system(size: 24 * scale))
                            .foregroundColor(.white)
                            .padding(12 * scale)
                            .background(
                                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .clipShape(RoundedRectangle(cornerRadius: 12 * scale))
                            )
                            .shadow(color: .purple.opacity(zoomLevel > 1.0 ? 0 : 0.3), radius: zoomLevel > 1.0 ? 0 : 8, x: 0, y: 4)
                        
                        VStack(alignment: .center, spacing: 2 * scale) {
                            Text(node.data)
                                .font(.system(size: 11 * scale, weight: .bold))
                            Text("Custom View Implementation")
                                .font(.system(size: 8 * scale))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16 * scale)
                    .background(
                        RoundedRectangle(cornerRadius: 20 * scale)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(zoomLevel > 1.0 ? 0 : 0.05), radius: zoomLevel > 1.0 ? 0 : 10, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20 * scale)
                            .stroke(node.selected ? Color.purple : Color.clear, lineWidth: 2)
                    )
                    
                    // Right handle | 右ハンドル
                    HandleView(nodeID: node.id, type: .source, placement: .right, store: store, onConnect: onConnect)
                }
            }
            
            // Bottom handle | 下ハンドル
            HandleView(nodeID: node.id, type: .source, placement: .bottom, store: store, onConnect: onConnect)
                .padding(.top, -3 * scale) // So that the handle center overlaps with the node edge | ハンドルの中心がノードの端に重なるように
        }
        .scaleEffect((node.selected && zoomLevel <= 1.0) ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: node.selected)
    }
}
