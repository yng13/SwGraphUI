import SwiftUI
import SwGraphUI

struct ToolbarNodeView: View {
    let node: BaseNode<String>
    let store: GraphStore<String>
    let onConnect: ((Connection) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            if node.selected {
                HStack(spacing: 8) {
                    Button(action: {
                        store.updateSelectedNodes { $0.data = "Updated!" }
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .padding(4)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .foregroundColor(.white)
                    
                    Button(action: {
                        store.deleteSelection()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .padding(4)
                    .background(Color.red)
                    .clipShape(Circle())
                    .foregroundColor(.white)
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.8))
                        .shadow(radius: 4)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .offset(y: -10)
                .zIndex(100)
            }
            
            DefaultNodeView(node: node, store: store, onConnect: onConnect)
        }
        .animation(.spring(response: 0.2), value: node.selected)
    }
}
