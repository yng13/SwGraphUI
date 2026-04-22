import SwiftUI

/// Composite key to uniquely identify a handle | ハンドルを一意に特定するための複合キー
public struct HandleKey: Hashable, Sendable {
    public let nodeID: String
    public let handleID: String?
    public let type: HandleType
    public let placement: Position

    public init(nodeID: String, handleID: String? = nil, type: HandleType, placement: Position) {
        self.nodeID = nodeID
        self.handleID = handleID
        self.type = type
        self.placement = placement
    }
}

/// Entry for a measured handle | 計測されたハンドルのエントリ
public struct HandleMeasurementEntry: Equatable, Sendable {
    public let key: HandleKey
    /// Center point in the viewport_container coordinate system (screen coordinates on the canvas) | viewport_container 座標系（キャンバス上のスクリーン座標）における中心点
    public let viewportCenter: XYPosition

    public init(key: HandleKey, viewportCenter: XYPosition) {
        self.key = key
        self.viewportCenter = viewportCenter
    }
}

/// PreferenceKey for collecting handle measurements from the SwiftUI view hierarchy | SwiftUI ビュー階層からハンドルの計測値を収集するための PreferenceKey
public struct HandlePositionPreferenceKey: PreferenceKey {
    public typealias Value = [HandleMeasurementEntry]

    public static var defaultValue: [HandleMeasurementEntry] { [] }

    public static func reduce(value: inout [HandleMeasurementEntry], nextValue: () -> [HandleMeasurementEntry]) {
        let newEntries = nextValue()
        for newEntry in newEntries {
            // Overwrite with the latest value if the same key exists, otherwise add it | 同一キーが存在する場合は最新（最後）の値で上書きし、なければ追加する
            if let index = value.firstIndex(where: { $0.key == newEntry.key }) {
                value[index] = newEntry
            } else {
                value.append(newEntry)
            }
        }
    }
}
