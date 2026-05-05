import Testing
import CoreGraphics
@testable import SwGraphUI

struct EdgeRendererTests {
    @Test
    func configuredDashPatternScalesWithViewportZoom() {
        #expect(EdgeDashPatternResolver.scaledDashPattern([10, 5], zoom: 0.5) == [5, 2.5])
        #expect(EdgeDashPatternResolver.scaledDashPattern([10, 5], zoom: 2.0) == [20, 10])
    }

    @Test
    func configuredDashPatternIgnoresInvalidZoom() {
        #expect(EdgeDashPatternResolver.scaledDashPattern([10, 5], zoom: 0) == [10, 5])
        #expect(EdgeDashPatternResolver.scaledDashPattern([10, 5], zoom: .nan) == [10, 5])
    }
}
