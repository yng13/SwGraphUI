import SwiftUI

private struct IsGraphExportingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// グラフが現在エクスポート中（静止画レンダリング中）であるかどうかを示す。
    /// エクスポート時には、ハンドルやツールバー等のインタラクティブな要素を非表示にするために使用します。
    public var isGraphExporting: Bool {
        get { self[IsGraphExportingKey.self] }
        set { self[IsGraphExportingKey.self] = newValue }
    }
}
