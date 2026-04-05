import XCTest
@testable import SwGraphUI

@MainActor
final class SelectionStateTests: XCTestCase {
    
    func testSelectSingleNodeSyncsModel() {
        let node1 = BaseNode(id: "n1", position: .zero, data: "1")
        let node2 = BaseNode(id: "n2", position: .zero, data: "2")
        let store = GraphStore(nodes: [node1, node2])
        
        // n1 を選択
        store.selectNode("n1")
        
        // Runtime State の確認
        XCTAssertTrue(store.runtimeState.selection.selectedNodeIDs.contains("n1"))
        XCTAssertEqual(store.runtimeState.selection.selectedNodeIDs.count, 1)
        
        // Model の確認
        XCTAssertTrue(store.nodes.first(where: { $0.id == "n1" })?.selected ?? false)
        XCTAssertFalse(store.nodes.first(where: { $0.id == "n2" })?.selected ?? true)
    }
    
    func testSelectEdgeSyncsModel() {
        let node = BaseNode(id: "n1", position: XYPosition.zero, data: "1")
        let edge1 = BaseEdge<String>(id: "e1", source: "n1", target: "n1")
        let edge2 = BaseEdge<String>(id: "e2", source: "n1", target: "n1")
        let store = GraphStore(nodes: [node], edges: [edge1, edge2])
        
        // e1 を選択
        store.selectEdge("e1")
        
        // Runtime State の確認
        XCTAssertTrue(store.runtimeState.selection.selectedEdgeIDs.contains("e1"))
        
        // Model の確認
        XCTAssertTrue(store.edges.first(where: { $0.id == "e1" })?.selected ?? false)
        XCTAssertFalse(store.edges.first(where: { $0.id == "e2" })?.selected ?? true)
    }
    
    func testSelectionExclusivity() {
        let node = BaseNode(id: "n1", position: .zero, data: "1")
        let edge = BaseEdge<String>(id: "e1", source: "n1", target: "n1")
        let store = GraphStore(nodes: [node], edges: [edge])
        
        // 1. ノードを選択
        store.selectNode("n1")
        XCTAssertTrue(store.nodes[0].selected)
        
        // 2. エッジを選択 -> ノードの選択が解除されるべき
        store.selectEdge("e1")
        XCTAssertFalse(store.nodes[0].selected)
        XCTAssertTrue(store.edges[0].selected)
        
        // 3. 再度ノードを選択 -> エッジの選択が解除されるべき
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
}
