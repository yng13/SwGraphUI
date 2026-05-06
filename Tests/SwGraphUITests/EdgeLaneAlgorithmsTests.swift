import Testing
@testable import SwGraphUI

struct EdgeLaneAlgorithmsTests {
    @Test
    func singleEdgeGetsCenteredLane() {
        let edge = BaseEdge<String>(id: "e1", source: "a", target: "b")

        let assignment = EdgeLaneAlgorithms.assignment(for: edge, in: [edge])

        #expect(assignment.index == 0)
        #expect(assignment.count == 1)
        #expect(assignment.offset == 0)
    }

    @Test
    func parallelEdgesGetSymmetricDeterministicLanes() {
        let edges = [
            BaseEdge<String>(id: "b", source: "a", target: "z"),
            BaseEdge<String>(id: "a", source: "z", target: "a"),
            BaseEdge<String>(id: "c", source: "a", target: "z")
        ]

        let first = EdgeLaneAlgorithms.assignment(for: edges[1], in: edges)
        let second = EdgeLaneAlgorithms.assignment(for: edges[0], in: edges)
        let third = EdgeLaneAlgorithms.assignment(for: edges[2], in: edges)

        #expect(first.index == -1)
        #expect(second.index == 0)
        #expect(third.index == 1)
    }

    @Test
    func distinctEndpointHandlesDoNotShareParallelLanes() {
        let edges = [
            BaseEdge<String>(id: "a", source: "core", target: "left", sourceHandle: "te1", targetHandle: "te1"),
            BaseEdge<String>(id: "b", source: "core", target: "left", sourceHandle: "te2", targetHandle: "te2")
        ]

        let first = EdgeLaneAlgorithms.assignment(for: edges[0], in: edges)
        let second = EdgeLaneAlgorithms.assignment(for: edges[1], in: edges)

        #expect(first.index == 0)
        #expect(first.count == 1)
        #expect(first.offset == 0)
        #expect(second.index == 0)
        #expect(second.count == 1)
        #expect(second.offset == 0)
    }

    @Test
    func sameEndpointHandlesShareParallelLanesWhenDirectionIsReversed() {
        let edges = [
            BaseEdge<String>(id: "a", source: "core", target: "leaf", sourceHandle: "te1", targetHandle: "te2"),
            BaseEdge<String>(id: "b", source: "leaf", target: "core", sourceHandle: "te2", targetHandle: "te1")
        ]

        let first = EdgeLaneAlgorithms.assignment(for: edges[0], in: edges)
        let second = EdgeLaneAlgorithms.assignment(for: edges[1], in: edges)

        #expect(first.index == -0.5)
        #expect(second.index == 0.5)
        #expect(first.count == 2)
        #expect(second.count == 2)
    }

    @Test
    func distinctVerticalEndpointHandlesKeepCenteredPaths() {
        let source = XYPosition(x: 0, y: 0)
        let target = XYPosition(x: 0, y: 120)
        let edges = [
            BaseEdge<String>(id: "a", source: "top", target: "bottom", sourceHandle: "gi0", targetHandle: "gi0"),
            BaseEdge<String>(id: "b", source: "top", target: "bottom", sourceHandle: "gi1", targetHandle: "gi1")
        ]
        let base = EdgePathAlgorithms.stepPath(
            sourceX: source.x,
            sourceY: source.y,
            sourcePosition: .bottom,
            targetX: target.x,
            targetY: target.y,
            targetPosition: .top
        )

        let adjusted = EdgeLaneAlgorithms.applyLane(
            to: base,
            source: source,
            target: target,
            sourceNodeID: edges[0].source,
            targetNodeID: edges[0].target,
            assignment: EdgeLaneAlgorithms.assignment(for: edges[0], in: edges),
            sourcePosition: .bottom,
            targetPosition: .top
        )

        #expect(adjusted.segments == base.segments)
        #expect(adjusted.labelX == base.labelX)
        #expect(adjusted.labelY == base.labelY)
    }

    @Test
    func straightParallelLaneKeepsAnchorsAndOffsetsInterior() {
        let source = XYPosition(x: 0, y: 0)
        let target = XYPosition(x: 100, y: 0)
        let base = EdgePathAlgorithms.straightPath(sourceX: source.x, sourceY: source.y, targetX: target.x, targetY: target.y)
        let adjusted = EdgeLaneAlgorithms.applyLane(
            to: base,
            source: source,
            target: target,
            sourceNodeID: "a",
            targetNodeID: "b",
            assignment: EdgeLaneAssignment(index: 1, count: 2, spacing: 18)
        )

        #expect(adjusted.segments.first == .move(to: source))
        #expect(adjusted.segments.last == .quadratic(to: target, control: XYPosition(x: 50, y: 18)))
        #expect(adjusted.labelX == 50)
        #expect(adjusted.labelY == 18)
    }

    @Test
    func reversedEndpointsUseSameCanonicalLaneSide() {
        let forward = EdgeLaneAlgorithms.offsetVector(
            source: XYPosition(x: 0, y: 0),
            target: XYPosition(x: 100, y: 0),
            sourceNodeID: "a",
            targetNodeID: "b",
            assignment: EdgeLaneAssignment(index: 1, count: 2, spacing: 18)
        )
        let reversed = EdgeLaneAlgorithms.offsetVector(
            source: XYPosition(x: 100, y: 0),
            target: XYPosition(x: 0, y: 0),
            sourceNodeID: "b",
            targetNodeID: "a",
            assignment: EdgeLaneAssignment(index: 1, count: 2, spacing: 18)
        )

        #expect(forward == reversed)
    }

    @Test
    func stepParallelLaneKeepsEndpointLeadsOrthogonal() {
        let source = XYPosition(x: 0, y: 0)
        let target = XYPosition(x: 120, y: 120)
        let base = EdgePathAlgorithms.stepPath(
            sourceX: source.x,
            sourceY: source.y,
            sourcePosition: .bottom,
            targetX: target.x,
            targetY: target.y,
            targetPosition: .top
        )

        let adjusted = EdgeLaneAlgorithms.applyLane(
            to: base,
            source: source,
            target: target,
            sourceNodeID: "a",
            targetNodeID: "b",
            assignment: EdgeLaneAssignment(index: 1, count: 2, spacing: 18),
            sourcePosition: .bottom,
            targetPosition: .top
        )

        let firstLine = adjusted.segments.dropFirst().first(where: { segment in
            if case .line = segment { return true }
            return false
        })
        let penultimatePoint = adjusted.segments.dropLast().last?.target

        #expect(firstLine?.target.x == source.x)
        #expect(penultimatePoint?.x == target.x)
    }
}
