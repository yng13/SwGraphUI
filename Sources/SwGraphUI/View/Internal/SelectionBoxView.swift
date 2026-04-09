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
            
            // 境界枠のレンダリング
            // ヒットテストを無効化し、背面のノードやリサイザーの操作を妨げないようにする
            Rectangle()
                .fill(Color.primary.opacity(0.02)) // 非常に薄い塗り（領域の視認用）
                .overlay(
                    Rectangle()
                        .stroke(Color.primary.opacity(0.15), lineWidth: 1) // 中立的な細い実線
                )
                .frame(width: bounds.width, height: bounds.height)
                .position(x: bounds.x + bounds.width / 2, y: bounds.y + bounds.height / 2)
                .allowsHitTesting(false)
        }
    }
}
