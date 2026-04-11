import XCTest
import Foundation
@testable import SwGraphUI

@MainActor
final class PerformanceMatrixTests: XCTestCase {
    
    // 補助メソッド: 高精度な時間計測用
    private func measureTime<T>(_ title: String, operation: () throws -> T) rethrows -> (T, Double) {
        let start = DispatchTime.now()
        let result = try operation()
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        let milliTime = Double(nanoTime) / 1_000_000.0
        return (result, milliTime)
    }

    /// 1. Construction Smoke Test
    /// 1,000 nodes / 999 edges のグラフを線形で構築し、整合性と所要時間をログ出力。
    func testLargeGraphConstructionSmoke() throws {
        var nodes: [BaseNode<String>] = []
        var edges: [BaseEdge<String>] = []
        
        let (_, time) = measureTime("Construction") {
            for i in 0..<1000 {
                nodes.append(BaseNode(id: "\(i)", position: XYPosition(x: Double(i) * 100, y: 0), data: "Node \(i)"))
                if i > 0 {
                    edges.append(BaseEdge(id: "e\(i)", source: "\(i-1)", target: "\(i)"))
                }
            }
        }
        
        let store = GraphStore(nodes: nodes, edges: edges)
        XCTAssertEqual(store.nodes.count, 1000)
        XCTAssertEqual(store.edges.count, 999)
        
        print("[Perf] Milestone 35 Construction Baseline: construct=\(String(format: "%.2f", time))ms")
    }
    
    /// 2. Selection & Snapshot Smoke Test
    /// selectAll() および snapshot() の実行コストを計測。
    func testLargeGraphSelectionAndSnapshotSmoke() throws {
        let store = GraphStore<String>()
        for i in 0..<1000 {
            store.nodes.append(BaseNode(id: "\(i)", position: XYPosition(x: Double(i) * 50, y: 0), data: "Node \(i)"))
            if i > 0 {
                store.edges.append(BaseEdge(id: "e\(i)", source: "\(i-1)", target: "\(i)"))
            }
        }
        
        let (_, selectTime) = measureTime("SelectAll") {
            store.selectAll()
        }
        
        let (_, snapshotTime) = measureTime("Snapshot") {
            _ = store.snapshot()
        }
        
        XCTAssertEqual(store.runtimeState.selection.selectedNodeIDs.count, 1000)
        
        print("[Perf] Milestone 35 Selection Baseline: selectAll=\(String(format: "%.2f", selectTime))ms snapshot=\(String(format: "%.2f", snapshotTime))ms")
    }
    
    /// 3. Move & Undo Smoke Test
    /// 全選択ノード移動と Undo/Redo の計測。
    func testLargeGraphMoveUndoSmoke() throws {
        let undoManager = UndoManager()
        let store = GraphStore<String>(undoManager: undoManager)
        for i in 0..<1000 {
            store.nodes.append(BaseNode(id: "\(i)", position: XYPosition(x: Double(i) * 50, y: 0), data: "Node \(i)"))
        }
        store.selectAll()
        
        let (_, moveTime) = measureTime("Move") {
            store.moveSelectedNodes(by: XYPosition(x: 10, y: 10))
        }
        
        let (_, undoTime) = measureTime("Undo") {
            undoManager.undo()
        }
        
        let (_, redoTime) = measureTime("Redo") {
            undoManager.redo()
        }
        
        XCTAssertEqual(store.nodes.first?.position.x, 10)
        
        print("[Perf] Milestone 35 Move Baseline: move=\(String(format: "%.2f", moveTime))ms undo=\(String(format: "%.2f", undoTime))ms redo=\(String(format: "%.2f", redoTime))ms")
    }
    
    /// 4. Layout Smoke Test
    /// applyLayout (Tree Style) の 1,000 ノードに対する適用時間を計測。
    /// 比較の安定のため、単純な chain 構造のグラフを使用。
    func testLargeGraphLayoutSmoke() throws {
        var nodes: [BaseNode<String>] = []
        var edges: [BaseEdge<String>] = []
        for i in 0..<1000 {
            nodes.append(BaseNode(id: "\(i)", position: .zero, data: "Node \(i)"))
            if i > 0 {
                edges.append(BaseEdge(id: "e\(i)", source: "\(i-1)", target: "\(i)"))
            }
        }
        let store = GraphStore(nodes: nodes, edges: edges)
        
        let (_, layoutTime) = measureTime("Layout") {
            store.applyLayout(direction: .topToBottom, spacing: 50)
        }
        
        XCTAssertEqual(store.nodes.count, 1000)
        // 少なくとも初期位置 .zero から移動していることを確認
        XCTAssertNotEqual(store.nodes.last?.position, .zero)
        
        print("[Perf] Milestone 35 Layout Baseline: layout=\(String(format: "%.2f", layoutTime))ms")
    }
}
