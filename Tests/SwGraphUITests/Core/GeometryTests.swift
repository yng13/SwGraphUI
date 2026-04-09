import Testing
import Foundation
@testable import SwGraphUI

@Suite("Geometry Transformation Tests")
struct GeometryTests {
    let viewport = Viewport(x: 100, y: 50, zoom: 2.0)
    
    @Test("XYPosition toScreen transformation")
    func testXYPositionToScreen() {
        let pos = XYPosition(x: 10, y: 20)
        let screenPos = pos.toScreen(viewport: viewport)
        
        // (10 * 2.0) + 100 = 120
        // (20 * 2.0) + 50 = 90
        #expect(screenPos.x == 120)
        #expect(screenPos.y == 90)
    }
    
    @Test("Rect toScreen transformation")
    func testRectToScreen() {
        let rect = Rect(x: 10, y: 20, width: 30, height: 40)
        let screenRect = rect.toScreen(viewport: viewport)
        
        // origin: (120, 90)
        // size: (30 * 2.0, 40 * 2.0) = (60, 80)
        #expect(screenRect.x == 120)
        #expect(screenRect.y == 90)
        #expect(screenRect.width == 60)
        #expect(screenRect.height == 80)
    }
    
    @Test("PathSegment toScreen transformation")
    func testPathSegmentToScreen() {
        let segment = PathSegment.bezier(
            to: XYPosition(x: 100, y: 100),
            control1: XYPosition(x: 20, y: 20),
            control2: XYPosition(x: 80, y: 80)
        )
        
        let screenSegment = segment.toScreen(viewport: viewport)
        
        if case .bezier(let to, let c1, let c2) = screenSegment {
            // to: (100 * 2 + 100, 100 * 2 + 50) = (300, 250)
            // c1: (20 * 2 + 100, 20 * 2 + 50) = (140, 90)
            // c2: (80 * 2 + 100, 80 * 2 + 50) = (260, 210)
            #expect(to.x == 300)
            #expect(to.y == 250)
            #expect(c1.x == 140)
            #expect(c1.y == 90)
            #expect(c2.x == 260)
            #expect(c2.y == 210)
        } else {
            Issue.record("Segment type mismatch")
        }
    }
}
