import SwiftUI
import SwGraphUI

struct ColorNodeView: View {
    let node: BaseNode<String>
    let store: GraphStore<String>
    let onConnect: ((Connection) -> Void)?
    
    var body: some View {
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
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(12)
            .frame(minWidth: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .shadow(radius: node.selected ? 4 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(node.selected ? Color.white : Color.clear, lineWidth: 2)
            )
            .overlay(
                HStack {
                    HandleView(nodeID: node.id, type: .target, placement: .left, store: store, onConnect: onConnect)
                        .offset(x: -8)
                    Spacer()
                    HandleView(nodeID: node.id, type: .source, placement: .right, store: store, onConnect: onConnect)
                        .offset(x: 8)
                }
            )
    }
}
