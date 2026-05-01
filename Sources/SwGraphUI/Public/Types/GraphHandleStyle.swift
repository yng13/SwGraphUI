import Foundation

/// Visual style and layout parameters for node handles.
public struct GraphHandleStyle: Sendable, Equatable {
    /// Visible radius-independent size of the handle before zoom is applied.
    public var visualSize: Double
    /// Extra hit target padding around the visible handle.
    public var hitAreaPadding: Double
    /// Distance between node border and handle center used by default node rendering and fallback edge anchors.
    public var anchorOffset: Double

    public static let `default` = GraphHandleStyle()

    public init(
        visualSize: Double = 6,
        hitAreaPadding: Double = 8,
        anchorOffset: Double = 8
    ) {
        self.visualSize = visualSize
        self.hitAreaPadding = hitAreaPadding
        self.anchorOffset = anchorOffset
    }
}
