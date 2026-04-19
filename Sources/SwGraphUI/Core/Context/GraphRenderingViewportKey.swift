import SwiftUI

private struct GraphRenderingViewportKey: EnvironmentKey {
    static let defaultValue: Viewport? = nil
}

extension EnvironmentValues {
    /// 描画に使用されるべきビューポート。
    /// nil の場合は live store のビューポートが使用されます。
    public var graphRenderingViewport: Viewport? {
        get { self[GraphRenderingViewportKey.self] }
        set { self[GraphRenderingViewportKey.self] = newValue }
    }
}
