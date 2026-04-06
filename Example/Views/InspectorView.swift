import SwiftUI
import SwGraphUI

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
