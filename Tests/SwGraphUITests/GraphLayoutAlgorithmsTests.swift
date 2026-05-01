import Testing
import Foundation
@testable import SwGraphUI

@Suite struct GraphLayoutAlgorithmsTests {
    
    @Test func testTreeLayoutCentering() {
        // Simple tree: 1 -> 2, 1 -> 3
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "1", position: .zero, data: "root", width: 100, height: 40),
            BaseNode(id: "2", position: .zero, data: "child1", width: 100, height: 40),
            BaseNode(id: "3", position: .zero, data: "child2", width: 100, height: 40)
        ]
        
        let edges: [BaseEdge<String>] = [
            BaseEdge(id: "e1-2", source: "1", target: "2"),
            BaseEdge(id: "e1-3", source: "1", target: "3")
        ]
        
        let spacing = 50.0
        let results = GraphLayoutAlgorithms.layoutNodesTreeStyle(
            nodes: nodes,
            edges: edges,
            direction: .topToBottom,
            spacing: spacing
        )
        
        // Layer 0: Node 1
        // Layer 1: Node 2, Node 3 (Total width = 100 + 50 + 100 = 250)
        // Max breadth = 250
        
        // Node 1 should be centered in 250 breadth
        // lateralOffset = (250 - 100) / 2 = 75
        let pos1 = results["1"]
        #expect(pos1?.x == 75.0)
        #expect(pos1?.y == 0.0)
        
        // Node 2 and 3 should start at 0 and 150
        let pos2 = results["2"]
        let pos3 = results["3"]
        #expect(pos2?.x == 0.0)
        #expect(pos3?.x == 150.0)
        #expect(pos2?.y == 40.0 + spacing)
        #expect(pos3?.y == 40.0 + spacing)
    }
    
    @Test func testEmptyLayout() {
        let nodes: [BaseNode<String>] = []
        let edges: [BaseEdge<String>] = []
        let results = GraphLayoutAlgorithms.layoutNodesTreeStyle(nodes: nodes, edges: edges)
        #expect(results.isEmpty)
    }
    
    @Test func testLayoutDeterminism() {
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "1", position: .zero, data: "a", width: 100, height: 40),
            BaseNode(id: "2", position: .zero, data: "b", width: 100, height: 40),
            BaseNode(id: "3", position: .zero, data: "c", width: 100, height: 40)
        ]
        let edges: [BaseEdge<String>] = [
            BaseEdge(id: "e1", source: "1", target: "2"),
            BaseEdge(id: "e2", source: "1", target: "3")
        ]
        
        let firstRun = GraphLayoutAlgorithms.layoutNodesTreeStyle(nodes: nodes, edges: edges)
        let secondRun = GraphLayoutAlgorithms.layoutNodesTreeStyle(nodes: nodes, edges: edges)
        
        #expect(firstRun.count == secondRun.count)
        for (id, pos) in firstRun {
            #expect(pos == secondRun[id])
        }
    }
    
    @Test func testLayoutNoOverlap() {
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "1", position: .zero, data: "a", width: 100, height: 40),
            BaseNode(id: "2", position: .zero, data: "b", width: 100, height: 40),
            BaseNode(id: "3", position: .zero, data: "c", width: 100, height: 40)
        ]
        let edges: [BaseEdge<String>] = [
            BaseEdge(id: "e1", source: "1", target: "2"),
            BaseEdge(id: "e2", source: "1", target: "3")
        ]
        let spacing = 50.0
        let results = GraphLayoutAlgorithms.layoutNodesTreeStyle(nodes: nodes, edges: edges, direction: .topToBottom, spacing: spacing)
        
        // Node 2 and Node 3 should be placed in the same layer (Layer 1) | Node 2 と Node 3 は同一レイヤー（Layer 1）に配置されるはず
        guard let pos2 = results["2"], let pos3 = results["3"] else {
            Issue.record("Nodes not found in result")
            return
        }
        
        // Verify that the distance between nodes is at least width (100) + spacing (50) | ノード間の距離が幅(100) + spacing(50) 以上であることを確認
        let distance = abs(pos3.x - pos2.x)
        #expect(distance >= 100.0 + spacing)
    }

    @Test func testLayoutRankedRespectsExternalRanksAndOrder() {
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "a", position: .zero, data: "a", width: 100, height: 40),
            BaseNode(id: "b", position: .zero, data: "b", width: 100, height: 40),
            BaseNode(id: "c", position: .zero, data: "c", width: 100, height: 40),
            BaseNode(id: "d", position: .zero, data: "d", width: 100, height: 40)
        ]

        let results = GraphLayoutAlgorithms.layoutRanked(
            nodes: nodes,
            ranks: ["a": 0, "b": 1, "c": 1, "d": 2],
            order: ["c": 0, "b": 1],
            direction: .topToBottom,
            spacing: 50
        )

        #expect(results["a"]?.y == 0)
        #expect(results["d"]?.y == 180)
        #expect(results["c"]?.x == 0)
        #expect(results["b"]?.x == 150)
    }

    @Test func testLayoutRankedPlacesAllNodesEvenWithoutRanks() {
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "a", position: .zero, data: "a", width: 100, height: 40),
            BaseNode(id: "b", position: .zero, data: "b", width: 100, height: 40),
            BaseNode(id: "c", position: .zero, data: "c", width: 100, height: 40)
        ]

        let results = GraphLayoutAlgorithms.layoutRanked(
            nodes: nodes,
            ranks: ["a": 0],
            order: [:],
            direction: .topToBottom,
            spacing: 50
        )

        #expect(results.keys.sorted() == ["a", "b", "c"])
        #expect(results["b"] != nil)
        #expect(results["c"] != nil)
    }

    @Test func testTreeLayoutPlacesAllNodesEvenWithCycle() {
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "a", position: .zero, data: "a", width: 100, height: 40),
            BaseNode(id: "b", position: .zero, data: "b", width: 100, height: 40)
        ]
        let edges: [BaseEdge<String>] = [
            BaseEdge(id: "e1", source: "a", target: "b"),
            BaseEdge(id: "e2", source: "b", target: "a")
        ]

        let results = GraphLayoutAlgorithms.layoutNodesTreeStyle(nodes: nodes, edges: edges)
        #expect(results.keys.sorted() == ["a", "b"])
    }
}
