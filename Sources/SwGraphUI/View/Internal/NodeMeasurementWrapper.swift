import SwiftUI

/// コンテンツのサイズを測定し、PreferenceKey を通じて通知するラッパー
struct NodeMeasurementWrapper<Content: View>: View {
    let id: String
    let content: Content
    @Environment(\.graphZoomLevel) private var zoomLevel
    
    var body: some View {
        content
            .background(
                GeometryReader { geometry in
                    let graphSpaceSize = CGSize(
                        width: geometry.size.width / max(zoomLevel, 0.0001),
                        height: geometry.size.height / max(zoomLevel, 0.0001)
                    )
                    Color.clear
                        .preference(
                            key: NodeSizePreferenceKey.self,
                            value: [NodeSizeEntry(id: id, size: graphSpaceSize)]
                        )
                }
            )
    }
}
