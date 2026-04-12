import SwiftUI
import Foundation

/// グラフの内容を PDF 形式で書き出す機能を提供します。
@MainActor
public struct PDFExporter<NodeData: Sendable> {
    private let store: GraphStore<NodeData>
    
    public init(store: GraphStore<NodeData>) {
        self.store = store
    }
    
    /// 現在のグラフ内容を PDF データとして生成します。
    /// - Parameters:
    ///   - settings: エクスポート設定。
    ///   - nodeBuilder: ノード描画用クロージャ。
    ///   - edgeBuilder: エッジ描画用クロージャ（任意）。
    /// - Returns: 生成された PDF データ（Data 型）。生成に失敗した場合は nil。
    public func export(
        settings: GraphExportSettings,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<NodeData>) -> some View,
        edgeBuilder: ((BaseEdge<NodeData>, [PathSegment], Color, CGFloat, Viewport, Dimensions, Bool, Bool) -> AnyView)? = nil
    ) -> Foundation.Data? {
        // 1. エクスポート対象の論理的な境界矩形を計算
        guard let bounds = GraphExportSupport(store: store).calculateExportBounds() else { return nil }
        
        // 2. レンダリング用のビューを構築
        // 背景は設定に従い、余計なオーバーレイを除去した状態の View を作成
        let exportView = GraphExportView(
            store: store,
            settings: settings,
            nodeBuilder: nodeBuilder,
            edgeBuilder: edgeBuilder ?? { _, segments, color, width, viewport, size, animated, reconnecting in
                AnyView(EdgeRenderer(segments: segments, strokeColor: color, strokeWidth: width, viewport: viewport, containerSize: size, animated: animated, isReconnecting: reconnecting))
            },
            bounds: bounds
        )
        
        // 3. ImageRenderer による PDF 生成
        let renderer = ImageRenderer(content: exportView)
        
        let pdfData = NSMutableData()
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else {
                return
            }
            
            pdfContext.beginPDFPage(nil)
            // context(CGContext) クロージャを呼び出し、exportView の内容を PDFContext に描画
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        
        return pdfData.length > 0 ? Data(referencing: pdfData) : nil
    }
}
