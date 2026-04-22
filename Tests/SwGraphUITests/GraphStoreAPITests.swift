import XCTest
import SwiftUI
@testable import SwGraphUI

@MainActor
final class GraphStoreAPITests: XCTestCase {
    var store: GraphStore<String>!
    var undoManager: UndoManager!
    
    override func setUp() async throws {
        try await super.setUp()
        undoManager = UndoManager()
        undoManager.groupsByEvent = false
        store = GraphStore<String>(nodes: [], undoManager: undoManager)
    }
    
    /// [Verification A] Verification of relative coordinate semantics | [検証項目 A] 相対座標意味論の検証
    /// When calling updateNodePosition(id:to:) for a node with a parent, | 親ノードを持つノードに対して updateNodePosition(id:to:) を呼び出した際、
    /// verify that the argument coordinate is reflected directly in the node's position property (relative to parent) instead of absolute coordinate. | 引数の座標が絶対座標ではなく、ノードの position プロパティ（親からの相対）に直接反映されることを確認します。
    func testUpdateNodePositionRelativeSemantics() {
        // 1. Place parent node at (100, 100) | 1. 親ノードを (100, 100) に配置
        let parent = BaseNode(id: "parent", position: XYPosition(x: 100, y: 100), data: "Parent")
        // 2. Place child node at relative (0, 0) == absolute (100, 100) | 2. 子ノードを親の相対 (0, 0) == 絶対 (100, 100) に配置
        let child = BaseNode(id: "child", position: .zero, data: "Child", parentID: "parent")
        
        store.nodes = [parent, child]
        
        // 3. Command child node to move to (10, 20) | 3. 子ノードを (10, 20) へ移動命令
        undoManager.beginUndoGrouping()
        store.updateNodePosition(id: "child", to: XYPosition(x: 10, y: 20))
        undoManager.endUndoGrouping()
        
        // Evaluation: node.position should be (10, 20) (treated as relative) | 評価: node.position が (10, 20) になっていること（相対座標として扱われていること）
        let updatedChild = store.node(id: "child")!
        XCTAssertEqual(updatedChild.position.x, 10, accuracy: 0.01)
        XCTAssertEqual(updatedChild.position.y, 20, accuracy: 0.01)
        
        // Evaluation: Absolute coordinate should be (110, 120) | 評価: 絶対座標が (110, 120) になっていること
        XCTAssertEqual(store.absolutePosition(for: "child").x, 110, accuracy: 0.01)
        XCTAssertEqual(store.absolutePosition(for: "child").y, 120, accuracy: 0.01)
    }
    
    /// [Verification B] Verification of constraint application | [検証項目 B] 制約適用の検証
    /// Verify that movement is clamped when it goes out of bounds with Parent Extent constraint. | Parent Extent 制約がある場合に、範囲外への移動がクランプされることを確認します。
    func testUpdateNodePositionConstraints() {
        // 100x100 parent node | 100x100 の親ノード
        var parent = BaseNode(id: "parent", position: .zero, data: "Parent", width: 100, height: 100)
        parent.measured = Dimensions(width: 100, height: 100)
        
        // 20x20 child node (with constraints) | 20x20 の子ノード (制約あり)
        var child = BaseNode(
            id: "child",
            position: .zero,
            data: "Child",
            parentID: "parent",
            extent: .parent,
            width: 20,
            height: 20
        )
        child.measured = Dimensions(width: 20, height: 20)
        
        store.nodes = [parent, child]
        
        // 1. Move within normal range | 1. 正常範囲内への移動
        undoManager.beginUndoGrouping()
        store.updateNodePosition(id: "child", to: XYPosition(x: 10, y: 10))
        undoManager.endUndoGrouping()
        XCTAssertEqual(store.node(id: "child")?.position.x, 10)
        
        // 2. Move out of range (bottom-right) -> should be clamped to (100-20, 100-20) = (80, 80) | 2. 範囲外（右下）への移動 -> 親のサイズ (100, 100) - 子のサイズ (20, 20) = (80, 80) にクランプされるはず
        undoManager.beginUndoGrouping()
        store.updateNodePosition(id: "child", to: XYPosition(x: 200, y: 200))
        undoManager.endUndoGrouping()
        XCTAssertEqual(store.node(id: "child")?.position.x, 80, "Parent extent constraint should limit X to 80")
        XCTAssertEqual(store.node(id: "child")?.position.y, 80, "Parent extent constraint should limit Y to 80")
        
        // 3. Move out of range (top-left) -> clamped to (0, 0) | 3. 範囲外（左上）への移動 -> (0, 0) にクランプ
        undoManager.beginUndoGrouping()
        store.updateNodePosition(id: "child", to: XYPosition(x: -50, y: -50))
        undoManager.endUndoGrouping()
        XCTAssertEqual(store.node(id: "child")?.position.x, 0)
        XCTAssertEqual(store.node(id: "child")?.position.y, 0)
    }
    
    /// [Verification C] Verification of Undo registration | [検証項目 C] Undo 登録の検証
    func testUpdateNodePositionUndoRegistration() {
        let node = BaseNode(id: "n1", position: .zero, data: "Node 1")
        store.nodes = [node]
        
        XCTAssertFalse(undoManager.canUndo)
        
        // Execute movement | 移動実行
        undoManager.beginUndoGrouping()
        store.updateNodePosition(id: "n1", to: XYPosition(x: 100, y: 100), title: "Custom Move Title")
        undoManager.endUndoGrouping()
        
        XCTAssertTrue(undoManager.canUndo)
        XCTAssertEqual(undoManager.undoActionName, "Custom Move Title")
        
        // Execute Undo | Undo 実行
        undoManager.undo()
        XCTAssertEqual(store.node(id: "n1")?.position, .zero)
        
        // Execute Redo | Redo 実行
        undoManager.redo()
        XCTAssertEqual(store.node(id: "n1")?.position, XYPosition(x: 100, y: 100))
    }
    
    /// Verification that Undo registration is skipped when there's no significant change | 有意な変化がない場合に Undo 登録をスキップすることの検証
    func testUpdateNodePositionNoOpGuard() {
        let node = BaseNode(id: "n1", position: XYPosition(x: 10, y: 10), data: "Node 1")
        store.nodes = [node]
        
        XCTAssertFalse(undoManager.canUndo, "Initially Undo should be disabled | 初期状態で Undo は不可であること")
        
        // 1. Move to the same position | 1. 同じ位置への移動
        // Note: If guard works, registerUndo won't be called, so even without begin/end | 注：ガードが機能すれば registerUndo が呼ばれないため、begin/end で囲まなくても
        // UndoManager's state error (must begin a group) should not occur. | NSUndoManager の状態エラー（must begin a group）は発生しないはず。
        store.updateNodePosition(id: "n1", to: XYPosition(x: 10, y: 10))
        XCTAssertFalse(undoManager.canUndo, "No-op move should not register undo")
        
        // 2. Sub-pixel movement | 2. 極小の移動
        store.updateNodePosition(id: "n1", to: XYPosition(x: 10.001, y: 10.001))
        XCTAssertFalse(undoManager.canUndo, "Sub-pixel move should not register undo")
    }
}
