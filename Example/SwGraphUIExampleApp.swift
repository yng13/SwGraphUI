import SwiftUI
#if os(macOS)
import AppKit
#endif
import SwGraphUI

@main
struct SwGraphUIExampleApp: App {
    @State private var appStore = ExampleAppStore()
    @State private var graphStore: GraphStore<String> = GraphStore(nodes: [])

    init() {
        #if os(macOS)
        NSApplication.shared.setActivationPolicy(.regular)
        #endif
    }
    
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
        .commands {
            // macOSデフォルトメニューが表示されない環境でも確実に出すために明示的に "Edit" メニューを設ける
            CommandMenu("Edit") {
                Button("Select All") {
                    graphStore.selectAll()
                }
                .keyboardShortcut("a", modifiers: .command)
                
                Divider()
                
                Button("Delete Selected") {
                    graphStore.deleteSelection()
                }
                .keyboardShortcut(.delete, modifiers: [])
                
                Button("Forward Delete Selected") {
                    graphStore.deleteSelection()
                }
                .keyboardShortcut(.deleteForward, modifiers: [])
            }
        }
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
            VSplitView {
                mainCanvasView
                    .frame(minHeight: 400, idealHeight: 1200, maxHeight: .infinity)
                    .layoutPriority(1)
                
                if appStore.isCodeViewVisible {
                    CodeView(graphStore: graphStore)
                        .frame(minHeight: 150, idealHeight: 400, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400)
            .layoutPriority(1) // 中央ペインを優先的に広げる
            
            // Detail/Inspector: Properties & Logs
            if appStore.isInspectorVisible {
                ZStack {
                    if appStore.isLogVisible {
                        VSplitView {
                            InspectorView(appStore: appStore, graphStore: graphStore)
                                .frame(minHeight: 200, maxHeight: .infinity)
                            
                            LogView(appStore: appStore)
                                .frame(minHeight: 150, idealHeight: 250, maxHeight: .infinity)
                        }
                    } else {
                        InspectorView(appStore: appStore, graphStore: graphStore)
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
            GraphView(
                store: graphStore,
                onEvent: handleGraphEvent,
                onConnect: { connection in
                    appStore.addEdge(connection: connection, in: graphStore)
                },
                onReconnect: { _, _ in },
                edgeBuilder: buildCustomEdge,
                nodeBuilder: buildCustomNode
            )
            .coordinateSpace(name: "graph")
            .background(Color.white)
            .border(Color.blue.opacity(0.3), width: 2) // FitView対象領域を可視化
            .onAppear {
                appStore.currentGraphSize = Dimensions(width: geometry.size.width, height: geometry.size.height)
            }
            .onChange(of: geometry.size) { _, newSize in
                appStore.currentGraphSize = Dimensions(width: newSize.width, height: newSize.height)
            }
            // 実測完了後の初回自動 fitView 調整
            .onChange(of: graphStore.nodes.map { $0.measured != nil }) { _, measuredStatuses in
                guard appStore.selectedCategory == .custom, !appStore.didAutoFitMeasuredSample else { return }
                
                let allMeasured = measuredStatuses.allSatisfy { $0 }
                if allMeasured && !measuredStatuses.isEmpty {
                    appStore.didAutoFitMeasuredSample = true
                    graphStore.fitView(in: appStore.currentGraphSize)
                    appStore.appendLog(kind: "auto.fit", payload: "measured weights applied")
                }
            }
        }
        #if os(macOS)
        .overlay {
            CanvasKeyboardBridge(
                onSelectAll: {
                    graphStore.selectAll()
                    appStore.appendLog(kind: "key.selectAll", payload: "all nodes selected via canvas focus")
                },
                onDeleteSelection: {
                    graphStore.deleteSelection()
                    appStore.appendLog(kind: "key.delete", payload: "selection removed via canvas focus")
                }
            )
        }
        #endif
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
        List {
            Section("Samples") {
                ForEach(ExampleAppStore.SampleCategory.allCases) { category in
                    HStack {
                        Text(category.rawValue)
                        Spacer()
                        if appStore.selectedCategory == category {
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                    .tag(category)
                }
            }
            .onChange(of: appStore.selectedCategory) { _, newValue in
                appStore.switchSample(to: newValue, in: graphStore)
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
    @Bindable var appStore: ExampleAppStore
    let graphStore: GraphStore<String>
    
    var body: some View {
        List {
            Section("Viewport") {
                HStack(spacing: 12) {
                    Button {
                        let center = XYPosition(x: appStore.currentGraphSize.width / 2, y: appStore.currentGraphSize.height / 2)
                        graphStore.zoom(at: center, factor: 1.2)
                    } label: {
                        Label("In", systemImage: "plus.magnifyingglass")
                    }
                    
                    Button {
                        let center = XYPosition(x: appStore.currentGraphSize.width / 2, y: appStore.currentGraphSize.height / 2)
                        graphStore.zoom(at: center, factor: 0.8)
                    } label: {
                        Label("Out", systemImage: "minus.magnifyingglass")
                    }
                    
                    Button {
                        graphStore.fitView(in: appStore.currentGraphSize)
                    } label: {
                        Label("Fit", systemImage: "scope")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .labelStyle(.iconOnly)
            }
            
            Section {
                LabeledContent("Nodes", value: "\(graphStore.selectedNodes.count)")
                LabeledContent("Edges", value: "\(graphStore.selectedEdges.count)")
                
                HStack {
                    Button("Clear", role: .cancel) {
                        graphStore.clearSelection()
                    }
                    
                    Button("Delete", role: .destructive) {
                        let nodes = graphStore.selectedNodes.count
                        let edges = graphStore.selectedEdges.count
                        graphStore.deleteSelection()
                        appStore.appendLog(kind: "selection.delete", payload: "nodes=\(nodes), edges=\(edges)")
                    }
                    .disabled(graphStore.selectedNodes.isEmpty && graphStore.selectedEdges.isEmpty)
                }
            } header: {
                Text("Selection Summary")
            }
            
            if !graphStore.selectedEdges.isEmpty {
                edgeEditorSection
            }
            
            if !graphStore.selectedNodes.isEmpty {
                nodeInfoSection
            }
            
            Section("Current Setup") {
                LabeledContent("Category", value: appStore.selectedCategory.rawValue)
                LabeledContent("Total Nodes", value: "\(graphStore.nodes.count)")
            }
            
            Section("Development") {
                Button(action: {
                    let nodes = graphStore.nodes.map { ["id": $0.id, "data": $0.data] }
                    let edges = graphStore.edges.map { ["id": $0.id, "source": $0.source, "target": $0.target] }
                    let snapshot: [String: Any] = ["nodes": nodes, "edges": edges]
                    if let data = try? JSONSerialization.data(withJSONObject: snapshot, options: .prettyPrinted),
                       let json = String(data: data, encoding: .utf8) {
                        appStore.appendLog(kind: "snapshot.save", payload: json)
                    }
                }) {
                    Label("Save Snapshot (Log)", systemImage: "square.and.arrow.down")
                }
            }
        }
    }
    
    @ViewBuilder
    private var edgeEditorSection: some View {
        let edges = graphStore.selectedEdges
        let representative = edges.first!
        
        Section {
            Picker("Kind", selection: Binding(
                get: { representative.kind ?? "bezier" },
                set: { newValue in
                    graphStore.updateSelectedEdges { $0.kind = newValue }
                }
            )) {
                Text("Bezier").tag("bezier")
                Text("Straight").tag("straight")
                Text("Step").tag("step")
                Text("SmoothStep").tag("smoothstep")
            }
            
            if (representative.kind ?? "bezier") == "bezier" {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Curvature")
                        Spacer()
                        Text(String(format: "%.2f", representative.curvature ?? 0.25))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { representative.curvature ?? 0.25 },
                        set: { val in graphStore.updateSelectedEdges { $0.curvature = val } }
                    ), in: 0...1)
                }
            }
            
            Toggle("Animated", isOn: Binding(
                get: { representative.animated },
                set: { val in graphStore.updateSelectedEdges { $0.animated = val } }
            ))
            
            TextField("Label", text: Binding(
                get: { representative.label ?? "" },
                set: { val in graphStore.updateSelectedEdges { $0.label = val.isEmpty ? nil : val } }
            ))
            
            Picker("Reconnect", selection: Binding(
                get: { representative.reconnectable },
                set: { val in graphStore.updateSelectedEdges { $0.reconnectable = val } }
            )) {
                ForEach(ReconnectMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
        } header: {
            Text("Edge Style")
        }
        
        Section {
            markerControl(title: "Start Marker", isEnd: false, edges: edges)
            Divider()
            markerControl(title: "End Marker", isEnd: true, edges: edges)
        } header: {
            Text("Markers")
        } footer: {
            if edges.count > 1 {
                Text("Modifying \(edges.count) edges (Bulk apply)")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    @ViewBuilder
    private func markerControl(title: String, isEnd: Bool, edges: [BaseEdge<String>]) -> some View {
        let representative = edges.first!
        let marker = isEnd ? representative.markerEnd : representative.markerStart
        
        VStack(alignment: .leading, spacing: 8) {
            Toggle(title, isOn: Binding(
                get: { marker != nil },
                set: { val in
                    graphStore.updateSelectedEdges { edge in
                        if isEnd {
                            edge.markerEnd = val ? EdgeMarker(type: .arrowClosed) : nil
                        } else {
                            edge.markerStart = val ? EdgeMarker(type: .arrowClosed) : nil
                        }
                    }
                }
            ))
            
            if let marker = marker {
                VStack(spacing: 4) {
                    HStack {
                        Text("Width")
                        Spacer()
                        Text("\(Int(marker.width ?? 6.0))px")
                            .font(.caption.monospaced())
                    }
                    Slider(value: Binding(
                        get: { marker.width ?? 6.0 },
                        set: { val in
                            graphStore.updateSelectedEdges { edge in
                                if isEnd {
                                    edge.markerEnd?.width = val
                                } else {
                                    edge.markerStart?.width = val
                                }
                            }
                        }
                    ), in: 2...20, step: 1)
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        Text("\(Int(marker.height ?? 6.0))px")
                            .font(.caption.monospaced())
                    }
                    Slider(value: Binding(
                        get: { marker.height ?? 6.0 },
                        set: { val in
                            graphStore.updateSelectedEdges { edge in
                                if isEnd {
                                    edge.markerEnd?.height = val
                                } else {
                                    edge.markerStart?.height = val
                                }
                            }
                        }
                    ), in: 2...20, step: 1)
                }
                .padding(.leading, 12)
                .font(.caption)
            }
        }
    }
    
    @ViewBuilder
    private var nodeInfoSection: some View {
        Section("Node Info") {
            ForEach(graphStore.selectedNodes) { node in
                VStack(alignment: .leading, spacing: 10) {
                    Text(node.id).font(.headline).monospaced()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Label").font(.caption).foregroundStyle(.secondary)
                        TextField("Node Data", text: Binding(
                            get: { node.data },
                            set: { val in
                                graphStore.updateSelectedNodes { target in
                                    if target.id == node.id { target.data = val }
                                }
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Type: \(node.kind ?? "default")").font(.caption)
                        Text("Pos: \(Int(node.position.x)), \(Int(node.position.y))").font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(appStore.logs) { log in
                        Text(log.description)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
            }
            .textSelection(.enabled)
        }
    }
}

#if os(macOS)
private struct CanvasKeyboardBridge: NSViewRepresentable {
    let onSelectAll: () -> Void
    let onDeleteSelection: () -> Void

    func makeNSView(context: Context) -> CanvasKeyboardView {
        let view = CanvasKeyboardView()
        view.onSelectAll = onSelectAll
        view.onDeleteSelection = onDeleteSelection
        return view
    }

    func updateNSView(_ nsView: CanvasKeyboardView, context: Context) {
        nsView.onSelectAll = onSelectAll
        nsView.onDeleteSelection = onDeleteSelection
    }
}

private final class CanvasKeyboardView: NSView {
    var onSelectAll: (() -> Void)?
    var onDeleteSelection: (() -> Void)?

    private var keyMonitor: Any?
    private var mouseMonitor: Any?
    private var isCanvasActive = false

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        installMonitorsIfNeeded()
        DispatchQueue.main.async { [weak self] in
            guard let self, let window else { return }
            window.makeFirstResponder(self)
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            removeMonitors()
        }
        super.viewWillMove(toWindow: newWindow)
    }

    private func installMonitorsIfNeeded() {
        guard keyMonitor == nil, mouseMonitor == nil else { return }

        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self, let window else { return event }
            let point = convert(event.locationInWindow, from: nil)
            if bounds.contains(point) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                isCanvasActive = true
                window.makeFirstResponder(self)
            } else {
                isCanvasActive = false
            }
            return event
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self, let window else { return event }

            let firstResponderIsInWindow = window.firstResponder != nil
            guard isCanvasActive || window.firstResponder === self || !firstResponderIsInWindow else {
                return event
            }

            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command],
               event.charactersIgnoringModifiers?.lowercased() == "a" {
                onSelectAll?()
                return nil
            }

            if event.keyCode == 51 || event.keyCode == 117 {
                onDeleteSelection?()
                return nil
            }

            return event
        }
    }

    private func removeMonitors() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
            self.mouseMonitor = nil
        }
    }
}
#endif

struct CustomNodeView: View {
    let node: BaseNode<String>
    let store: GraphStore<String>
    let onConnect: ((Connection) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // 上ハンドル
            HandleView(nodeID: node.id, type: .target, placement: .top, store: store, onConnect: onConnect)
                .padding(.bottom, -3) // ハンドルの中心がノードの端に重なるように
            
            VStack(spacing: 8) {
                Text("CUSTOM NODE")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.purple.opacity(0.8))
                
                HStack(spacing: 0) {
                    // 左ハンドル
                    HandleView(nodeID: node.id, type: .target, placement: .left, store: store, onConnect: onConnect)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "cpu")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            )
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text(node.data)
                                .font(.system(size: 11, weight: .bold))
                            Text("Custom View Implementation")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(node.selected ? Color.purple : Color.clear, lineWidth: 2)
                    )
                    
                    // 右ハンドル
                    HandleView(nodeID: node.id, type: .source, placement: .right, store: store, onConnect: onConnect)
                }
            }
            
            // 下ハンドル
            HandleView(nodeID: node.id, type: .source, placement: .bottom, store: store, onConnect: onConnect)
                .padding(.top, -3) // ハンドルの中心がノードの端に重なるように
        }
        .scaleEffect(node.selected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: node.selected)
    }
}

// MARK: - Milestone 21 Custom Components

/// 選択時にツールバーを表示するノード
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

/// カラーバリエーションを持つシンプルなノード
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

/// 本体の描画のみをカスタマイズしたエッジ例
struct CustomEdgeBody: View {
    let segments: [PathSegment]
    let color: Color
    let width: CGFloat
    let animated: Bool
    let reconnecting: Bool
    
    var body: some View {
        ZStack {
            // 背景に太い光彩を入れる例
            EdgeRenderer(
                segments: segments,
                strokeColor: color.opacity(0.2),
                strokeWidth: width + 4,
                animated: animated,
                isReconnecting: reconnecting
            )
            
            // 本体
            EdgeRenderer(
                segments: segments,
                strokeColor: color,
                strokeWidth: width,
                animated: animated,
                isReconnecting: reconnecting
            )
            
            // 中心に模様を入れる点線
            if !reconnecting {
                EdgeRenderer(
                    segments: segments,
                    strokeColor: .white.opacity(0.5),
                    strokeWidth: 1,
                    animated: animated,
                    isReconnecting: false
                )
                .mask(
                    EdgeRenderer(
                        segments: segments,
                        strokeColor: .black,
                        strokeWidth: width,
                        animated: false,
                        isReconnecting: false
                    )
                )
            }
        }
    }
}

// MARK: - Builders

extension ContentView {
    private var onConnectHandler: (Connection) -> Void {
        { connection in
            appStore.addEdge(connection: connection, in: graphStore)
        }
    }

    @ViewBuilder
    private func buildCustomNode(_ node: BaseNode<String>) -> some View {
        switch node.kind {
        case "toolbar":
            ToolbarNodeView(node: node, store: graphStore, onConnect: onConnectHandler)
        case "color":
            ColorNodeView(node: node, store: graphStore, onConnect: onConnectHandler)
        case "custom":
            CustomNodeView(node: node, store: graphStore, onConnect: onConnectHandler)
        default:
            DefaultNodeView(node: node, store: graphStore, onConnect: onConnectHandler)
        }
    }
    
    private func buildCustomEdge(
        _ edge: BaseEdge<String>,
        _ segments: [PathSegment],
        _ color: Color,
        _ width: CGFloat,
        _ animated: Bool,
        _ reconnecting: Bool
    ) -> AnyView {
        if edge.kind == "custom" {
            return AnyView(CustomEdgeBody(segments: segments, color: color, width: width, animated: animated, reconnecting: reconnecting))
        } else {
            return AnyView(
                DefaultEdgeView(
                    edge: edge,
                    store: graphStore,
                    onReconnect: nil,
                    modifierKeys: nil,
                    edgeBodyBuilder: nil
                )
            )
        }
    }
}
