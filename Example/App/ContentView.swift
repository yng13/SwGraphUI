import SwiftUI
import SwGraphUI

struct ContentView: View {
    @Bindable var appStore: ExampleAppStore
    let graphStore: GraphStore<String>
    @Environment(\.undoManager) var undoManager
    
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
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Sample Navigator | サンプルナビゲータ")
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 1)
                            .accessibilityHidden(true)
                    }
            }
            
            // Content: Main Graph Canvas & Code
            VSplitView {
                mainCanvasView
                    .frame(minHeight: 400, idealHeight: 1200, maxHeight: .infinity)
                    .layoutPriority(1)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Graph Editing Area | グラフ編集エリア")
                
                if appStore.isCodeViewVisible {
                    CodeView(graphStore: graphStore)
                        .frame(minHeight: 150, idealHeight: 400, maxHeight: .infinity)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Code View | コードビュー")
                }
            }
            .frame(minWidth: 400)
            .layoutPriority(1) // Prioritize expanding the center pane | 中央ペインを優先的に広げる
            
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
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Inspector Pane | インスペクタペイン")
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("SwGraphUI Example")
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

                Divider()

                Menu {
                    Button(action: exportPNG) {
                        Label("PNG Image", systemImage: "photo")
                    }
                    Button(action: exportPDF) {
                        Label("PDF Vector", systemImage: "doc.richtext")
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .help("Export Graph as PNG or PDF")
            }
        }
        .onAppear {
            graphStore.undoManager = undoManager
        }
        .onChange(of: undoManager) { old, new in
            graphStore.undoManager = new
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
            ZStack(alignment: .bottomTrailing) {
                GraphView(
                    store: graphStore,
                    onEvent: handleGraphEvent,
                    onConnect: { connection in
                        appStore.addEdge(connection: connection, in: graphStore)
                    },
                    onReconnect: { _, _ in },
                    edgeBuilder: buildCustomEdge,
                    nodeBuilder: buildCustomNode,
                    backgroundBuilder: {
                        AnyView(BackgroundView(
                            viewport: graphStore.runtimeState.viewport.viewport,
                            variant: appStore.backgroundVariant
                        ))
                    }
                )
                .coordinateSpace(name: "graph")
                .background(Color(NSColor.underPageBackgroundColor))
                .border(Color.blue.opacity(0.3), width: 2) // Visualize FitView target area | FitView対象領域を可視化
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Graph Canvas Area | グラフキャンバス領域")
                
                // Plugins Area
                ZStack {
                    if appStore.isMiniMapVisible {
                        MiniMapView(
                            store: graphStore,
                            containerSize: Dimensions(width: geometry.size.width, height: geometry.size.height)
                        )
                        .frame(width: 200, height: 150)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                    
                    if appStore.isControlsVisible {
                        ControlsView(store: graphStore)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                }
                .allowsHitTesting(true) // Allow input to the plugin area | プラグイン領域への入力を許可
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Graph Auxiliary Controls | グラフ補助コントロール")
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Main Canvas | メインキャンバス")
            .onAppear {
                appStore.currentGraphSize = Dimensions(width: geometry.size.width, height: geometry.size.height)
            }
            .onChange(of: geometry.size) { _, newSize in
                appStore.currentGraphSize = Dimensions(width: newSize.width, height: newSize.height)
            }
            // Initial automatic fitView adjustment after measurement completion | 実測完了後の初回自動 fitView 調整
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
                },
                onMoveNodes: { offset in
                    graphStore.moveSelectedNodes(by: offset)
                }
            )
            .accessibilityHidden(true)
        }
        #endif
    }
    
    private func exportPNG() {
        #if os(macOS)
        appStore.exportToPNG(in: graphStore) { node in
            AnyView(buildCustomNode(node))
        }
        #endif
    }
    
    private func exportPDF() {
        #if os(macOS)
        appStore.exportToPDF(in: graphStore) { node in
            AnyView(buildCustomNode(node))
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
            ToolbarNodeView(
                node: node,
                store: graphStore,
                onUpdate: {
                    graphStore.updateSelectedNodes { $0.data = "Updated via Toolbar!" }
                    appStore.appendLog(kind: "toolbar.update", payload: "node text changed")
                },
                onDelete: {
                    graphStore.deleteSelection()
                    appStore.appendLog(kind: "toolbar.delete", payload: "node removed")
                },
                onConnect: onConnectHandler
            )
        case "color":
            ColorNodeView(node: node, store: graphStore, onConnect: onConnectHandler)
        case "custom":
            CustomNodeView(node: node, store: graphStore, onConnect: onConnectHandler)
        case "resizer":
            ResizableNodeView(node: node)
        case "group":
            GroupNodeView(node: node)
        default:
            DefaultNodeView(node: node, store: graphStore, onConnect: onConnectHandler)
        }
    }
    
    private func buildCustomEdge(
        _ edge: BaseEdge<String>,
        _ segments: [PathSegment],
        _ color: Color,
        _ width: CGFloat,
        _ viewport: Viewport,
        _ containerSize: Dimensions,
        _ animated: Bool,
        _ reconnecting: Bool
    ) -> AnyView {
        if edge.kind == "custom" {
            return AnyView(CustomEdgeBody(segments: segments, color: color, width: width, viewport: viewport, animated: animated, reconnecting: reconnecting, containerSize: containerSize))
        } else {
            return AnyView(
                EdgeRenderer(
                    segments: segments,
                    strokeColor: color,
                    strokeWidth: width,
                    viewport: viewport,
                    containerSize: containerSize,
                    animated: animated,
                    isReconnecting: reconnecting
                )
            )
        }
    }
}
