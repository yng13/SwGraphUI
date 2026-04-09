import SwiftUI

/// グラフの内容を PNG 画像データとして書き出す機能を提供します。
@MainActor
public struct PNGExporter<Data: Sendable> {
    private let store: GraphStore<Data>
    
    public init(store: GraphStore<Data>) {
        self.store = store
    }
    
    /// 現在のグラフ内容を PNG データとして生成します。
    /// - Parameters:
    ///   - settings: エクスポート設定。
    ///   - nodeBuilder: ノード描画用クロージャ。
    ///   - edgeBuilder: エッジ描画用クロージャ（任意）。
    /// - Returns: 生成された PNG データ。生成に失敗した場合は nil。
    /// エクスポート対象の論理的な境界矩形を計算します。
    /// ノード、エッジの接続点、ラベル、マーカー、および曲線パスの張り出し（制御点）をすべて包含し、
    /// 最後に安全マージン（4pt）を適用します。
    public func calculateExportBounds() -> Rect? {
        let nodes = store.nodes
        guard !nodes.isEmpty else { return nil }

        let nodeLookup = store.nodeLookup
        var bounds = NodePositioningAlgorithms.getNodesBounds(nodes, nodeLookup: nodeLookup)

        // 1b. エッジの接続点・ラベル・マーカー、および曲線パスの張り出しも考慮
        for edge in store.edges {
            let sourcePos = edge.sourcePosition ?? .right
            let targetPos = edge.targetPosition ?? .left
            let sourceKey = HandleKey(nodeID: edge.source, handleID: edge.sourceHandle, type: .source, placement: sourcePos)
            let targetKey = HandleKey(nodeID: edge.target, handleID: edge.targetHandle, type: .target, placement: targetPos)
            
            let sPos = store.resolvedHandlePosition(for: sourceKey)
            let tPos = store.resolvedHandlePosition(for: targetKey)

            bounds = union(bounds, pointRect(at: sPos))
            bounds = union(bounds, pointRect(at: tPos))

            let path = EdgePathAlgorithms.calculatePath(
                source: sPos,
                target: tPos,
                sourcePosition: sourcePos,
                targetPosition: targetPos,
                kind: edge.kind,
                curvature: edge.curvature ?? 0.25
            )

            // 曲線エッジの張り出し（制御点）もすべて Bounds に含める
            for segment in path.segments {
                switch segment {
                case .move(let to), .line(let to):
                    bounds = union(bounds, pointRect(at: to))
                case .bezier(let to, let c1, let c2):
                    bounds = union(bounds, pointRect(at: to))
                    bounds = union(bounds, pointRect(at: c1))
                    bounds = union(bounds, pointRect(at: c2))
                case .quadratic(let to, let c):
                    bounds = union(bounds, pointRect(at: to))
                    bounds = union(bounds, pointRect(at: c))
                @unknown default:
                    break
                }
            }

            if let label = edge.label, !label.isEmpty {
                bounds = union(bounds, labelRect(for: label, style: edge.labelStyle, center: XYPosition(x: path.labelX, y: path.labelY)))
            }

            if let marker = edge.markerStart {
                bounds = union(bounds, markerRect(at: sPos, marker: marker))
            }

            if let marker = edge.markerEnd {
                bounds = union(bounds, markerRect(at: tPos, marker: marker))
            }
        }
        
        // 1c. 線幅やシャドウによる微細なはみ出しを防ぐため、最終 Bounds に安全マージンを適用
        return Rect(
            x: bounds.x - 4,
            y: bounds.y - 4,
            width: bounds.width + 8,
            height: bounds.height + 8
        )
    }

    public func export(
        settings: GraphExportSettings,
        @ViewBuilder nodeBuilder: @escaping (BaseNode<Data>) -> some View,
        edgeBuilder: ((BaseEdge<Data>, [PathSegment], Color, CGFloat, Bool, Bool) -> AnyView)? = nil
    ) -> Foundation.Data? {
        // 1. エクスポート対象の論理的な境界矩形を計算
        guard let bounds = calculateExportBounds() else { return nil }
        
        // 2. レンダリング用のビューを構築
        let exportView = GraphExportView(
            store: store,
            settings: settings,
            nodeBuilder: nodeBuilder,
            edgeBuilder: edgeBuilder ?? { _, segments, color, width, animated, reconnecting in
                AnyView(EdgeRenderer(segments: segments, strokeColor: color, strokeWidth: width, animated: animated, isReconnecting: reconnecting))
            },
            bounds: bounds
        )
        
        // 3. ImageRenderer による画像生成
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = settings.scale
        
        #if os(macOS)
        guard let nsImage = renderer.nsImage else { return nil }
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #else
        guard let uiImage = renderer.uiImage else { return nil }
        return uiImage.pngData()
        #endif
    }
}

private extension PNGExporter {
    func pointRect(at point: XYPosition, padding: Double = 8) -> Rect {
        Rect(
            x: point.x - padding,
            y: point.y - padding,
            width: padding * 2,
            height: padding * 2
        )
    }

    func markerRect(at point: XYPosition, marker: EdgeMarker) -> Rect {
        let width = max(marker.width ?? 6.0, marker.height ?? 6.0) + 8.0
        return Rect(
            x: point.x - width,
            y: point.y - width,
            width: width * 2,
            height: width * 2
        )
    }

    func labelRect(for label: String, style: EdgeLabelStyle, center: XYPosition) -> Rect {
        let fontSize = resolvedExportFontSize(for: style)
        let horizontalPadding = style.bgPadding * 2
        let verticalPadding = style.bgPadding * 0.8
        let estimatedWidth = max(Double(label.count) * fontSize * 0.58 + horizontalPadding, fontSize * 2.4)
        let estimatedHeight = fontSize * 1.4 + verticalPadding

        return Rect(
            x: center.x - estimatedWidth / 2,
            y: center.y - estimatedHeight / 2,
            width: estimatedWidth,
            height: estimatedHeight
        )
    }

    func resolvedExportFontSize(for style: EdgeLabelStyle) -> Double {
        if let size = style.fontSize {
            return size
        }

        switch style.font?.lowercased() {
        case "caption2":
            return 11
        case "caption":
            return 12
        case "footnote":
            return 13
        case "subheadline":
            return 15
        case "callout":
            return 16
        case "body":
            return 17
        default:
            return 11
        }
    }

    func union(_ lhs: Rect, _ rhs: Rect) -> Rect {
        GeometryAlgorithms.union(of: [lhs, rhs]) ?? lhs
    }
}
