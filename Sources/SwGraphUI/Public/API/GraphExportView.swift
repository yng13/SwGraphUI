import SwiftUI

/// エクスポート（画像書き出し）専用のグラフ表示ビュー。
/// 画質を最優先し、ジェスチャやデバッグ用のオーバーレイを含みません。
internal struct GraphExportView<NodeData: Sendable, NodeContent: View>: View {
    let store: GraphStore<NodeData>
    let settings: GraphExportSettings
    let nodeBuilder: (BaseNode<NodeData>) -> NodeContent
    let edgeBuilder: (BaseEdge<NodeData>, [PathSegment], Color, CGFloat, Bool, Bool) -> AnyView
    
    // エクスポート対象の矩形領域（グラフ絶対座標系）
    let bounds: Rect
    
    var body: some View {
        let contentSize = CGSize(width: bounds.width + settings.margin * 2,
                               height: bounds.height + settings.margin * 2)
        
        ZStack(alignment: .topLeading) {
            // 背景色（透明でない場合）
            if !settings.isTransparent {
                #if os(macOS)
                Color(nsColor: .windowBackgroundColor)
                #else
                Color(.secondarySystemBackground)
                #endif
            }
            
            // 背景グリッド（要求された場合）
            if settings.includeBackground {
                let exportViewport = Viewport(
                    x: -bounds.x + settings.margin,
                    y: -bounds.y + settings.margin,
                    zoom: 1.0
                )
                BackgroundView(
                    viewport: exportViewport,
                    variant: settings.backgroundVariant
                )
            }
            
            // 描画レイヤー
            GraphLayerStack(
                store: store,
                nodeBuilder: nodeBuilder,
                edgeBuilder: edgeBuilder,
                onReconnect: nil,
                modifierKeys: nil,
                nodeWrapper: { _, content in
                    // エクスポート時はジェスチャ不要。そのまま返す。
                    content
                }
            )
            // 算出した Bounds の左上に合わせるためのオフセット
            .offset(x: -bounds.x + settings.margin, y: -bounds.y + settings.margin)
        }
        .frame(width: contentSize.width, height: contentSize.height)
        .environment(\.isGraphExporting, true)
    }
}
