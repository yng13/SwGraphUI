import Testing
@testable import SwGraphUI

@MainActor
struct ConnectionInteractionTests {

    // MARK: - Helpers

    private func makeStore() -> GraphStore<EmptyPayload> {
        let nodeA = BaseNode(id: "a", position: XYPosition(x: 0, y: 0), data: EmptyPayload(), width: 100, height: 50)
        let nodeB = BaseNode(id: "b", position: XYPosition(x: 200, y: 0), data: EmptyPayload(), width: 100, height: 50)
        return GraphStore<EmptyPayload>(nodes: [nodeA, nodeB])
    }

    // MARK: - Normal connect flow

    @Test
    func testConnectReturnsConnectionOnSuccess() {
        let store = makeStore()

        store.startConnecting(
            fromNodeID: "a",
            fromHandleID: nil,
            fromHandleType: .source,
            fromHandlePosition: .right,
            fromPosition: XYPosition(x: 100, y: 25),
            at: XYPosition(x: 100, y: 25)
        )
        #expect(store.runtimeState.connection.isConnecting)

        store.updateConnecting(
            to: XYPosition(x: 200, y: 25),
            targetNodeID: "b",
            targetHandleID: nil,
            targetHandlePosition: .left
        )

        let connection = store.stopConnecting()
        #expect(connection != nil)
        #expect(connection?.source == "a")
        #expect(connection?.target == "b")
        #expect(!store.runtimeState.connection.isConnecting)
    }

    // MARK: - Connect with no target

    @Test
    func testConnectWithNoTargetReturnsNil() {
        let store = makeStore()

        store.startConnecting(
            fromNodeID: "a",
            fromHandleID: nil,
            fromHandleType: .source,
            fromHandlePosition: .right,
            fromPosition: XYPosition(x: 100, y: 25),
            at: XYPosition(x: 100, y: 25)
        )

        store.updateConnecting(to: XYPosition(x: 150, y: 100))

        let connection = store.stopConnecting()
        #expect(connection == nil)
        #expect(!store.runtimeState.connection.isConnecting)
    }

    // MARK: - Reconnect no-op guard

    @Test
    func testReconnectToSameEndpointReturnsNil() {
        var existingEdge = BaseEdge<EmptyPayload>(id: "e1", source: "a", target: "b")
        existingEdge.sourcePosition = .right
        existingEdge.targetPosition = .left
        let nodeA = BaseNode(id: "a", position: XYPosition(x: 0, y: 0), data: EmptyPayload(), width: 100, height: 50)
        let nodeB = BaseNode(id: "b", position: XYPosition(x: 200, y: 0), data: EmptyPayload(), width: 100, height: 50)
        let store = GraphStore<EmptyPayload>(nodes: [nodeA, nodeB], edges: [existingEdge])

        // Drag the target end of e1 back to the same node (b, left handle) — should be a no-op
        store.startConnecting(
            fromNodeID: "a",
            fromHandleID: nil,
            fromHandleType: .source,
            fromHandlePosition: .right,
            fromPosition: XYPosition(x: 100, y: 25),
            at: XYPosition(x: 100, y: 25),
            mode: .reconnect(edgeID: "e1", isSource: false)
        )

        store.updateConnecting(
            to: XYPosition(x: 200, y: 25),
            targetNodeID: "b",
            targetHandleID: nil,
            targetHandlePosition: .left
        )

        let result = store.stopConnecting()
        #expect(result == nil)
        #expect(!store.runtimeState.connection.isConnecting)
    }

    // MARK: - Reconnect with new target

    @Test
    func testReconnectToNewTargetReturnsUpdatedConnection() {
        let nodeA = BaseNode(id: "a", position: XYPosition(x: 0, y: 0), data: EmptyPayload(), width: 100, height: 50)
        let nodeB = BaseNode(id: "b", position: XYPosition(x: 200, y: 0), data: EmptyPayload(), width: 100, height: 50)
        let nodeC = BaseNode(id: "c", position: XYPosition(x: 200, y: 200), data: EmptyPayload(), width: 100, height: 50)
        var existingEdge = BaseEdge<EmptyPayload>(id: "e1", source: "a", target: "b")
        existingEdge.sourcePosition = .right
        existingEdge.targetPosition = .left
        let store = GraphStore<EmptyPayload>(nodes: [nodeA, nodeB, nodeC], edges: [existingEdge])

        // Drag the target end of e1 to node c instead
        store.startConnecting(
            fromNodeID: "a",
            fromHandleID: nil,
            fromHandleType: .source,
            fromHandlePosition: .right,
            fromPosition: XYPosition(x: 100, y: 25),
            at: XYPosition(x: 100, y: 25),
            mode: .reconnect(edgeID: "e1", isSource: false)
        )

        store.updateConnecting(
            to: XYPosition(x: 200, y: 225),
            targetNodeID: "c",
            targetHandleID: nil,
            targetHandlePosition: .left
        )

        let result = store.stopConnecting()
        #expect(result != nil)
        #expect(result?.source == "a")
        #expect(result?.target == "c")
    }
}
