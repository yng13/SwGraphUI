import SwiftUI

private struct GraphZoomLevelKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    /// Current zoom level of the graph (1.0 = standard). | グラフの現在のズーム倍率（1.0 = 標準）。
    /// Used by components to adjust rendering quality upon magnification. | コンポーネントが拡大時にレンダリング品質を調整するために使用します。
    public var graphZoomLevel: Double {
        get { self[GraphZoomLevelKey.self] }
        set { self[GraphZoomLevelKey.self] = newValue }
    }
}
