import SwiftUI
import SwGraphUI

#if os(macOS)
struct SidebarView: View {
    @Bindable var appStore: ExampleAppStore
    let graphStore: GraphStore<String>
    
    var body: some View {
        List {
            // 一番上のカテゴリ（Basic）だけがヘッダー化されるのを防ぐため、
            // 空のセクションや、あるいは明示的なスタイルを持つセクション構成に。
            // macOS のサイドバー特有の挙動に対処します。
            ForEach(ExampleAppStore.SampleCategory.allCases) { category in
                Section(header: Text(category.rawValue).font(.headline).foregroundColor(.secondary)) {
                    ForEach(appStore.samples(in: category), id: \.id) { sample in
                        HStack {
                            Label(sample.title, systemImage: "doc.text")
                                .font(.subheadline)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appStore.switchSample(to: sample, in: graphStore)
                        }
                    }
                }
            }
            
            Divider()
            
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
        .listStyle(.sidebar)
    }
}
#endif
