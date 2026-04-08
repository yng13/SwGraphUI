import Testing
import Foundation
@testable import SwGraphUI

@Suite struct ResizeCalculationTests {
    @Test func bottomRightResize() async throws {
        let original = ResizeResult(x: 100, y: 100, width: 200, height: 100)
        let result = ResizeCalculation.calculate(
            original: original,
            handlePosition: .bottomRight,
            deltaX: 50,
            deltaY: 20,
            minWidth: 50,
            minHeight: 30
        )
        
        #expect(result.width == 250)
        #expect(result.height == 120)
        #expect(result.x == 100)
        #expect(result.y == 100)
    }
    
    @Test func topLeftResize() async throws {
        let original = ResizeResult(x: 100, y: 100, width: 200, height: 100)
        let result = ResizeCalculation.calculate(
            original: original,
            handlePosition: .topLeft,
            deltaX: -50,
            deltaY: -20,
            minWidth: 50,
            minHeight: 30
        )
        
        // width = 200 - (-50) = 250
        // newX = 100 + (200 - 250) = 50
        #expect(result.width == 250)
        #expect(result.height == 120)
        #expect(result.x == 50)
        #expect(result.y == 80)
    }
    
    @Test func minWidthConstraint() async throws {
        let original = ResizeResult(x: 100, y: 100, width: 100, height: 100)
        let result = ResizeCalculation.calculate(
            original: original,
            handlePosition: .right,
            deltaX: -80, // 本来なら幅 20 になる操作
            deltaY: 0,
            minWidth: 50,
            minHeight: 50
        )
        
        #expect(result.width == 50) // minWidth に制限される
    }

    @Test func leftEdgeResize() async throws {
        let original = ResizeResult(x: 200, y: 100, width: 100, height: 100)
        let result = ResizeCalculation.calculate(
            original: original,
            handlePosition: .left,
            deltaX: -50, // 左へ 50 拡大
            deltaY: 0,
            minWidth: 10,
            minHeight: 10
        )
        
        #expect(result.width == 150)
        #expect(result.x == 150)
    }
}
