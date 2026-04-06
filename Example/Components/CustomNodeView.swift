import SwiftUI
import SwGraphUI

struct CustomNodeView: View {
    let node: BaseNode<String>
    let store: GraphStore<String>
    let onConnect: ((Connection) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // 上ハンドル
            HandleView(nodeID: node.id, type: .target, placement: .top, store: store, onConnect: onConnect)
                .padding(.bottom, -3) // ハンドルの中心がノードの端に重なるように
            
            VStack(spacing: 8) {
                Text("CUSTOM NODE")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.purple.opacity(0.8))
                
                HStack(spacing: 0) {
                    // 左ハンドル
                    HandleView(nodeID: node.id, type: .target, placement: .left, store: store, onConnect: onConnect)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "cpu")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            )
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text(node.data)
                                .font(.system(size: 11, weight: .bold))
                            Text("Custom View Implementation")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(node.selected ? Color.purple : Color.clear, lineWidth: 2)
                    )
                    
                    // 右ハンドル
                    HandleView(nodeID: node.id, type: .source, placement: .right, store: store, onConnect: onConnect)
                }
            }
            
            // 下ハンドル
            HandleView(nodeID: node.id, type: .source, placement: .bottom, store: store, onConnect: onConnect)
                .padding(.top, -3) // ハンドルの中心がノードの端に重なるように
        }
        .scaleEffect(node.selected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: node.selected)
    }
}
