import Testing
import Foundation
@testable import SwGraphUI

@Suite struct InteractionCorrectionTests {
    
    /// 親 Origin=center, 子 Origin=topLeft のテスト
    @Test func mixedOriginParentCenterChildTopLeft() async throws {
        let parent = Node(
            id: "parent",
            position: XYPosition(x: 100, y: 100),
            data: EmptyPayload(),
            origin: .center,
            width: 100,
            height: 100
        )
        
        let child = Node(
            id: "child",
            position: XYPosition(x: 0, y: 0),
            data: EmptyPayload(),
            parentID: "parent",
            origin: .topLeft,
            width: 50,
            height: 50
        )
        
        let lookup = ["parent": parent, "child": child]
        
        // 親の左上端は (50, 50) になるはず (100 - 100*0.5)
        let parentTopLeft = NodePositioningAlgorithms.evaluateAbsolutePosition(parent, nodeLookup: lookup)
        #expect(parentTopLeft.x == 50)
        #expect(parentTopLeft.y == 50)
        
        // 子の絶対座標 (左上端) は evaluateAbsolutePosition で解決
        let childAbs = NodePositioningAlgorithms.evaluateAbsolutePosition(child, nodeLookup: lookup)
        #expect(childAbs.x == 50) // parentTopLeft(50) + childRelPos(0)
        #expect(childAbs.y == 50)
    }
    
    /// 親 -> 子 -> 孫 の 3 段階階層での座標変換テスト
    @Test func nestedAbsoluteRelativeConversion() async throws {
        let root = Node(id: "root", position: .init(x: 100, y: 100), data: .init(), width: 100, height: 100)
        let child = Node(id: "child", position: .init(x: 50, y: 50), data: .init(), parentID: "root", width: 50, height: 50)
        let grandchild = Node(id: "grandchild", position: .init(x: 10, y: 10), data: .init(), parentID: "child", width: 20, height: 20)
        
        let lookup = ["root": root, "child": child, "grandchild": grandchild]
        
        // rootTL = (100,100)
        // childTL = (150,150)
        // grandchildTL = (160,160)
        
        // 1. 絶対座標への変換確認
        let gcAbs = NodePositioningAlgorithms.toAbsolutePosition(.init(x: 10, y: 10), parent: grandchild.parentID.flatMap { lookup[$0] }, nodeLookup: lookup)
        #expect(gcAbs.x == 160)
        #expect(gcAbs.y == 160)
        
        // 2. 絶対座標から相対座標への逆変換確認
        // (160, 160) を孫の親（child）基準の相対座標に戻すと (10, 10) になるはず
        let gcRel = NodePositioningAlgorithms.toRelativePosition(.init(x: 160, y: 160), parent: grandchild.parentID.flatMap { lookup[$0] }, nodeLookup: lookup)
        #expect(gcRel.x == 10)
        #expect(gcRel.y == 10)
    }
    
    /// 階層構造におけるドラッグオフセットと移動後の相対座標の検証
    @Test func hierarchicalDragOffset() async throws {
        let parent = Node(id: "p", position: .init(x: 100, y: 100), data: .init(), width: 100, height: 100)
        let child = Node(id: "c", position: .init(x: 50, y: 50), data: .init(), parentID: "p", width: 50, height: 50)
        let lookup = ["p": parent, "c": child]
        
        var state = DragState()
        // 子(abs=150,150) の中心付近 (175, 175) をクリックしてドラッグ開始
        state.startDrag(nodes: [child], nodeLookup: lookup, pointer: .init(x: 175, y: 175))
        
        #expect(state.draggedNodes[0].distance.x == 25) // 175 - 150
        
        // (200, 200) までドラッグ
        let results = DragManager.calculateNextPositions(
            draggedNodes: state.draggedNodes,
            pointer: .init(x: 200, y: 200),
            nodeLookup: lookup
        )
        
        // 新しい絶対座標は 200 - 25 = 175
        // 親(100,100) から見た相対座標は 175 - 100 = 75
        #expect(results["c"]?.x == 75)
    }
    
    /// 循環参照ガードのテスト (座標変換リファクタ後も機能することを確認)
    @Test func cycleGuardStillWorksAfterRelativeConversionRefactor() async throws {
        let n1 = Node(id: "n1", position: .init(x: 10, y: 10), data: .init(), parentID: "n2")
        let n2 = Node(id: "n2", position: .init(x: 20, y: 20), data: .init(), parentID: "n1")
        
        let lookup = ["n1": n1, "n2": n2]
        
        // 循環を検知して停止すること
        let absPos = NodePositioningAlgorithms.evaluateAbsolutePosition(n1, nodeLookup: lookup)
        #expect(absPos.x == 30) // n1(10) + n2(20)
        
        // 循環環境下での相対変換
        let relPos = NodePositioningAlgorithms.toRelativePosition(.init(x: 100, y: 100), parent: n1, nodeLookup: lookup)
        #expect(relPos.x == 70) // 100 - abs(n1)=30
    }
    
    /// 非推奨の Convenience Overload が単一階層（Flat Graph）で動作することを確認
    @Test func deprecatedConvenienceStillWorksForFlatGraph() async throws {
        let n1 = Node(id: "n1", position: .init(x: 100, y: 100), data: .init(), width: 50, height: 50)
        var state = DragState()
        
        // 非推奨版 startDrag の呼び出し
        state.startDrag(nodes: [n1], pointer: .init(x: 125, y: 125))
        
        #expect(state.draggedNodes.count == 1)
        #expect(state.draggedNodes[0].distance.x == 25)
        #expect(state.draggedNodes[0].lastPosition.x == 100)
    }
    
    /// 階層ノードを含む fitView のテスト
    @Test func fitViewWithHierarchicalNodes() async throws {
        let parent = Node(id: "p", position: .init(x: 1000, y: 1000), data: .init(), width: 100, height: 100)
        let child = Node(id: "c", position: .init(x: 50, y: 50), data: .init(), parentID: "p", width: 50, height: 50)
        
        let lookup = ["p": parent, "c": child]
        let viewSize = Dimensions(width: 800, height: 600)
        
        let viewport = ViewportManager.calculateFitView(
            nodes: [parent, child],
            nodeLookup: lookup,
            in: viewSize,
            minZoom: 0.1,
            maxZoom: 10.0,
            padding: .all(.points(0))
        )
        
        // Bounds は (1000,1000) から (1100,1100) = size 100x100
        #expect(viewport.zoom == 6.0)
    }

    /// 寸法フォールバックのテスト
    @Test func boundsWithInitialDimensions() async throws {
        let node = Node(id: "n1", position: .init(x: 0, y: 0), data: .init(), initialWidth: 200, initialHeight: 100)
        let bounds = NodePositioningAlgorithms.getNodesBounds([node])
        #expect(bounds.size.width == 200)
        #expect(bounds.size.height == 100)
    }
}
