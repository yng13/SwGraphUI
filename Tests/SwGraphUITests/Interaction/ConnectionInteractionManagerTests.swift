import XCTest
@testable import SwGraphUI

final class ConnectionInteractionManagerTests: XCTestCase {
    
    func testFindTargetHandleSnap() {
        // 等倍ズーム
        let viewport = Viewport(x: 0, y: 0, zoom: 1.0)
        let nodeA = GraphNode(id: "A", position: XYPosition(x: 0, y: 0), data: "A", measured: Dimensions(width: 100, height: 100))
        let nodeB = GraphNode(id: "B", position: XYPosition(x: 200, y: 0), data: "B", measured: Dimensions(width: 100, height: 100))
        
        let nodes = [nodeA, nodeB]
        
        // B の左ハンドルのグラフ座標は (200, 50)
        // グラフ空間で 20px 離れた位置 (180, 50) -> スクリーン空間でも 20px 離れている
        let pointerNearB = XYPosition(x: 180, y: 50) 
        
        let nodeLookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        
        let match = ConnectionInteractionManager.findTargetHandle(
            near: pointerNearB,
            in: nodes,
            nodeLookup: nodeLookup,
            viewport: viewport,
            fromNodeID: "A"
        )
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.node.id, "B")
        XCTAssertEqual(match?.handle.placement, .left)
    }
    
    func testFindTargetHandleSnapUnderZoom() {
        // 2倍ズーム。グラフ空間の距離はスクリーン空間で 2 倍になる。
        let viewport = Viewport(x: 0, y: 0, zoom: 2.0)
        let nodeA = GraphNode(id: "A", position: XYPosition(x: 0, y: 0), data: "A", measured: Dimensions(width: 100, height: 100))
        let nodeB = GraphNode(id: "B", position: XYPosition(x: 200, y: 0), data: "B", measured: Dimensions(width: 100, height: 100))
        
        let nodes = [nodeA, nodeB]
        let nodeLookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        
        // B の左ハンドル (200, 50)
        // グラフ空間で 20px 離れた位置 (180, 50) 
        // -> スクリーン空間では 20px * 2.0 = 40px 離れている。
        // -> snapDistance(24px) を超えるため、スナップしないはず。
        let pointerInGraph = XYPosition(x: 180, y: 50) 
        
        let match = ConnectionInteractionManager.findTargetHandle(
            near: pointerInGraph,
            in: nodes,
            nodeLookup: nodeLookup,
            viewport: viewport,
            fromNodeID: "A"
        )
        
        XCTAssertNil(match, "Should NOT snap because it's 40px away in screen space")
        
        // グラフ空間で 10px 離れた位置 (190, 50)
        // -> スクリーン空間では 10px * 2.0 = 20px 離れている。
        // -> snapDistance(24px) 以内なので、スナップするはず。
        let pointerCloser = XYPosition(x: 190, y: 50)
        let matchClose = ConnectionInteractionManager.findTargetHandle(
            near: pointerCloser,
            in: nodes,
            nodeLookup: nodeLookup,
            viewport: viewport,
            fromNodeID: "A"
        )
        
        XCTAssertNotNil(matchClose, "Should snap because it's 20px away in screen space")
    }
    
    func testSelfConnectionValidation() {
        let viewport = Viewport(x: 0, y: 0, zoom: 1.0)
        let nodeA = GraphNode(id: "A", position: XYPosition(x: 0, y: 0), data: "A", measured: Dimensions(width: 100, height: 100))
        let nodeLookup = ["A": nodeA]
        
        // A のハンドル近くだが、fromNodeID が A なのでスナップ対象外
        let pointerNearA = XYPosition(x: 110, y: 50) 
        let match = ConnectionInteractionManager.findTargetHandle(
            near: pointerNearA,
            in: [nodeA],
            nodeLookup: nodeLookup,
            viewport: viewport,
            fromNodeID: "A"
        )
        
        XCTAssertNil(match, "Should NOT snap to self")
    }
}
