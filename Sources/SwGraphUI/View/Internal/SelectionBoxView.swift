import SwiftUI

/// 複数ノードが選択されている場合に、その全体を囲む境界枠を表示する View。
/// 座標系はグラフ空間（絶対座標）を想定しています。
struct SelectionBoxView<Data: Sendable>: View {
    let store: GraphStore<Data>
    
    // エクスポート中などの判定用（もし将来的に必要であれば）
    @Environment(\.isGraphExporting) private var isGraphExporting
    
    var body: some View {
        let selectedNodes = store.selectedNodes
        
        // 2つ以上のノードが選択されている場合のみ表示
        // かつエクスポート中ではない場合に表示
        if selectedNodes.count >= 2 && !isGraphExporting {
            let lookup = store.nodeLookup
            let bounds = NodePositioningAlgorithms.getNodesBounds(selectedNodes, nodeLookup: lookup)
            
            let viewport = store.runtimeState.viewport.viewport
            let screenBounds = bounds.toScreen(viewport: viewport)
            
            // 境界枠のレンダリング
            // ズームにかかわらず視認性を保つため、lineWidth をクランプ (0.5 to 2.0 pt on screen)
            let zoom = viewport.zoom
            let lineWidth = min(max(1.0 / zoom, 0.5), 2.0)
            
            Rectangle()
                .fill(Color.primary.opacity(0.02))
                .overlay(
                    Rectangle()
                        .stroke(Color.primary.opacity(0.15), lineWidth: lineWidth)
                )
                .frame(width: screenBounds.width, height: screenBounds.height)
                .position(x: screenBounds.origin.x + screenBounds.width / 2, y: screenBounds.origin.y + screenBounds.height / 2)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
