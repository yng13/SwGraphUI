import XCTest
import SwiftUI
@testable import SwGraphUI

@MainActor
final class RegressionMatrixTests: XCTestCase {
    var store: GraphStore<String>!
    var undoManager: UndoManager!
    
    override func setUp() {
        super.setUp()
        undoManager = UndoManager()
        undoManager.groupsByEvent = false
        store = GraphStore<String>(nodes: [], undoManager: undoManager)
    }
    
    // MARK: - Helpers
    
    private func createNode(id: String, x: Double, y: Double, parentID: String? = nil, extent: NodeExtent? = nil) -> BaseNode<String> {
        BaseNode(
            id: id,
            position: XYPosition(x: x, y: y),
            data: "Node \(id)",
            parentID: parentID,
            extent: extent,
            width: 100,
            height: 40
        )
    }
    
    private func assertSelectionState(selectedNodeIDs: Set<String> = [], selectedEdgeIDs: Set<String> = [], message: String = "", file: StaticString = #file, line: UInt = #line) {
        // Node selection integrity
        XCTAssertEqual(store.runtimeState.selection.selectedNodeIDs, selectedNodeIDs, "RuntimeState selectedNodeIDs mismatch: \(message)", file: file, line: line)
        for node in store.nodes {
            if selectedNodeIDs.contains(node.id) {
                XCTAssertTrue(node.selected, "Node \(node.id) flag should be true: \(message)", file: file, line: line)
            } else {
                XCTAssertFalse(node.selected, "Node \(node.id) flag should be false: \(message)", file: file, line: line)
            }
        }
        
        // Edge selection integrity
        XCTAssertEqual(store.runtimeState.selection.selectedEdgeIDs, selectedEdgeIDs, "RuntimeState selectedEdgeIDs mismatch: \(message)", file: file, line: line)
        for edge in store.edges {
            if selectedEdgeIDs.contains(edge.id) {
                XCTAssertTrue(edge.selected, "Edge \(edge.id) flag should be true: \(message)", file: file, line: line)
            } else {
                XCTAssertFalse(edge.selected, "Edge \(edge.id) flag should be false: \(message)", file: file, line: line)
            }
        }
    }
    
    // MARK: - Case A: Hierarchy x Move x Undo
    
    func testHierarchyMoveUndoRedo() {
        // Setup: Parent p1 at (0,0), Child c1 at (10,10) relative to p1
        let p1 = createNode(id: "p1", x: 0, y: 0)
        let c1 = createNode(id: "c1", x: 10, y: 10, parentID: "p1")
        store.nodes = [p1, c1]
        
        // 1. Move Parent by (50, 50)
        store.selectNode("p1")
        undoManager.beginUndoGrouping()
        store.moveSelectedNodes(by: XYPosition(x: 50, y: 50))
        undoManager.endUndoGrouping()
        assertSelectionState(selectedNodeIDs: ["p1"], selectedEdgeIDs: [], message: "Selection state after move parent | 親移動後の選択状態")
        
        XCTAssertEqual(store.nodes.first(where: { $0.id == "p1" })?.position, XYPosition(x: 50, y: 50))
        XCTAssertEqual(store.nodes.first(where: { $0.id == "c1" })?.position, XYPosition(x: 10, y: 10), "Child node's relative coordinate should be unchanged | 子ノードの相対座標は不変であること")
        
        // 2. Move Child by (20, 20)
        store.clearSelection()
        store.selectNode("c1")
        undoManager.beginUndoGrouping()
        store.moveSelectedNodes(by: XYPosition(x: 20, y: 20))
        undoManager.endUndoGrouping()
        assertSelectionState(selectedNodeIDs: ["c1"], selectedEdgeIDs: [], message: "Selection state after move child | 子移動後の選択状態")
        
        XCTAssertEqual(store.nodes.first(where: { $0.id == "c1" })?.position, XYPosition(x: 30, y: 30), "Child node's relative coordinate should be updated | 子ノードの相対座標が更新されること")
        
        // 3. Undo (1) -> Child movement is restored | 3. Undo (1) -> 子の移動が戻る
        undoManager.undo()
        assertSelectionState(selectedNodeIDs: ["c1"], selectedEdgeIDs: [], message: "Selection state after Undo(1) | Undo(1)後の選択状態")
        XCTAssertEqual(store.nodes.first(where: { $0.id == "c1" })?.position, XYPosition(x: 10, y: 10), "Child movement should be restored after first Undo | Undo 1回目で子の移動が復元されること")
        XCTAssertEqual(store.nodes.first(where: { $0.id == "p1" })?.position, XYPosition(x: 50, y: 50))
        
        // 4. Undo (2) -> Parent movement is restored | 4. Undo (2) -> 親の移動が戻る
        undoManager.undo()
        assertSelectionState(selectedNodeIDs: ["p1"], selectedEdgeIDs: [], message: "Selection state after Undo(2) | Undo(2)後の選択状態")
        XCTAssertEqual(store.nodes.first(where: { $0.id == "p1" })?.position, .zero, "Parent movement should be restored after second Undo | Undo 2回目で親の移動が復元されること")
        XCTAssertEqual(store.nodes.first(where: { $0.id == "c1" })?.position, XYPosition(x: 10, y: 10), "Child relative coordinate should be maintained | 子の相対座標が維持されていること")
        
        // 5. Redo (1) -> Parent movement is reapplied | 5. Redo (1) -> 親の移動が再適用
        undoManager.redo()
        assertSelectionState(selectedNodeIDs: ["c1"], selectedEdgeIDs: [], message: "Selection state after Redo(1) | Redo(1)後の選択状態")
        XCTAssertEqual(store.nodes.first(where: { $0.id == "p1" })?.position, XYPosition(x: 50, y: 50))
        
        // 6. Redo (2) -> Child movement is reapplied | 6. Redo (2) -> 子の移動が再適用
        undoManager.redo()
        XCTAssertEqual(store.nodes.first(where: { $0.id == "c1" })?.position, XYPosition(x: 30, y: 30))
        assertSelectionState(selectedNodeIDs: ["c1"], selectedEdgeIDs: [], message: "Selection of c1 should be maintained after Redo | Redo 後に c1 の選択が維持されていること")
    }
    
    // MARK: - Case B: Multi-selection x Delete x Undo
    
    func testMultiSelectionDeleteUndo() {
        let p1 = createNode(id: "p1", x: 0, y: 0)
        let c1 = createNode(id: "c1", x: 10, y: 10, parentID: "p1")
        let n3 = createNode(id: "n3", x: 200, y: 0)
        let e1 = BaseEdge<String>(id: "e1", source: "p1", target: "n3") // p1 -> n3
        let e2 = BaseEdge<String>(id: "e2", source: "c1", target: "n3") // c1 -> n3
        
        store.nodes = [p1, c1, n3]
        store.edges = [e1, e2]
        
        // 1. Select p1 (parent) and e2 (edge) | 1. p1 (親) と e2 (エッジ) を選択
        store.selectNode("p1")
        store.toggleEdgeSelection("e2") // selectNode is exclusive, so add e2 via toggle | selectNode は排他的なので、e2 をトグルで追加選択
        assertSelectionState(selectedNodeIDs: ["p1"], selectedEdgeIDs: ["e2"], message: "Initial selection state | 初期選択状態")
        
        // 2. Delete (expected: deleting p1 takes c1 with it, or at least p1 and related edges are gone) | 2. 削除 (p1 を消すと c1 も道連れに、あるいは少なくとも p1 とそれに関連するエッジが消えることを想定)
        undoManager.beginUndoGrouping()
        store.deleteSelection()
        undoManager.endUndoGrouping()
        
        XCTAssertFalse(store.nodes.contains(where: { $0.id == "p1" }), "p1 should be deleted | p1 が消去されていること")
        XCTAssertFalse(store.edges.contains(where: { $0.id == "e1" }), "e1 (edge connected to p1) should be deleted | e1 (p1に連なるエッジ) が消去されていること")
        XCTAssertFalse(store.edges.contains(where: { $0.id == "e2" }), "e2 (selected edge) should be deleted | e2 (選択されていたエッジ) が消去されていること")
        assertSelectionState(selectedNodeIDs: [], selectedEdgeIDs: [], message: "No selection after deletion | 削除後は選択なし")
        
        // 3. Undo | 3. Undo
        undoManager.undo()
        
        XCTAssertTrue(store.nodes.contains(where: { $0.id == "p1" }), "p1 should be restored by Undo | Undo で p1 が復元されていること")
        XCTAssertTrue(store.nodes.contains(where: { $0.id == "c1" }), "c1 should exist | c1 が存在すること")
        XCTAssertEqual(store.nodes.first(where: { $0.id == "c1" })?.parentID, "p1", "c1's parentID should be p1 | c1 の parentID が p1 であること")
        XCTAssertTrue(store.edges.contains(where: { $0.id == "e1" }), "e1 should be restored | e1 が復元されていること")
        XCTAssertTrue(store.edges.contains(where: { $0.id == "e2" }), "e2 should be restored | e2 が復元されていること")
        XCTAssertEqual(store.edges.first(where: { $0.id == "e1" })?.source, "p1", "e1's source should be p1 | e1 の接続元が p1 であること")
        XCTAssertEqual(store.edges.first(where: { $0.id == "e1" })?.target, "n3", "e1's target should be n3 | e1 の接続先が n3 であること")
        
        assertSelectionState(selectedNodeIDs: ["p1"], selectedEdgeIDs: ["e2"], message: "Selection state (both nodes and edges) should be restored after Undo | Undo 後に選択状態（ノード・エッジ両方）が復元されていること")
        
        // 4. Redo | 4. Redo
        undoManager.redo()
        XCTAssertFalse(store.nodes.contains(where: { $0.id == "p1" }), "p1 should be deleted after Redo | Redo 後に p1 が消去されていること")
        XCTAssertFalse(store.edges.contains(where: { $0.id == "e1" }), "e1 should be deleted after Redo | Redo 後に e1 が消去されていること")
        assertSelectionState(selectedNodeIDs: [], selectedEdgeIDs: [], message: "Deleted again after Redo | Redo 後に再度消去")
    }
    
    // MARK: - Case C: Layout x Undo x Redo
    
    func testLayoutUndoRedoDeterminism() {
        let n1 = createNode(id: "1", x: 0, y: 0)
        let n2 = createNode(id: "2", x: 0, y: 0)
        let n3 = createNode(id: "3", x: 0, y: 0)
        let e1 = BaseEdge<String>(id: "e1", source: "1", target: "2")
        let e2 = BaseEdge<String>(id: "e2", source: "1", target: "3")
        store.nodes = [n1, n2, n3]
        store.edges = [e1, e2]
        store.selectNode("1")
        store.toggleNodeSelection("2") // Use toggle for multi-selection | 複数選択のためにトグルを使用
        assertSelectionState(selectedNodeIDs: ["1", "2"], selectedEdgeIDs: [])
        
        let initialPositions = store.nodes.reduce(into: [String: XYPosition]()) { $0[$1.id] = $1.position }
        
        // 1. Apply layout | 1. レイアウト適用
        undoManager.beginUndoGrouping()
        store.applyLayout(direction: .topToBottom, spacing: 50)
        undoManager.endUndoGrouping()
        assertSelectionState(selectedNodeIDs: ["1", "2"], selectedEdgeIDs: [], message: "Selection state after layout | レイアウト後の選択状態")
        
        let layoutedPositions = store.nodes.reduce(into: [String: XYPosition]()) { $0[$1.id] = $1.position }
        XCTAssertNotEqual(initialPositions, layoutedPositions, "Coordinates should be updated by layout | レイアウトによって座標が更新されていること")
        
        // 2. Undo
        undoManager.undo()
        assertSelectionState(selectedNodeIDs: ["1", "2"], selectedEdgeIDs: [], message: "Selection state after layout Undo | レイアウトUndo後の選択状態")
        for node in store.nodes {
            XCTAssertEqual(node.position, initialPositions[node.id], "ID \(node.id) coordinate should return to initial position after Undo | Undo 後に ID \(node.id) の座標が初期位置に戻ること")
        }
        
        // 3. Redo
        undoManager.redo()
        assertSelectionState(selectedNodeIDs: ["1", "2"], selectedEdgeIDs: [], message: "Selection state after layout Redo | レイアウトRedo後の選択状態")
        for node in store.nodes {
            XCTAssertEqual(node.position, layoutedPositions[node.id], "ID \(node.id) coordinate should deterministically return to post-layout position after Redo | Redo 後に ID \(node.id) の座標が決定論的にレイアウト後の位置に戻ること")
        }
        assertSelectionState(selectedNodeIDs: ["1", "2"], selectedEdgeIDs: [], message: "Selection should be maintained after Redo | Redo 後に選択が維持されていること")
    }
    
    // MARK: - Case D: Parent extent x Move x Undo x Redo
    
    func testParentExtentMoveUndoRedo() {
        // Parent 200x200, Child 100x40 at (50,50), extent: .parent | Parent 200x200, Child 100x40 at (50,50), extent: .parent
        let p1 = BaseNode(id: "p1", position: .zero, data: "", width: 200, height: 200)
        let c1 = BaseNode(id: "c1", position: XYPosition(x: 50, y: 50), data: "", parentID: "p1", extent: .parent, width: 100, height: 40)
        store.nodes = [p1, c1]
        
        store.selectNode("c1")
        assertSelectionState(selectedNodeIDs: ["c1"], selectedEdgeIDs: [])
        
        // 1. Move beyond the right edge (drag to (200, 200)) | 1. 右端へはみ出すように移動 (200, 200) へドラッグ
        // Clamped relative coordinate is (200-100, 200-40) = (100, 160) | クランプ後の相対座標は (200-100, 200-40) = (100, 160)
        undoManager.beginUndoGrouping()
        store.moveSelectedNodes(by: XYPosition(x: 150, y: 150))
        undoManager.endUndoGrouping()
        
        let clampedPos = store.nodes.first(where: { $0.id == "c1" })?.position
        XCTAssertEqual(clampedPos, XYPosition(x: 100, y: 160), "Should be clamped at boundary | 境界でクランプされていること")
        
        // 2. Undo
        undoManager.undo()
        assertSelectionState(selectedNodeIDs: ["c1"], selectedEdgeIDs: [], message: "Selection state after constraint-move Undo | 制約移動Undo後の選択状態")
        XCTAssertEqual(store.nodes.first(where: { $0.id == "c1" })?.position, XYPosition(x: 50, y: 50), "Undo should restore original position | Undo で元の位置に戻ること")
        
        // 3. Redo
        undoManager.redo()
        XCTAssertEqual(store.nodes.first(where: { $0.id == "c1" })?.position, XYPosition(x: 100, y: 160), "Redo should correctly return to clamped position | Redo でクランプ後の位置に正しく戻ること")
        assertSelectionState(selectedNodeIDs: ["c1"], selectedEdgeIDs: [], message: "Selection should be maintained after Redo | Redo 後に選択が維持されていること")
    }
    
    // MARK: - Case E: Large graph smoke test
    
    func testLargeGraphSmokePerformance() {
        var nodes: [BaseNode<String>] = []
        var edges: [BaseEdge<String>] = []
        
        // 1. Generate 200 nodes / 199 edges | 1. 200 ノード / 199 エッジ生成
        for i in 0..<200 {
            nodes.append(createNode(id: "\(i)", x: Double(i % 10) * 120, y: Double(i / 10) * 100))
            if i > 0 {
                edges.append(BaseEdge<String>(id: "e\(i)", source: "\(i-1)", target: "\(i)"))
            }
        }
        
        store.nodes = nodes
        store.edges = edges
        
        // 2. Select all | 2. 全選択
        store.selectAll()
        XCTAssertEqual(store.runtimeState.selection.selectedNodeIDs.count, 200)
        XCTAssertEqual(store.runtimeState.selection.selectedEdgeIDs.count, 199)
        assertSelectionState(
            selectedNodeIDs: Set(nodes.map { $0.id }),
            selectedEdgeIDs: Set(edges.map { $0.id }),
            message: "Consistency check of select-all state | 全選択状態の整合性確認"
        )
        
        // 3. Select-all move | 3. 全選択移動
        undoManager.beginUndoGrouping()
        store.moveSelectedNodes(by: XYPosition(x: 10, y: 10))
        undoManager.endUndoGrouping()
        XCTAssertEqual(store.nodes[0].position.x, 10.0) // Initial (0,0) + 10 | 初期 (0,0) + 10
        
        // 4. Apply layout (Smoke test: should complete) | 4. レイアウト適用 (Smoke test: 正常終了を確認)
        undoManager.beginUndoGrouping()
        store.applyLayout()
        undoManager.endUndoGrouping()
        
        // 5. Snapshot | 5. スナップショット
        let snapshot = store.snapshot()
        XCTAssertNotNil(snapshot, "Snapshot should be obtained successfully | スナップショットが正常に取得できること")
        XCTAssertEqual(snapshot.nodes.count, 200)
        
        // Basic consistency check | 基本的な整合性確認
        XCTAssertEqual(store.nodes.count, 200)
        XCTAssertEqual(store.edges.count, 199)
        assertSelectionState(
            selectedNodeIDs: Set(nodes.map { $0.id }),
            selectedEdgeIDs: Set(edges.map { $0.id }),
            message: "Selection-all should be maintained after layout | レイアウト後も全選択が維持されていること"
        )
    }
}
