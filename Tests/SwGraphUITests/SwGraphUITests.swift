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

@Test func runtimeStateUpdatesSelectionAndViewport() async throws {
    var state = GraphRuntimeState()

    state.selection.selectNode(id: "n1")
    state.selection.selectEdge(id: "e1")
    state.hover.hoveredNodeID = "n1"
    state.drag = DragState(draggedNodeIDs: ["n1"], dragOrigin: .init(x: 0, y: 0), currentPosition: .init(x: 5, y: 5))
    state.connection = ConnectionRuntimeState(active: .init(fromNodeID: "n1", fromHandleType: .source, currentPointer: .init(x: 10, y: 10)))
    state.viewport.panBy(dx: 10, dy: -5)
    state.viewport.zoomTo(2)

    #expect(state.selection.selectedNodeIDs == ["n1"])
    #expect(state.selection.selectedEdgeIDs == ["e1"])
    #expect(state.hover.hoveredNodeID == "n1")
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
