import SwiftUI

private struct GraphHandleStyleKey: EnvironmentKey {
    static let defaultValue: GraphHandleStyle = .default
}

extension EnvironmentValues {
    /// Handle rendering style used by built-in node and handle components.
    public var graphHandleStyle: GraphHandleStyle {
        get { self[GraphHandleStyleKey.self] }
        set { self[GraphHandleStyleKey.self] = newValue }
    }
}
