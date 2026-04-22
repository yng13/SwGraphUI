import Foundation
import SwGraphUI

struct MiniMapAndControlsSample: GraphSample {
    var title: String = "MiniMap & Controls"
    var category: ExampleAppStore.SampleCategory = .plugins
    var description: String = "Demo of MiniMap and Controls. Nodes are arranged over a wide area. | MiniMap と Controls のデモ。広範囲にノードを配置しています。"
    
    func setup(in store: GraphStore<String>, appStore: ExampleAppStore) {
        store.nodes = [
            BaseNode(id: "1", position: .init(x: 0, y: 0), data: "Center"),
            BaseNode(id: "2", position: .init(x: -500, y: -500), data: "Top Left"),
            BaseNode(id: "3", position: .init(x: 500, y: -500), data: "Top Right"),
            BaseNode(id: "4", position: .init(x: -500, y: 500), data: "Bottom Left"),
            BaseNode(id: "5", position: .init(x: 500, y: 500), data: "Bottom Right"),
            BaseNode(id: "6", position: .init(x: 1500, y: 1500), data: "Far Edge")
        ]
        
        store.edges = [
            BaseEdge(id: "e1-2", source: "1", target: "2"),
            BaseEdge(id: "e1-3", source: "1", target: "3"),
            BaseEdge(id: "e1-4", source: "1", target: "4"),
            BaseEdge(id: "e1-5", source: "1", target: "5"),
            BaseEdge(id: "e5-6", source: "5", target: "6")
        ]
        
        // Relaxing zoom limits (to allow displaying wide-range node placements) | ズーム制限の緩和（広範囲なノード配置を表示可能にするため）
        store.runtimeState.interactivity.minZoom = 0.1
        store.runtimeState.interactivity.maxZoom = 4.0
        
        // Initial state is unlocked | 初期状態はロック解除
        store.setNodesDraggable(true)
        store.setPanOnDrag(true)
        
        appStore.appendLog(kind: "sample.setup", payload: "MiniMap & Controls sample loaded")
    }
}
