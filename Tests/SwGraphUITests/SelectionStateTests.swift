import XCTest
@testable import SwGraphUI

@MainActor
final class SelectionStateTests: XCTestCase {
    
    func testSelectSingleNodeSyncsModel() {
        let node1 = BaseNode(id: "n1", position: .zero, data: "1")
        let node2 = BaseNode(id: "n2", position: .zero, data: "2")
        let store = GraphStore(nodes: [node1, node2])
        
        // Select n1 | n1 を選択
        store.selectNode("n1")
        
        // Verify Runtime State | Runtime State の確認
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("n1"))
        XCTAssertEqual(store.runtimeState.selection.selectedNodeIDs.count, 1)
        
        // Verify Model | Model の確認
        XCTAssertTrue(store.nodes.first(where: { $0.id == "n1" })?.selected ?? false)
        XCTAssertFalse(store.nodes.first(where: { $0.id == "n2" })?.selected ?? true)
    }
    
    func testSelectEdgeSyncsModel() {
        let node = BaseNode(id: "n1", position: XYPosition.zero, data: "1")
        let edge1 = BaseEdge<String>(id: "e1", source: "n1", target: "n1")
        let edge2 = BaseEdge<String>(id: "e2", source: "n1", target: "n1")
        let store = GraphStore(nodes: [node], edges: [edge1, edge2])
        
        // Select e1 | e1 を選択
        store.selectEdge("e1")
        
        // Verify Runtime State | Runtime State の確認
        XCTAssertTrue(store.runtimeState.selection.selectedEdgeIDs.contains("e1"))
        
        // Verify Model | Model の確認
        XCTAssertTrue(store.edges.first(where: { $0.id == "e1" })?.selected ?? false)
        XCTAssertFalse(store.edges.first(where: { $0.id == "e2" })?.selected ?? true)
    }
    
    func testSelectionExclusivity() {
        let node = BaseNode(id: "n1", position: .zero, data: "1")
        let edge = BaseEdge<String>(id: "e1", source: "n1", target: "n1")
        let store = GraphStore(nodes: [node], edges: [edge])
        
        // 1. Select node | 1. ノードを選択
        store.selectNode("n1")
        XCTAssertTrue(store.nodes[0].selected)
        
        // 2. Select edge -> Node selection should be cleared | 2. エッジを選択 -> ノードの選択が解除されるべき
        store.selectEdge("e1")
        XCTAssertFalse(store.nodes[0].selected)
        XCTAssertTrue(store.edges[0].selected)
        
        // 3. Select node again -> Edge selection should be cleared | 3. 再度ノードを選択 -> エッジの選択が解除されるべき
        store.selectNode("n1")
        XCTAssertTrue(store.nodes[0].selected)
        XCTAssertFalse(store.edges[0].selected)
    }
    
    func testClearSelection() {
        var node = BaseNode(id: "n1", position: .zero, data: "1")
        node.selected = true
        var edge = BaseEdge<String>(id: "e1", source: "n1", target: "n1")
        edge.selected = true
        
        let store = GraphStore(nodes: [node], edges: [edge])
        store.selectNode("n1")
        store.selectEdge("e1")
        
        store.clearSelection()
        
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.isEmpty)
        XCTAssertTrue(store.runtimeState.selection.selectedEdgeIDs.isEmpty)
        XCTAssertFalse(store.nodes[0].selected)
        XCTAssertFalse(store.edges[0].selected)
    }
    
    func testToggleNodeSelection() {
        let node1 = BaseNode(id: "n1", position: .zero, data: "1")
        let node2 = BaseNode(id: "n2", position: .zero, data: "2")
        let store = GraphStore(nodes: [node1, node2])
        
        // 1. Select n1 | 1. n1 を選択
        store.selectNode("n1")
        XCTAssertTrue(store.nodes[0].selected)
        XCTAssertFalse(store.nodes[1].selected)
        
        // 2. Toggle n2 (multi-selection) | 2. n2 をトグル（複数選択）
        store.toggleNodeSelection("n2")
        XCTAssertTrue(store.nodes[0].selected)
        XCTAssertTrue(store.nodes[1].selected)
        XCTAssertEqual(store.runtimeState.selection.selectedNodeIDs.count, 2)
        
        // 3. Toggle n1 (deselection) | 3. n1 をトグル（選択解除）
        store.toggleNodeSelection("n1")
        XCTAssertFalse(store.nodes[0].selected)
        XCTAssertTrue(store.nodes[1].selected)
        XCTAssertEqual(store.runtimeState.selection.selectedNodeIDs.count, 1)
    }
    
    func testToggleEdgeSelection() {
        let node = BaseNode(id: "n1", position: .zero, data: "1")
        let edge1 = BaseEdge<String>(id: "e1", source: "n1", target: "n1")
        let edge2 = BaseEdge<String>(id: "e2", source: "n1", target: "n1")
        let store = GraphStore(nodes: [node], edges: [edge1, edge2])
        
        // 1. Select e1 | 1. e1 を選択
        store.selectEdge("e1")
        XCTAssertTrue(store.edges[0].selected)
        XCTAssertFalse(store.edges[1].selected)
        
        // 2. Toggle e2 | 2. e2 をトグル
        store.toggleEdgeSelection("e2")
        XCTAssertTrue(store.edges[0].selected)
        XCTAssertTrue(store.edges[1].selected)
        
        // 3. Toggle e1 | 3. e1 をトグル
        store.toggleEdgeSelection("e1")
        XCTAssertFalse(store.edges[0].selected)
        XCTAssertTrue(store.edges[1].selected)
    }

    func testShiftClickPreservesNodeAndEdgeSelection() {
        let node = BaseNode(id: "n1", position: .zero, data: "1")
        let edge = BaseEdge<String>(id: "e1", source: "n1", target: "n1")
        let store = GraphStore(nodes: [node], edges: [edge])
        
        // 1. Select node | 1. ノードを選択
        store.selectNode("n1")
        
        // 2. Toggle edge | 2. エッジをトグル
        store.toggleEdgeSelection("e1")
        
        // Both should be selected | 両方選択されているべき
        XCTAssertTrue(store.nodes[0].selected)
        XCTAssertTrue(store.edges[0].selected)
    }
}
