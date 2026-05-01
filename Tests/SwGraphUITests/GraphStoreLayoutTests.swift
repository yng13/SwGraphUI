import XCTest
@testable import SwGraphUI

@MainActor
final class GraphStoreLayoutTests: XCTestCase {
    
    @MainActor
    func testApplyLayoutUndoRedo() {
        // 1. Setup: Nodes with scattered coordinates | 1. セットアップ: バラバラの座標を持つノード
        let n1 = BaseNode(id: "1", position: XYPosition(x: 10, y: 10), data: "1", width: 100, height: 40)
        let n2 = BaseNode(id: "2", position: XYPosition(x: 500, y: 500), data: "2", width: 100, height: 40)
        let e1 = BaseEdge<String>(id: "e1", source: "1", target: "2")
        
        let store = GraphStore<String>(
            nodes: [n1, n2],
            edges: [e1],
            undoManager: UndoManager()
        )
        
        // Record original coordinates | 元の座標を記録
        let originalPos2 = store.node(id: "2")?.position
        XCTAssertEqual(originalPos2?.x, 500)
        XCTAssertEqual(originalPos2?.y, 500)
        
        // 2. Execute layout | 2. レイアウト実行
        store.applyLayout(direction: GraphLayoutDirection.topToBottom, spacing: 50)
        
        // Verify that coordinates have changed | 座標が変わっていることを確認
        let layoutPos2 = store.node(id: "2")?.position
        XCTAssertNotEqual(layoutPos2?.y, 500)
        // TB Layout: Node 1 (h=40) -> spacing(50) -> Node 2 | TB レイアウト: Node 1 (h=40) -> spacing(50) -> Node 2
        XCTAssertEqual(layoutPos2?.y, 90) // 40 + 50
        
        // 3. Execute Undo | 3. Undo 実行
        store.undoManager?.undo()
        
        let undoPos2 = store.node(id: "2")?.position
        XCTAssertEqual(undoPos2?.x, 500, "Undo should restore original X coordinate | Undo で元の X 座標に戻るべき")
        XCTAssertEqual(undoPos2?.y, 500, "Undo should restore original Y coordinate | Undo で元の Y 座標に戻るべき")
        
        // 4. Execute Redo | 4. Redo 実行
        store.undoManager?.redo()
        
        let redoPos2 = store.node(id: "2")?.position
        XCTAssertEqual(redoPos2?.x, layoutPos2?.x, "Redo should restore X coordinate after layout | Redo でレイアウト後の X 座標に戻るべき")
        XCTAssertEqual(redoPos2?.y, 90, "Redo should restore Y coordinate after layout | Redo でレイアウト後の Y 座標に戻るべき")
    }

    @MainActor
    func testApplyExplicitPositionsUndoRedo() {
        let n1 = BaseNode(id: "1", position: XYPosition(x: 10, y: 10), data: "1", width: 100, height: 40)
        let n2 = BaseNode(id: "2", position: XYPosition(x: 500, y: 500), data: "2", width: 100, height: 40)

        let store = GraphStore<String>(
            nodes: [n1, n2],
            edges: [],
            undoManager: UndoManager()
        )

        let positions: [String: XYPosition] = [
            "1": XYPosition(x: 100, y: 120),
            "2": XYPosition(x: 220, y: 120)
        ]

        store.applyLayout(positions: positions, undoTitle: "Apply External Layout | 外部レイアウトの適用")

        XCTAssertEqual(store.node(id: "1")?.position, positions["1"])
        XCTAssertEqual(store.node(id: "2")?.position, positions["2"])
        XCTAssertEqual(store.undoManager?.undoActionName, "Apply External Layout | 外部レイアウトの適用")

        store.undoManager?.undo()
        XCTAssertEqual(store.node(id: "1")?.position, XYPosition(x: 10, y: 10))
        XCTAssertEqual(store.node(id: "2")?.position, XYPosition(x: 500, y: 500))

        store.undoManager?.redo()
        XCTAssertEqual(store.node(id: "1")?.position, positions["1"])
        XCTAssertEqual(store.node(id: "2")?.position, positions["2"])
    }

    @MainActor
    func testApplyExplicitPositionsNoOpGuard() {
        let n1 = BaseNode(id: "1", position: XYPosition(x: 10, y: 10), data: "1", width: 100, height: 40)
        let undoManager = UndoManager()
        let store = GraphStore<String>(nodes: [n1], edges: [], undoManager: undoManager)

        store.applyLayout(positions: ["1": XYPosition(x: 10, y: 10)])

        XCTAssertFalse(undoManager.canUndo)
    }
}
