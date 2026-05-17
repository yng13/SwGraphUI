import SwiftUI

/// Provides functionality to export graph content as PNG image data. | グラフの内容を PNG 画像データとして書き出す機能を提供します。
@MainActor
public struct PNGExporter<NodeData: Sendable> {
    private let store: GraphStore<NodeData>
    
    public init(store: GraphStore<NodeData>) {
        self.store = store
    }
    
    /// Calculates the logical boundary rectangle for export. | エクスポート対象の論理的な境界矩形を計算します。
    public func calculateExportBounds() -> Rect? {
        GraphExportSupport(store: store).calculateExportBounds()
    }

    /// Generates current graph content as PNG data. | 現在のグラフ内容を PNG データとして生成します。
    public func export(
        settings: GraphExportSettings,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<NodeData>) -> some View,
        edgeBuilder: ((BaseEdge<NodeData>, [PathSegment], Color, CGFloat, Viewport, Dimensions, Bool, Bool) -> AnyView)? = nil
    ) -> Foundation.Data? {
        // 1. Calculate the logical boundary rectangle for export | 1. エクスポート対象の論理的な境界矩形を計算
        guard let bounds = calculateExportBounds() else { return nil }
        
        // 2. Construct the view for rendering | 2. レンダリング用のビューを構築
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
                        strokeShape: context.strokeShape,
                        viewport: context.viewport,
                        containerSize: context.containerSize,
                        animated: context.animated,
                        isReconnecting: context.isReconnecting
                    )
                )
            },
            bounds: bounds
        )
        
        // 3. Image generation using ImageRenderer | 3. ImageRenderer による画像生成
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = settings.scale
        
        #if os(macOS)
        guard let nsImage = renderer.nsImage else { return nil }
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
        #else
        guard let uiImage = renderer.uiImage else { return nil }
        return uiImage.pngData()
        #endif
    }
}
