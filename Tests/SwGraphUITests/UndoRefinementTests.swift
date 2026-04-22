import XCTest
import SwiftUI
@testable import SwGraphUI

@MainActor
final class UndoRefinementTests: XCTestCase {
    var store: GraphStore<String>!
    var undoManager: UndoManager!
    
    override func setUp() {
        super.setUp()
        undoManager = UndoManager()
        store = GraphStore<String>(
            nodes: [
                BaseNode(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
                BaseNode(id: "2", position: XYPosition(x: 100, y: 100), data: "B")
            ],
            undoManager: undoManager
        )
    }
    
    // MARK: - Viewport Undo Symmetry (fitView)
    
    func testFitViewUndoRedoSymmetry() {
        let originalViewport = store.runtimeState.viewport.viewport
        
        // 1. Execute fitView (fit nodes 1, 2 in size 500x500) | 1. fitView 実行 (Size 500x500 でノード 1, 2 を収める)
        store.fitView(in: Dimensions(width: 500, height: 500))
        let fittedViewport = store.runtimeState.viewport.viewport
        XCTAssertNotEqual(originalViewport, fittedViewport, "Viewport should be changed by fitView | fitView によってビューポートが変更されること")
        XCTAssertTrue(undoManager.canUndo, "fitView should be registered for Undo | fitView が Undo 登録されていること")
        
        // 2. Undo
        undoManager.undo()
        XCTAssertEqual(store.runtimeState.viewport.viewport, originalViewport, "Undo should restore original viewport | Undo で元のビューポートに戻ること")
        XCTAssertTrue(undoManager.canRedo, "Redo should be possible | Redo が可能であること")
        
        // 3. Redo
        undoManager.redo()
        XCTAssertEqual(store.runtimeState.viewport.viewport, fittedViewport, "Redo should restore the state after fitView | Redo で fitView 後の状態に再復旧すること")
    }
    
    func testFitViewUndoRedoDoesNotAffectSelection() {
        // 1. Set node 1 to selected state | 1. ノード 1 を選択した状態にする
        store.selectNode("1")
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"))
        XCTAssertTrue(store.nodes[0].selected)
        
        // 2. Execute fitView (Only viewport should change) | 2. fitView 実行 (Viewport のみが変わるはず)
        store.fitView(in: Dimensions(width: 500, height: 500))
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"), "Selection should be maintained after fitView | fitView 後も選択が維持されていること")
        XCTAssertTrue(store.nodes[0].selected, "Model flag should also be maintained | モデルのフラグも維持されていること")
        
        // 3. Undo
        undoManager.undo()
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"), "Selection should be maintained after Viewport Undo | Viewport Undo 後も選択が維持されていること")
        XCTAssertTrue(store.nodes[0].selected, "Model flag should also be maintained after Undo | モデルフラグも Undo 後に維持されていること")
        
        // 4. Redo
        undoManager.redo()
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"), "Selection should be maintained after Viewport Redo | Viewport Redo 後も選択が維持されていること")
    }
    
    // MARK: - Selection Restoration Symmetry (Delete -> Undo)
    
    func testNodeDeleteUndoSelectionSync() {
        // 1. Select node 1 | 1. ノード 1 を選択
        store.selectNode("1")
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"))
        XCTAssertTrue(store.nodes[0].selected)
        
        // 2. Delete | 2. 削除
        store.deleteSelection()
        XCTAssertEqual(store.nodes.count, 1)
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.isEmpty, "Selection should be cleared after deletion | 削除後は選択がクリアされること")
        
        // 3. Undo
        undoManager.undo()
        XCTAssertEqual(store.nodes.count, 2, "Deleted node should be restored | 削除されたノードが復元されること")
        XCTAssertTrue(store.nodes.first(where: { $0.id == "1" })?.selected == true, "Model flag should be restored | モデルフラグが復元されること")
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"), "Selection ID set in RuntimeState should also be fully synchronized during Undo | RuntimeState の選択 ID 集合も Undo 時に完全同期されること")
    }
    
    // MARK: - No-op Guard Tests
    
    func testMoveSelectedNodesNoOpGuard() {
        store.selectNode("1")
        XCTAssertEqual(undoManager.canUndo, false, "Initial state | 初期状態")
        
        // 1. Zero movement | 1. ゼロ移動
        store.moveSelectedNodes(by: .zero)
        XCTAssertFalse(undoManager.canUndo, "Undo should not be registered if there is no substantial movement | 実質的な移動がない場合、Undo は登録されないこと")
        
        // 2. Same if actual position didn't change due to constraints (e.g., extent) (Simplified verification with offset .zero for now) | 2. 制約（extent 等）により実際の位置が変わらなかった場合も同様 (現時点では簡易的に offset .zero で検証)
        store.moveSelectedNodes(by: XYPosition(x: 0, y: 0))
        XCTAssertFalse(undoManager.canUndo)
        
        // 3. Substantial movement | 3. 有意な移動
        store.moveSelectedNodes(by: XYPosition(x: 10, y: 10))
        XCTAssertTrue(undoManager.canUndo, "Should be registered only if position has changed | 位置が変わった場合のみ登録されること")
    }
    
    // MARK: - Restore vs Undo Logic Separation
    
    func testApplySnapshotRestoreSelectionFlag() {
        // Take a snapshot of the current state (node 1 is selected) | 現在の状態のスナップショット（ノード 1 が選択中）をとる
        store.selectNode("1")
        let snapshot = store.snapshot()
        
        // 1. General Restore (Save/Restore path) | 1. 一般の Restore (Save/Restore 導線)
        // M26 Compliance: Clear selection when loading from external source | M26 準拠：外部からのロード時は選択をクリアする
        store.clearSelection() // Clear temporarily | 一旦クリア
        store.apply(snapshot: snapshot, restoringSelection: false)
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.isEmpty, "Selection is not restored in normal Restore | 通常の Restore では選択は復元されない")
        
        // 2. Restoration during Undo (restoringSelection: true) | 2. Undo 時の復元 (restoringSelection: true)
        store.apply(snapshot: snapshot, restoringSelection: true)
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"), "Selection is restored when restoringSelection is true | restoringSelection: true 時は選択が復元される")
    }
}
