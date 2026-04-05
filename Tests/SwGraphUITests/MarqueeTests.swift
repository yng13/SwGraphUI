import XCTest
import SwiftUI
@testable import SwGraphUI

@MainActor
final class MarqueeTests: XCTestCase {
    
    func testMarqueeSelection() {
        let store = GraphStore<Void>()
        
        // 1. ノードの配置 (グラフ空間)
        // Node A: (10, 10), Size: (50, 50)
        // Node B: (100, 100), Size: (50, 50)
        var nodeA = BaseNode(id: "A", position: XYPosition(x: 10, y: 10), data: ())
        var nodeB = BaseNode(id: "B", position: XYPosition(x: 100, y: 100), data: ())
        nodeA.measured = Dimensions(width: 50, height: 50)
        nodeB.measured = Dimensions(width: 50, height: 50)
        
        store.nodes = [nodeA, nodeB]
        
        // 2. ビューポートの設定 (拡大率1.0, オフセットなし)
        store.setViewport(Viewport(x: 0, y: 0, zoom: 1.0))
        
        // 3. Marquee の開始と更新 (グラフ空間)
        store.startMarquee(at: CGPoint(x: 0, y: 0))
        store.updateMarquee(to: CGPoint(x: 70, y: 70))
        
        // 4. Marquee の終了
        store.endMarquee(isShiftPressed: false)
        
        // 5. 検証
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("A"), "Node A should be selected")
        XCTAssertFalse(store.runtimeState.selection.selectedNodeIDs.contains("B"), "Node B should not be selected")
        XCTAssertTrue(store.nodes[0].selected)
        XCTAssertFalse(store.nodes[1].selected)
        XCTAssertNil(store.runtimeState.marquee, "MarqueeState should be cleared")
    }
    
    func testMarqueeWithViewportOffset() {
        let store = GraphStore<Void>()
        
        // Node A: (50, 50), Size: (50, 50)
        var nodeA = BaseNode(id: "A", position: XYPosition(x: 50, y: 50), data: ())
        nodeA.measured = Dimensions(width: 50, height: 50)
        store.nodes = [nodeA]
        
        // ビューポート設定
        store.setViewport(Viewport(x: -50, y: -50, zoom: 2.0))
        
        // 1. 部分的に重なる選択 (intersects は true だが contains は false)
        store.startMarquee(at: CGPoint(x: 40, y: 40))
        store.updateMarquee(to: CGPoint(x: 60, y: 60))
        store.endMarquee(isShiftPressed: false)
        XCTAssertFalse(store.runtimeState.selection.selectedNodeIDs.contains("A"), "Node A should NOT be selected when only partially intersected")

        // 2. 完全に囲む選択 (グラフ空間の 40,40 から 160,160)
        store.startMarquee(at: CGPoint(x: 40, y: 40))
        store.updateMarquee(to: CGPoint(x: 160, y: 160))
        store.endMarquee(isShiftPressed: false)
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("A"), "Node A should be selected when fully contained")
    }
}
