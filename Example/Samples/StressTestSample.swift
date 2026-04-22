import Foundation
import SwGraphUI
import SwiftUI

/// A benchmark sample for verifying UI load when displaying 1,000 nodes. | 1,000ノード表示時の UI 負荷を確認するためのベンチマーク用サンプル。
public struct StressTestSample: GraphSample {
    public let title = "Integrated Stress Test"
    public let category: ExampleAppStore.SampleCategory = .overview
    public let description = "1,000 nodes / 900 edges UI load verification (M35b) demo. | 1,000ノード / 900エッジによる UI 負荷検証（M35b）用デモ。"

    public func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore) {
        var nodes: [BaseNode<String>] = []
        var edges: [BaseEdge<String>] = []
        
        let rowCount = 40
        let colCount = 25 // 40 * 25 = 1000 nodes
        
        for row in 0..<rowCount {
            for col in 0..<colCount {
                let id = "n-\(row)-\(col)"
                nodes.append(BaseNode(
                    id: id,
                    position: XYPosition(x: Double(col * 150), y: Double(row * 100)),
                    data: "Node \(row)-\(col)",
                    width: 100,
                    height: 40
                ))
                
                // Generate adjacent nodes and edges | 隣接するノードとエッジを生成
                if col > 0 {
                    edges.append(BaseEdge(
                        id: "e-\(row)-\(col-1)-\(col)",
                        source: "n-\(row)-\(col-1)",
                        target: id,
                        animated: false
                    ))
                }
            }
        }
        
        graphStore.nodes = nodes
        graphStore.edges = edges
        appStore.appendLog(kind: "stress.setup", payload: "Generated 1,000 nodes and \(edges.count) animated edges.")
    }
}
