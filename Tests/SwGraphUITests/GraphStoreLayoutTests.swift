import XCTest
@testable import SwGraphUI

@MainActor
final class GraphStoreLayoutTests: XCTestCase {
    
    @MainActor
    func testApplyLayoutUndoRedo() {
        // 1. セットアップ: バラバラの座標を持つノード
        let n1 = BaseNode(id: "1", position: XYPosition(x: 10, y: 10), data: "1", width: 100, height: 40)
        let n2 = BaseNode(id: "2", position: XYPosition(x: 500, y: 500), data: "2", width: 100, height: 40)
        let e1 = BaseEdge<String>(id: "e1", source: "1", target: "2")
        
        let store = GraphStore<String>(
            nodes: [n1, n2],
            edges: [e1],
            undoManager: UndoManager()
        )
        
        // 元の座標を記録
        let originalPos2 = store.node(id: "2")?.position
        XCTAssertEqual(originalPos2?.x, 500)
        XCTAssertEqual(originalPos2?.y, 500)
        
        // 2. レイアウト実行
        store.applyLayout(direction: GraphLayoutDirection.topToBottom, spacing: 50)
        
        // 座標が変わっていることを確認
        let layoutPos2 = store.node(id: "2")?.position
        XCTAssertNotEqual(layoutPos2?.y, 500)
        // TB レイアウト: Node 1 (h=40) -> spacing(50) -> Node 2
        XCTAssertEqual(layoutPos2?.y, 90) // 40 + 50
        
        // 3. Undo 実行
        store.undoManager?.undo()
        
        let undoPos2 = store.node(id: "2")?.position
        XCTAssertEqual(undoPos2?.x, 500, "Undo で元の X 座標に戻るべき")
        XCTAssertEqual(undoPos2?.y, 500, "Undo で元の Y 座標に戻るべき")
        
        // 4. Redo 実行
        store.undoManager?.redo()
        
        let redoPos2 = store.node(id: "2")?.position
        XCTAssertEqual(redoPos2?.x, layoutPos2?.x, "Redo でレイアウト後の X 座標に戻るべき")
        XCTAssertEqual(redoPos2?.y, 90, "Redo でレイアウト後の Y 座標に戻るべき")
    }
}
