import Testing
@testable import SwGraphUI
import SwiftUI
import Foundation

@Suite struct PNGExporterTests {
    @MainActor
    @Test func exportBoundsIncludesBezierControlPoints() async throws {
        let store = GraphStore<String>()
        
        // 2つのノードを配置。n2 を下方にずらし、上面同士を繋ぐことで大きな上向きの曲線を作る
        let n1 = BaseNode(id: "n1", position: XYPosition(x: 0, y: 0), data: "node1")
        let n2 = BaseNode(id: "n2", position: XYPosition(x: 200, y: 200), data: "node2")
        
        store.nodes = [n1, n2]
        store.updateNodeDimensions(id: "n1", dimensions: Dimensions(width: 50, height: 50))
        store.updateNodeDimensions(id: "n2", dimensions: Dimensions(width: 50, height: 50))
        
        // ベジェ曲線エッジを追加。上面(Top)から上面(Top)に繋ぐことで、上に大きく膨らませる
        store.edges = [
            BaseEdge<String>(
                id: "e1",
                source: "n1",
                target: "n2",
                kind: "default",
                sourcePosition: .top, 
                targetPosition: .top,
                curvature: 1.5
            )
        ]
        
        let exporter = PNGExporter(store: store)
        let bounds = try #require(exporter.calculateExportBounds())
        
        // 1. 直線的なノード範囲 (0,0) to (250,50) を超えて、曲線が上に張り出していること
        // 上面(Top)接続点は y=0 付近。高い曲率 (1.5) のベジェは y = -100 以下まで膨らむ計算
        #expect(bounds.y < -50, "曲線エッジの制御点による膨らみが Bounds に含まれている必要があります")
        
        // 2. 安全マージン (4pt) が適用されていることの確認
        // ノード n1 (0,0,50,50) の左端は 0 だが、マージンにより -4 になるはず
        #expect(bounds.x <= -4)
        
        // 3. 右端も同様。n2 (200,0,50,50) の右端 250 にマージン +4 で 254 以上
        #expect(bounds.x + bounds.width >= 254)
    }
    
    @MainActor
    @Test func exportBoundsIncludesEmptyGraphReturnsNil() async throws {
        let store = GraphStore<String>()
        let exporter = PNGExporter(store: store)
        #expect(exporter.calculateExportBounds() == nil)
    }

    @MainActor
    @Test func exportBoundsIncludesSmoothStepBends() async throws {
        let store = GraphStore<String>()
        let n1 = BaseNode(id: "n1", position: XYPosition(x: 0, y: 0), data: "n1")
        let n2 = BaseNode(id: "n2", position: XYPosition(x: 100, y: 100), data: "n2")
        store.nodes = [n1, n2]
        store.updateNodeDimensions(id: "n1", dimensions: Dimensions(width: 50, height: 50))
        store.updateNodeDimensions(id: "n2", dimensions: Dimensions(width: 50, height: 50))
        
        // SmoothStep: 上面同士を接続。デフォルトの offset (20pt) により y はマイナス方向へ張り出す
        store.edges = [
            BaseEdge<String>(
                id: "e1",
                source: "n1",
                target: "n2",
                kind: "smoothstep",
                sourcePosition: .top,
                targetPosition: .top
            )
        ]
        
        let exporter = PNGExporter(store: store)
        let bounds = try #require(exporter.calculateExportBounds())
        
        // y = 0 から offset 20pt 張り出し + padding 8pt + マージン 4pt = -32pt 付近になるはず
        #expect(bounds.y <= -30, "SmoothStep のオフセットによる張り出しが Bounds に含まれている必要があります (実際の y: \(bounds.y))")
    }

    @MainActor
    @Test func exportBoundsIncludesStepBends() async throws {
        let store = GraphStore<String>()
        let n1 = BaseNode(id: "n1", position: XYPosition(x: 0, y: 0), data: "n1")
        let n2 = BaseNode(id: "n2", position: XYPosition(x: 100, y: 100), data: "n2")
        store.nodes = [n1, n2]
        store.updateNodeDimensions(id: "n1", dimensions: Dimensions(width: 50, height: 50))
        store.updateNodeDimensions(id: "n2", dimensions: Dimensions(width: 50, height: 50))
        
        // Step: 同様にオフセットによる張り出しを検証
        store.edges = [
            BaseEdge<String>(
                id: "e1",
                source: "n1",
                target: "n2",
                kind: "step",
                sourcePosition: .top,
                targetPosition: .top
            )
        ]
        
        let exporter = PNGExporter(store: store)
        let bounds = try #require(exporter.calculateExportBounds())
        
        #expect(bounds.y <= -30, "Step のオフセットによる張り出しが Bounds に含まれている必要があります (実際の y: \(bounds.y))")
    }
}
