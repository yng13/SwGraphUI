import SwiftUI
import SwGraphUI

/// グループノード（親ノード）表示用のシンプルなビュー
struct GroupNodeView: View {
    let node: BaseNode<String>
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                )
            
            Text(node.data)
                .font(.caption)
                .bold()
                .padding(8)
                .foregroundColor(.blue.opacity(0.8))
        }
        .frame(width: node.width.map { CGFloat($0) }, height: node.height.map { CGFloat($0) })
    }
}
