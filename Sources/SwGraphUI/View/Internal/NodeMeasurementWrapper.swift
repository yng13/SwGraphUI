import SwiftUI

/// コンテンツのサイズを測定し、PreferenceKey を通じて通知するラッパー
struct NodeMeasurementWrapper<Content: View>: View {
    let id: String
    let content: Content
    
    var body: some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: NodeSizePreferenceKey.self,
                            value: [NodeSizeEntry(id: id, size: geometry.size)]
                        )
                }
            )
    }
}
