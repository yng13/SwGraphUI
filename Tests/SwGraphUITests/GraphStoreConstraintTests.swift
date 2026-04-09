import Testing
import Foundation
import CoreGraphics
@testable import SwGraphUI

@MainActor
struct GraphStoreConstraintTests {
    
    @Test
    func testUpdateNodePositionWithParentExtent() {
        // Setup: Parent (200x200) and Child (50x50)
        let parent = BaseNode(id: "parent", position: XYPosition(x: 100, y: 100), data: EmptyPayload(), width: 200, height: 200)
        var child = BaseNode(id: "child", position: XYPosition(x: 0, y: 0), data: EmptyPayload(), width: 50, height: 50)
        child.parentID = "parent"
        child.extent = NodeExtent.parent
        
        let store = GraphStore<EmptyPayload>(nodes: [parent, child])
        
        // 1. Valid move within parent (0,0 -> 10,10)
        store.updateNodePosition(id: "child", position: XYPosition(x: 10, y: 10))
        #expect(store.nodeLookup["child"]?.position == XYPosition(x: 10, y: 10))
        
        // 2. Out of bounds move (bottom-right)
        // Child is 50x50, parent is 200x200. Max relative pos is (150, 150)
        store.updateNodePosition(id: "child", position: XYPosition(x: 160, y: 160))
        #expect(store.nodeLookup["child"]?.position == XYPosition(x: 150, y: 150))
        
        // 3. Out of bounds move (top-left)
        store.updateNodePosition(id: "child", position: XYPosition(x: -10, y: -10))
        #expect(store.nodeLookup["child"]?.position == XYPosition(x: 0, y: 0))
    }
    
    @Test
    func testUpdateNodePositionWithCoordinateExtent() {
        // Setup: Node with absolute coordinate extent [0, 0, 500, 500]
        let extent = CoordinateExtent(minX: 0, minY: 0, maxX: 500, maxY: 500)
        var node = BaseNode(id: "node", position: XYPosition(x: 100, y: 100), data: EmptyPayload(), width: 50, height: 50)
        node.extent = NodeExtent.coordinate(extent)
        
        let store = GraphStore<EmptyPayload>(nodes: [node])
        
        // 1. Valid move
        store.updateNodePosition(id: "node", position: XYPosition(x: 200, y: 200))
        #expect(store.nodeLookup["node"]?.position == XYPosition(x: 200, y: 200))
        
        // 2. Out of bounds (right: 500 - 50 = 450)
        store.updateNodePosition(id: "node", position: XYPosition(x: 460, y: 200))
        #expect(store.nodeLookup["node"]?.position == XYPosition(x: 450, y: 200))
        
        // 3. Out of bounds (top: 0)
        store.updateNodePosition(id: "node", position: XYPosition(x: 200, y: -50))
        #expect(store.nodeLookup["node"]?.position == XYPosition(x: 200, y: 0))
    }
}
