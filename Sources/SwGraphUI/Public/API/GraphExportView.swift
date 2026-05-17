import SwiftUI

/// Graph display view specialized for export (image output). | エクスポート（画像書き出し）専用のグラフ表示ビュー。
/// Prioritizes image quality and does not include gestures or debug overlays. | 画質を最優先し、ジェスチャやデバッグ用のオーバーレイを含みません。
internal struct GraphExportView<NodeData: Sendable, NodeContent: View>: View {
    let store: GraphStore<NodeData>
    let settings: GraphExportSettings
    let nodeBuilder: (BaseNode<NodeData>) -> NodeContent
    let edgeBuilder: (EdgeRenderContext<NodeData>) -> AnyView
    
    // Rectangular area to be exported (absolute graph coordinate system) | エクスポート対象の矩形領域（グラフ絶対座標系）
    let bounds: Rect
    
    var body: some View {
        let contentSize = CGSize(width: bounds.width + settings.margin * 2,
                               height: bounds.height + settings.margin * 2)
        let exportViewport = Viewport(
            x: -bounds.x + settings.margin,
            y: -bounds.y + settings.margin,
            zoom: 1.0
        )
        
        ZStack(alignment: .topLeading) {
            // Background color (if not transparent) | 背景色（透明でない場合）
            if !settings.isTransparent {
                #if os(macOS)
                Color(nsColor: .windowBackgroundColor)
                #else
                Color(.secondarySystemBackground)
                #endif
            }
            
            // Background grid (if requested) | 背景グリッド（要求された場合）
            if settings.includeBackground {
                BackgroundView(
                    viewport: exportViewport,
                    variant: settings.backgroundVariant
                )
            }
            
            // Drawing layers | 描画レイヤー
            GraphLayerStack(
                store: store,
                nodeBuilder: nodeBuilder,
                edgeBuilder: edgeBuilder,
                onConnect: nil,
                onReconnect: nil,
                modifierKeys: nil,
                containerSize: Dimensions(width: contentSize.width, height: contentSize.height),
                viewportCullingEnabled: false,
                viewportCullingMargin: 0,
                nodeWrapper: { _, content in
                    // No gestures needed during export. Return as is. | エクスポート時はジェスチャ不要。そのまま返す。
                    content
                }
            )
        }
        .frame(width: contentSize.width, height: contentSize.height)
        .environment(\.isGraphExporting, true)
        .environment(\.graphRenderingViewport, exportViewport)
        .environment(\.graphZoomLevel, 1.0)
    }
}
