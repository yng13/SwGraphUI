import SwiftUI

/// グラフの内容を PNG 画像データとして書き出す機能を提供します。
@MainActor
public struct PNGExporter<NodeData: Sendable> {
    private let store: GraphStore<NodeData>
    
    public init(store: GraphStore<NodeData>) {
        self.store = store
    }
    
    /// エクスポート対象の論理的な境界矩形を計算します。
    public func calculateExportBounds() -> Rect? {
        GraphExportSupport(store: store).calculateExportBounds()
    }

    /// 現在のグラフ内容を PNG データとして生成します。
    public func export(
        settings: GraphExportSettings,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<NodeData>) -> some View,
        edgeBuilder: ((BaseEdge<NodeData>, [PathSegment], Color, CGFloat, Viewport, Bool, Bool) -> AnyView)? = nil
    ) -> Foundation.Data? {
        // 1. エクスポート対象の論理的な境界矩形を計算
        guard let bounds = calculateExportBounds() else { return nil }
        
        // 2. レンダリング用のビューを構築
        let exportView = GraphExportView(
            store: store,
            settings: settings,
            nodeBuilder: nodeBuilder,
            edgeBuilder: edgeBuilder ?? { _, segments, color, width, viewport, animated, reconnecting in
                AnyView(EdgeRenderer(segments: segments, strokeColor: color, strokeWidth: width, viewport: viewport, animated: animated, isReconnecting: reconnecting))
            },
            bounds: bounds
        )
        
        // 3. ImageRenderer による画像生成
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = settings.scale
        
        #if os(macOS)
        guard let nsImage = renderer.nsImage else { return nil }
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #else
        guard let uiImage = renderer.uiImage else { return nil }
        return uiImage.pngData()
        #endif
    }
}
