import SwiftUI

/// エクスポート機能（PNG/PDF）で共通利用するロジックを提供します。
@MainActor
internal struct GraphExportSupport<NodeData: Sendable> {
    let store: GraphStore<NodeData>
    
    /// エクスポート対象の論理的な境界矩形を計算します。
    func calculateExportBounds() -> Rect? {
        let nodes = store.nodes
        guard !nodes.isEmpty else { return nil }

        let nodeLookup = store.nodeLookup
        var bounds = NodePositioningAlgorithms.getNodesBounds(nodes, nodeLookup: nodeLookup)

        // エッジの接続点・ラベル・マーカー、および曲線パスの張り出しも考慮
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
        
        // 線幅やシャドウによる微細なはみ出しを防ぐため、最終 Bounds に安全マージンを適用
        return Rect(
            x: bounds.x - 4,
            y: bounds.y - 4,
            width: bounds.width + 8,
            height: bounds.height + 8
        )
    }

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
        case "caption2": return 11
        case "caption": return 12
        case "footnote": return 13
        case "subheadline": return 15
        case "callout": return 16
        case "body": return 17
        default: return 11
        }
    }

    func union(_ lhs: Rect, _ rhs: Rect) -> Rect {
        GeometryAlgorithms.union(of: [lhs, rhs]) ?? lhs
    }
}
