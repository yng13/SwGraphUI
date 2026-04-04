import SwiftUI

/// ハンドルを一意に特定するための複合キー
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

/// 計測されたハンドルのエントリ
public struct HandleMeasurementEntry: Equatable, Sendable {
    public let key: HandleKey
    /// viewport_container 座標系（キャンバス上のスクリーン座標）における中心点
    public let viewportCenter: XYPosition

    public init(key: HandleKey, viewportCenter: XYPosition) {
        self.key = key
        self.viewportCenter = viewportCenter
    }
}

/// SwiftUI ビュー階層からハンドルの計測値を収集するための PreferenceKey
public struct HandlePositionPreferenceKey: PreferenceKey {
    public typealias Value = [HandleMeasurementEntry]

    public static var defaultValue: [HandleMeasurementEntry] { [] }

    public static func reduce(value: inout [HandleMeasurementEntry], nextValue: () -> [HandleMeasurementEntry]) {
        let newEntries = nextValue()
        for newEntry in newEntries {
            // 同一キーが存在する場合は最新（最後）の値で上書きし、なければ追加する
            if let index = value.firstIndex(where: { $0.key == newEntry.key }) {
                value[index] = newEntry
            } else {
                value.append(newEntry)
            }
        }
    }
}
