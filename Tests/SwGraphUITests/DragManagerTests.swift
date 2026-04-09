import Testing
import SwiftUI
import Foundation
@testable import SwGraphUI

@MainActor
struct DragManagerTests {
    
    @Test
    func applyConstraintsClampsToParentExtent() throws {
        // 準備: 親ノード(400x300) と 子ノード(100x50, extent: .parent)
        let parent = BaseNode(id: "p", position: .zero, data: "", width: 400, height: 300)
        let child = BaseNode(id: "c", position: .zero, data: "", parentID: "p", extent: .parent, width: 100, height: 50)
        
        let nodeLookup = ["p": parent, "c": child]
        
        // ケース1: 枠内に収まる場合（絶対座標 50,50）
        let pos1 = DragManager.applyConstraints(
            to: XYPosition(x: 50, y: 50),
            node: child,
            nodeLookup: nodeLookup,
            applySnap: false
        )
        #expect(pos1 == XYPosition(x: 50, y: 50))
        
        // ケース2: 左・上にはみ出す場合 -> (0,0) にクランプされるはず
        let pos2 = DragManager.applyConstraints(
            to: XYPosition(x: -20, y: -10),
            node: child,
            nodeLookup: nodeLookup,
            applySnap: false
        )
        #expect(pos2 == XYPosition(x: 0, y: 0))
        
        // ケース3: 右・下にはみ出す場合 -> (400-100, 300-50) = (300, 250) にクランプされるはず
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
        // 準備: 座標制限のあるノード (-100, -100) 〜 (100, 100)
        let extent = NodeExtent.coordinate(CoordinateExtent(min: XYPosition(x: -100, y: -100), max: XYPosition(x: 100, y: 100)))
        let node = BaseNode(id: "n", position: .zero, data: "", extent: extent, width: 20, height: 20)
        let nodeLookup = ["n": node]
        
        // 範囲外 (150, 150) -> (100-20, 100-20) = (80, 80) にクランプ
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
        // 準備: extent: .parent だが親がいないノード
        let node = BaseNode(id: "n", position: .zero, data: "", extent: .parent, width: 100, height: 50)
        let nodeLookup = ["n": node]
        
        // 制限なしでそのまま返るはず
        let pos = DragManager.applyConstraints(
            to: XYPosition(x: 500, y: 500),
            node: node,
            nodeLookup: nodeLookup,
            applySnap: false
        )
        #expect(pos == XYPosition(x: 500, y: 500))
    }
}
