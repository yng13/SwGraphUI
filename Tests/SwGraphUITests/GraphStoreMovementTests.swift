import Testing
import SwiftUI
@testable import SwGraphUI

@MainActor
struct GraphStoreMovementTests {
    
    @Test
    func moveSelectedNodesMovesAllSelectedNodes() async throws {
        let store = GraphStore<String>()
        
        // Setup: Parent group (p), its child (c), and a regular node (r) | 準備: 親グループ(p), その子(c), 独立ノード(r)
        let p = BaseNode(id: "p", position: XYPosition(x: 100, y: 100), data: "Parent", width: 200, height: 200)
        let c = BaseNode(id: "c", position: XYPosition(x: 10, y: 10), data: "Child", parentID: "p", width: 50, height: 50)
        let r = BaseNode(id: "r", position: XYPosition(x: 400, y: 400), data: "Regular", width: 50, height: 50)
        
        store.nodes = [p, c, r]
        
        // Select all | 全選択
        store.selectAll()
        
        // Move by (10, 10) | (10, 10) 移動
        store.moveSelectedNodes(by: XYPosition(x: 10, y: 10))
        
        // Verification: | 検証:
        // Regular (r): (400, 400) -> (410, 410) | Regular (r): (400, 400) -> (410, 410)
        let nodeR = store.nodes.first(where: { $0.id == "r" })!
        #expect(nodeR.position == XYPosition(x: 410, y: 410), "Regular node should move by offset")
        
        // Parent (p): (100, 100) -> (110, 110) | Parent (p): (100, 100) -> (110, 110)
        let nodeP = store.nodes.first(where: { $0.id == "p" })!
        #expect(nodeP.position == XYPosition(x: 110, y: 110), "Parent node should move by offset")
        
        // Child (c):
        // Expected: stays at relative (10, 10). | 期待値: 相対座標 (10, 10) のまま。
        // Because if the parent moves (10, 10), the absolute position is automatically incremented by (10, 10). | なぜなら親が (10, 10) 動けば、絶対座標としては自動的に (10, 10) 加算されるため。
        let nodeC = store.nodes.first(where: { $0.id == "c" })!
        
        // Note: If the current implementation is "add offset to absolute and convert back to relative," | 注意: もし現在の実装が「絶対座標に offset を足して相対に戻す」であり、
        // and calculated using the parent's old position: | かつ親の old position を使って計算しているなら:
        // currentAbs = (OldParent 100 + Relative 10) = 110 | currentAbs = (OldParent 100 + Relative 10) = 110
        // targetAbs = 110 + 10 = 120 | targetAbs = 110 + 10 = 120
        // resultRelative = 120 - OldParent 100 = 20 | resultRelative = 120 - OldParent 100 = 20
        // Here, the relative coordinate becomes (20, 20), and along with the parent's (10, 10) move, would result in an absolute (20, 20) shift. | これだと相対座標が (20, 20) になり、親の移動 (10, 10) と合わさって絶対的には (20, 20) 動いたことになる。
        
        #expect(nodeC.position == XYPosition(x: 10, y: 10), "Child relative position should NOT change if parent is also moving by the same offset")
    }
}
