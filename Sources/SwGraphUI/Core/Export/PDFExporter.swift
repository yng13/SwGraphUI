import SwiftUI
import Foundation

/// Provides functionality to export graph content in PDF format. | グラフの内容を PDF 形式で書き出す機能を提供します。
@MainActor
public struct PDFExporter<NodeData: Sendable> {
    private let store: GraphStore<NodeData>
    
    public init(store: GraphStore<NodeData>) {
        self.store = store
    }
    
    /// Generates current graph content as PDF data. | 現在のグラフ内容を PDF データとして生成します。
    /// - Parameters:
    ///   - settings: Export settings. | エクスポート設定。
    ///   - nodeBuilder: Closure for node rendering. | ノード描画用クロージャ。
    ///   - edgeBuilder: Closure for edge rendering (optional). | エッジ描画用クロージャ（任意）。
    /// - Returns: Generated PDF data (Data type). Returns nil if generation fails. | 生成された PDF データ（Data 型）。生成に失敗した場合は nil。
    public func export(
        settings: GraphExportSettings,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<NodeData>) -> some View,
        edgeBuilder: ((BaseEdge<NodeData>, [PathSegment], Color, CGFloat, Viewport, Dimensions, Bool, Bool) -> AnyView)? = nil
    ) -> Foundation.Data? {
        // 1. Calculate the logical boundary rectangle for export | 1. エクスポート対象の論理的な境界矩形を計算
        guard let bounds = GraphExportSupport(store: store).calculateExportBounds() else { return nil }
        
        // 2. Construct the view for rendering | 2. レンダリング用のビューを構築
        // Create a view with the background set according to preferences and unwanted overlays removed | 背景は設定に従い、余計なオーバーレイを除去した状態の View を作成
        let exportView = GraphExportView(
            store: store,
            settings: settings,
            nodeBuilder: nodeBuilder,
            edgeBuilder: edgeBuilder.map { legacyBuilder in
                { context in
                    legacyBuilder(
                        context.edge,
                        context.graphSegments,
                        context.strokeColor,
                        context.strokeWidth,
                        context.viewport,
                        context.containerSize,
                        context.animated,
                        context.isReconnecting
                    )
                }
            } ?? { context in
                AnyView(
                    EdgeRenderer(
                        segments: context.graphSegments,
                        strokeColor: context.strokeColor,
                        strokeWidth: context.strokeWidth,
                        dashStyle: context.dashStyle,
                        viewport: context.viewport,
                        containerSize: context.containerSize,
                        animated: context.animated,
                        isReconnecting: context.isReconnecting
                    )
                )
            },
            bounds: bounds
        )
        
        // 3. PDF generation using ImageRenderer | 3. ImageRenderer による PDF 生成
        let renderer = ImageRenderer(content: exportView)
        
        let pdfData = NSMutableData()
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else {
                return
            }
            
            pdfContext.beginPDFPage(nil)
            // Call the context(CGContext) closure to draw the content of exportView into the PDFContext | context(CGContext) クロージャを呼び出し、exportView の内容を PDFContext に描画
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        
        return pdfData.length > 0 ? Data(referencing: pdfData) : nil
    }
}
