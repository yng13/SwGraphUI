import Testing
@testable import SwGraphUI

@Test func example() async throws {
    #expect(Position.left.opposite == .right)
    #expect(Position.top.opposite == .bottom)
}

@Test func unionCalculatesBoundingRect() async throws {
    let rects = [
        Rect(x: 10, y: 20, width: 30, height: 40),
        Rect(x: -5, y: 15, width: 10, height: 10),
    ]

    let union = GeometryAlgorithms.union(of: rects)

    #expect(union == Rect(x: -5, y: 15, width: 45, height: 45))
}

@Test func nodeAndEdgeCanBeConstructed() async throws {
    let node = Node(id: "n1", position: .init(x: 10, y: 20), data: EmptyPayload())
    let edge = Edge(id: "e1", source: "n1", target: "n2")

    #expect(node.id == "n1")
    #expect(edge.source == "n1")
    #expect(edge.target == "n2")
}

@Test func addEdgePreventsDuplicates() async throws {
    let existing = GraphEdge<EmptyPayload>(id: "e1", source: "a", target: "b")
    let duplicateConnection = Connection(source: "a", target: "b")

    let result = ConnectionsAlgorithms.addEdge(from: duplicateConnection, to: [existing])

    #expect(result.count == 1)
}

@Test func pointEndpointEdgesCanBeConstructedAndDeduplicated() async throws {
    let edge = GraphEdge<EmptyPayload>(
        id: "floating",
        sourceEndpoint: .node(id: "a", handleID: "out"),
        targetEndpoint: .point(XYPosition(x: 120, y: 240))
    )
    let duplicate = GraphEdge<EmptyPayload>(
        id: "floating-2",
        sourceEndpoint: .node(id: "a", handleID: "out"),
        targetEndpoint: .point(XYPosition(x: 120, y: 240))
    )

    let result = ConnectionsAlgorithms.addEdge(duplicate, to: [edge])

    #expect(edge.source == "a")
    #expect(edge.sourceHandle == "out")
    #expect(edge.target.isEmpty)
    #expect(result.count == 1)
    #expect(GraphAlgorithms.isEdge(edge))
}

@Test func graphAlgorithmsFindNeighbors() async throws {
    let nodes = [
        GraphNode(id: "a", position: .init(x: 0, y: 0), data: EmptyPayload()),
        GraphNode(id: "b", position: .init(x: 10, y: 0), data: EmptyPayload()),
        GraphNode(id: "c", position: .init(x: 20, y: 0), data: EmptyPayload()),
    ]
    let edges = [
        GraphEdge<EmptyPayload>(id: "e1", source: "a", target: "b"),
        GraphEdge<EmptyPayload>(id: "e2", source: "c", target: "a"),
    ]

    let outgoers = GraphAlgorithms.outgoers(for: "a", nodes: nodes, edges: edges)
    let incomers = GraphAlgorithms.incomers(for: "a", nodes: nodes, edges: edges)

    #expect(outgoers.map(\.id) == ["b"])
    #expect(incomers.map(\.id) == ["c"])
}

@Test func nodeDimensionsPreferMeasuredOverExplicitEstimate() async throws {
    let node = GraphNode(
        id: "rich-node",
        position: .zero,
        data: EmptyPayload(),
        width: 100,
        height: 40,
        initialWidth: 80,
        initialHeight: 30,
        measured: Dimensions(width: 180, height: 72)
    )

    #expect(GraphAlgorithms.nodeDimensions(for: node) == Dimensions(width: 180, height: 72))
}

@Test func geometryBoundsPreferMeasuredDimensions() async throws {
    let node = GraphNode(
        id: "rich-node",
        position: XYPosition(x: 10, y: 20),
        data: EmptyPayload(),
        width: 100,
        height: 40,
        measured: Dimensions(width: 180, height: 72)
    )

    let bounds = GeometryAlgorithms.getBounds(nodes: [node])

    #expect(bounds == Rect(x: 10, y: 20, width: 180, height: 72))
}

@Test func endpointLabelPositionMovesOutwardFromHandlePlacement() async throws {
    let handle = XYPosition(x: 100, y: 100)
    let offset = 12.0

    #expect(EdgeEndpointLabelAlgorithms.graphPosition(handlePoint: handle, placement: .top, offset: offset) == XYPosition(x: 100, y: 88))
    #expect(EdgeEndpointLabelAlgorithms.graphPosition(handlePoint: handle, placement: .right, offset: offset) == XYPosition(x: 112, y: 100))
    #expect(EdgeEndpointLabelAlgorithms.graphPosition(handlePoint: handle, placement: .bottom, offset: offset) == XYPosition(x: 100, y: 112))
    #expect(EdgeEndpointLabelAlgorithms.graphPosition(handlePoint: handle, placement: .left, offset: offset) == XYPosition(x: 88, y: 100))
}

@Test func endpointLabelPositionStaggersCollisionLanesOutward() async throws {
    let handle = XYPosition(x: 100, y: 100)

    #expect(
        EdgeEndpointLabelAlgorithms.graphPosition(
            handlePoint: handle,
            placement: .bottom,
            offset: 12,
            collisionLane: 2,
            crossAxisExtent: 14,
            laneGap: 4
        ) == XYPosition(x: 100, y: 148)
    )
    #expect(
        EdgeEndpointLabelAlgorithms.graphPosition(
            handlePoint: handle,
            placement: .left,
            offset: 12,
            collisionLane: 1,
            crossAxisExtent: 44,
            laneGap: 4
        ) == XYPosition(x: 40, y: 100)
    )
}

@Test func endpointLabelCollisionLaneStacksOverlappingSideLabels() async throws {
    let candidates = [
        EdgeEndpointLabelAlgorithms.CollisionCandidate(id: "a", center: XYPosition(x: 100, y: 200), extent: 60),
        EdgeEndpointLabelAlgorithms.CollisionCandidate(id: "b", center: XYPosition(x: 130, y: 200), extent: 60),
        EdgeEndpointLabelAlgorithms.CollisionCandidate(id: "c", center: XYPosition(x: 190, y: 200), extent: 44)
    ]

    #expect(EdgeEndpointLabelAlgorithms.collisionLane(id: "a", placement: .bottom, candidates: candidates) == 0)
    #expect(EdgeEndpointLabelAlgorithms.collisionLane(id: "b", placement: .bottom, candidates: candidates) == 1)
    #expect(EdgeEndpointLabelAlgorithms.collisionLane(id: "c", placement: .bottom, candidates: candidates) == 0)
}

@Test func endpointLabelCollisionLaneUsesVerticalAxisForLeftRightLabels() async throws {
    let candidates = [
        EdgeEndpointLabelAlgorithms.CollisionCandidate(id: "a", center: XYPosition(x: 200, y: 100), extent: 18),
        EdgeEndpointLabelAlgorithms.CollisionCandidate(id: "b", center: XYPosition(x: 200, y: 110), extent: 18),
        EdgeEndpointLabelAlgorithms.CollisionCandidate(id: "c", center: XYPosition(x: 200, y: 140), extent: 18)
    ]

    #expect(EdgeEndpointLabelAlgorithms.collisionLane(id: "a", placement: .right, candidates: candidates) == 0)
    #expect(EdgeEndpointLabelAlgorithms.collisionLane(id: "b", placement: .right, candidates: candidates) == 1)
    #expect(EdgeEndpointLabelAlgorithms.collisionLane(id: "c", placement: .right, candidates: candidates) == 0)
}

@Test func bezierPathProducesNonEmptyPath() async throws {
    let result = EdgePathAlgorithms.bezierPath(
        sourceX: 0,
        sourceY: 0,
        sourcePosition: .right,
        targetX: 100,
        targetY: 50,
        targetPosition: .left
    )

    #expect(!result.path.isEmpty)
    #expect(result.labelX > 0)
}

@Test func smoothStepPathProducesNonEmptyPath() async throws {
    let result = EdgePathAlgorithms.smoothStepPath(
        sourceX: 0,
        sourceY: 0,
        sourcePosition: .right,
        targetX: 100,
        targetY: 50,
        targetPosition: .left
    )

    #expect(!result.path.isEmpty)
    #expect(result.labelX >= 0)
}

@MainActor
@Test func runtimeStateUpdatesSelectionAndViewport() async throws {
    var state = GraphRuntimeState()

    state.selection.selectNode(id: "n1")
    state.selection.selectEdge(id: "e1")
    state.hover.hoveredNodeID = "n1"
    state.hover.hoveredEdgeID = "e1"
    let n1 = GraphNode(id: "n1", position: .zero, data: EmptyPayload())
    state.drag.startDrag(nodes: [n1], nodeLookup: ["n1": n1], pointer: .zero)
    state.drag.updateDrag(to: .init(x: 5, y: 5))
    state.connection = ConnectionState(active: .init(fromNodeID: "n1", fromHandleID: nil, fromHandleType: .source, fromHandlePosition: .right, fromPosition: .zero, currentPointer: .init(x: 10, y: 10)))
    state.viewport.setViewport(.init(x: 10, y: -5, zoom: 2))

    #expect(state.selection.selectedNodeIDs == ["n1"])
    #expect(state.selection.selectedEdgeIDs == ["e1"])
    #expect(state.hover.hoveredNodeID == "n1")
    #expect(state.hover.hoveredEdgeID == "e1")
    #expect(state.drag.isDragging)
    #expect(state.connection.isConnecting)
    #expect(state.viewport.viewport == Viewport(x: 10, y: -5, zoom: 2))
}

@Test func viewportForBoundsCentersContent() async throws {
    let viewport = GeometryAlgorithms.getViewportForBounds(
        Rect(x: 0, y: 0, width: 100, height: 100),
        in: Dimensions(width: 200, height: 100),
        minZoom: 0.5,
        maxZoom: 2,
        padding: .all(.points(0))
    )

    #expect(viewport.zoom == 1)
    #expect(viewport.x == 50)
    #expect(viewport.y == 0)
}

@Test func layoutAnchorHelpersRoundTrip() async throws {
    let size = Dimensions(width: 120, height: 80)
    let center = XYPosition(x: 300, y: 220)

    let topLeft = GraphLayoutAlgorithms.centerToTopLeft(center, size: size)
    #expect(topLeft == XYPosition(x: 240, y: 180))

    let restored = GraphLayoutAlgorithms.topLeftToCenter(topLeft, size: size)
    #expect(restored == center)
}
