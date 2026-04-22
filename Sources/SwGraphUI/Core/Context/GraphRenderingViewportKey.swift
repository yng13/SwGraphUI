import SwiftUI

private struct GraphRenderingViewportKey: EnvironmentKey {
    static let defaultValue: Viewport? = nil
}

extension EnvironmentValues {
    /// The viewport that should be used for rendering. | 描画に使用されるべきビューポート。
    /// If nil, the viewport from the live store is used. | nil の場合は live store のビューポートが使用されます。
    public var graphRenderingViewport: Viewport? {
        get { self[GraphRenderingViewportKey.self] }
        set { self[GraphRenderingViewportKey.self] = newValue }
    }
}
