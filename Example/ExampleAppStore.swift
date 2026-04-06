import Foundation
import Observation
import SwGraphUI
#if os(macOS)
import SwiftUI
#endif

/// サンプルアプリ固有の状態（ログ、表示オプション、サンプル切り替え）を管理するストア。
/// ライブラリ本体の GraphStore とは独立して動作します。
@Observable @MainActor
public final class ExampleAppStore {
    
    // MARK: - Sample Selection
    
    public enum SampleCategory: String, CaseIterable, Identifiable {
        case basic = "Basic"
        case hierarchy = "Hierarchy"
        case overlap = "Overlap Test"
        case custom = "Custom & Measure"
        case overview = "Feature Overview"
        case interaction = "Interaction Playground"
        case customShowcase = "Custom Showcase"

        
        public var id: String { rawValue }
    }
    
    public var selectedCategory: SampleCategory = .basic
    
    /// 実測が必要なサンプル（Custom等）において、初回実測後の自動 fitView が完了したか
    public var didAutoFitMeasuredSample: Bool = false
    
    // MARK: - Size Tracking
    
    /// 現在の GraphView の表示領域サイズ。fitView 時に使用します。
    public var currentGraphSize: Dimensions = Dimensions(width: 800, height: 600)
    
    // MARK: - UI Options
    
    #if os(macOS)
    public var columnVisibility: NavigationSplitViewVisibility = .all
    public var isSidebarVisible: Bool = true
    #endif
    
    public var isCodeViewVisible: Bool = true
    public var isLogVisible: Bool = true
    public var isInspectorVisible: Bool = true
    
    // MARK: - Debug Logging
    
    public struct LogEntry: Identifiable {
        public let id = UUID()
        public let kind: String
        public let payload: String
        
        public var description: String {
            "[\(kind)] \(payload)"
        }
    }
    
    private(set) public var logs: [LogEntry] = []
    private let maxLogCount = 50
    
    public func appendLog(kind: String, payload: String = "") {
        let entry = LogEntry(kind: kind, payload: payload)
        logs.insert(entry, at: 0) // 最新を上に
        
        if logs.count > maxLogCount {
            logs.removeLast()
        }
    }
    
    public func clearLogs() {
        logs.removeAll()
    }
    
    // MARK: - Business Logic
    
    /// 指定したカテゴリのサンプルデータを GraphStore に適用します。
    public func switchSample(to category: SampleCategory, in graphStore: GraphStore<String>) {
        self.selectedCategory = category
        self.didAutoFitMeasuredSample = false // リセット
        appendLog(kind: "sample.select", payload: category.rawValue)
        
        var newNodes: [BaseNode<String>] = []
        
        var newEdges: [BaseEdge<String>] = []
        
        switch category {
        case .basic:
            newNodes = [
                BaseNode(id: "A", position: XYPosition(x: 100, y: 100), data: "Node A", width: 150, height: 50),
                BaseNode(id: "B", position: XYPosition(x: 400, y: 200), data: "Node B", width: 150, height: 50)
            ]
            newEdges = [
                BaseEdge(id: "eA-B", source: "A", target: "B", markerEnd: EdgeMarker(type: .arrowClosed))
            ]
        case .hierarchy:
            let p = BaseNode(id: "parent", position: XYPosition(x: 50, y: 50), data: "Parent", width: 400, height: 350)
            let c = BaseNode(id: "child", position: XYPosition(x: 50, y: 50), data: "Child", parentID: "parent", width: 300, height: 250)
            let g = BaseNode(id: "grandchild", position: XYPosition(x: 50, y: 50), data: "Grandchild", parentID: "child", width: 150, height: 50)
            newNodes = [p, c, g]
            appendLog(kind: "hint", payload: "Try connecting Parent -> Child in hierarchy")
        case .overlap:
            newNodes = (1...5).map { i in
                BaseNode(id: "Node\(i)", position: XYPosition(x: Double(i * 40), y: Double(i * 40)), data: "Overlapping \(i)", width: 150, height: 50)
            }
        case .custom:
            newNodes = [
                BaseNode(id: "Short", position: XYPosition(x: 50, y: 50), data: "Short", kind: "custom"),
                BaseNode(id: "CPU-Node", position: XYPosition(x: 450, y: 150), data: "CPU Logic Node", kind: "custom"),
                BaseNode(id: "Default", position: XYPosition(x: 150, y: 350), data: "Standard Node")
            ]
            appendLog(kind: "hint", payload: "Custom nodes have purple handles")
            
        case .overview:
            let g1 = BaseNode(id: "g1", position: XYPosition(x: 450, y: 150), data: "Group Node", width: 250, height: 200)
            let c1 = BaseNode(id: "c1", position: XYPosition(x: 50, y: 50), data: "Inside Group", parentID: "g1")
            
            newNodes = [
                BaseNode(id: "welcome", position: XYPosition(x: 250, y: 0), data: "Overview: Feature Gallery"),
                BaseNode(id: "n-source", position: XYPosition(x: 50, y: 120), data: "Common Source"),
                BaseNode(id: "n-styled", position: XYPosition(x: 250, y: 120), data: "Styled Nodes"),
                
                BaseNode(id: "n-target1", position: XYPosition(x: 50, y: 350), data: "Bezier (Default)"),
                BaseNode(id: "n-target2", position: XYPosition(x: 250, y: 350), data: "Straight Path"),
                g1, c1
            ]
            newEdges = [
                // Bezier
                BaseEdge<String>(id: "e-bez", source: "n-source", target: "n-target1", markerEnd: EdgeMarker(type: .arrowClosed), label: "Bezier & Label", reconnectable: .both),
                // Straight
                BaseEdge<String>(id: "e-str", source: "n-source", target: "n-target2", kind: "straight", markerEnd: EdgeMarker(type: .arrowClosed), label: "Straight Line", reconnectable: .both),
                // SmoothStep to Group Child
                BaseEdge<String>(id: "e-smooth", source: "n-styled", target: "c1", kind: "smoothstep", markerEnd: EdgeMarker(type: .arrowClosed), label: "Smooth Step", reconnectable: .both),
                // Animated Bezier with Start/End Markers
                BaseEdge<String>(id: "e-anim", source: "welcome", target: "n-styled", animated: true, markerStart: EdgeMarker(type: .arrow), markerEnd: EdgeMarker(type: .arrowClosed), label: "Animated Markers", reconnectable: .both)
            ]
            appendLog(kind: "sample", payload: "Overview: [Reconnect/Label/Marker/Group] showcase")
            appendLog(kind: "hint", payload: "Try dragging edge ends to RECONNECT, or select nodes to move them.")

        case .interaction:
            // Hierarchy
            let group = BaseNode(id: "g1", position: XYPosition(x: 50, y: 50), data: "Hierarchy Group", width: 300, height: 250)
            let c1 = BaseNode(id: "c1", position: XYPosition(x: 50, y: 50), data: "Child 1", parentID: "g1")
            let c2 = BaseNode(id: "c2", position: XYPosition(x: 50, y: 150), data: "Child 2", parentID: "g1")
            
            // Overlap
            let o1 = BaseNode(id: "o1", position: XYPosition(x: 400, y: 50), data: "Overlap 1 (Bottom)")
            let o2 = BaseNode(id: "o2", position: XYPosition(x: 430, y: 80), data: "Overlap 2")
            let o3 = BaseNode(id: "o3", position: XYPosition(x: 460, y: 110), data: "Overlap 3 (Top)")
            
            // Floating
            let f1 = BaseNode(id: "f1", position: XYPosition(x: 400, y: 250), data: "Floating Target")
            
            newNodes = [group, c1, c2, o1, o2, o3, f1]
            let e1 = BaseEdge<String>(id: "e-c1-c2", source: "c1", target: "c2", markerEnd: EdgeMarker(type: .arrowClosed), label: "Reconnect Me", reconnectable: .both)
            let e2 = BaseEdge<String>(id: "e-o1-o3", source: "o1", target: "o3", markerEnd: EdgeMarker(type: .arrowClosed), label: "Overlap Edge", reconnectable: .both)
            newEdges = [e1, e2]
            appendLog(kind: "sample", payload: "Interaction: Test Multi-select, Marquee (Shift+Drag), Hierarchy Drag, and Overlap")
            appendLog(kind: "hint", payload: "Try Shift+Drag for Marquee Selection or Cmd+Wheel to Zoom")
            
        case .customShowcase:
            newNodes = [
                BaseNode(id: "toolbar-node", position: XYPosition(x: 50, y: 150), data: "Select for Toolbar", kind: "toolbar"),
                BaseNode(id: "red-node", position: XYPosition(x: 350, y: 50), data: "Red", kind: "color"),
                BaseNode(id: "blue-node", position: XYPosition(x: 350, y: 250), data: "Blue", kind: "color"),
                BaseNode(id: "custom-v1", position: XYPosition(x: 50, y: 350), data: "Complex CPU Node", kind: "custom"),
                BaseNode(id: "styled-node", position: XYPosition(x: 450, y: 350), data: "Standard Styled")
            ]
            newEdges = [
                BaseEdge<String>(id: "e-custom-edge", source: "toolbar-node", target: "red-node", kind: "custom", markerEnd: EdgeMarker(type: .arrowClosed), label: "Custom Path & Neon", reconnectable: .both),
                BaseEdge<String>(id: "e-red-blue", source: "red-node", target: "blue-node", markerEnd: EdgeMarker(type: .arrowClosed), label: "Default Edge", reconnectable: .both),
                BaseEdge<String>(id: "e-blue-styled", source: "blue-node", target: "styled-node", animated: true, markerEnd: EdgeMarker(type: .arrowClosed), label: "Animated Default", reconnectable: .both)
            ]
            appendLog(kind: "sample", payload: "Custom Showcase: ToolbarNode, ColorNode, and CustomEdgeBody")
            appendLog(kind: "hint", payload: "Click 'toolbar-node' to see floating menus. Red/Blue nodes are Custom ColorNodes.")
        }

        
        graphStore.nodes = newNodes
        graphStore.edges = newEdges
        
        // 切り替え時に自動で fitView を実行
        graphStore.fitView(in: currentGraphSize)
    }

    // MARK: - Connection

    /// 接続ドラッグが成功した際に呼ばれ、グラフに新しいエッジを追加します。
    public func addEdge(connection: Connection, in graphStore: GraphStore<String>) {
        appendLog(kind: "onConnect", payload: "\(connection.source) -> \(connection.target)")
        
        // 簡易的な重複チェック
        if graphStore.edges.contains(where: { $0.source == connection.source && $0.target == connection.target }) {
            appendLog(kind: "skip", payload: "Edge already exists")
            return
        }
        
        let id = "e-\(connection.source)-\(connection.target)-\(Int(Date().timeIntervalSince1970))"
        let newEdge = BaseEdge<String>(
            id: id,
            source: connection.source,
            target: connection.target,
            sourceHandle: connection.sourceHandle,
            targetHandle: connection.targetHandle,
            sourcePosition: connection.sourcePosition,
            targetPosition: connection.targetPosition,
            markerEnd: EdgeMarker(type: .arrowClosed),
            reconnectable: .both
        )
        
        graphStore.edges.append(newEdge)
    }
    
    // MARK: - Initializer
    
    public init() {}
}
