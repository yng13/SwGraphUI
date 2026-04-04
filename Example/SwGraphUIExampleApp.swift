import SwiftUI
import SwGraphUI

@main
struct SwGraphUIExampleApp: App {
    @State private var appStore = ExampleAppStore()
    @State private var graphStore: GraphStore<String> = GraphStore(nodes: [])
    
    var body: some Scene {
        WindowGroup {
            ContentView(appStore: appStore, graphStore: graphStore)
                .onAppear {
                    appStore.switchSample(to: .basic, in: graphStore)
                }
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        #endif
    }
}

struct ContentView: View {
    @Bindable var appStore: ExampleAppStore
    let graphStore: GraphStore<String>
    
    var body: some View {
        #if os(macOS)
        desktopLayout
        #else
        mobileLayout
        #endif
    }
    
    // MARK: - Desktop Layout (Modern 3-Column IDE)
    
    #if os(macOS)
    @ViewBuilder
    private var desktopLayout: some View {
        HSplitView {
            // Sidebar: Sample Selection
            if appStore.isSidebarVisible {
                SidebarView(appStore: appStore, graphStore: graphStore)
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 400)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 1)
                    }
            }
            
            // Content: Main Graph Canvas & Code
            VStack(spacing: 0) {
                mainCanvasView
                    .frame(minHeight: 300)
                
                if appStore.isCodeViewVisible {
                    Divider()
                    CodeView(graphStore: graphStore)
                        .frame(height: 200)
                }
            }
            .frame(minWidth: 400)
            .layoutPriority(1) // 中央ペインを優先的に広げる
            
            // Detail/Inspector: Properties & Logs
            if appStore.isInspectorVisible {
                VStack(spacing: 0) {
                    InspectorView(appStore: appStore, graphStore: graphStore)
                        .frame(minHeight: 200)
                    
                    if appStore.isLogVisible {
                        Divider()
                        LogView(appStore: appStore)
                            .frame(height: 250)
                    }
                }
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 500)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: { appStore.isSidebarVisible.toggle() }) {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
                .help("Toggle Sidebar")
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { appStore.isCodeViewVisible.toggle() }) {
                    Label("Toggle Code", systemImage: "chevron.left.slash.chevron.right")
                }
                .help("Toggle JSON Code View")

                Button(action: { appStore.isInspectorVisible.toggle() }) {
                    Label("Toggle Inspector", systemImage: "sidebar.right")
                }
                .help("Toggle Inspector")

                Button(action: { appStore.isLogVisible.toggle() }) {
                    Label("Toggle Logs", systemImage: "terminal")
                }
                .help("Toggle Debug Logs")
            }
        }
    }
    #endif
    
    // MARK: - Mobile Layout (Adaptive)
    
    @ViewBuilder
    private var mobileLayout: some View {
        TabView {
            ZStack(alignment: .topTrailing) {
                mainCanvasView
                
                VStack {
                    Button(action: { appStore.isInspectorVisible.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
            .tabItem {
                Label("Graph", systemImage: "network")
            }
            
            NavigationStack {
                List {
                    Section("Samples") {
                        ForEach(ExampleAppStore.SampleCategory.allCases) { category in
                            Button(category.rawValue) {
                                appStore.switchSample(to: category, in: graphStore)
                            }
                            .foregroundColor(appStore.selectedCategory == category ? .blue : .primary)
                        }
                    }
                    Section("Code (JSON)") {
                        CodeView(graphStore: graphStore)
                    }
                    Section("Debug Logs") {
                        ForEach(appStore.logs) { log in
                            Text(log.description)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                .navigationTitle("Diagnostics")
            }
            .tabItem {
                Label("Diagnostics", systemImage: "terminal")
            }
        }
        .sheet(isPresented: $appStore.isInspectorVisible) {
            NavigationStack {
                InspectorView(appStore: appStore, graphStore: graphStore)
                    .navigationTitle("Inspector")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { appStore.isInspectorVisible = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Shared Helpers
    
    private var mainCanvasView: some View {
        GeometryReader { geometry in
            GraphView(store: graphStore, onEvent: handleGraphEvent) { node in
                if node.kind == "custom" {
                    CustomNodeView(node: node)
                } else {
                    DefaultNodeView(node: node)
                }
            }
            .background(Color.white)
            .border(Color.blue.opacity(0.3), width: 2) // FitView対象領域を可視化
            .onAppear {
                appStore.currentGraphSize = Dimensions(width: geometry.size.width, height: geometry.size.height)
            }
            .onChange(of: geometry.size) { _, newSize in
                appStore.currentGraphSize = Dimensions(width: newSize.width, height: newSize.height)
            }
        }
    }
    
    private func handleGraphEvent(_ event: GraphEvent) {
        switch event {
        case .dragStart(let nodeIDs):
            appStore.appendLog(kind: "drag.start", payload: "node=\(nodeIDs.first ?? "unknown")")
        case .dragStop(let nodeIDs):
            appStore.appendLog(kind: "drag.stop", payload: "node=\(nodeIDs.first ?? "unknown")")
        case .dragUpdate:
            break
        }
    }
}

// MARK: - Subviews

#if os(macOS)
struct SidebarView: View {
    @Bindable var appStore: ExampleAppStore
    let graphStore: GraphStore<String>
    
    var body: some View {
        List(ExampleAppStore.SampleCategory.allCases, selection: $appStore.selectedCategory) { category in
            HStack {
                Text(category.rawValue)
                Spacer()
                if appStore.selectedCategory == category {
                    Image(systemName: "checkmark").foregroundColor(.blue)
                }
            }
            .tag(category)
        }
        .onChange(of: appStore.selectedCategory) { _, newValue in
            appStore.switchSample(to: newValue, in: graphStore)
        }
    }
}
#endif

struct CodeView: View {
    let graphStore: GraphStore<String>
    
    private var jsonString: String {
        let nodesPart = graphStore.nodes.map { node in
            let absPos = graphStore.absolutePosition(for: node.id)
            let measured = node.measured.map { "[\(Int($0.width)), \(Int($0.height))]" } ?? "null"
            return """
              {
                "id": "\(node.id)",
                "kind": "\(node.kind ?? "default")",
                "pos": [\(Int(node.position.x)), \(Int(node.position.y))],
                "absPos": [\(Int(absPos.x)), \(Int(absPos.y))],
                "measured": \(measured)
              }
            """
        }.joined(separator: ",\n")
        return "{\n \"nodes\": [\n\(nodesPart)\n ]\n}"
    }
    
    var body: some View {
        ScrollView {
            Text(jsonString)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(.caption, design: .monospaced))
        }
        .background(Color.black.opacity(0.05))
    }
}

struct InspectorView: View {
    let appStore: ExampleAppStore
    let graphStore: GraphStore<String>
    
    var body: some View {
        List {
            Section("Actions") {
                Button("Fit View") {
                    graphStore.fitView(in: appStore.currentGraphSize)
                    appStore.appendLog(kind: "action", payload: "fitView(w:\(Int(appStore.currentGraphSize.width)), h:\(Int(appStore.currentGraphSize.height)))")
                }
                .buttonStyle(.borderedProminent)
            }
            Section("Current Setup") {
                LabeledContent("Category", value: appStore.selectedCategory.rawValue)
                LabeledContent("Nodes", value: "\(graphStore.nodes.count)")
            }
        }
    }
}

struct LogView: View {
    let appStore: ExampleAppStore
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LOGS").font(.caption).bold()
                Spacer()
                Button("Clear") { appStore.clearLogs() }
                    .buttonStyle(.plain)
                    .font(.caption)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            
            List(appStore.logs) { log in
                Text(log.description)
                    .font(.system(.caption, design: .monospaced))
            }
            .listStyle(.plain)
        }
        .background(Color.white)
    }
}

// MARK: - Custom Node View Example

struct CustomNodeView: View {
    let node: BaseNode<String>
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cpu")
                .foregroundColor(.white)
                .padding(8)
                .background(Circle().fill(Color.purple))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(node.id)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(node.data)
                    .font(.body)
                    .bold()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(node.selected ? Color.purple : Color.purple.opacity(0.3), lineWidth: node.selected ? 3 : 1)
        )
        .shadow(color: .purple.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
