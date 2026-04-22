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
            deltaX: -80, // Operation that would result in width 20 | 本来なら幅 20 になる操作
            deltaY: 0,
            minWidth: 50,
            minHeight: 50
        )
        
        #expect(result.width == 50) // Limited by minWidth | minWidth に制限される
    }

    @Test func leftEdgeResize() async throws {
        let original = ResizeResult(x: 200, y: 100, width: 100, height: 100)
        let result = ResizeCalculation.calculate(
            original: original,
            handlePosition: .left,
            deltaX: -50, // Expand 50 to the left | 左へ 50 拡大
            deltaY: 0,
            minWidth: 10,
            minHeight: 10
        )
        
        #expect(result.width == 150)
        #expect(result.x == 150)
    }

    @Test func aspectRatioBottomRight() async throws {
        let original = ResizeResult(x: 100, y: 100, width: 200, height: 100) // 2:1 ratio
        let result = ResizeCalculation.calculate(
            original: original,
            handlePosition: .bottomRight,
            deltaX: 50,  // w: 250 (+25%)
            deltaY: 10,  // h: 110 (+10%)
            minWidth: 10,
            minHeight: 10,
            preserveAspectRatio: true
        )
        
        // Width with larger change % (25%) becomes the primary axis | 変化量(%)が大きい Width (25%) が主軸となる
        // newWidth = 250, newHeight = 250 / 2 = 125
        #expect(result.width == 250)
        #expect(result.height == 125)
    }

    @Test func aspectRatioTopLeft() async throws {
        let original = ResizeResult(x: 100, y: 100, width: 200, height: 100) // 2:1 ratio
        let result = ResizeCalculation.calculate(
            original: original,
            handlePosition: .topLeft,
            deltaX: -50, // w: 250 (+25%)
            deltaY: -10, // h: 110 (+10%)
            minWidth: 10,
            minHeight: 10,
            preserveAspectRatio: true
        )
        
        // Width is the primary axis | Width が主軸
        // newWidth = 250, newHeight = 125
        // x = 100 + (200 - 250) = 50
        // y = 100 + (100 - 125) = 75
        #expect(result.width == 250)
        #expect(result.height == 125)
        #expect(result.x == 50)
        #expect(result.y == 75)
    }

    @Test func aspectRatioConstraint() async throws {
        let original = ResizeResult(x: 100, y: 100, width: 100, height: 100) // 1:1 ratio
        let result = ResizeCalculation.calculate(
            original: original,
            handlePosition: .bottomRight,
            deltaX: -80, // w: 20
            deltaY: -80, // h: 20
            minWidth: 50, // Set minWidth to 50 | width 最小を 50 に設定
            minHeight: 10,
            preserveAspectRatio: true
        )
        
        // Normally 20x20, but should be 50x50 due to minWidth=50 | 通常なら 20x20 になるが、minWidth = 50 により 50x50 になるはず
        #expect(result.width == 50)
        #expect(result.height == 50)
    }
}
