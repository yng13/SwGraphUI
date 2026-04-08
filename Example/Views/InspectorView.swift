import SwiftUI
import SwGraphUI

/// Xcode の属性インスペクター風のビュー (M28a: Core Density Refinement)
struct InspectorView: View {
    @Bindable var appStore: ExampleAppStore
    let graphStore: GraphStore<String>
    
    // MARK: - Constants
    private enum Constants {
        static let labelWidth: CGFloat = 92
        static let headerHeight: CGFloat = 22
        static let rowHeight: CGFloat = 22
        static let horizontalPadding: CGFloat = 4
        static let fontSize: CGFloat = 11
        static let headerBackground = Color.primary.opacity(0.05)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Viewport Section
                InspectorHeader("Viewport")
                VStack(spacing: 4) {
                    InspectorRow("Zoom") {
                        HStack(spacing: 4) {
                            Button {
                                let center = XYPosition(x: appStore.currentGraphSize.width / 2, y: appStore.currentGraphSize.height / 2)
                                graphStore.zoom(at: center, factor: 1.2)
                            } label: { Image(systemName: "plus.magnifyingglass") }
                            
                            Button {
                                let center = XYPosition(x: appStore.currentGraphSize.width / 2, y: appStore.currentGraphSize.height / 2)
                                graphStore.zoom(at: center, factor: 0.8)
                            } label: { Image(systemName: "minus.magnifyingglass") }
                            
                            Button {
                                graphStore.fitView(in: appStore.currentGraphSize)
                            } label: { Image(systemName: "scope") }
                        }
                        .buttonStyle(.bordered)
                        #if os(macOS)
                        .controlSize(.small)
                        #endif
                    }
                }
                .padding(.vertical, 4)
                
                // Selection Section
                InspectorHeader("Selection Summary")
                VStack(spacing: 2) {
                    InspectorRow("Nodes") {
                        Text("\(graphStore.selectedNodes.count)").font(.system(size: Constants.fontSize, design: .monospaced))
                    }
                    InspectorRow("Edges") {
                        Text("\(graphStore.selectedEdges.count)").font(.system(size: Constants.fontSize, design: .monospaced))
                    }
                    
                    InspectorRow("") {
                        HStack {
                            Button("Clear") { graphStore.clearSelection() }
                            Button("Delete", role: .destructive) {
                                let nodes = graphStore.selectedNodes.count
                                let edges = graphStore.selectedEdges.count
                                graphStore.deleteSelection()
                                appStore.appendLog(kind: "selection.delete", payload: "nodes=\(nodes), edges=\(edges)")
                            }
                            .disabled(graphStore.selectedNodes.isEmpty && graphStore.selectedEdges.isEmpty)
                        }
                        .buttonStyle(.bordered)
                        #if os(macOS)
                        .controlSize(.small)
                        #endif
                    }
                }
                .padding(.vertical, 4)
                
                if !graphStore.selectedEdges.isEmpty {
                    edgeEditorSection
                }
                
                if !graphStore.selectedNodes.isEmpty {
                    nodeInfoSection
                }
                
                // Global Options
                InspectorHeader("Global View Options")
                VStack(spacing: 2) {
                    InspectorRow("MiniMap") {
                        Toggle("", isOn: $appStore.isMiniMapVisible).labelsHidden()
                    }
                    InspectorRow("Controls") {
                        Toggle("", isOn: $appStore.isControlsVisible).labelsHidden()
                    }
                    InspectorRow("Background") {
                        Picker("", selection: $appStore.backgroundVariant) {
                            Text("Dots").tag(BackgroundVariant.dots)
                            Text("Lines").tag(BackgroundVariant.lines)
                            Text("Cross").tag(BackgroundVariant.cross)
                        }
                        .labelsHidden()
                        #if os(macOS)
                        .controlSize(.small)
                        #endif
                    }
                }
                .padding(.vertical, 4)
                
                // Persistence
                InspectorHeader("Persistence")
                VStack(spacing: 4) {
                    InspectorRow("State") {
                        HStack {
                            Button("Take Snapshot") {
                                let snapshot = graphStore.snapshot()
                                appStore.savedSnapshot = snapshot
                                appStore.appendLog(kind: "snapshot.save", payload: "Captured to memory")
                            }
                            Button("Restore") {
                                if let snapshot = appStore.savedSnapshot {
                                    graphStore.apply(snapshot: snapshot)
                                }
                            }
                            .disabled(appStore.savedSnapshot == nil)
                        }
                        .buttonStyle(.bordered)
                        #if os(macOS)
                        .controlSize(.small)
                        #endif
                    }
                }
                .padding(.vertical, 4)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var edgeEditorSection: some View {
        let edges = graphStore.selectedEdges
        let representative = edges.first!
        
        InspectorHeader("Edge Style")
        VStack(spacing: 2) {
            InspectorRow("Kind") {
                Picker("", selection: Binding(
                    get: { representative.kind ?? "bezier" },
                    set: { newValue in graphStore.updateSelectedEdges { $0.kind = newValue } }
                )) {
                    Text("Bezier").tag("bezier")
                    Text("Straight").tag("straight")
                    Text("Step").tag("step")
                    Text("SmoothStep").tag("smoothstep")
                }
                .labelsHidden()
                #if os(macOS)
                .controlSize(.small)
                #endif
            }
            
            if (representative.kind ?? "bezier") == "bezier" {
                InspectorRow("Curvature") {
                    HStack {
                        Slider(value: Binding(
                            get: { representative.curvature ?? 0.25 },
                            set: { val in graphStore.updateSelectedEdges { $0.curvature = val } }
                        ), in: 0...1)
                        Text(String(format: "%.2f", representative.curvature ?? 0.25))
                            .font(.system(size: 9, design: .monospaced))
                            .frame(width: 30)
                    }
                    #if os(macOS)
                    .controlSize(.small)
                    #endif
                }
            }
            
            InspectorRow("Animated") {
                Toggle("", isOn: Binding(
                    get: { representative.animated },
                    set: { val in graphStore.updateSelectedEdges { $0.animated = val } }
                )).labelsHidden()
            }
            
            InspectorRow("Label") {
                TextField("Title", text: Binding(
                    get: { representative.label ?? "" },
                    set: { val in graphStore.updateSelectedEdges { $0.label = val.isEmpty ? nil : val } }
                ))
                .textFieldStyle(.roundedBorder)
                #if os(macOS)
                .controlSize(.small)
                #endif
            }
        }
        .padding(.vertical, 4)
        
        InspectorHeader("Markers")
        VStack(spacing: 2) {
            markerRow(title: "Start", isEnd: false, edges: edges)
            markerRow(title: "End", isEnd: true, edges: edges)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var nodeInfoSection: some View {
        InspectorHeader("Node Info")
        VStack(spacing: 6) {
            ForEach(graphStore.selectedNodes) { node in
                VStack(spacing: 2) {
                    InspectorRow("ID") {
                        Text(node.id).font(.system(size: Constants.fontSize, design: .monospaced)).bold()
                    }
                    InspectorRow("Label") {
                        TextField("", text: Binding(
                            get: { node.data },
                            set: { val in
                                graphStore.updateSelectedNodes { target in
                                    if target.id == node.id { target.data = val }
                                }
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        #if os(macOS)
                        .controlSize(.small)
                        #endif
                    }
                    InspectorRow("Position") {
                        Text("\(Int(node.position.x)), \(Int(node.position.y))")
                            .font(.system(size: Constants.fontSize - 1, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                if node.id != graphStore.selectedNodes.last?.id {
                    Divider().padding(.leading, Constants.labelWidth + 8).opacity(0.3)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func markerRow(title: String, isEnd: Bool, edges: [BaseEdge<String>]) -> some View {
        let representative = edges.first!
        let marker = isEnd ? representative.markerEnd : representative.markerStart
        
        InspectorRow(title) {
            HStack(spacing: 8) {
                Toggle("", isOn: Binding(
                    get: { marker != nil },
                    set: { val in
                        graphStore.updateSelectedEdges { edge in
                            if isEnd { edge.markerEnd = val ? EdgeMarker(type: .arrowClosed) : nil }
                            else { edge.markerStart = val ? EdgeMarker(type: .arrowClosed) : nil }
                        }
                    }
                )).labelsHidden()
                
                if let marker = marker {
                    HStack(spacing: 4) {
                        Text("W:").font(.system(size: 9)).foregroundStyle(.secondary)
                        TextField("", value: Binding(
                            get: { marker.width ?? 6.0 },
                            set: { val in
                                graphStore.updateSelectedEdges { edge in
                                    if isEnd { edge.markerEnd?.width = val } else { edge.markerStart?.width = val }
                                }
                            }
                        ), formatter: NumberFormatter())
                        .frame(width: 30)
                        
                        Text("H:").font(.system(size: 9)).foregroundStyle(.secondary)
                        TextField("", value: Binding(
                            get: { marker.height ?? 6.0 },
                            set: { val in
                                graphStore.updateSelectedEdges { edge in
                                    if isEnd { edge.markerEnd?.height = val } else { edge.markerStart?.height = val }
                                }
                            }
                        ), formatter: NumberFormatter())
                        .frame(width: 30)
                    }
                    .textFieldStyle(.plain)
                    #if os(macOS)
                    .controlSize(.small)
                    #endif
                }
            }
        }
    }
    
    // MARK: - Components
    
    /// Xcode 風のプロパティ行
    @ViewBuilder
    private func InspectorRow<Content: View>(_ label: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(label)
                .font(.system(size: Constants.fontSize))
                .foregroundStyle(.secondary)
                .frame(width: Constants.labelWidth, alignment: .trailing)
            
            content()
                .font(.system(size: Constants.fontSize))
            
            Spacer()
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(minHeight: Constants.rowHeight)
    }
    
    /// Xcode 風のセクションヘッダー
    @ViewBuilder
    private func InspectorHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: Constants.fontSize, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(height: Constants.headerHeight)
        .background(Constants.headerBackground)
    }
}
