import Testing
import SwiftUI
import Foundation
@testable import SwGraphUI

@MainActor
struct PDFExporterTests {
    @Test
    func exportGeneratesNonEmptyData() async throws {
        // Setup: Graph with one node | 準備: 1つのノードを持つグラフ
        let store = GraphStore<String>()
        store.nodes = [
            BaseNode(id: "1", position: XYPosition(x: 0, y: 0), data: "Node 1")
        ]
        
        let exporter = PDFExporter(store: store)
        let settings = GraphExportSettings(
            scale: 1.0,
            margin: 10,
            includeBackground: false,
            backgroundVariant: .dots,
            isTransparent: true
        )
        
        // Execute: PDF export | 実行: PDF エクスポート
        let data = exporter.export(settings: settings) { node in
            Text(node.data)
        }
        
        // Verification: Data exists and has minimal PDF structure (e.g., magic number) | 検証: データが存在し、最小限の PDF 構造（マジックナンバー等）を持っていること
        #expect(data != nil)
        if let data = data {
            #expect(data.count > 100)
            
            // Check PDF magic number "%PDF" | PDF のマジックナンバー "%PDF" をチェック
            let header = String(data: data.prefix(4), encoding: .ascii)
            #expect(header == "%PDF")
        }
    }
    
    @Test
    func exportWithEmptyGraphReturnsNil() async throws {
        let store = GraphStore<String>()
        let exporter = PDFExporter(store: store)
        let settings = GraphExportSettings(scale: 1.0, margin: 10)
        
        let data = exporter.export(settings: settings) { node in
            Text(node.data)
        }
        
        #expect(data == nil)
    }
}
