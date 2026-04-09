import Testing
import Foundation
@testable import SwGraphUI

@Suite struct InteractionTests {
    
    // 1. ドラッグ中に複数ノードの相対配置が維持されること
    @Test func multiDragPreservesRelativeDistances() async throws {
        let node1 = Node(id: "n1", position: .init(x: 10, y: 10), data: EmptyPayload())
        let node2 = Node(id: "n2", position: .init(x: 50, y: 50), data: EmptyPayload())
        let nodes: [String: Node] = ["n1": node1, "n2": node2]
        
        // ドラッグ開始
        let pointerStart = XYPosition(x: 100, y: 100)
        let items = [
            NodeDragItem(id: "n1", lastPosition: node1.position, distance: .init(x: pointerStart.x - node1.position.x, y: pointerStart.y - node1.position.y)),
            NodeDragItem(id: "n2", lastPosition: node2.position, distance: .init(x: pointerStart.x - node2.position.x, y: pointerStart.y - node2.position.y))
        ]
        
        // 50, 50 移動
        let pointerCurrent = XYPosition(x: 150, y: 150)
        let nextPositions = DragManager.calculateNextPositions(
            draggedNodes: items,
            pointer: pointerCurrent,
            nodeLookup: nodes
        )
        
        let p1 = nextPositions["n1"]!
        let p2 = nextPositions["n2"]!
        
        #expect(p1 == .init(x: 60, y: 60))
        #expect(p2 == .init(x: 100, y: 100))
        #expect(p2.x - p1.x == 40)
        #expect(p2.y - p1.y == 40)
    }
    
    // 2. Extent 適用時に clamp された結果でも snap が破綻しないこと (Snap -> Extent)
    @Test func snapThenExtentOrdering() async throws {
        let node = Node(id: "n1", position: .init(x: 0, y: 0), data: EmptyPayload(), extent: .coordinate(CoordinateExtent(min: .zero, max: .init(x: 50, y: 50))), measured: .init(width: 10, height: 10))
        let items = [NodeDragItem(id: "n1", lastPosition: .zero, distance: .zero)]
        
        // SnapGrid: 20, Extent: 0...50, Size: 10x10
        // ポインタが 45 にある場合:
        // 1. Snap -> 40
        // 2. Extent (0...40) -> 40
        let next = DragManager.calculateNextPositions(
            draggedNodes: items,
            pointer: .init(x: 45, y: 0),
            nodeLookup: ["n1": node],
            snapGrid: SnapGrid(width: 20, height: 20)
        )
        #expect(next["n1"]!.x == 40)
        
        // ポインタが 55 にある場合:
        // 1. Snap -> 60
        // 2. Extent (0...40) -> 40 (Clamp wins)
        let next2 = DragManager.calculateNextPositions(
            draggedNodes: items,
            pointer: .init(x: 55, y: 0),
            nodeLookup: ["n1": node],
            snapGrid: SnapGrid(width: 20, height: 20)
        )
        #expect(next2["n1"]!.x == 40)
    }
    
    // 3. zoom at point で、指定 screen point に対応する graph point が保存されること
    @Test func zoomAtPointInvariance() async throws {
        let initialViewport = Viewport(x: 100, y: 100, zoom: 1.0)
        let screenPoint = XYPosition(x: 200, y: 200)
        
        // ズーム前の screenPoint に対応する graphPoints を計算
        // graphX = (screenPoint.x - viewport.x) / zoom = (200 - 100) / 1.0 = 100
        let graphPointBefore = XYPosition(
            x: (screenPoint.x - initialViewport.x) / initialViewport.zoom,
            y: (screenPoint.y - initialViewport.y) / initialViewport.zoom
        )
        
        // 2倍ズーム
        let newViewport = ViewportManager.calculateZoomAtPoint(
            current: initialViewport,
            factor: 2.0,
            at: screenPoint,
            minZoom: 0.1,
            maxZoom: 5.0
        )
        
        // ズーム後の screenPoint に対応する graphPoints を再計算
        let graphPointAfter = XYPosition(
            x: (screenPoint.x - newViewport.x) / newViewport.zoom,
            y: (screenPoint.y - newViewport.y) / newViewport.zoom
        )
        
        #expect(abs(graphPointBefore.x - graphPointAfter.x) < 0.001)
        #expect(abs(graphPointBefore.y - graphPointAfter.y) < 0.001)
        #expect(newViewport.zoom == 2.0)
    }
    
    // 4. fitView が空ノード配列で壊れないこと
    @Test func fitViewHandlesEmptyNodesSafely() async throws {
        let size = Dimensions(width: 800, height: 600)
        let viewport = ViewportManager.calculateFitView(
            nodes: [Node](),
            in: size,
            minZoom: 0.1,
            maxZoom: 5.0,
            padding: .all(.points(0))
        )
        
        // デフォルト値が返されること
        #expect(viewport.zoom == 1.0)
        #expect(viewport.x == 400)
        #expect(viewport.y == 300)
    }
}
