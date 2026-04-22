import Testing
import SwiftUI
import Foundation
@testable import SwGraphUI

@MainActor
struct DragManagerTests {
    
    @Test
    func applyConstraintsClampsToParentExtent() throws {
        // Setup: Parent node (400x300) and Child node (100x50, extent: .parent) | 準備: 親ノード(400x300) と 子ノード(100x50, extent: .parent)
        let parent = BaseNode(id: "p", position: .zero, data: "", width: 400, height: 300)
        let child = BaseNode(id: "c", position: .zero, data: "", parentID: "p", extent: .parent, width: 100, height: 50)
        
        let nodeLookup = ["p": parent, "c": child]
        
        // Case 1: Within bounds (absolute coordinate 50,50) | ケース1: 枠内に収まる場合（絶対座標 50,50）
        let pos1 = DragManager.applyConstraints(
            to: XYPosition(x: 50, y: 50),
            node: child,
            nodeLookup: nodeLookup,
            applySnap: false
        )
        #expect(pos1 == XYPosition(x: 50, y: 50))
        
        // Case 2: Out of bounds (left/top) -> should be clamped to (0,0) | ケース2: 左・上にはみ出す場合 -> (0,0) にクランプされるはず
        let pos2 = DragManager.applyConstraints(
            to: XYPosition(x: -20, y: -10),
            node: child,
            nodeLookup: nodeLookup,
            applySnap: false
        )
        #expect(pos2 == XYPosition(x: 0, y: 0))
        
        // Case 3: Out of bounds (right/bottom) -> should be clamped to (300, 250) | ケース3: 右・下にはみ出す場合 -> (400-100, 300-50) = (300, 250) にクランプされるはず
        let pos3 = DragManager.applyConstraints(
            to: XYPosition(x: 500, y: 400),
            node: child,
            nodeLookup: nodeLookup,
            applySnap: false
        )
        #expect(pos3 == XYPosition(x: 300, y: 250))
    }
    
    @Test
    func applyConstraintsRespectsCoordinateExtent() throws {
        // Setup: Node with coordinate extent (-100, -100) to (100, 100) | 準備: 座標制限のあるノード (-100, -100) 〜 (100, 100)
        let extent = NodeExtent.coordinate(CoordinateExtent(min: XYPosition(x: -100, y: -100), max: XYPosition(x: 100, y: 100)))
        let node = BaseNode(id: "n", position: .zero, data: "", extent: extent, width: 20, height: 20)
        let nodeLookup = ["n": node]
        
        // Out of range (150, 150) -> clamped to (80, 80) | 範囲外 (150, 150) -> (100-20, 100-20) = (80, 80) にクランプ
        let pos = DragManager.applyConstraints(
            to: XYPosition(x: 150, y: 150),
            node: node,
            nodeLookup: nodeLookup,
            applySnap: false
        )
        #expect(pos == XYPosition(x: 80, y: 80))
    }
    
    @Test
    func applyConstraintsFallbacksWhenNoParent() throws {
        // Setup: Node with extent: .parent but no parent | 準備: extent: .parent だが親がいないノード
        let node = BaseNode(id: "n", position: .zero, data: "", extent: .parent, width: 100, height: 50)
        let nodeLookup = ["n": node]
        
        // Should return as-is without restrictions | 制限なしでそのまま返るはず
        let pos = DragManager.applyConstraints(
            to: XYPosition(x: 500, y: 500),
            node: node,
            nodeLookup: nodeLookup,
            applySnap: false
        )
        #expect(pos == XYPosition(x: 500, y: 500))
    }
}
