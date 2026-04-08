import SwiftUI
import SwGraphUI

struct NodeResizerSample: GraphSample {
    let title = "Node Resizer"
    let category: ExampleAppStore.SampleCategory = .basic
    let description = "Drag handles to resize nodes manually."
    
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        graphStore.nodes = [
            // デフォルトの最小制約 (80x50) を持たせたノード
            BaseNode(
                id: "resizer-1", 
                position: XYPosition(x: 50, y: 50), 
                data: "Resizable (Min: 80x65)", 
                kind: "resizer", 
                width: 120, 
                height: 80,
                minWidth: 80,
                minHeight: 65
            ),
            // 最小・最大の両方の制約を持たせたノード
            BaseNode(
                id: "resizer-2", 
                position: XYPosition(x: 350, y: 100), 
                data: "Constrained (80x80 to 250x250)", 
                kind: "resizer",
                width: 120, 
                height: 120,
                minWidth: 80,
                minHeight: 80,
                maxWidth: 250,
                maxHeight: 250
            )
        ]
        graphStore.edges = [
            BaseEdge(id: "e1-2", source: "resizer-1", target: "resizer-2", markerEnd: EdgeMarker(type: .arrowClosed))
        ]
    }
}

/// NodeResizerSample で使用するノードの見た目
struct ResizableNodeView: View {
    let node: BaseNode<String>
    
    var body: some View {
        let width = node.width.map { CGFloat($0) }
        let height = node.height.map { CGFloat($0) }
        
        ZStack {
            // 背景（ここがノードの実体サイズを決定する。クリッピングの影響を受けないように個別に frame を適用）
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(node.selected ? 0.2 : 0.1), radius: node.selected ? 8 : 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(node.selected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: node.selected ? 2 : 1)
                )
                .frame(width: width, height: height)
            
            // コンテンツ（ここでもサイズを固定し、はみ出しを内部でクリップする）
            VStack {
                Text(node.id)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(node.data)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                Spacer()
                if let measured = node.measured {
                    Text("\(Int(measured.width)) x \(Int(measured.height))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(width: width, height: height)
            .clipped()
        }
        // リサイザーは枠外のハンドルを表示可能にするため、クリップされていない親 ZStack の overlay として配置
        .overlay {
            NodeResizer<String>(node: node)
        }
    }
}
