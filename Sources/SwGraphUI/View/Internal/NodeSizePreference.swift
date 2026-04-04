import SwiftUI

/// ノード一個分の測定結果
struct NodeSizeEntry: Equatable, Sendable {
    let id: String
    let size: CGSize
}

/// グラフ内の全ノードのサイズを収集するための PreferenceKey
struct NodeSizePreferenceKey: PreferenceKey {
    static var defaultValue: [NodeSizeEntry] { [] }
    
    static func reduce(value: inout [NodeSizeEntry], nextValue: () -> [NodeSizeEntry]) {
        value.append(contentsOf: nextValue())
    }
}
