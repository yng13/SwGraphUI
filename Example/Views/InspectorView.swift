import SwiftUI
import SwGraphUI

/// Xcode の属性インスペクター風のビュー (M28a-Polish: 1px Alignment & Density Precision)
struct InspectorView: View {
    @Bindable var appStore: ExampleAppStore
    let graphStore: GraphStore<String>
    
    // MARK: - Constants
    private enum Constants {
        static let labelWidth: CGFloat = 92
        static let headerHeight: CGFloat = 22
        static let rowHeight: CGFloat = 20 // 22から20にさらに凝縮
        static let horizontalPadding: CGFloat = 6 // Xcode準拠
        static let contentIndent: CGFloat = 4 // ラベルとコンテンツの間
        static let fontSize: CGFloat = 11
        static let headerBackground = Color.primary.opacity(0.05)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Viewport Section
                InspectorHeader("Viewport")
                VStack(spacing: 1) {
                    InspectorRow("Zoom") {
                        HStack(spacing: 0) {
                            Button {
                                let center = XYPosition(x: appStore.currentGraphSize.width / 2, y: appStore.currentGraphSize.height / 2)
                                graphStore.zoom(at: center, factor: 1.2)
                            } label: { 
                                Image(systemName: "plus")
                                    .frame(width: 20, height: 16)
                            }
                            
                            Button {
                                let center = XYPosition(x: appStore.currentGraphSize.width / 2, y: appStore.currentGraphSize.height / 2)
                                graphStore.zoom(at: center, factor: 0.8)
                            } label: { 
                                Image(systemName: "minus")
                                    .frame(width: 20, height: 16)
                            }
                            
                            Button {
                                graphStore.fitView(in: appStore.currentGraphSize)
                            } label: { 
                                Image(systemName: "scope")
                                    .frame(width: 20, height: 16)
                            }
                        }
                        .buttonStyle(.plain)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(4)
                        .offset(y: -0.5)
                    }
                }
                .padding(.vertical, 4)
                
                // Selection Section
                InspectorHeader("Selection Summary")
                VStack(spacing: 0) {
                    InspectorRow("Nodes") {
                        Text("\(graphStore.selectedNodes.count)").font(.system(size: Constants.fontSize, design: .monospaced))
                    }
                    InspectorRow("Edges") {
                        Text("\(graphStore.selectedEdges.count)").font(.system(size: Constants.fontSize, design: .monospaced))
                    }
                    
                    if !graphStore.selectedNodes.isEmpty {
                        InspectorRow("Draggable") {
                            Toggle("", isOn: Binding(
                                get: { graphStore.selectedNodes.allSatisfy { $0.draggable } },
                                set: { newValue in
                                    graphStore.updateSelectedNodes { $0.draggable = newValue }
                                }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .scaleEffect(0.7)
                            .offset(x: -8, y: 0.5)
                        }
                    }
                    
                    InspectorRow("") {
                        HStack(spacing: 4) {
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
                VStack(spacing: 0) {
                    InspectorRow("MiniMap") {
                        Toggle("", isOn: $appStore.isMiniMapVisible)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .scaleEffect(0.7) // Xcode風に小型化
                            .offset(x: -8, y: 0.5)
                    }
                    InspectorRow("Controls") {
                        Toggle("", isOn: $appStore.isControlsVisible)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .scaleEffect(0.7)
                            .offset(x: -8, y: 0.5)
                    }
                    InspectorRow("Background") {
                        Picker("", selection: $appStore.backgroundVariant) {
                            Text("Dots").tag(BackgroundVariant.dots)
                            Text("Lines").tag(BackgroundVariant.lines)
                            Text("Cross").tag(BackgroundVariant.cross)
                        }
                        .labelsHidden()
                        .offset(y: -1)
                        #if os(macOS)
                        .controlSize(.small)
                        #endif
                    }
                }
                .padding(.vertical, 4)
                
                // Persistence
                InspectorHeader("Persistence")
                VStack(spacing: 0) {
                    InspectorRow("State") {
                        HStack(spacing: 4) {
                            Button("Snapshot") {
                                let snapshot = graphStore.snapshot()
                                appStore.savedSnapshot = snapshot
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
        VStack(spacing: 0) {
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
                .offset(y: -1)
                #if os(macOS)
                .controlSize(.small)
                #endif
            }
            
            if (representative.kind ?? "bezier") == "bezier" {
                InspectorRow("Curvature") {
                    HStack(spacing: 4) {
                        Slider(value: Binding(
                            get: { representative.curvature ?? 0.25 },
                            set: { val in graphStore.updateSelectedEdges { $0.curvature = val } }
                        ), in: 0...1)
                        Text(String(format: "%.2f", representative.curvature ?? 0.25))
                            .font(.system(size: 9, design: .monospaced))
                            .frame(width: 26)
                    }
                    .offset(y: -1)
                    #if os(macOS)
                    .controlSize(.small)
                    #endif
                }
            }
            
            InspectorRow("Animated") {
                Toggle("", isOn: Binding(
                    get: { representative.animated },
                    set: { val in graphStore.updateSelectedEdges { $0.animated = val } }
                ))
                .labelsHidden()
                .toggleStyle(.checkbox) // Xcode風チェックボックス
                .offset(y: 0.5)
            }
            
            InspectorRow("Label") {
                InspectorTextField(text: Binding(
                    get: { representative.label ?? "" },
                    set: { val in graphStore.updateSelectedEdges { $0.label = val.isEmpty ? nil : val } }
                ))
            }
        }
        .padding(.vertical, 4)
        
        InspectorHeader("Markers")
        VStack(spacing: 0) {
            markerRow(title: "Start", isEnd: false, edges: edges)
            markerRow(title: "End", isEnd: true, edges: edges)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var nodeInfoSection: some View {
        InspectorHeader("Node Info")
        VStack(spacing: 0) {
            ForEach(graphStore.selectedNodes) { node in
                VStack(spacing: 0) {
                    InspectorRow("ID") {
                        Text(node.id).font(.system(size: Constants.fontSize, design: .monospaced)).bold()
                    }
                    InspectorRow("Label") {
                        InspectorTextField(text: Binding(
                            get: { node.data },
                            set: { val in
                                graphStore.updateSelectedNodes { target in
                                    if target.id == node.id { target.data = val }
                                }
                            }
                        ))
                    }
                    InspectorRow("Position") {
                        Text("\(Int(node.position.x)), \(Int(node.position.y))")
                            .font(.system(size: Constants.fontSize - 1, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                if node.id != graphStore.selectedNodes.last?.id {
                    Divider().padding(.leading, Constants.labelWidth + 8).opacity(0.1).padding(.vertical, 2)
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
            HStack(spacing: 4) {
                Toggle("", isOn: Binding(
                    get: { marker != nil },
                    set: { val in
                        graphStore.updateSelectedEdges { edge in
                            if isEnd { edge.markerEnd = val ? EdgeMarker(type: .arrowClosed) : nil }
                            else { edge.markerStart = val ? EdgeMarker(type: .arrowClosed) : nil }
                        }
                    }
                ))
                .labelsHidden()
                .toggleStyle(.checkbox)
                .offset(y: 0.5)
                
                if let marker = marker {
                    HStack(spacing: 2) {
                        Text("W").font(.system(size: 8)).foregroundStyle(.secondary)
                        CompactNumberField(value: Binding(
                            get: { marker.width ?? 6.0 },
                            set: { val in
                                graphStore.updateSelectedEdges { edge in
                                    if isEnd { edge.markerEnd?.width = val } else { edge.markerStart?.width = val }
                                }
                            }
                        ))
                        
                        Text("H").font(.system(size: 8)).foregroundStyle(.secondary)
                        CompactNumberField(value: Binding(
                            get: { marker.height ?? 6.0 },
                            set: { val in
                                graphStore.updateSelectedEdges { edge in
                                    if isEnd { edge.markerEnd?.height = val } else { edge.markerStart?.height = val }
                                }
                            }
                        ))
                    }
                }
            }
        }
    }
    
    // MARK: - Components
    
    /// Xcode 風の入力欄
    private struct InspectorTextField: View {
        @Binding var text: String
        var body: some View {
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .padding(.horizontal, 4)
                .frame(height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                )
                #if os(macOS)
                .controlSize(.small)
                #endif
        }
    }
    
    /// 数値用小型入力欄
    private struct CompactNumberField: View {
        @Binding var value: Double
        var body: some View {
            TextField("", value: $value, formatter: NumberFormatter())
                .textFieldStyle(.plain)
                .font(.system(size: 10, design: .monospaced))
                .multilineTextAlignment(.center)
                .frame(width: 28, height: 16)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
    
    /// Xcode 風のプロパティ行 (1px Polish)
    @ViewBuilder
    private func InspectorRow<Content: View>(_ label: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        HStack(alignment: .center, spacing: Constants.contentIndent) {
            Text(label)
                .font(.system(size: Constants.fontSize))
                .foregroundStyle(.secondary)
                .frame(width: Constants.labelWidth, alignment: .trailing)
            
            content()
            
            Spacer()
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(minHeight: Constants.rowHeight)
    }
    
    /// Xcode 風のセクションヘッダー (Density Polish)
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
