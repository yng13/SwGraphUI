import SwiftUI
import SwGraphUI

struct ColorNodeView: View {
    let node: BaseNode<String>
    let store: GraphStore<String>
    let onConnect: ((Connection) -> Void)?
    
    @Environment(\.graphZoomLevel) private var zoomLevel
    
    var body: some View {
        let scale = max(CGFloat(zoomLevel), 0.0001)
        let color: Color = {
            switch node.data.lowercased() {
            case "red": return .red
            case "blue": return .blue
            case "green": return .green
            case "orange": return .orange
            default: return .purple
            }
        }()
        
        Text(node.data)
            .font(.system(size: 12 * scale, weight: .bold))
            .foregroundColor(.white)
            .padding(12 * scale)
            .frame(minWidth: 80 * scale)
            .background(
                RoundedRectangle(cornerRadius: 8 * scale)
                    .fill(color)
                    .shadow(radius: (node.selected && zoomLevel <= 1.0) ? 4 : (zoomLevel > 1.0 ? 0 : 2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8 * scale)
                    .stroke(node.selected ? Color.white : Color.clear, lineWidth: 2)
            )
            .overlay(
                HStack {
                    HandleView(nodeID: node.id, type: .target, placement: .left, store: store, onConnect: onConnect)
                        .offset(x: -8 * scale)
                    Spacer()
                    HandleView(nodeID: node.id, type: .source, placement: .right, store: store, onConnect: onConnect)
                        .offset(x: 8 * scale)
                }
            )
    }
}
