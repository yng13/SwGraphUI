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
        
        // 変換後の座標（Screen Space）での境界位置を確認
        let screenLeft = (bounds.x * viewport.zoom) + viewport.x
        let screenTop = (bounds.y * viewport.zoom) + viewport.y
        let screenRight = size.width - (bounds.x + bounds.width) * viewport.zoom - viewport.x
        let screenBottom = size.height - (bounds.y + bounds.height) * viewport.zoom - viewport.y

        // パディングを「厳密に」満たしているか検証
        // xyflowのロジックでは、余白が最小の辺がそのパディング値と一致するようにオフセットが補正される
        // このテストケースでは余白に余裕があるため、全方位で指定以上のパディングが確保されていることを確認
        #expect(screenLeft >= 50)
        #expect(screenTop >= 10)
        #expect(screenRight >= 200)
        #expect(screenBottom >= 100)
        
        // 少なくとも一つの辺がパディングと「ほぼ一致」することを期待（収まりの最適化）
        let minGap = [screenLeft - 50, screenTop - 10, screenRight - 200, screenBottom - 100].min() ?? 0
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
        
        // 最初のセグメントがハンドルの向き（右）を向いているか
        // sourceX(0) + offset(20) + sourceGapOffset(-10) = 10.0
        #expect(points[1].x == 10.0)
        #expect(points[1].y == 0.0)
        
        // 同一方向近距離での gapOffset 補正により、sourceGapped と targetGapped の x 座標が重ならないことを確認
        let sourceGapped = points[1]
        let targetGapped = points[points.count - 2]
        #expect(sourceGapped.x == 10.0)
        #expect(targetGapped.x == 30.0)
        #expect(sourceGapped.x != targetGapped.x, "Source gapped and target gapped x coordinates should not overlap due to gapOffset")
    }
    
    @Test func smoothStepMixedHandlesCoordinateCheck() async throws {
        // Right -> Bottom (Mixed)
        let result = EdgePathAlgorithms.smoothStepPoints(
            source: .init(x: 0, y: 0), sourcePosition: .right,
            target: .init(x: 50, y: 50), targetPosition: .bottom,
            center: (nil, nil), offset: 20, stepPosition: 0.5
        )
        
        let points = result.points
        // 始点(M 0,0 L 20,0)
        #expect(points[0] == XYPosition(x: 0, y: 0))
        #expect(points[1] == XYPosition(x: 20, y: 0))
        
        // 終点(L 50,70 L 50,50) Target=50,50, Pos=bottom(0,1), offset=20 -> gapped=50,70
        #expect(points.last == XYPosition(x: 50, y: 50))
        #expect(points[points.count - 2] == XYPosition(x: 50, y: 70))
    }
}
