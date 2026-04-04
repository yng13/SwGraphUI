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
    public var isInspectorVisible: Bool = false
    
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
        case .overlap:
            newNodes = (1...5).map { i in
                BaseNode(id: "Node\(i)", position: XYPosition(x: Double(i * 40), y: Double(i * 40)), data: "Overlapping \(i)", width: 150, height: 50)
            }
        case .custom:
            newNodes = [
                BaseNode(id: "Short", position: XYPosition(x: 50, y: 50), data: "Short", kind: "custom"),
                BaseNode(id: "Long", position: XYPosition(x: 250, y: 50), data: "This is a much longer text to test the measurement engine", kind: "custom"),
                BaseNode(id: "Default", position: XYPosition(x: 150, y: 300), data: "Standard Node")
            ]
        }
        
        graphStore.nodes = newNodes
        graphStore.edges = newEdges
        
        // 切り替え時に自動で fitView を実行
        graphStore.fitView(in: currentGraphSize)
    }
    
    // MARK: - Initializer
    
    public init() {}
}
