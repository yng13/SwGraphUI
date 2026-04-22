import SwiftUI

/// Measurement result for a single node | ノード一個分の測定結果
struct NodeSizeEntry: Equatable, Sendable {
    let id: String
    let size: CGSize
}

/// PreferenceKey for collecting the sizes of all nodes within the graph | グラフ内の全ノードのサイズを収集するための PreferenceKey
struct NodeSizePreferenceKey: PreferenceKey {
    static var defaultValue: [NodeSizeEntry] { [] }
    
    static func reduce(value: inout [NodeSizeEntry], nextValue: () -> [NodeSizeEntry]) {
        value.append(contentsOf: nextValue())
    }
}
