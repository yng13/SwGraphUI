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
    
    // MARK: - Sample Registry
    
    /// 全サンプルのレジストリ
    private let allSamples: [any GraphSample] = [
        BasicSample(),
        HierarchySample(),
        OverlapSample(),
        CustomSample(),
        OverviewSample(),
        InteractionSample(),
        CustomShowcaseSample()
    ]
    
    /// カテゴリに属するサンプルを返します
    public func samples(in category: SampleCategory) -> [any GraphSample] {
        allSamples.filter { $0.category == category }
    }
    
    /// 指定したサンプルのデータを GraphStore に適用します。
    public func switchSample(to sample: any GraphSample, in graphStore: GraphStore<String>) {
        self.selectedCategory = sample.category
        self.didAutoFitMeasuredSample = false // リセット
        appendLog(kind: "sample.select", payload: sample.title)
        
        sample.setup(in: graphStore, appStore: self)
        
        // 切り替え時に自動で fitView を実行
        graphStore.fitView(in: currentGraphSize)
    }

    /// カテゴリのデフォルト要素を適用します（後方互換用）
    public func switchSample(to category: SampleCategory, in graphStore: GraphStore<String>) {
        if let firstSample = allSamples.first(where: { $0.category == category }) {
            switchSample(to: firstSample, in: graphStore)
        }
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
