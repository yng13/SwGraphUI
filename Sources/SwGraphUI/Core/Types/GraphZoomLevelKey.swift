import SwiftUI

private struct GraphZoomLevelKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    /// グラフの現在のズーム倍率（1.0 = 標準）。
    /// コンポーネントが拡大時にレンダリング品質を調整するために使用します。
    public var graphZoomLevel: Double {
        get { self[GraphZoomLevelKey.self] }
        set { self[GraphZoomLevelKey.self] = newValue }
    }
}
