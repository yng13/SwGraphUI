import Testing
import Foundation
@testable import SwGraphUI

@Suite struct GeometryAlgorithmsTests {
    @Test func getViewportForBoundsWithAsymmetricPaddingStrict() async throws {
        let bounds = Rect(x: 0, y: 0, width: 100, height: 100)
        let size = Dimensions(width: 400, height: 400)
        
        // 非対称パディング (top: 10, left: 50, bottom: 100, right: 200)
        let padding = GeometryAlgorithms.Padding(
            top: .points(10),
            left: .points(50),
            bottom: .points(100),
            right: .points(200)
        )
        
        let viewport = GeometryAlgorithms.getViewportForBounds(
            bounds, in: size, minZoom: 1, maxZoom: 1, padding: padding
        )
        
        // 実際の適用パディングを計算して検証 (P2対応: 全方位の充足確認)
        let applied = GeometryAlgorithms.calculateAppliedPaddings(
            bounds: bounds,
            x: viewport.x,
            y: viewport.y,
            zoom: viewport.zoom,
            width: size.width,
            height: size.height
        )

        // 全てのパディングが指定値以上であることを確認
        #expect(applied.left >= 50)
        #expect(applied.top >= 10)
        #expect(applied.right >= 200)
        #expect(applied.bottom >= 100)
        
        // 非対称パディング補正により、少なくとも一つの辺がパディング値と一致（または極めて近い）はず
        let minGap = [applied.left - 50, applied.top - 10, applied.right - 200, applied.bottom - 100].min() ?? 0
        #expect(minGap < 1.0) 
    }
}

@Suite struct EdgePathAlgorithmsTests {
    @Test func smoothStepSameSideNearDistanceCoordinateCheck() async throws {
        // smoothStepPoints を直接検証 (P2対応: SVG文字列依存の排除)
        let result = EdgePathAlgorithms.smoothStepPoints(
            source: .init(x: 0, y: 0), sourcePosition: .right,
            target: .init(x: 10, y: 50), targetPosition: .right,
            center: (nil, nil), offset: 20, stepPosition: 0.5
        )
        
        let points = result.points
        #expect(points.count >= 4)
        #expect(points.first == XYPosition(x: 0, y: 0))
        #expect(points.last == XYPosition(x: 10, y: 50))
        
        // sourceDir=(1,0), offset=20, diff=10 -> gapOffsetVal=10, sourceGapOffset=(-10,0)
        // gappedSource = (20 - 10, 0) = (10, 0)
        #expect(points[1].x == 10.0)
        #expect(points[1].y == 0.0)
        
        // targetGapped = (10+20, 50) = (30, 50)
        // 重なりが回避されていることを検証
        let sourceGapped = points[1]
        let targetGapped = points[points.count - 2]
        #expect(sourceGapped.x == 10.0)
        #expect(targetGapped.x == 30.0)
        #expect(sourceGapped.x != targetGapped.x)
    }
    
    @Test func smoothStepMixedHandlesCoordinateCheck() async throws {
        // Right -> Bottom (Mixed)
        let result = EdgePathAlgorithms.smoothStepPoints(
            source: .init(x: 0, y: 0), sourcePosition: .right,
            target: .init(x: 50, y: 50), targetPosition: .bottom,
            center: (nil, nil), offset: 20, stepPosition: 0.5
        )
        
        let points = result.points
        // Source(Right) 進展方向の確認
        #expect(points[1].x > points[0].x)
        #expect(points[1].y == points[0].y)
        
        // Target(Bottom) 進入方向の確認
        #expect(points[points.count - 2].x == points.last!.x)
        #expect(points[points.count - 2].y > points.last!.y)
    }
}
