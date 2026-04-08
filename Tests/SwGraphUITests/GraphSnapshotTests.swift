import Testing
import Foundation
@testable import SwGraphUI

@MainActor
struct GraphSnapshotTests {
    @Test func testSnapshotRoundTrip() throws {
        let store = GraphStore<EmptyPayload>()
        
        let nodes = [
            BaseNode(id: "n1", position: XYPosition(x: 10, y: 20), data: EmptyPayload(), resizable: false),
            BaseNode(id: "n2", position: XYPosition(x: 100, y: 200), data: EmptyPayload(), parentID: "n1")
        ]
        let edges = [
            BaseEdge<EmptyPayload>(
                id: "e1",
                source: "n1",
                target: "n2",
                markerEnd: EdgeMarker(type: .arrowClosed, color: "#ff0000"),
                label: "Edge Label"
            )
        ]
        
        let viewport = Viewport(x: 5, y: 5, zoom: 1.5)
        
        store.nodes = nodes
        store.edges = edges
        store.setViewport(viewport)
        store.selectNode("n1") // 選択状態にする
        
        // 1. Snapshot 作成
        let snapshot = store.snapshot()
        
        // 2. JSON シリアライズ
        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        
        // 3. デシリアライズ
        let decoder = JSONDecoder()
        let restoredSnapshot = try decoder.decode(GraphSnapshot<EmptyPayload>.self, from: data)
        
        // 4. 新しいストアに適用
        let newStore = GraphStore<EmptyPayload>()
        newStore.apply(snapshot: restoredSnapshot)
        
        // 5. 検証
        #expect(newStore.nodes.count == 2)
        #expect(newStore.edges.count == 1)
        #expect(newStore.runtimeState.viewport.viewport == viewport)
        
        // configuration が保たれているか
        #expect(newStore.nodes[0].resizable == false)
        #expect(newStore.nodes[1].parentID == "n1")
        
        // エッジの属性が保たれているか
        #expect(newStore.edges[0].markerEnd?.type == .arrowClosed)
        #expect(newStore.edges[0].markerEnd?.color == "#ff0000")
        #expect(newStore.edges[0].label == "Edge Label")
        
        // 選択状態がクリアされているか (一括置換 + apply 時のクリア両方で保証)
        #expect(newStore.nodes[0].selected == false)
        #expect(newStore.selectedNodes.isEmpty)
    }
}
