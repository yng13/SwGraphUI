import SwiftUI
import SwGraphUI

/// グループノード（親ノード）表示用のシンプルなビュー
struct GroupNodeView: View {
    let node: BaseNode<String>
    @Environment(\.graphZoomLevel) private var zoomLevel
    
    var body: some View {
        let scale = max(CGFloat(zoomLevel), 0.0001)
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12 * scale)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12 * scale)
                        .stroke(node.selected ? Color.blue : Color.blue.opacity(0.2), lineWidth: node.selected ? 3 : 2)
                )
            
            Text(node.data)
                .font(.system(size: 12 * scale, weight: .bold))
                .bold()
                .padding(8 * scale)
                .foregroundColor(.blue.opacity(0.8))
        }
        .frame(width: node.width.map { CGFloat($0) * scale }, height: node.height.map { CGFloat($0) * scale })
    }
}
