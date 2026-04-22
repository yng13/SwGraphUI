import Foundation
import Observation
import SwGraphUI
#if os(macOS)
import SwiftUI
import AppKit
import UniformTypeIdentifiers
#endif

/// A store that manages sample-app-specific states (logs, display options, sample switching). | サンプルアプリ固有の状態（ログ、表示オプション、サンプル切り替え）を管理するストア。
/// Operates independently from the library's main GraphStore. | ライブラリ本体の GraphStore とは独立して動作します。
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
        case snapshots = "Snapshots"
        case plugins = "Plugins"
        case subflow = "Subflows & Nesting"
        case layout = "Layout"
        
        public var id: String { rawValue }
    }
    
    public var selectedCategory: SampleCategory = .basic
    public var selectedSample: (any GraphSample)?
    
    /// For memory retention of snapshots | スナップショットのメモリ保持用
    public var savedSnapshot: GraphSnapshot<String>?
    
    /// In samples requiring measurement (e.g., Custom), whether initial automatic fitView after measurement has completed | 実測が必要なサンプル（Custom等）において、初回実測後の自動 fitView が完了したか
    public var didAutoFitMeasuredSample: Bool = false
    
    // MARK: - Size Tracking
    
    /// Current display area size of GraphView. Used during fitView. | 現在の GraphView の表示領域サイズ。fitView 時に使用します。
    public var currentGraphSize: Dimensions = Dimensions(width: 800, height: 600)
    
    // MARK: - UI Options
    
    #if os(macOS)
    public var columnVisibility: NavigationSplitViewVisibility = .all
    public var isSidebarVisible: Bool = true
    #endif
    
    public var isCodeViewVisible: Bool = true
    public var isLogVisible: Bool = true
    public var isInspectorVisible: Bool = true
    
    public var isMiniMapVisible: Bool = true
    public var isControlsVisible: Bool = true
    
    /// Background drawing style (dots, lines, cross) | 背景の描画スタイル (dots, lines, cross)
    public var backgroundVariant: BackgroundVariant = .dots
    
    /// Whether to include the background during export | エクスポート時に背景を含めるか
    public var isExportBackgroundEnabled: Bool = false
    
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
        logs.insert(entry, at: 0) // Newest at top | 最新を上に
        
        if logs.count > maxLogCount {
            logs.removeLast()
        }
    }
    
    public func clearLogs() {
        logs.removeAll()
    }
    
    // MARK: - Sample Registry
    
    /// Registry of all samples | 全サンプルのレジストリ
    private let allSamples: [any GraphSample] = [
        BasicSample(),
        HierarchySample(),
        OverlapSample(),
        CustomSample(),
        OverviewSample(),
        InteractionSample(),
        CustomShowcaseSample(),
        MiniMapAndControlsSample(),
        EdgeLabelSample(),
        NodeResizerSample(),
        SaveRestoreSample(),
        SubflowSample(),
        DagreTreeSample(),
        StressTestSample()
    ]
    
    /// Returns samples belonging to a category | カテゴリに属するサンプルを返します
    public func samples(in category: SampleCategory) -> [any GraphSample] {
        allSamples.filter { $0.category == category }
    }
    
    /// Retrieves a sample by ID. | ID からサンプルを取得します。
    public func sample(id: String) -> (any GraphSample)? {
        allSamples.first { $0.id == id }
    }
    
    /// Applies data from the specified sample to GraphStore. | 指定したサンプルのデータを GraphStore に適用します。
    public func switchSample(to sample: any GraphSample, in graphStore: GraphStore<String>) {
        self.selectedCategory = sample.category
        self.selectedSample = sample
        self.didAutoFitMeasuredSample = false // Reset | リセット
        appendLog(kind: "sample.select", payload: sample.title)
        
        sample.setup(in: graphStore, appStore: self)
        
        // Automatically execute fitView when switching | 切り替え時に自動で fitView を実行
        graphStore.fitView(in: currentGraphSize)
    }

    /// Applies the default element of a category (for backward compatibility) | カテゴリのデフォルト要素を適用します（後方互換用）
    public func switchSample(to category: SampleCategory, in graphStore: GraphStore<String>) {
        if let firstSample = allSamples.first(where: { $0.category == category }) {
            switchSample(to: firstSample, in: graphStore)
        }
    }
    
    // MARK: - Connection
    
    /// Called when connection drag is successful, adding a new edge to the graph. | 接続ドラッグが成功した際に呼ばれ、グラフに新しいエッジを追加します。
    public func addEdge(connection: Connection, in graphStore: GraphStore<String>) {
        appendLog(kind: "onConnect", payload: "\(connection.source) -> \(connection.target)")
        
        // Simple duplication check | 簡易的な重複チェック
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
    
    // MARK: - Export
    
    #if os(macOS)
    /// Exports graph content as PNG (macOS only) | グラフの内容を PNG として書き出します（macOS専用）
    public func exportToPNG(
        in graphStore: GraphStore<String>,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<String>) -> AnyView
    ) {
        let exporter = PNGExporter(store: graphStore)
        // Apply settings (scale: 2.0, margin: 32, reflects background toggle) | 設定を適用 (scale: 2.0, margin: 32, 背景トグル反映)
        let settings = GraphExportSettings(
            scale: 2.0,
            margin: 32.0,
            includeBackground: isExportBackgroundEnabled,
            backgroundVariant: backgroundVariant,
            isTransparent: false
        )
        
        guard let data = exporter.export(
            settings: settings,
            nodeBuilder: { node in nodeBuilder(node) }
        ) else {
            appendLog(kind: "export.error", payload: "Failed to generate PNG data")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save Graph as PNG"
        savePanel.nameFieldStringValue = "graph-export.png"
        
        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            do {
                try data.write(to: url)
                self.appendLog(kind: "export.success", payload: "Saved to \(url.lastPathComponent)")
            } catch {
                self.appendLog(kind: "export.error", payload: error.localizedDescription)
            }
        }
    }
    
    /// Exports graph content as PDF (macOS only) | グラフの内容を PDF として書き出します（macOS専用）
    public func exportToPDF(
        in graphStore: GraphStore<String>,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<String>) -> AnyView
    ) {
        let exporter = PDFExporter(store: graphStore)
        let settings = GraphExportSettings(
            scale: 1.0,
            margin: 32.0,
            includeBackground: isExportBackgroundEnabled,
            backgroundVariant: backgroundVariant,
            isTransparent: false
        )
        
        guard let data = exporter.export(
            settings: settings,
            nodeBuilder: { node in nodeBuilder(node) }
        ) else {
            appendLog(kind: "export.error", payload: "Failed to generate PDF data")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save Graph as PDF"
        savePanel.nameFieldStringValue = "graph-export.pdf"
        
        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            do {
                try data.write(to: url)
                self.appendLog(kind: "export.success", payload: "Saved to \(url.lastPathComponent)")
            } catch {
                self.appendLog(kind: "export.error", payload: error.localizedDescription)
            }
        }
    }
    #endif
    
    // MARK: - Initializer
    
    public init() {}
}
