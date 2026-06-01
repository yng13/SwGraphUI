import XCTest
@testable import SwGraphUI

@MainActor
final class GraphStoreTests: XCTestCase {
    
    @MainActor
    func testStoreInitialState() {
        let node = BaseNode(id: "1", position: XYPosition(x: 100, y: 100), data: "test")
        let store = GraphStore(nodes: [node])
        
        XCTAssertEqual(store.nodes.count, 1)
        XCTAssertEqual(store.node(id: "1")?.id, "1")
    }
    
    @MainActor
    func testHierarchicalDragSync() {
        let parent = BaseNode(id: "p", position: XYPosition(x: 10, y: 10), data: "p")
        let child = BaseNode(id: "c", position: XYPosition(x: 5, y: 5), data: "c", parentID: "p")
        let store = GraphStore(nodes: [parent, child])
        
        // Start dragging child node (assume pointer is at absolute (15, 15)) | 子ノードのドラッグ開始（ポインタは絶対座標 15,15 の位置とする）
        store.startDragging(nodeIDs: ["c"], at: XYPosition(x: 15, y: 15))
        
        // Verify dragging flag | dragging フラグの確認
        XCTAssertTrue(store.nodes.first(where: { $0.id == "c" })?.dragging ?? false)
        XCTAssertFalse(store.nodes.first(where: { $0.id == "p" })?.dragging ?? true)
        
        // Move pointer to (20, 20) | ポインタを 20,20 へ移動
        store.updateDragging(to: XYPosition(x: 20, y: 20))
        
        // Verify new relative position of the child node | 子ノードの新しい相対位置を検証
        // Delta is (+5, +5) since it moved from absolute (15, 15) to (20, 20). | 変化分は +5,+5。元の絶対 15,15 から 20,20 なので。
        // Child's original relative was (5, 5). New relative should be (10, 10). | 子の元の相対は 5,5。新しい相対は 10,10 になるはず。
        let updatedChild = store.nodes.first { $0.id == "c" }!
        XCTAssertEqual(updatedChild.position.x, 10)
        XCTAssertEqual(updatedChild.position.y, 10)
        
        store.stopDragging()
        XCTAssertFalse(store.nodes.first(where: { $0.id == "c" })?.dragging ?? true)
    }
    
    @MainActor
    func testAbsolutePositionHierarchy() {
        let parent = BaseNode(id: "p", position: XYPosition(x: 100, y: 100), data: "p")
        let child = BaseNode(id: "c", position: XYPosition(x: 50, y: 50), data: "c", parentID: "p")
        let grandchild = BaseNode(id: "g", position: XYPosition(x: 20, y: 20), data: "g", parentID: "c")
        let store = GraphStore(nodes: [parent, child, grandchild])
        
        // Grandchild node's absolute coordinate: 100 + 50 + 20 = 170 | 孫ノードの絶対座標: 100 + 50 + 20 = 170
        let absPos = store.absolutePosition(for: "g")
        XCTAssertEqual(absPos.x, 170)
        XCTAssertEqual(absPos.y, 170)
    }

    @MainActor
    func testResolvedEdgeEndpointsSupportsNodeToPoint() {
        let node = BaseNode(
            id: "n1",
            position: XYPosition(x: 20, y: 40),
            data: "node",
            measured: Dimensions(width: 80, height: 40)
        )
        let edge = BaseEdge<String>(
            id: "floating",
            sourceEndpoint: .node(id: "n1", handleID: nil),
            targetEndpoint: .point(XYPosition(x: 60, y: 140)),
            kind: "smoothstep"
        )
        let store = GraphStore(nodes: [node], edges: [edge])

        let resolved = store.resolvedEdgeEndpoints(for: edge)

        XCTAssertEqual(resolved?.sourcePosition, .bottom)
        XCTAssertEqual(resolved?.sourcePoint, XYPosition(x: 60, y: 88))
        XCTAssertEqual(resolved?.targetPosition, .left)
        XCTAssertEqual(resolved?.targetPoint, XYPosition(x: 60, y: 140))
    }
    
    @MainActor
    func testStateIntegrityDuringDrag() {
        var node = BaseNode(id: "n1", position: .zero, data: "test")
        node.selected = true // Preset as selected | 事前に選択状態にしておく
        let store = GraphStore(nodes: [node])
        
        store.startDragging(nodeIDs: ["n1"], at: .zero)
        
        let draggedNode = store.nodes[0]
        XCTAssertTrue(draggedNode.dragging)
        XCTAssertTrue(draggedNode.selected, "selected state should not be broken when updating dragging | dragging 更新時に selected 状態が壊れてはいけない")
        
        store.stopDragging()
        XCTAssertFalse(store.nodes[0].dragging)
        XCTAssertTrue(store.nodes[0].selected)
    }
    
    func testCoordinateAdapterRoundTrip() {
        let viewport = Viewport(x: 100, y: 100, zoom: 2.0)
        let screenPoint = XYPosition(x: 200, y: 200)
        
        // screenToGraph: (200 - 100) / 2.0 = 50 | screenToGraph: (200 - 100) / 2.0 = 50
        let graphPoint = CoordinateAdapter.screenToGraph(screenPoint, viewport: viewport)
        XCTAssertEqual(graphPoint.x, 50)
        XCTAssertEqual(graphPoint.y, 50)
        
        // graphToScreen: 50 * 2.0 + 100 = 200 | graphToScreen: 50 * 2.0 + 100 = 200
        let roundTrip = CoordinateAdapter.graphToScreen(graphPoint, viewport: viewport)
        XCTAssertEqual(roundTrip.x, 200)
        XCTAssertEqual(roundTrip.y, 200)
    }

    // MARK: - Measurement Engine Tests
    
    @MainActor
    func testUpdateNodeDimensions() {
        let node = BaseNode(id: "1", position: .zero, data: "test")
        let store = GraphStore(nodes: [node])
        
        let newSize = Dimensions(width: 200, height: 100)
        store.updateNodeDimensions(id: "1", dimensions: newSize)
        
        XCTAssertEqual(store.nodes[0].measured, newSize)
        
        // Verify that instance is not unnecessarily changed on subsequent identical update | 再度の同値更新でインスタンスが不必要に変更されないことを確認
        store.updateNodeDimensions(id: "1", dimensions: newSize)
        XCTAssertEqual(store.nodes[0].measured, newSize)
    }
    
    @MainActor
    func testFitViewWithMeasuredDimensions() {
        // Node with unknown size (width=0) in initial state | 初期状態ではサイズ不明のノード (width=0)
        let node = BaseNode(id: "1", position: .zero, data: "test")
        let store = GraphStore(nodes: [node])
        
        let containerSize = Dimensions(width: 1000, height: 1000)
        
        // Reflect measured size (assume a huge 500x500 node) | 実測サイズを反映 (500x500の巨大なノードとする)
        let measuredSize = Dimensions(width: 500, height: 500)
        store.updateNodeDimensions(id: "1", dimensions: measuredSize)
        
        // fitView after reflecting measured size | 実測サイズ反映後の fitView
        store.fitView(in: containerSize, padding: .all(.points(0)))
        let zoomAfterMeasure = store.runtimeState.viewport.viewport.zoom
        
        // For 500x500 to fit in 1000x1000, zoom = 1000 / 500 = 2.0 | 500x500 が 1000x1000 に収まるには zoom = 1000 / 500 = 2.0
        XCTAssertEqual(zoomAfterMeasure, 2.0, accuracy: 0.0001)
    }

    @MainActor
    func testFitViewUsesContainerSizeByDefault() {
        let node = BaseNode(id: "1", position: .zero, data: "test", measured: Dimensions(width: 500, height: 500))
        let store = GraphStore(nodes: [node])

        store.setContainerSize(Dimensions(width: 1000, height: 1000))
        store.fitView(padding: .all(.points(0)))

        XCTAssertEqual(store.runtimeState.viewport.viewport.zoom, 2.0, accuracy: 0.0001)
    }

    @MainActor
    func testDragWithoutSnapGridPreservesExistingBehavior() {
        let node = BaseNode(id: "1", position: XYPosition(x: 5, y: 5), data: "test")
        let store = GraphStore(nodes: [node])

        store.startDragging(nodeIDs: ["1"], at: XYPosition(x: 15, y: 15))
        store.updateDragging(to: XYPosition(x: 32, y: 32))

        XCTAssertEqual(store.nodes[0].position.x, 22)
        XCTAssertEqual(store.nodes[0].position.y, 22)
    }

    @MainActor
    func testDragWithSnapGridSnapsNodePosition() {
        let node = BaseNode(id: "1", position: XYPosition(x: 5, y: 5), data: "test")
        let store = GraphStore(nodes: [node])
        store.setSnapGrid(SnapGrid(width: 20, height: 20))

        store.startDragging(nodeIDs: ["1"], at: XYPosition(x: 15, y: 15))
        store.updateDragging(to: XYPosition(x: 32, y: 32))

        XCTAssertEqual(store.nodes[0].position.x, 20)
        XCTAssertEqual(store.nodes[0].position.y, 20)
    }

    @MainActor
    func testDragWithSnapGridUsesGraphSpaceUnderZoom() {
        let node = BaseNode(id: "1", position: XYPosition(x: 5, y: 5), data: "test")
        let store = GraphStore(nodes: [node])
        store.setSnapGrid(SnapGrid(width: 20, height: 20))
        store.setViewport(Viewport(x: 100, y: 100, zoom: 0.35))

        store.startDragging(nodeIDs: ["1"], at: XYPosition(x: 15, y: 15))
        store.updateDragging(to: XYPosition(x: 32, y: 32))

        XCTAssertEqual(store.nodes[0].position.x, 20)
        XCTAssertEqual(store.nodes[0].position.y, 20)
    }

    @MainActor
    func testDragWithSnapGridMovesMultiSelectionDeterministically() {
        var node1 = BaseNode(id: "1", position: XYPosition(x: 5, y: 5), data: "a")
        var node2 = BaseNode(id: "2", position: XYPosition(x: 25, y: 25), data: "b")
        node1.selected = true
        node2.selected = true
        let store = GraphStore(nodes: [node1, node2])
        store.runtimeState.selection.selectNode(id: "1")
        store.runtimeState.selection.selectNode(id: "2")
        store.setSnapGrid(SnapGrid(width: 20, height: 20))

        store.startDragging(nodeIDs: ["1", "2"], at: XYPosition(x: 15, y: 15))
        store.updateDragging(to: XYPosition(x: 32, y: 32))

        XCTAssertEqual(store.node(id: "1")?.position, XYPosition(x: 20, y: 20))
        XCTAssertEqual(store.node(id: "2")?.position, XYPosition(x: 40, y: 40))
    }

    @MainActor
    func testDragWithSnapGridPreservesUndoRedo() {
        let undoManager = UndoManager()
        let node = BaseNode(id: "1", position: XYPosition(x: 5, y: 5), data: "test")
        let store = GraphStore(nodes: [node], undoManager: undoManager)
        store.setSnapGrid(SnapGrid(width: 20, height: 20))

        store.startDragging(nodeIDs: ["1"], at: XYPosition(x: 15, y: 15))
        store.updateDragging(to: XYPosition(x: 32, y: 32))
        store.stopDragging()

        XCTAssertEqual(store.nodes[0].position, XYPosition(x: 20, y: 20))

        undoManager.undo()
        XCTAssertEqual(store.nodes[0].position, XYPosition(x: 5, y: 5))

        undoManager.redo()
        XCTAssertEqual(store.nodes[0].position, XYPosition(x: 20, y: 20))
    }

    @MainActor
    func testDragWithSnapGridStillRespectsParentExtent() {
        let parent = BaseNode(
            id: "p",
            position: XYPosition(x: 0, y: 0),
            data: "parent",
            measured: Dimensions(width: 100, height: 100)
        )
        let child = BaseNode(
            id: "c",
            position: XYPosition(x: 10, y: 10),
            data: "child",
            parentID: "p",
            extent: .parent,
            measured: Dimensions(width: 20, height: 20)
        )
        let store = GraphStore(nodes: [parent, child])
        store.setSnapGrid(SnapGrid(width: 20, height: 20))

        store.startDragging(nodeIDs: ["c"], at: XYPosition(x: 10, y: 10))
        store.updateDragging(to: XYPosition(x: 98, y: 98))

        XCTAssertEqual(store.node(id: "c")?.position, XYPosition(x: 80, y: 80))
    }

    @MainActor
    func testResolvedHandlePositionIsStableAcrossViewportZoomLevels() {
        let node = BaseNode(id: "1", position: XYPosition(x: 10, y: 20), data: "test", measured: Dimensions(width: 132, height: 60))
        let store = GraphStore(nodes: [node])
        let key = HandleKey(nodeID: "1", handleID: nil, type: .source, placement: .right)

        store.runtimeState.viewport.setViewport(Viewport(x: 0, y: 0, zoom: 0.35))
        let posAt035 = store.resolvedHandlePosition(for: key)

        store.runtimeState.viewport.setViewport(Viewport(x: 0, y: 0, zoom: 1.0))
        let posAt100 = store.resolvedHandlePosition(for: key)

        store.runtimeState.viewport.setViewport(Viewport(x: 0, y: 0, zoom: 2.0))
        let posAt200 = store.resolvedHandlePosition(for: key)

        XCTAssertEqual(posAt035.x, 150, accuracy: 0.0001)
        XCTAssertEqual(posAt035.y, 50, accuracy: 0.0001)
        XCTAssertEqual(posAt100.x, posAt035.x, accuracy: 0.0001)
        XCTAssertEqual(posAt100.y, posAt035.y, accuracy: 0.0001)
        XCTAssertEqual(posAt200.x, posAt035.x, accuracy: 0.0001)
        XCTAssertEqual(posAt200.y, posAt035.y, accuracy: 0.0001)
    }

    @MainActor
    func testResolvedHandlePositionUsesConfigurableAnchorOffset() {
        let node = BaseNode(id: "1", position: XYPosition(x: 10, y: 20), data: "test", measured: Dimensions(width: 100, height: 60))
        let store = GraphStore(nodes: [node])
        let key = HandleKey(nodeID: "1", handleID: nil, type: .source, placement: .right)

        store.runtimeState.handleAnchorOffset = 12
        let resolved = store.resolvedHandlePosition(for: key)

        XCTAssertEqual(resolved.x, 122, accuracy: 0.0001)
        XCTAssertEqual(resolved.y, 50, accuracy: 0.0001)
    }

    @MainActor
    func testResolvedEdgePositionsAutoSelectsHorizontalSides() {
        let source = BaseNode(id: "s", position: XYPosition(x: 0, y: 0), data: "s", measured: Dimensions(width: 100, height: 60))
        let target = BaseNode(id: "t", position: XYPosition(x: 300, y: 20), data: "t", measured: Dimensions(width: 100, height: 60))
        let edge = BaseEdge<String>(id: "e", source: "s", target: "t")
        let store = GraphStore(nodes: [source, target], edges: [edge])

        let resolved = store.resolvedEdgePositions(for: edge)
        XCTAssertEqual(resolved.source, .right)
        XCTAssertEqual(resolved.target, .left)
    }

    @MainActor
    func testResolvedEdgePositionsAutoSelectsVerticalSides() {
        let source = BaseNode(id: "s", position: XYPosition(x: 40, y: 0), data: "s", measured: Dimensions(width: 100, height: 60))
        let target = BaseNode(id: "t", position: XYPosition(x: 50, y: 260), data: "t", measured: Dimensions(width: 100, height: 60))
        let edge = BaseEdge<String>(id: "e", source: "s", target: "t")
        let store = GraphStore(nodes: [source, target], edges: [edge])

        let resolved = store.resolvedEdgePositions(for: edge)
        XCTAssertEqual(resolved.source, .bottom)
        XCTAssertEqual(resolved.target, .top)
    }

    @MainActor
    func testEdgeRoutingControlsStepSplitPosition() {
        let edge = BaseEdge<String>(
            id: "e",
            source: "s",
            target: "t",
            kind: "step",
            routing: EdgeRouting(stepPosition: 0.25)
        )
        let store = GraphStore(nodes: [], edges: [edge])

        let path = store.laneAdjustedPath(
            for: edge,
            source: XYPosition(x: 0, y: 0),
            target: XYPosition(x: 100, y: 100),
            sourcePosition: .bottom,
            targetPosition: .top
        )

        XCTAssertTrue(path.path.contains("L0.0,35.0"))
        XCTAssertTrue(path.path.contains("L100.0,35.0"))
        XCTAssertEqual(path.labelY, 35, accuracy: 0.0001)
    }

    func testEdgeRoutingRoundTripsThroughCodable() throws {
        let edge = BaseEdge<String>(
            id: "e",
            source: "s",
            target: "t",
            kind: "smoothstep",
            routing: EdgeRouting(centerX: 42, centerY: 84, stepPosition: 0.25)
        )

        let data = try JSONEncoder().encode(edge)
        let decoded = try JSONDecoder().decode(BaseEdge<String>.self, from: data)

        XCTAssertEqual(decoded.routing, EdgeRouting(centerX: 42, centerY: 84, stepPosition: 0.25))
    }

    @MainActor
    func testResolvedEdgePositionsPreferHorizontalOnDiagonalTie() {
        let source = BaseNode(id: "s", position: XYPosition(x: 0, y: 0), data: "s", measured: Dimensions(width: 100, height: 100))
        let target = BaseNode(id: "t", position: XYPosition(x: 200, y: 200), data: "t", measured: Dimensions(width: 100, height: 100))
        let edge = BaseEdge<String>(id: "e", source: "s", target: "t")
        let store = GraphStore(nodes: [source, target], edges: [edge])

        let resolved = store.resolvedEdgePositions(for: edge)
        XCTAssertEqual(resolved.source, .right)
        XCTAssertEqual(resolved.target, .left)
    }

    @MainActor
    func testResolvedEdgePositionsPrefersHandlePlacementOverAutoSide() {
        let source = BaseNode(
            id: "s",
            position: XYPosition(x: 0, y: 0),
            data: "s",
            handles: [NodeHandle(id: "out", placement: .top, type: .source)],
            measured: Dimensions(width: 100, height: 60)
        )
        let target = BaseNode(id: "t", position: XYPosition(x: 300, y: 0), data: "t", measured: Dimensions(width: 100, height: 60))
        let edge = BaseEdge<String>(id: "e", source: "s", target: "t", sourceHandle: "out")
        let store = GraphStore(nodes: [source, target], edges: [edge])

        let resolved = store.resolvedEdgePositions(for: edge)
        XCTAssertEqual(resolved.source, .top)
        XCTAssertEqual(resolved.target, .left)
    }

    @MainActor
    func testAutomaticPeerSideHandleChoosesPeerDirection() {
        let source = BaseNode(
            id: "s",
            position: XYPosition(x: 0, y: 200),
            data: "s",
            handles: [NodeHandle(id: "out", placement: .right, type: .source, placementMode: .automaticPeerSide)],
            measured: Dimensions(width: 100, height: 60)
        )
        let target = BaseNode(id: "t", position: XYPosition(x: 20, y: 0), data: "t", measured: Dimensions(width: 100, height: 60))
        let edge = BaseEdge<String>(id: "e", source: "s", target: "t", sourceHandle: "out")
        let store = GraphStore(nodes: [source, target], edges: [edge])

        let resolved = store.resolvedEdgePositions(for: edge)
        XCTAssertEqual(resolved.source, .top)
        XCTAssertEqual(resolved.target, .bottom)
    }

    @MainActor
    func testAutomaticNodeHandlePlacementUsesConnectedPeerDirection() {
        let source = BaseNode(
            id: "s",
            position: XYPosition(x: 0, y: 200),
            data: "s",
            handles: [NodeHandle(id: "out", placement: .right, type: .source, placementMode: .automaticPeerSide)],
            measured: Dimensions(width: 100, height: 60)
        )
        let target = BaseNode(id: "t", position: XYPosition(x: 20, y: 0), data: "t", measured: Dimensions(width: 100, height: 60))
        let edge = BaseEdge<String>(id: "e", source: "s", target: "t", sourceHandle: "out")
        let store = GraphStore(nodes: [source, target], edges: [edge])

        let placement = store.resolvedNodeHandlePlacement(nodeID: "s", handleID: "out", type: .source)

        XCTAssertEqual(placement, .top)
    }

    @MainActor
    func testAutomaticBoundsHandlesDistributeOnSameSide() {
        let source = BaseNode(
            id: "s",
            position: .zero,
            data: "s",
            handles: [
                NodeHandle(id: "a", placement: .right, type: .source, placementMode: .automaticPeerSide),
                NodeHandle(id: "b", placement: .right, type: .source, placementMode: .automaticPeerSide)
            ],
            measured: Dimensions(width: 100, height: 60)
        )
        let target = BaseNode(id: "t", position: XYPosition(x: 300, y: 0), data: "t", measured: Dimensions(width: 100, height: 60))
        let edges = [
            BaseEdge<String>(id: "e1", source: "s", target: "t", sourceHandle: "a"),
            BaseEdge<String>(id: "e2", source: "s", target: "t", sourceHandle: "b")
        ]
        let store = GraphStore(nodes: [source, target], edges: edges)

        let a = store.resolvedHandlePosition(for: HandleKey(nodeID: "s", handleID: "a", type: .source, placement: .right))
        let b = store.resolvedHandlePosition(for: HandleKey(nodeID: "s", handleID: "b", type: .source, placement: .right))

        XCTAssertEqual(a.x, 100, accuracy: 0.0001)
        XCTAssertEqual(b.x, 100, accuracy: 0.0001)
        XCTAssertNotEqual(a.y, b.y, accuracy: 0.0001)
        XCTAssertGreaterThan(a.y, 16)
        XCTAssertLessThan(b.y, 44)
    }

    @MainActor
    func testAutomaticBoundsHandleIgnoresMeasuredManualHandlePosition() {
        let source = BaseNode(
            id: "s",
            position: .zero,
            data: "s",
            handles: [NodeHandle(id: "out", placement: .right, type: .source, placementMode: .automaticPeerSide)],
            measured: Dimensions(width: 100, height: 60)
        )
        let target = BaseNode(id: "t", position: XYPosition(x: 300, y: 0), data: "t", measured: Dimensions(width: 100, height: 60))
        let edge = BaseEdge<String>(id: "e", source: "s", target: "t", sourceHandle: "out")
        let store = GraphStore(nodes: [source, target], edges: [edge])
        let key = HandleKey(nodeID: "s", handleID: "out", type: .source, placement: .right)

        store.updateHandlePosition(key: key, absolutePosition: XYPosition(x: 999, y: 999))
        let resolved = store.resolvedHandlePosition(for: key)

        XCTAssertEqual(resolved.x, 100, accuracy: 0.0001)
        XCTAssertEqual(resolved.y, 30, accuracy: 0.0001)
    }
    
    @MainActor
    func testMoveSelectedNodes() {
        let n1 = BaseNode(id: "1", position: XYPosition(x: 10, y: 10), data: "1")
        let n2 = BaseNode(id: "2", position: XYPosition(x: 100, y: 100), data: "2")
        let store = GraphStore(nodes: [n1, n2])
        
        // 1. Select node 1 only | 1. ノード1のみ選択
        store.selectNode("1")
        
        // 2. Move (+5, -2) | 2. 移動 (+5, -2)
        store.moveSelectedNodes(by: XYPosition(x: 5, y: -2))
        
        XCTAssertEqual(store.node(id: "1")?.position.x, 15)
        XCTAssertEqual(store.node(id: "1")?.position.y, 8)
        XCTAssertEqual(store.node(id: "2")?.position.x, 100, "Unselected nodes should not move | 非選択ノードは動いてはいけない")
        
        // 3. Relative movement in multi-selection | 3. 複数選択での相対移動
        store.toggleNodeSelection("2") // Add 2 while 1 is selected | 1が選択されている状態で2も追加
        store.moveSelectedNodes(by: XYPosition(x: 10, y: 10))
        
        XCTAssertEqual(store.node(id: "1")?.position.x, 25)
        XCTAssertEqual(store.node(id: "2")?.position.x, 110)
        
        // 4. Set individual nodes to undraggable | 4. 個別のノードをドラッグ不可に設定
        store.nodes[0].draggable = false // Lock node 1 | ノード1をロック
        store.moveSelectedNodes(by: XYPosition(x: 100, y: 100))
        XCTAssertEqual(store.node(id: "1")?.position.x, 25, "Individually locked node 1 should not move | 個別ロック中のノード1は動いてはいけない")
        XCTAssertEqual(store.node(id: "2")?.position.x, 210, "Unlocked node 2 should move | ロックされていないノード2は動くべき")
        
        // 5. Guard for global drag prohibition state | 5. グローバルなドラッグ禁止状態でのガード
        store.runtimeState.interactivity.nodesDraggable = false
        store.moveSelectedNodes(by: XYPosition(x: 1000, y: 1000))
        XCTAssertEqual(store.node(id: "2")?.position.x, 210, "Nodes should not move during global prohibition | グローバル禁止時は全ノード動いてはいけない")
    }
    
    @MainActor
    func testUndoRedoNodeMovement() {
        let store = GraphStore<String>(
            nodes: [BaseNode(id: "1", position: .zero, data: "test")],
            undoManager: UndoManager()
        )
        
        // 1. Movement | 1. 移動
        store.startDragging(nodeIDs: ["1"], at: .zero)
        store.updateDragging(to: XYPosition(x: 50, y: 50))
        store.stopDragging()
        
        XCTAssertEqual(store.node(id: "1")?.position.x, 50)
        
        // 2. Undo | 2. Undo
        store.undoManager?.undo()
        XCTAssertEqual(store.node(id: "1")?.position.x, 0, "Undo should restore original position | Undo で元の位置に戻るべき")
        
        // 3. Redo | 3. Redo
        store.undoManager?.redo()
        XCTAssertEqual(store.node(id: "1")?.position.x, 50, "Redo should restore position after movement | Redo で移動後の位置に戻るべき")
    }
    
    @MainActor
    func testUndoRedoDeletion() {
        let store = GraphStore<String>(
            nodes: [BaseNode(id: "1", position: .zero, data: "test")],
            undoManager: UndoManager()
        )
        
        // 1. Select and delete | 1. 選択して削除
        store.selectNode("1")
        store.deleteSelection()
        XCTAssertTrue(store.nodes.isEmpty)
        
        // 2. Undo | 2. Undo
        store.undoManager?.undo()
        XCTAssertEqual(store.nodes.count, 1, "Undo should restore the node | Undo でノードが復活すべき")
        XCTAssertEqual(store.nodes[0].id, "1")
        
        // 3. Redo | 3. Redo
        store.undoManager?.redo()
        XCTAssertTrue(store.nodes.isEmpty, "Redo should execute deletion again | Redo で再び削除されるべき")
    }
}
