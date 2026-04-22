import XCTest
@testable import SwGraphUI

@MainActor
final class GraphStoreTests: XCTestCase {
    
    @MainActor
    func testStoreInitialState() {
        let node = BaseNode(id: "1", position: XYPosition(x: 100, y: 100), data: "test")
        let store = GraphStore(nodes: [node])
        
        XCTAssertEqual(store.nodes.count, 1)
        XCTAssertEqual(store.node(id: "1")?.id, "1")
    }
    
    @MainActor
    func testHierarchicalDragSync() {
        let parent = BaseNode(id: "p", position: XYPosition(x: 10, y: 10), data: "p")
        let child = BaseNode(id: "c", position: XYPosition(x: 5, y: 5), data: "c", parentID: "p")
        let store = GraphStore(nodes: [parent, child])
        
        // Start dragging child node (assume pointer is at absolute (15, 15)) | 子ノードのドラッグ開始（ポインタは絶対座標 15,15 の位置とする）
        store.startDragging(nodeIDs: ["c"], at: XYPosition(x: 15, y: 15))
        
        // Verify dragging flag | dragging フラグの確認
        XCTAssertTrue(store.nodes.first(where: { $0.id == "c" })?.dragging ?? false)
        XCTAssertFalse(store.nodes.first(where: { $0.id == "p" })?.dragging ?? true)
        
        // Move pointer to (20, 20) | ポインタを 20,20 へ移動
        store.updateDragging(to: XYPosition(x: 20, y: 20))
        
        // Verify new relative position of the child node | 子ノードの新しい相対位置を検証
        // Delta is (+5, +5) since it moved from absolute (15, 15) to (20, 20). | 変化分は +5,+5。元の絶対 15,15 から 20,20 なので。
        // Child's original relative was (5, 5). New relative should be (10, 10). | 子の元の相対は 5,5。新しい相対は 10,10 になるはず。
        let updatedChild = store.nodes.first { $0.id == "c" }!
        XCTAssertEqual(updatedChild.position.x, 10)
        XCTAssertEqual(updatedChild.position.y, 10)
        
        store.stopDragging()
        XCTAssertFalse(store.nodes.first(where: { $0.id == "c" })?.dragging ?? true)
    }
    
    @MainActor
    func testAbsolutePositionHierarchy() {
        let parent = BaseNode(id: "p", position: XYPosition(x: 100, y: 100), data: "p")
        let child = BaseNode(id: "c", position: XYPosition(x: 50, y: 50), data: "c", parentID: "p")
        let grandchild = BaseNode(id: "g", position: XYPosition(x: 20, y: 20), data: "g", parentID: "c")
        let store = GraphStore(nodes: [parent, child, grandchild])
        
        // Grandchild node's absolute coordinate: 100 + 50 + 20 = 170 | 孫ノードの絶対座標: 100 + 50 + 20 = 170
        let absPos = store.absolutePosition(for: "g")
        XCTAssertEqual(absPos.x, 170)
        XCTAssertEqual(absPos.y, 170)
    }
    
    @MainActor
    func testStateIntegrityDuringDrag() {
        var node = BaseNode(id: "n1", position: .zero, data: "test")
        node.selected = true // Preset as selected | 事前に選択状態にしておく
        let store = GraphStore(nodes: [node])
        
        store.startDragging(nodeIDs: ["n1"], at: .zero)
        
        let draggedNode = store.nodes[0]
        XCTAssertTrue(draggedNode.dragging)
        XCTAssertTrue(draggedNode.selected, "selected state should not be broken when updating dragging | dragging 更新時に selected 状態が壊れてはいけない")
        
        store.stopDragging()
        XCTAssertFalse(store.nodes[0].dragging)
        XCTAssertTrue(store.nodes[0].selected)
    }
    
    func testCoordinateAdapterRoundTrip() {
        let viewport = Viewport(x: 100, y: 100, zoom: 2.0)
        let screenPoint = XYPosition(x: 200, y: 200)
        
        // screenToGraph: (200 - 100) / 2.0 = 50 | screenToGraph: (200 - 100) / 2.0 = 50
        let graphPoint = CoordinateAdapter.screenToGraph(screenPoint, viewport: viewport)
        XCTAssertEqual(graphPoint.x, 50)
        XCTAssertEqual(graphPoint.y, 50)
        
        // graphToScreen: 50 * 2.0 + 100 = 200 | graphToScreen: 50 * 2.0 + 100 = 200
        let roundTrip = CoordinateAdapter.graphToScreen(graphPoint, viewport: viewport)
        XCTAssertEqual(roundTrip.x, 200)
        XCTAssertEqual(roundTrip.y, 200)
    }

    // MARK: - Measurement Engine Tests
    
    @MainActor
    func testUpdateNodeDimensions() {
        let node = BaseNode(id: "1", position: .zero, data: "test")
        let store = GraphStore(nodes: [node])
        
        let newSize = Dimensions(width: 200, height: 100)
        store.updateNodeDimensions(id: "1", dimensions: newSize)
        
        XCTAssertEqual(store.nodes[0].measured, newSize)
        
        // Verify that instance is not unnecessarily changed on subsequent identical update | 再度の同値更新でインスタンスが不必要に変更されないことを確認
        store.updateNodeDimensions(id: "1", dimensions: newSize)
        XCTAssertEqual(store.nodes[0].measured, newSize)
    }
    
    @MainActor
    func testFitViewWithMeasuredDimensions() {
        // Node with unknown size (width=0) in initial state | 初期状態ではサイズ不明のノード (width=0)
        let node = BaseNode(id: "1", position: .zero, data: "test")
        let store = GraphStore(nodes: [node])
        
        let containerSize = Dimensions(width: 1000, height: 1000)
        
        // Reflect measured size (assume a huge 500x500 node) | 実測サイズを反映 (500x500の巨大なノードとする)
        let measuredSize = Dimensions(width: 500, height: 500)
        store.updateNodeDimensions(id: "1", dimensions: measuredSize)
        
        // fitView after reflecting measured size | 実測サイズ反映後の fitView
        store.fitView(in: containerSize, padding: .all(.points(0)))
        let zoomAfterMeasure = store.runtimeState.viewport.viewport.zoom
        
        // For 500x500 to fit in 1000x1000, zoom = 1000 / 500 = 2.0 | 500x500 が 1000x1000 に収まるには zoom = 1000 / 500 = 2.0
        XCTAssertEqual(zoomAfterMeasure, 2.0, accuracy: 0.0001)
    }
    
    @MainActor
    func testMoveSelectedNodes() {
        let n1 = BaseNode(id: "1", position: XYPosition(x: 10, y: 10), data: "1")
        let n2 = BaseNode(id: "2", position: XYPosition(x: 100, y: 100), data: "2")
        let store = GraphStore(nodes: [n1, n2])
        
        // 1. Select node 1 only | 1. ノード1のみ選択
        store.selectNode("1")
        
        // 2. Move (+5, -2) | 2. 移動 (+5, -2)
        store.moveSelectedNodes(by: XYPosition(x: 5, y: -2))
        
        XCTAssertEqual(store.node(id: "1")?.position.x, 15)
        XCTAssertEqual(store.node(id: "1")?.position.y, 8)
        XCTAssertEqual(store.node(id: "2")?.position.x, 100, "Unselected nodes should not move | 非選択ノードは動いてはいけない")
        
        // 3. Relative movement in multi-selection | 3. 複数選択での相対移動
        store.toggleNodeSelection("2") // Add 2 while 1 is selected | 1が選択されている状態で2も追加
        store.moveSelectedNodes(by: XYPosition(x: 10, y: 10))
        
        XCTAssertEqual(store.node(id: "1")?.position.x, 25)
        XCTAssertEqual(store.node(id: "2")?.position.x, 110)
        
        // 4. Set individual nodes to undraggable | 4. 個別のノードをドラッグ不可に設定
        store.nodes[0].draggable = false // Lock node 1 | ノード1をロック
        store.moveSelectedNodes(by: XYPosition(x: 100, y: 100))
        XCTAssertEqual(store.node(id: "1")?.position.x, 25, "Individually locked node 1 should not move | 個別ロック中のノード1は動いてはいけない")
        XCTAssertEqual(store.node(id: "2")?.position.x, 210, "Unlocked node 2 should move | ロックされていないノード2は動くべき")
        
        // 5. Guard for global drag prohibition state | 5. グローバルなドラッグ禁止状態でのガード
        store.runtimeState.interactivity.nodesDraggable = false
        store.moveSelectedNodes(by: XYPosition(x: 1000, y: 1000))
        XCTAssertEqual(store.node(id: "2")?.position.x, 210, "Nodes should not move during global prohibition | グローバル禁止時は全ノード動いてはいけない")
    }
    
    @MainActor
    func testUndoRedoNodeMovement() {
        let store = GraphStore<String>(
            nodes: [BaseNode(id: "1", position: .zero, data: "test")],
            undoManager: UndoManager()
        )
        
        // 1. Movement | 1. 移動
        store.startDragging(nodeIDs: ["1"], at: .zero)
        store.updateDragging(to: XYPosition(x: 50, y: 50))
        store.stopDragging()
        
        XCTAssertEqual(store.node(id: "1")?.position.x, 50)
        
        // 2. Undo | 2. Undo
        store.undoManager?.undo()
        XCTAssertEqual(store.node(id: "1")?.position.x, 0, "Undo should restore original position | Undo で元の位置に戻るべき")
        
        // 3. Redo | 3. Redo
        store.undoManager?.redo()
        XCTAssertEqual(store.node(id: "1")?.position.x, 50, "Redo should restore position after movement | Redo で移動後の位置に戻るべき")
    }
    
    @MainActor
    func testUndoRedoDeletion() {
        let store = GraphStore<String>(
            nodes: [BaseNode(id: "1", position: .zero, data: "test")],
            undoManager: UndoManager()
        )
        
        // 1. Select and delete | 1. 選択して削除
        store.selectNode("1")
        store.deleteSelection()
        XCTAssertTrue(store.nodes.isEmpty)
        
        // 2. Undo | 2. Undo
        store.undoManager?.undo()
        XCTAssertEqual(store.nodes.count, 1, "Undo should restore the node | Undo でノードが復活すべき")
        XCTAssertEqual(store.nodes[0].id, "1")
        
        // 3. Redo | 3. Redo
        store.undoManager?.redo()
        XCTAssertTrue(store.nodes.isEmpty, "Redo should execute deletion again | Redo で再び削除されるべき")
    }
}
