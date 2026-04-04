import SwiftUI
import SwGraphUI

@main
struct SwGraphUIExampleApp: App {
    // M9 検証用の初期データ
    @State private var store: GraphStore<String> = {
        let parent = BaseNode(
            id: "parent",
            position: XYPosition(x: 100, y: 100),
            data: "Parent"
        )
        let child = BaseNode(
            id: "child",
            position: XYPosition(x: 100, y: 100),
            data: "Child",
            parentID: "parent"
        )
        // 孫ノードの追加
        let grandchild = BaseNode(
            id: "grandchild",
            position: XYPosition(x: 100, y: 100),
            data: "Grandchild",
            parentID: "child"
        )
        return GraphStore(nodes: [parent, child, grandchild])
    }()
    
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                // コントロールパネル
                HStack {
                    VStack(alignment: .leading) {
                        Text("SwGraphUI M9: Platform Bridge")
                            .font(.headline)
                        Text("Hierarchy & Viewport Synchronization")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        store.fitView(in: Dimensions(width: 800, height: 600))
                    }) {
                        Label("fitView", systemImage: "scope")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.background)
                
                Divider()
                
                // グラフ表示エリア
                GraphView(store: store)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.05))
            }
            .frame(minWidth: 900, minHeight: 700)
        }
    }
}
