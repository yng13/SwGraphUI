import SwiftUI

/// Provides common logic used across export functions (PNG/PDF). | エクスポート機能（PNG/PDF）で共通利用するロジックを提供します。
@MainActor
internal struct GraphExportSupport<NodeData: Sendable> {
    let store: GraphStore<NodeData>
    
    /// Calculates the logical boundary rectangle for export. | エクスポート対象の論理的な境界矩形を計算します。
    func calculateExportBounds() -> Rect? {
        let nodes = store.nodes
        guard !nodes.isEmpty else { return nil }

        let nodeLookup = store.nodeLookup
        var bounds = NodePositioningAlgorithms.getNodesBounds(nodes, nodeLookup: nodeLookup)

        // Account for edge connection points, labels, markers, and path protrusions | エッジの接続点・ラベル・マーカー、および曲線パスの張り出しも考慮
        for edge in store.edges {
            let resolved = store.resolvedEdgePositions(for: edge)
            let sourcePos = resolved.source
            let targetPos = resolved.target
            let sourceKey = HandleKey(nodeID: edge.source, handleID: edge.sourceHandle, type: .source, placement: sourcePos)
            let targetKey = HandleKey(nodeID: edge.target, handleID: edge.targetHandle, type: .target, placement: targetPos)
            
            let sPos = store.resolvedHandlePosition(for: sourceKey)
            let tPos = store.resolvedHandlePosition(for: targetKey)

            bounds = union(bounds, pointRect(at: sPos))
            bounds = union(bounds, pointRect(at: tPos))

            let path = store.laneAdjustedPath(
                for: edge,
                source: sPos,
                target: tPos,
                sourcePosition: sourcePos,
                targetPosition: targetPos
            )
            let laneOffset = store.edgeLaneOffsetVector(for: edge, source: sPos, target: tPos)

            // Include all protrusions of curved edges (control points) into bounds | 曲線エッジの張り出し（制御点）もすべて Bounds に含める
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

            if let label = edge.sourceEndpointLabel, shouldExport(label, edge: edge) {
                let point = EdgeEndpointLabelAlgorithms.graphPosition(
                    handlePoint: sPos + laneOffset,
                    placement: sourcePos,
                    offset: label.offset ?? EdgeEndpointLabelAlgorithms.defaultOffset
                )
                bounds = union(bounds, labelRect(for: label.text, style: resolvedEndpointLabelStyle(label), center: point, maxWidth: label.maxWidth))
            }

            if let label = edge.targetEndpointLabel, shouldExport(label, edge: edge) {
                let point = EdgeEndpointLabelAlgorithms.graphPosition(
                    handlePoint: tPos + laneOffset,
                    placement: targetPos,
                    offset: label.offset ?? EdgeEndpointLabelAlgorithms.defaultOffset
                )
                bounds = union(bounds, labelRect(for: label.text, style: resolvedEndpointLabelStyle(label), center: point, maxWidth: label.maxWidth))
            }

            if let marker = edge.markerStart {
                bounds = union(bounds, markerRect(at: sPos, marker: marker))
            }

            if let marker = edge.markerEnd {
                bounds = union(bounds, markerRect(at: tPos, marker: marker))
            }
        }
        
        // Apply a safety margin to the final Bounds to prevent minor cropping due to line width or shadows | 線幅やシャドウによる微細なはみ出しを防ぐため、最終 Bounds に安全マージンを適用
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
        labelRect(for: label, style: style, center: center, maxWidth: nil)
    }

    func labelRect(for label: String, style: EdgeLabelStyle, center: XYPosition, maxWidth: Double?) -> Rect {
        let fontSize = resolvedExportFontSize(for: style)
        let horizontalPadding = style.bgPadding * 2
        let verticalPadding = style.bgPadding * 0.8
        let displayLabel = constrainedLabelText(for: label, style: style, maxWidth: maxWidth)
        let naturalWidth = max(Double(displayLabel.count) * fontSize * 0.58 + horizontalPadding, fontSize * 2.4)
        let estimatedWidth = maxWidth.map { min(naturalWidth, $0) } ?? naturalWidth
        let estimatedHeight = fontSize * 1.4 + verticalPadding

        return Rect(
            x: center.x - estimatedWidth / 2,
            y: center.y - estimatedHeight / 2,
            width: estimatedWidth,
            height: estimatedHeight
        )
    }

    func constrainedLabelText(for label: String, style: EdgeLabelStyle, maxWidth: Double?) -> String {
        guard let maxWidth else { return label }

        let fontSize = resolvedExportFontSize(for: style)
        let textWidth = max(maxWidth - style.bgPadding * 2, fontSize * 1.2)
        let maxCharacters = Int(floor(textWidth / (fontSize * 0.58)))
        guard maxCharacters > 0, label.count > maxCharacters else { return label }

        let marker = "..."
        guard maxCharacters > marker.count + 1 else {
            return String(label.prefix(maxCharacters))
        }

        let visibleCharacters = maxCharacters - marker.count
        let leadingCount = Int(ceil(Double(visibleCharacters) / 2.0))
        let trailingCount = max(visibleCharacters - leadingCount, 0)
        return String(label.prefix(leadingCount)) + marker + String(label.suffix(trailingCount))
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

    func resolvedEndpointLabelStyle(_ label: EdgeEndpointLabel) -> EdgeLabelStyle {
        var style = label.style
        switch label.presentation {
        case .chip:
            style.showBg = true
        case .plain:
            style.showBg = false
        case .subtle:
            style.showBg = true
            if style.bgStyle == nil {
                style.bgStyle = "#F6F8FA"
            }
            if style.textColor == nil {
                style.textColor = "#57606A"
            }
        }
        return style
    }

    func shouldExport(_ label: EdgeEndpointLabel, edge: BaseEdge<NodeData>) -> Bool {
        switch label.visibility {
        case .always, .whenZoomedIn:
            true
        case .whenSelected:
            edge.selected
        case .whenHovered:
            false
        }
    }

    func union(_ lhs: Rect, _ rhs: Rect) -> Rect {
        GeometryAlgorithms.union(of: [lhs, rhs]) ?? lhs
    }
}
