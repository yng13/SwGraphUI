import Testing
import Foundation
@testable import SwGraphUI

struct AutoPanAlgorithmsTests {
    
    let size = Dimensions(width: 1000, height: 800)
    let threshold = 40.0
    let speed = 15.0
    
    @Test func testCalculatesZeroInCenter() {
        let pos = XYPosition(x: 500, y: 400)
        let vel = AutoPanAlgorithms.calculateVelocity(mousePosition: pos, containerSize: size, speed: speed, threshold: threshold)
        
        #expect(vel.x == 0)
        #expect(vel.y == 0)
    }
    
    @Test func testCalculatesPositiveXAtLeftEdge() {
        // x = 0 (Left edge) -> velocity coefficient should be 1.0 | x = 0 (左端) -> velocity coefficient should be 1.0
        let pos = XYPosition(x: 0, y: 400)
        let vel = AutoPanAlgorithms.calculateVelocity(mousePosition: pos, containerSize: size, speed: speed, threshold: threshold)
        
        #expect(vel.x == 15.0)
        #expect(vel.y == 0)
    }
    
    @Test func testCalculatesNegativeXAtRightEdge() {
        // x = 1000 (Right edge) -> velocity coefficient should be -1.0 | x = 1000 (右端) -> velocity coefficient should be -1.0
        let pos = XYPosition(x: 1000, y: 400)
        let vel = AutoPanAlgorithms.calculateVelocity(mousePosition: pos, containerSize: size, speed: speed, threshold: threshold)
        
        #expect(vel.x == -15.0)
        #expect(vel.y == 0)
    }
    
    @Test func testCalculatesPositiveYAtTopEdge() {
        // y = 0 (Top edge) -> velocity coefficient should be 1.0 | y = 0 (上端) -> velocity coefficient should be 1.0
        let pos = XYPosition(x: 500, y: 0)
        let vel = AutoPanAlgorithms.calculateVelocity(mousePosition: pos, containerSize: size, speed: speed, threshold: threshold)
        
        #expect(vel.x == 0)
        #expect(vel.y == 15.0)
    }
    
    @Test func testCalculatesNegativeYAtBottomEdge() {
        // y = 800 (Bottom edge) -> velocity coefficient should be -1.0 | y = 800 (下端) -> velocity coefficient should be -1.0
        let pos = XYPosition(x: 500, y: 800)
        let vel = AutoPanAlgorithms.calculateVelocity(mousePosition: pos, containerSize: size, speed: speed, threshold: threshold)
        
        #expect(vel.x == 0)
        #expect(vel.y == -15.0)
    }
    
    @Test func testLinearAcceleration() {
        // x = 20 (half of threshold 40) -> coefficient should be (40 - 20) / 40 = 0.5 | x = 20 (閾値 40 の半分) -> coefficient should be (40 - 20) / 40 = 0.5
        let pos = XYPosition(x: 20, y: 400)
        let vel = AutoPanAlgorithms.calculateVelocity(mousePosition: pos, containerSize: size, speed: speed, threshold: threshold)
        
        #expect(vel.x == 7.5) // 15.0 * 0.5
    }
    
    @Test func testStaysZeroAtThresholdBoundary() {
        let posLeft = XYPosition(x: 40, y: 400)
        let velLeft = AutoPanAlgorithms.calculateVelocity(mousePosition: posLeft, containerSize: size, speed: speed, threshold: threshold)
        #expect(velLeft.x == 0)
        
        let posRight = XYPosition(x: 960, y: 400)
        let velRight = AutoPanAlgorithms.calculateVelocity(mousePosition: posRight, containerSize: size, speed: speed, threshold: threshold)
        #expect(velRight.x == 0)
    }
}
