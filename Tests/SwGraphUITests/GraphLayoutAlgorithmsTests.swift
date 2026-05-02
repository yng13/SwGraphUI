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

    @Test func layoutRankedDefaultOptionsMatchesExistingOutput() {
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "a", position: .zero, data: "a", width: 100, height: 40),
            BaseNode(id: "b", position: .zero, data: "b", width: 100, height: 40),
            BaseNode(id: "c", position: .zero, data: "c", width: 100, height: 40),
            BaseNode(id: "d", position: .zero, data: "d", width: 100, height: 40)
        ]

        let legacy = GraphLayoutAlgorithms.layoutRanked(
            nodes: nodes,
            ranks: ["a": 0, "b": 1, "c": 1, "d": 2],
            order: ["c": 0, "b": 1],
            direction: .topToBottom,
            spacing: 50
        )

        let options = GraphLayoutAlgorithms.layoutRanked(
            nodes: nodes,
            ranks: ["a": 0, "b": 1, "c": 1, "d": 2],
            order: ["c": 0, "b": 1],
            options: RankedLayoutOptions(direction: .topToBottom, spacing: 50)
        )

        #expect(legacy == options)
    }

    @Test func layoutRankedWrapsWideTopToBottomRank() {
        let nodes = (0..<6).map { index in
            BaseNode(id: "n\(index)", position: .zero, data: "n\(index)", width: 100, height: 40)
        }

        let positions = GraphLayoutAlgorithms.layoutRanked(
            nodes: nodes,
            ranks: Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, 0) }),
            options: RankedLayoutOptions(
                direction: .topToBottom,
                spacing: 20,
                maxRankBreadth: 260,
                wrappedLaneSpacing: 60
            )
        )

        let distinctY = Set(nodes.compactMap { positions[$0.id]?.y })
        #expect(distinctY.count == 3)
    }

    @Test func layoutRankedWrapsWideLeftToRightRank() {
        let nodes = (0..<6).map { index in
            BaseNode(id: "n\(index)", position: .zero, data: "n\(index)", width: 100, height: 40)
        }

        let positions = GraphLayoutAlgorithms.layoutRanked(
            nodes: nodes,
            ranks: Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, 0) }),
            options: RankedLayoutOptions(
                direction: .leftToRight,
                spacing: 20,
                maxRankBreadth: 120,
                wrappedLaneSpacing: 60
            )
        )

        let distinctX = Set(nodes.compactMap { positions[$0.id]?.x })
        #expect(distinctX.count == 3)
    }

    @Test func layoutRankedWrapIsDeterministic() {
        let nodes = (0..<8).map { index in
            BaseNode(id: "n\(index)", position: .zero, data: "n\(index)", width: 90, height: 40)
        }
        let ranks = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, 0) })
        let options = RankedLayoutOptions(
            direction: .topToBottom,
            spacing: 20,
            maxRankBreadth: 220,
            wrappedLaneSpacing: 40
        )

        let first = GraphLayoutAlgorithms.layoutRanked(nodes: nodes, ranks: ranks, options: options)
        let second = GraphLayoutAlgorithms.layoutRanked(nodes: nodes, ranks: ranks, options: options)
        #expect(first == second)
    }

    @Test func layoutRankedWrapDoesNotOverlapVariableNodeSizes() {
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "a", position: .zero, data: "a", width: 180, height: 50),
            BaseNode(id: "b", position: .zero, data: "b", width: 120, height: 60),
            BaseNode(id: "c", position: .zero, data: "c", width: 140, height: 45),
            BaseNode(id: "d", position: .zero, data: "d", width: 110, height: 80)
        ]

        let positions = GraphLayoutAlgorithms.layoutRanked(
            nodes: nodes,
            ranks: Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, 0) }),
            options: RankedLayoutOptions(
                direction: .topToBottom,
                spacing: 20,
                maxRankBreadth: 300,
                wrappedLaneSpacing: 40
            )
        )

        let sorted = nodes.compactMap { node -> (String, XYPosition, Double, Double)? in
            guard let pos = positions[node.id] else { return nil }
            return (node.id, pos, node.width ?? 0, node.height ?? 0)
        }.sorted { lhs, rhs in
            if lhs.1.y != rhs.1.y { return lhs.1.y < rhs.1.y }
            return lhs.1.x < rhs.1.x
        }

        for index in 1..<sorted.count {
            let previous = sorted[index - 1]
            let current = sorted[index]
            if previous.1.y == current.1.y {
                #expect(previous.1.x + previous.2 <= current.1.x)
            } else {
                #expect(previous.1.y + previous.3 <= current.1.y)
            }
        }
    }

    @Test func packComponentsPreservesRelativePositions() {
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "a", position: .zero, data: "a", width: 100, height: 40),
            BaseNode(id: "b", position: .zero, data: "b", width: 100, height: 40),
            BaseNode(id: "c", position: .zero, data: "c", width: 100, height: 40),
            BaseNode(id: "d", position: .zero, data: "d", width: 100, height: 40)
        ]
        let positions: [String: XYPosition] = [
            "a": XYPosition(x: 0, y: 0),
            "b": XYPosition(x: 150, y: 0),
            "c": XYPosition(x: 20, y: 30),
            "d": XYPosition(x: 170, y: 30)
        ]

        let packed = GraphLayoutAlgorithms.packComponents(
            positions: positions,
            nodes: nodes,
            component: ["a": 0, "b": 0, "c": 1, "d": 1],
            direction: .topToBottom,
            gap: 160
        )

        #expect((packed["b"]?.x ?? 0) - (packed["a"]?.x ?? 0) == 150)
        #expect((packed["d"]?.x ?? 0) - (packed["c"]?.x ?? 0) == 150)
        #expect((packed["d"]?.y ?? 0) - (packed["c"]?.y ?? 0) == 0)
    }

    @Test func packComponentsSeparatesBoundingBoxesByGap() {
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "a", position: .zero, data: "a", width: 100, height: 40),
            BaseNode(id: "b", position: .zero, data: "b", width: 100, height: 40)
        ]
        let positions: [String: XYPosition] = [
            "a": XYPosition(x: 0, y: 0),
            "b": XYPosition(x: 0, y: 0)
        ]

        let packed = GraphLayoutAlgorithms.packComponents(
            positions: positions,
            nodes: nodes,
            component: ["a": 0, "b": 1],
            direction: .topToBottom,
            gap: 160
        )

        let delta = (packed["b"]?.x ?? 0) - (packed["a"]?.x ?? 0)
        #expect(delta >= 260)
    }

    @Test func packComponentsHonorsBottomToTopAndRightToLeftDirections() {
        let nodes: [BaseNode<String>] = [
            BaseNode(id: "a", position: .zero, data: "a", width: 100, height: 40),
            BaseNode(id: "b", position: .zero, data: "b", width: 100, height: 40)
        ]
        let basePositions = GraphLayoutAlgorithms.layoutRanked(
            nodes: nodes,
            ranks: ["a": 0, "b": 1],
            direction: .bottomToTop,
            spacing: 50
        )
        let packedBottom = GraphLayoutAlgorithms.packComponents(
            positions: basePositions,
            nodes: nodes,
            component: ["a": 0, "b": 1],
            direction: .bottomToTop,
            gap: 160
        )
        #expect((packedBottom["a"]?.y ?? 0) <= 0)
        #expect((packedBottom["b"]?.y ?? 0) <= 0)

        let rightToLeftBase = GraphLayoutAlgorithms.layoutRanked(
            nodes: nodes,
            ranks: ["a": 0, "b": 1],
            direction: .rightToLeft,
            spacing: 50
        )
        let packedRight = GraphLayoutAlgorithms.packComponents(
            positions: rightToLeftBase,
            nodes: nodes,
            component: ["a": 0, "b": 1],
            direction: .rightToLeft,
            gap: 160
        )
        #expect((packedRight["a"]?.x ?? 0) <= 0)
        #expect((packedRight["b"]?.x ?? 0) <= 0)
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
