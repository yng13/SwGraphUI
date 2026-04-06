import SwiftUI
import SwGraphUI

#if os(macOS)
struct SidebarView: View {
    @Bindable var appStore: ExampleAppStore
    let graphStore: GraphStore<String>
    
    var body: some View {
        List {
            ForEach(ExampleAppStore.SampleCategory.allCases) { category in
                Section(category.rawValue) {
                    ForEach(appStore.samples(in: category), id: \.id) { sample in
                        HStack {
                            Label(sample.title, systemImage: "doc.text")
                                .font(.subheadline)
                            Spacer()
                            if appStore.selectedCategory == category && graphStore.nodes.count > 0 {
                                // 簡易的な選択状態表示（実際には選択中のサンプルを保持するのが理想）
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appStore.switchSample(to: sample, in: graphStore)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            
            Section("Actions") {
                Button(action: {
                    let screenCenter = XYPosition(x: appStore.currentGraphSize.width / 2, y: appStore.currentGraphSize.height / 2)
                    let graphPos = graphStore.runtimeState.viewport.toGraphSpace(screenCenter)
                    let newNodeID = "node-\(UUID().uuidString.prefix(4).lowercased())"
                    let newNode = BaseNode(
                        id: newNodeID,
                        position: graphPos,
                        data: "New Node"
                    )
                    graphStore.addNode(newNode)
                    appStore.appendLog(kind: "node.add", payload: "id=\(newNodeID)")
                }) {
                    Label("Add Node", systemImage: "plus.circle")
                }
            }
        }
    }
}
#endif
