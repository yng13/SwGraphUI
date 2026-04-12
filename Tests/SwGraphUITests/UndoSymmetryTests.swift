import XCTest
import SwiftUI
@testable import SwGraphUI

@MainActor
final class UndoSymmetryTests: XCTestCase {
    var store: GraphStore<String>!
    var undoManager: UndoManager!
    
    override func setUp() async throws {
        try await super.setUp()
        undoManager = UndoManager()
        undoManager.groupsByEvent = false
        store = GraphStore<String>(nodes: [], undoManager: undoManager)
    }
    
    // MARK: - Helpers
    
    private func createSimpleSystem() {
        let n1 = BaseNode(id: "n1", position: XYPosition(x: 0, y: 0), data: "Node 1", width: 100, height: 40)
        let n2 = BaseNode(id: "n2", position: XYPosition(x: 200, y: 0), data: "Node 2", width: 100, height: 40)
        let e1 = BaseEdge<String>(id: "e1", source: "n1", target: "n2", sourceHandle: "s1", targetHandle: "t1", sourcePosition: .right, targetPosition: .left)
        store.nodes = [n1, n2]
        store.edges = [e1]
    }
    
    private func assertSymmetry(label: String, action: () -> Void) {
        let original = store.snapshot()
        
        undoManager.beginUndoGrouping()
        action()
        undoManager.endUndoGrouping()
        
        XCTAssertNotEqual(store.snapshot(), original, "[\(label)] 行動後に状態が変化していること")
        
        undoManager.undo()
        XCTAssertEqual(store.snapshot(), original, "[\(label)] Undo 後に元の状態と完全一致すること")
        
        undoManager.redo()
        XCTAssertNotEqual(store.snapshot(), original, "[\(label)] Redo 後に修正後の状態に戻ること")
        
        undoManager.undo()
        XCTAssertEqual(store.snapshot(), original, "[\(label)] 最終的に Undo で元に戻ること")
    }
    
    // MARK: - Symmetry Tests
    
    func testMoveSymmetry() {
        createSimpleSystem()
        store.selectNode("n1")
        
        assertSymmetry(label: "Move") {
            store.moveSelectedNodes(by: XYPosition(x: 50, y: 50))
        }
    }
    
    func testDeleteSymmetry() {
        createSimpleSystem()
        store.selectNode("n1")
        
        assertSymmetry(label: "Delete") {
            store.deleteSelection()
        }
    }
    
    func testResizeSymmetry() {
        createSimpleSystem()
        
        assertSymmetry(label: "Resize") {
            store.startResizing(id: "n1")
            store.updateNodeDimensionsAfterResize(id: "n1", width: 150, height: 80, position: .zero)
            store.stopResizing()
        }
    }
    
    func testReconnectSymmetry() {
        createSimpleSystem()
        // 第3のノードを追加
        store.nodes.append(BaseNode(id: "n3", position: XYPosition(x: 400, y: 0), data: "Node 3"))
        
        let initialEdge = store.snapshot().edges[0]
        
        undoManager.beginUndoGrouping()
        // 再接続操作 (n1 -> n2 を n1 -> n3 へ)
        store.startConnecting(
            fromNodeID: "n1",
            fromHandleID: "s1",
            fromHandleType: .source,
            fromHandlePosition: .right,
            fromPosition: .zero,
            at: .zero,
            mode: .reconnect(edgeID: "e1", isSource: false)
        )
        store.updateConnecting(to: .zero, targetNodeID: "n3", targetHandleID: "t3", targetHandlePosition: .left)
        _ = store.stopConnecting()
        undoManager.endUndoGrouping()
        
        XCTAssertEqual(store.edges[0].target, "n3")
        XCTAssertEqual(store.edges[0].targetHandle, "t3")
        
        // Undo でハンドルIDやポジションまで完全に元に戻るか確認
        undoManager.undo()
        let restoredEdge = store.edges[0]
        XCTAssertEqual(restoredEdge.target, initialEdge.target)
        XCTAssertEqual(restoredEdge.targetHandle, initialEdge.targetHandle)
        XCTAssertEqual(restoredEdge.targetPosition, initialEdge.targetPosition)
        XCTAssertEqual(restoredEdge.sourceHandle, initialEdge.sourceHandle)
    }
    
    // MARK: - No-Op Protection Tests
    
    func testNoOpProtection() {
        createSimpleSystem()
        
        // 1. 変化のない移動
        store.selectNode("n1")
        store.moveSelectedNodes(by: .zero)
        XCTAssertFalse(undoManager.canUndo, "移動量ゼロは履歴に積まないこと")
        
        // 2. 極小の移動 (0.1px 未満)
        store.moveSelectedNodes(by: XYPosition(x: 0.05, y: 0.05))
        XCTAssertFalse(undoManager.canUndo, "0.1px 未満の移動は履歴に積まないこと")
        
        // 3. 変化のないリサイズ
        store.startResizing(id: "n1")
        store.updateNodeDimensionsAfterResize(id: "n1", width: 100, height: 40, position: .zero)
        store.stopResizing()
        XCTAssertFalse(undoManager.canUndo, "サイズの変わらないリサイズは履歴に積まないこと")
    }
    
    func testViewportIsolation() {
        createSimpleSystem()
        let initialViewport = Viewport(x: 10, y: 10, zoom: 1.0)
        store.setViewport(initialViewport)
        
        // 1. レイアウト適用 (Viewport を保護するはずの操作)
        undoManager.beginUndoGrouping()
        store.applyLayout()
        undoManager.endUndoGrouping()
        
        // 2. ビューポートを独立して変更
        let newViewport = Viewport(x: 100, y: 100, zoom: 2.0)
        store.setViewport(newViewport)
        
        // 3. Undo
        undoManager.undo()
        
        // 期待結果: レイアウト（ノード位置）は戻るが、ビューポート（パン・ズーム）は変更後のまま維持される
        XCTAssertEqual(store.runtimeState.viewport.viewport.x, 100, "Undo 時にビューポートが勝手に戻らないこと")
    }
}
