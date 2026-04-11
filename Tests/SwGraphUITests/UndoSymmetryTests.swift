import XCTest
import SwiftUI
@testable import SwGraphUI

@MainActor
final class UndoSymmetryTests: XCTestCase {
    var store: GraphStore<String>!
    var undoManager: UndoManager!
    
    override func setUp() {
        super.setUp()
        undoManager = UndoManager()
        undoManager.groupsByEvent = false
        store = GraphStore<String>(nodes: [], undoManager: undoManager)
    }
    
    // MARK: - Helpers
    
    private func createSimpleSystem() {
        let n1 = BaseNode(id: "n1", position: XYPosition(x: 0, y: 0), data: "Node 1", width: 100, height: 40)
        let n2 = BaseNode(id: "n2", position: XYPosition(x: 200, y: 0), data: "Node 2", width: 100, height: 40)
        let e1: BaseEdge<String> = BaseEdge(id: "e1", source: "n1", target: "n2")
        store.nodes = [n1, n2]
        store.edges = [e1]
    }
    
    // MARK: - Symmetry Tests
    
    func testMoveSymmetry() {
        createSimpleSystem()
        let initialPos = store.nodes[0].position
        
        // 1. Move
        store.selectNode("n1")
        undoManager.beginUndoGrouping()
        store.moveSelectedNodes(by: XYPosition(x: 50, y: 50))
        undoManager.endUndoGrouping()
        
        XCTAssertEqual(store.nodes[0].position, XYPosition(x: 50, y: 50))
        
        // 2. Undo
        undoManager.undo()
        XCTAssertEqual(store.nodes[0].position, initialPos, "Undo should restore initial position")
        XCTAssertTrue(store.nodes[0].selected, "Undo should restore selection state")
        
        // 3. Redo
        undoManager.redo()
        XCTAssertEqual(store.nodes[0].position, XYPosition(x: 50, y: 50), "Redo should restore moved position")
    }
    
    func testDeleteSymmetry() {
        createSimpleSystem()
        let initialCount = store.nodes.count
        
        // 1. Delete
        store.selectNode("n1")
        undoManager.beginUndoGrouping()
        store.deleteSelection()
        undoManager.endUndoGrouping()
        XCTAssertEqual(store.nodes.count, initialCount - 1)
        
        // 2. Undo
        undoManager.undo()
        XCTAssertEqual(store.nodes.count, initialCount, "Undo should restore deleted node")
        XCTAssertTrue(store.nodes.contains(where: { $0.id == "n1" }))
        XCTAssertTrue(store.nodes.first(where: { $0.id == "n1" })?.selected ?? false, "Selection should be restored")
        XCTAssertFalse(store.edges.isEmpty, "Edges should be restored")
        
        // 3. Redo
        undoManager.redo()
        XCTAssertEqual(store.nodes.count, initialCount - 1, "Redo should delete again")
    }
    
    func testResizeSymmetry() {
        createSimpleSystem()
        let n1 = store.nodes[0]
        let initialSize = CGSize(width: n1.width ?? 0, height: n1.height ?? 0)
        
        // 1. Resize
        store.startResizing(id: "n1")
        store.updateNodeDimensionsAfterResize(id: "n1", width: 150, height: 100, position: .zero)
        undoManager.beginUndoGrouping()
        store.stopResizing()
        undoManager.endUndoGrouping()
        
        XCTAssertEqual(store.nodes[0].width, 150)
        
        // 2. Undo
        undoManager.undo()
        XCTAssertEqual(store.nodes[0].width, initialSize.width, "Undo should restore initial width")
        XCTAssertEqual(store.nodes[0].height, initialSize.height, "Undo should restore initial height")
        
        // 3. Redo
        undoManager.redo()
        XCTAssertEqual(store.nodes[0].width, 150)
    }
    
    func testReconnectSymmetry() {
        createSimpleSystem()
        let initialEdge = store.edges[0]
        
        // add third node
        store.nodes.append(BaseNode(id: "n3", position: XYPosition(x: 400, y: 0), data: "Node 3"))
        
        // 1. Reconnect
        store.startConnecting(
            fromNodeID: "n1",
            fromHandleID: "source",
            fromHandleType: .source,
            fromHandlePosition: .right,
            fromPosition: .zero,
            at: .zero,
            mode: .reconnect(edgeID: "e1", isSource: false) // target handle を付け替える
        )
        // Simulate finding and updating target
        store.updateConnecting(to: .zero, targetNodeID: "n3", targetHandleID: "target", targetHandlePosition: .left)
        
        // End connection
        undoManager.beginUndoGrouping()
        _ = store.stopConnecting()
        undoManager.endUndoGrouping()
        
        XCTAssertEqual(store.edges[0].target, "n3")
        XCTAssertEqual(store.edges[0].sourceHandle, initialEdge.sourceHandle)
        XCTAssertEqual(store.edges[0].targetHandle, "target")
        XCTAssertEqual(store.edges[0].sourcePosition, initialEdge.sourcePosition)
        XCTAssertEqual(store.edges[0].targetPosition, .left)
        
        // 2. Undo
        undoManager.undo()
        XCTAssertEqual(store.edges[0].source, initialEdge.source, "Undo should restore source")
        XCTAssertEqual(store.edges[0].target, initialEdge.target, "Undo should restore target")
        XCTAssertEqual(store.edges[0].sourceHandle, initialEdge.sourceHandle, "Undo should restore source handle")
        XCTAssertEqual(store.edges[0].targetHandle, initialEdge.targetHandle, "Undo should restore target handle")
        XCTAssertEqual(store.edges[0].sourcePosition, initialEdge.sourcePosition, "Undo should restore source position")
        XCTAssertEqual(store.edges[0].targetPosition, initialEdge.targetPosition, "Undo should restore target position")
        
        // 3. Redo
        undoManager.redo()
        XCTAssertEqual(store.edges[0].source, initialEdge.source, "Redo should preserve source")
        XCTAssertEqual(store.edges[0].target, "n3", "Redo should restore target")
        XCTAssertEqual(store.edges[0].sourceHandle, initialEdge.sourceHandle, "Redo should preserve source handle")
        XCTAssertEqual(store.edges[0].targetHandle, "target", "Redo should restore target handle")
        XCTAssertEqual(store.edges[0].sourcePosition, initialEdge.sourcePosition, "Redo should preserve source position")
        XCTAssertEqual(store.edges[0].targetPosition, .left, "Redo should restore target position")
    }
    
    // MARK: - No-op and Viewport Tests
    
    func testNoOpProtection() {
        createSimpleSystem()
        
        // 1. Move by zero
        store.selectNode("n1")
        store.moveSelectedNodes(by: .zero)
        
        XCTAssertFalse(undoManager.canUndo, "Move by zero should not register undo")
        
        // 2. Resize to same size
        store.startResizing(id: "n1")
        store.updateNodeDimensionsAfterResize(id: "n1", width: 100, height: 40, position: .zero)
        store.stopResizing()
        
        XCTAssertFalse(undoManager.canUndo, "Resize to same size should not register undo")
    }
    
    func testViewportIsolation() {
        createSimpleSystem()
        store.setViewport(Viewport(x: 10, y: 10, zoom: 1.0))
        
        // 1. Layout Apply (with ignoringViewport = true in registerUndo)
        undoManager.beginUndoGrouping()
        store.applyLayout()
        undoManager.endUndoGrouping()
        XCTAssertTrue(undoManager.canUndo)
        
        // 2. Change Viewport (this should NOT be part of the applyLayout undo group)
        store.setViewport(Viewport(x: 100, y: 100, zoom: 2.0))
        
        // 3. Undo Layout
        undoManager.undo()
        XCTAssertEqual(store.runtimeState.viewport.viewport.x, 100, "Undo Layout should NOT restore old viewport if ignoringViewport was true")
    }
}
