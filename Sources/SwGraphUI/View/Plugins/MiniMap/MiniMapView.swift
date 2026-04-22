import SwiftUI

/// Component that displays a reduced map of the entire graph. | グラフ全体の縮小図を表示するコンポーネント。
public struct MiniMapView<Data: Sendable>: View {
    public let store: GraphStore<Data>
    public let containerSize: Dimensions
    public var backgroundColor: Color = .gray.opacity(0.1)
    public var nodeColor: Color = .gray.opacity(0.5)
    public var maskColor: Color = .blue.opacity(0.1)
    public var strokeColor: Color = .blue.opacity(0.3)
    
    public init(
        store: GraphStore<Data>,
        containerSize: Dimensions,
        backgroundColor: Color = .gray.opacity(0.1),
        nodeColor: Color = .gray.opacity(0.5),
        maskColor: Color = .blue.opacity(0.1),
        strokeColor: Color = .blue.opacity(0.3)
    ) {
        self.store = store
        self.containerSize = containerSize
        self.backgroundColor = backgroundColor
        self.nodeColor = nodeColor
        self.maskColor = maskColor
        self.strokeColor = strokeColor
    }
    
    public var body: some View {
        GeometryReader { geometry in
            // Bounds of the entire graph | グラフ全体の Bounds
            let nodeRects = store.nodes.map { node in
                let absPos = store.absolutePosition(for: node.id)
                let width = node.width ?? node.measured?.width ?? node.initialWidth ?? 100
                let height = node.height ?? node.measured?.height ?? node.initialHeight ?? 50
                let origin = node.origin ?? .init(x: 0, y: 0)
                
                return Rect(
                    x: absPos.x - width * origin.x,
                    y: absPos.y - height * origin.y,
                    width: width,
                    height: height
                )
            }
            let bounds = GeometryAlgorithms.union(of: nodeRects) ?? Rect(x: 0, y: 0, width: 0, height: 0)
            
            let viewport = store.runtimeState.viewport.viewport
            
            // Calculate a rectangle that contains both the entire graph Bounds and the current Viewport (visible area) | グラフ全体の Bounds と、現在の Viewport (可視領域) の両方を包含する矩形を計算
            // This ensures that even if the viewport is far from the nodes, it fits within the minimap | これにより、ビューポートがノードから遠く離れていてもミニマップ内に収まるようにする
            let visibleRect = Rect(
                x: -viewport.x / viewport.zoom,
                y: -viewport.y / viewport.zoom,
                width: containerSize.width / viewport.zoom,
                height: containerSize.height / viewport.zoom
            )
            
            let combinedRect = GeometryAlgorithms.union(of: [bounds, visibleRect]) ?? bounds
            
            // Scale calculation within the minimap | ミニマップ内のスケール計算
            let scale = min(
                Double(geometry.size.width) / (combinedRect.width > 0 ? combinedRect.width : 1),
                Double(geometry.size.height) / (combinedRect.height > 0 ? combinedRect.height : 1)
            ) * 0.9 // For margins | 余白用
            
            let offsetX = (Double(geometry.size.width) - combinedRect.width * scale) / 2 - combinedRect.x * scale
            let offsetY = (Double(geometry.size.height) - combinedRect.height * scale) / 2 - combinedRect.y * scale
            
            ZStack(alignment: .topLeading) {
                // Background | 背景
                backgroundColor
                
                // Nodes (rectangles as background) | ノード（背景としての矩形）
                ForEach(store.nodes) { node in
                    let absPos = store.absolutePosition(for: node.id)
                    let width = node.width ?? node.measured?.width ?? node.initialWidth ?? 100
                    let height = node.height ?? node.measured?.height ?? node.initialHeight ?? 50
                    let origin = node.origin ?? .init(x: 0, y: 0)
                    
                    let nodeRect = Rect(
                        x: absPos.x - width * origin.x,
                        y: absPos.y - height * origin.y,
                        width: width,
                        height: height
                    )
                    
                    Rectangle()
                        .fill(nodeColor)
                        .frame(width: nodeRect.width * scale, height: nodeRect.height * scale)
                        .offset(x: nodeRect.x * scale + offsetX, y: nodeRect.y * scale + offsetY)
                }
                
                // Current viewport area | 現在のビューポート領域
                Rectangle()
                    .stroke(strokeColor, lineWidth: 1.5) // Slightly thicker line | 線を少し太く
                    .background(maskColor)
                    .frame(width: visibleRect.width * scale, height: visibleRect.height * scale)
                    .offset(x: visibleRect.x * scale + offsetX, y: visibleRect.y * scale + offsetY)
            }
            .clipped()
            .background(.ultraThinMaterial) // Glassmorphism for both premium feel and visibility | グラスモフィズムによる高級感と視認性の両立
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let tappedX = (value.location.x - offsetX) / scale
                        let tappedY = (value.location.y - offsetY) / scale
                        
                        // Update the viewport to bring the tapped point to the center | タップ地点を中心に持ってくるようにビューポートを更新
                        let newX = containerSize.width / 2 - tappedX * viewport.zoom
                        let newY = containerSize.height / 2 - tappedY * viewport.zoom
                        
                        store.setViewport(Viewport(x: newX, y: newY, zoom: viewport.zoom))
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 12)) // Slightly rounded corners | 角を少し丸く
        .accessibilityLabel("Minimap showing current viewing area | 現在の表示範囲を示すミニマップ")
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5) // Emphasize floating feel | 浮遊感を強調
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}
