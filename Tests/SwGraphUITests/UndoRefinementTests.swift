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
        
        // 1. fitView 実行 (Size 500x500 でノード 1, 2 を収める)
        store.fitView(in: Dimensions(width: 500, height: 500))
        let fittedViewport = store.runtimeState.viewport.viewport
        XCTAssertNotEqual(originalViewport, fittedViewport, "fitView によってビューポートが変更されること")
        XCTAssertTrue(undoManager.canUndo, "fitView が Undo 登録されていること")
        
        // 2. Undo
        undoManager.undo()
        XCTAssertEqual(store.runtimeState.viewport.viewport, originalViewport, "Undo で元のビューポートに戻ること")
        XCTAssertTrue(undoManager.canRedo, "Redo が可能であること")
        
        // 3. Redo
        undoManager.redo()
        XCTAssertEqual(store.runtimeState.viewport.viewport, fittedViewport, "Redo で fitView 後の状態に再復旧すること")
    }
    
    func testFitViewUndoRedoDoesNotAffectSelection() {
        // 1. ノード 1 を選択した状態にする
        store.selectNode("1")
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"))
        XCTAssertTrue(store.nodes[0].selected)
        
        // 2. fitView 実行 (Viewport のみが変わるはず)
        store.fitView(in: Dimensions(width: 500, height: 500))
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"), "fitView 後も選択が維持されていること")
        XCTAssertTrue(store.nodes[0].selected, "モデルのフラグも維持されていること")
        
        // 3. Undo
        undoManager.undo()
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"), "Viewport Undo 後も選択が維持されていること")
        XCTAssertTrue(store.nodes[0].selected, "モデルフラグも Undo 後に維持されていること")
        
        // 4. Redo
        undoManager.redo()
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"), "Viewport Redo 後も選択が維持されていること")
    }
    
    // MARK: - Selection Restoration Symmetry (Delete -> Undo)
    
    func testNodeDeleteUndoSelectionSync() {
        // 1. ノード 1 を選択
        store.selectNode("1")
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"))
        XCTAssertTrue(store.nodes[0].selected)
        
        // 2. 削除
        store.deleteSelection()
        XCTAssertEqual(store.nodes.count, 1)
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.isEmpty, "削除後は選択がクリアされること")
        
        // 3. Undo
        undoManager.undo()
        XCTAssertEqual(store.nodes.count, 2, "削除されたノードが復元されること")
        XCTAssertTrue(store.nodes.first(where: { $0.id == "1" })?.selected == true, "モデルフラグが復元されること")
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"), "RuntimeState の選択 ID 集合も Undo 時に完全同期されること")
    }
    
    // MARK: - No-op Guard Tests
    
    func testMoveSelectedNodesNoOpGuard() {
        store.selectNode("1")
        XCTAssertEqual(undoManager.canUndo, false, "初期状態")
        
        // 1. ゼロ移動
        store.moveSelectedNodes(by: .zero)
        XCTAssertFalse(undoManager.canUndo, "実質的な移動がない場合、Undo は登録されないこと")
        
        // 2. 制約（extent 等）により実際の位置が変わらなかった場合も同様 (現時点では簡易的に offset .zero で検証)
        store.moveSelectedNodes(by: XYPosition(x: 0, y: 0))
        XCTAssertFalse(undoManager.canUndo)
        
        // 3. 有意な移動
        store.moveSelectedNodes(by: XYPosition(x: 10, y: 10))
        XCTAssertTrue(undoManager.canUndo, "位置が変わった場合のみ登録されること")
    }
    
    // MARK: - Restore vs Undo Logic Separation
    
    func testApplySnapshotRestoreSelectionFlag() {
        // 現在の状態のスナップショット（ノード 1 が選択中）をとる
        store.selectNode("1")
        let snapshot = store.snapshot()
        
        // 1. 一般の Restore (Save/Restore 導線)
        // M26 準拠：外部からのロード時は選択をクリアする
        store.clearSelection() // 一旦クリア
        store.apply(snapshot: snapshot, restoringSelection: false)
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.isEmpty, "通常の Restore では選択は復元されない")
        
        // 2. Undo 時の復元 (restoringSelection: true)
        store.apply(snapshot: snapshot, restoringSelection: true)
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("1"), "restoringSelection: true 時は選択が復元される")
    }
}
