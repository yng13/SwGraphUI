import SwiftUI

/// グラフの基本操作を提供するコントロールパネル。
public struct ControlsView<NodeData: Sendable>: View {
    public let store: GraphStore<NodeData>
    
    public init(store: GraphStore<NodeData>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Zoom In
            ControlButton(icon: "plus") {
                store.zoomIn()
            }
            Divider()
            
            // Zoom Out
            ControlButton(icon: "minus") {
                store.zoomOut()
            }
            Divider()
            
            // Fit View
            ControlButton(icon: "arrow.up.left.and.arrow.down.right") {
                store.fitView()
            }
            Divider()
            
            // Lock / Unlock
            let isLocked = !store.runtimeState.interactivity.nodesDraggable
            ControlButton(icon: isLocked ? "lock.fill" : "lock.open.fill", color: isLocked ? .red : .primary) {
                let newState = !store.runtimeState.interactivity.nodesDraggable
                store.setNodesDraggable(newState)
                store.setPanOnDrag(newState)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 40) // 固定幅により、横への引き延ばしを防止
        .background(.ultraThinMaterial) // モダンなグラスモフィズム
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct ControlButton: View {
    let icon: String
    var color: Color = .primary
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isHovered {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                        .padding(4)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 40, height: 40)
                    .foregroundColor(color)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHover in
            isHovered = isHover
        }
    }
}
