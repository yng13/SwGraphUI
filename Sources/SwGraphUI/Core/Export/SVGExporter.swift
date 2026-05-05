import Foundation

public typealias SVGNodeRenderer<NodeData: Sendable> = (BaseNode<NodeData>, Rect) -> String
public typealias SVGEdgeRenderer<NodeData: Sendable> = (SVGEdgeRenderContext<NodeData>) -> String

public struct SVGEdgeRenderContext<NodeData: Sendable>: Sendable {
    public let edge: BaseEdge<NodeData>
    public let segments: [PathSegment]
    public let sourcePosition: Position
    public let targetPosition: Position
    public let sourcePoint: XYPosition
    public let targetPoint: XYPosition
    public let labelPoint: XYPosition

    public init(
        edge: BaseEdge<NodeData>,
        segments: [PathSegment],
        sourcePosition: Position,
        targetPosition: Position,
        sourcePoint: XYPosition,
        targetPoint: XYPosition,
        labelPoint: XYPosition
    ) {
        self.edge = edge
        self.segments = segments
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
        self.sourcePoint = sourcePoint
        self.targetPoint = targetPoint
        self.labelPoint = labelPoint
    }
}

/// Provides functionality to export graph content as SVG vector data. | グラフの内容を SVG ベクターデータとして書き出す機能を提供します。
@MainActor
public struct SVGExporter<NodeData: Sendable> {
    private let store: GraphStore<NodeData>

    public init(store: GraphStore<NodeData>) {
        self.store = store
    }

    /// Calculates the logical boundary rectangle for export. | エクスポート対象の論理的な境界矩形を計算します。
    public func calculateExportBounds() -> Rect? {
        GraphExportSupport(store: store).calculateExportBounds()
    }

    /// Generates current graph content as an SVG string. | 現在のグラフ内容を SVG 文字列として生成します。
    public func export(
        settings: GraphExportSettings = GraphExportSettings(),
        nodeRenderer: SVGNodeRenderer<NodeData>? = nil,
        edgeRenderer: SVGEdgeRenderer<NodeData>? = nil
    ) -> String? {
        guard let bounds = calculateExportBounds() else { return nil }

        let width = bounds.width + settings.margin * 2
        let height = bounds.height + settings.margin * 2
        let translation = XYPosition(
            x: -bounds.x + settings.margin,
            y: -bounds.y + settings.margin
        )
        let support = GraphExportSupport(store: store)

        var svg = [
            #"<svg xmlns="http://www.w3.org/2000/svg" width="\#(format(width))" height="\#(format(height))" viewBox="0 0 \#(format(width)) \#(format(height))">"#,
            "<title>SwGraphUI Graph</title>"
        ]

        let markerDefinitions = buildMarkerDefinitions()
        if !markerDefinitions.isEmpty {
            svg.append("<defs>")
            svg.append(contentsOf: markerDefinitions)
            svg.append("</defs>")
        }

        if !settings.isTransparent {
            svg.append("<rect id=\"background-fill\" x=\"0\" y=\"0\" width=\"\(format(width))\" height=\"\(format(height))\" fill=\"#F6F8FA\"/>")
        }

        if settings.includeBackground {
            svg.append(renderBackground(
                width: width,
                height: height,
                translation: translation,
                variant: settings.backgroundVariant
            ))
        }

        for edge in store.edges where !edge.hidden {
            let resolved = store.resolvedEdgePositions(for: edge)
            let sourceKey = HandleKey(
                nodeID: edge.source,
                handleID: edge.sourceHandle,
                type: .source,
                placement: resolved.source
            )
            let targetKey = HandleKey(
                nodeID: edge.target,
                handleID: edge.targetHandle,
                type: .target,
                placement: resolved.target
            )

            let source = translate(store.resolvedHandlePosition(for: sourceKey), by: translation)
            let target = translate(store.resolvedHandlePosition(for: targetKey), by: translation)
            let basePath = EdgePathAlgorithms.calculatePath(
                source: source,
                target: target,
                sourcePosition: resolved.source,
                targetPosition: resolved.target,
                kind: edge.kind,
                curvature: edge.curvature ?? 0.25
            )
            let path = EdgeLaneAlgorithms.applyLane(
                to: basePath,
                source: source,
                target: target,
                sourceNodeID: edge.source,
                targetNodeID: edge.target,
                assignment: store.edgeLaneAssignment(for: edge),
                sourcePosition: resolved.source,
                targetPosition: resolved.target
            )

            let labelPoint = XYPosition(
                x: path.labelX,
                y: path.labelY
            )
            let context = SVGEdgeRenderContext(
                edge: edge,
                segments: path.segments,
                sourcePosition: resolved.source,
                targetPosition: resolved.target,
                sourcePoint: source,
                targetPoint: target,
                labelPoint: labelPoint
            )
            svg.append(edgeRenderer?(context) ?? renderDefaultEdge(context, path: path, support: support))
        }

        for node in store.nodes where !node.hidden {
            let absolutePosition = store.absolutePosition(for: node.id)
            let translated = translate(absolutePosition, by: translation)
            let dimensions = resolvedNodeDimensions(for: node)
            let frame = Rect(
                x: translated.x,
                y: translated.y,
                width: dimensions.width,
                height: dimensions.height
            )
            svg.append(nodeRenderer?(node, frame) ?? renderDefaultNode(node: node, frame: frame))
        }

        svg.append("</svg>")
        return svg.joined(separator: "\n")
    }

    private func resolvedNodeDimensions(for node: BaseNode<NodeData>) -> Dimensions {
        Dimensions(
            width: node.measured?.width ?? node.width ?? node.initialWidth ?? 100,
            height: node.measured?.height ?? node.height ?? node.initialHeight ?? 50
        )
    }

    private func renderDefaultNode(node: BaseNode<NodeData>, frame: Rect) -> String {
        let label = escapedText(node.label ?? node.ariaLabel ?? node.id)
        let nodeID = sanitizedID("node-\(node.id)")
        let centerX = frame.x + frame.width / 2
        let centerY = frame.y + frame.height / 2 + 5

        return """
        <g id="\(nodeID)">
        <rect x="\(format(frame.x))" y="\(format(frame.y))" width="\(format(frame.width))" height="\(format(frame.height))" rx="10" ry="10" fill="#FFFFFF" stroke="#D0D7DE" stroke-width="1.25"/>
        <text x="\(format(centerX))" y="\(format(centerY))" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, sans-serif" font-size="14" fill="#24292F">\(label)</text>
        </g>
        """
    }

    private func renderDefaultEdge(
        _ context: SVGEdgeRenderContext<NodeData>,
        path: EdgePathResult,
        support: GraphExportSupport<NodeData>
    ) -> String {
        let edge = context.edge
        let edgeID = sanitizedID("edge-\(edge.id)")
        let strokeColor = resolvedEdgeStrokeColor(edge)
        let strokeWidth = resolvedEdgeStrokeWidth(edge)
        let dashAttributes = resolvedEdgeDashAttributes(edge)
        let markerAttributes = markerReferenceAttributes(for: edge)
        let laneOffset = store.edgeLaneOffsetVector(for: edge, source: context.sourcePoint, target: context.targetPoint)
        var lines = [
            #"<g id="\#(edgeID)">"#,
            #"<path d="\#(escapedAttribute(path.path))" fill="none" stroke="\#(strokeColor)" stroke-width="\#(format(strokeWidth))" stroke-linecap="round" stroke-linejoin="round"\#(dashAttributes)\#(markerAttributes)/>"#
        ]

        if let label = edge.label, !label.isEmpty {
            let fontSize = support.resolvedExportFontSize(for: edge.labelStyle)
            if edge.labelStyle.showBg {
                let labelRect = support.labelRect(for: label, style: edge.labelStyle, center: context.labelPoint)
                let backgroundColor = resolvedLabelBackgroundColor(edge.labelStyle)
                lines.append(
                    #"<rect x="\#(format(labelRect.x))" y="\#(format(labelRect.y))" width="\#(format(labelRect.width))" height="\#(format(labelRect.height))" rx="\#(format(edge.labelStyle.bgBorderRadius))" ry="\#(format(edge.labelStyle.bgBorderRadius))" fill="\#(backgroundColor)" stroke="none"/>"#
                )
            }
            lines.append(
                #"<text x="\#(format(context.labelPoint.x))" y="\#(format(context.labelPoint.y + fontSize * 0.35))" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, sans-serif" font-size="\#(format(fontSize))" fill="\#(resolvedLabelTextColor(edge.labelStyle))">\#(escapedText(label))</text>"#
            )
        }

        if let label = edge.sourceEndpointLabel, support.shouldExport(label, edge: edge) {
            let point = EdgeEndpointLabelAlgorithms.graphPosition(
                handlePoint: context.sourcePoint + laneOffset,
                placement: context.sourcePosition,
                offset: label.offset ?? EdgeEndpointLabelAlgorithms.defaultOffset
            )
            lines.append(renderEndpointLabel(label, center: point, support: support))
        }

        if let label = edge.targetEndpointLabel, support.shouldExport(label, edge: edge) {
            let point = EdgeEndpointLabelAlgorithms.graphPosition(
                handlePoint: context.targetPoint + laneOffset,
                placement: context.targetPosition,
                offset: label.offset ?? EdgeEndpointLabelAlgorithms.defaultOffset
            )
            lines.append(renderEndpointLabel(label, center: point, support: support))
        }

        lines.append("</g>")
        return lines.joined(separator: "\n")
    }

    private func renderEndpointLabel(
        _ label: EdgeEndpointLabel,
        center: XYPosition,
        support: GraphExportSupport<NodeData>
    ) -> String {
        let style = support.resolvedEndpointLabelStyle(label)
        let fontSize = support.resolvedExportFontSize(for: style)
        var lines: [String] = []
        if style.showBg {
            let rect = support.labelRect(for: label.text, style: style, center: center, maxWidth: label.maxWidth)
            lines.append(
                #"<rect x="\#(format(rect.x))" y="\#(format(rect.y))" width="\#(format(rect.width))" height="\#(format(rect.height))" rx="\#(format(style.bgBorderRadius))" ry="\#(format(style.bgBorderRadius))" fill="\#(resolvedLabelBackgroundColor(style))" stroke="none"/>"#
            )
        }
        let text = support.constrainedLabelText(for: label.text, style: style, maxWidth: label.maxWidth)
        lines.append(
            #"<text x="\#(format(center.x))" y="\#(format(center.y + fontSize * 0.35))" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, sans-serif" font-size="\#(format(fontSize))" fill="\#(resolvedLabelTextColor(style))">\#(escapedText(text))</text>"#
        )
        return lines.joined(separator: "\n")
    }

    private func resolvedLabelBackgroundColor(_ style: EdgeLabelStyle) -> String {
        sanitizeColor(style.bgStyle, fallback: "#FFFFFF")
    }

    private func resolvedLabelTextColor(_ style: EdgeLabelStyle) -> String {
        sanitizeColor(style.textColor, fallback: "#111827")
    }

    private func resolvedEdgeStrokeColor(_ edge: BaseEdge<NodeData>) -> String {
        sanitizeColor(edge.strokeStyle?.color, fallback: "#6B7280")
    }

    private func resolvedEdgeStrokeWidth(_ edge: BaseEdge<NodeData>) -> Double {
        edge.strokeStyle?.width ?? 2
    }

    private func resolvedEdgeDashAttributes(_ edge: BaseEdge<NodeData>) -> String {
        guard let dash = edge.strokeStyle?.dash, !dash.pattern.isEmpty else { return "" }
        let pattern = dash.pattern.map(format).joined(separator: " ")
        return #" stroke-dasharray="\#(escapedAttribute(pattern))""#
    }

    private func buildMarkerDefinitions() -> [String] {
        var definitions: [String] = []
        for edge in store.edges where !edge.hidden {
            if let marker = edge.markerStart {
                definitions.append(markerDefinition(marker, id: markerID(for: edge, kind: "start"), forStart: true))
            }
            if let marker = edge.markerEnd {
                definitions.append(markerDefinition(marker, id: markerID(for: edge, kind: "end"), forStart: false))
            }
        }
        return definitions
    }

    private func markerDefinition(_ marker: EdgeMarker, id: String, forStart: Bool) -> String {
        let width = marker.width ?? 10
        let height = marker.height ?? 10
        let color = sanitizeColor(marker.color, fallback: "#6B7280")
        let strokeWidth = marker.strokeWidth ?? 1.5
        let orient = escapedAttribute(marker.orient ?? (forStart ? "auto-start-reverse" : "auto"))
        let units = escapedAttribute(marker.markerUnits ?? "strokeWidth")
        let path: String
        switch marker.type {
        case .arrow:
            path = #"<path d="M 0 0 L 10 5 L 0 10" fill="none" stroke="\#(color)" stroke-width="\#(format(strokeWidth))" stroke-linecap="round" stroke-linejoin="round"/>"#
        case .arrowClosed:
            path = #"<path d="M 0 0 L 10 5 L 0 10 z" fill="\#(color)" stroke="\#(color)" stroke-width="\#(format(strokeWidth))" stroke-linejoin="round"/>"#
        }
        return #"<marker id="\#(id)" viewBox="0 0 10 10" refX="10" refY="5" markerWidth="\#(format(width))" markerHeight="\#(format(height))" markerUnits="\#(units)" orient="\#(orient)">\#(path)</marker>"#
    }

    private func markerReferenceAttributes(for edge: BaseEdge<NodeData>) -> String {
        var attributes: [String] = []
        if edge.markerStart != nil {
            attributes.append(#" marker-start="url(#\#(markerID(for: edge, kind: "start")))" "#)
        }
        if edge.markerEnd != nil {
            attributes.append(#" marker-end="url(#\#(markerID(for: edge, kind: "end")))" "#)
        }
        return attributes.joined()
    }

    private func markerID(for edge: BaseEdge<NodeData>, kind: String) -> String {
        sanitizedID("marker-\(edge.id)-\(kind)")
    }

    private func renderBackground(
        width: Double,
        height: Double,
        translation: XYPosition,
        variant: BackgroundVariant
    ) -> String {
        let spacing = 20.0
        let majorEvery = 5
        let startX = Int(floor((-translation.x) / spacing)) - 1
        let endX = Int(ceil((width - translation.x) / spacing)) + 1
        let startY = Int(floor((-translation.y) / spacing)) - 1
        let endY = Int(ceil((height - translation.y) / spacing)) + 1

        var lines = ["<g id=\"background-grid\" stroke=\"#D0D7DE\" fill=\"#D0D7DE\">"]

        switch variant {
        case .dots:
            for xIndex in startX...endX {
                for yIndex in startY...endY {
                    let x = translation.x + Double(xIndex) * spacing
                    let y = translation.y + Double(yIndex) * spacing
                    let isMajor = xIndex.isMultiple(of: majorEvery) && yIndex.isMultiple(of: majorEvery)
                    let radius = isMajor ? 1.8 : 1.0
                    let opacity = isMajor ? 0.42 : 0.2
                    lines.append(#"<circle cx="\#(format(x))" cy="\#(format(y))" r="\#(format(radius))" opacity="\#(format(opacity))"/>"#)
                }
            }
        case .lines:
            for xIndex in startX...endX {
                let x = translation.x + Double(xIndex) * spacing
                let isMajor = xIndex.isMultiple(of: majorEvery)
                let opacity = isMajor ? 0.32 : 0.14
                let lineWidth = isMajor ? 1.0 : 0.6
                lines.append(#"<line x1="\#(format(x))" y1="0" x2="\#(format(x))" y2="\#(format(height))" opacity="\#(format(opacity))" stroke-width="\#(format(lineWidth))"/>"#)
            }
            for yIndex in startY...endY {
                let y = translation.y + Double(yIndex) * spacing
                let isMajor = yIndex.isMultiple(of: majorEvery)
                let opacity = isMajor ? 0.32 : 0.14
                let lineWidth = isMajor ? 1.0 : 0.6
                lines.append(#"<line x1="0" y1="\#(format(y))" x2="\#(format(width))" y2="\#(format(y))" opacity="\#(format(opacity))" stroke-width="\#(format(lineWidth))"/>"#)
            }
        case .cross:
            for xIndex in startX...endX {
                for yIndex in startY...endY {
                    let x = translation.x + Double(xIndex) * spacing
                    let y = translation.y + Double(yIndex) * spacing
                    let isMajor = xIndex.isMultiple(of: majorEvery) && yIndex.isMultiple(of: majorEvery)
                    let size = isMajor ? 3.5 : 2.0
                    let opacity = isMajor ? 0.4 : 0.18
                    let lineWidth = isMajor ? 1.0 : 0.6
                    lines.append(#"<line x1="\#(format(x - size))" y1="\#(format(y))" x2="\#(format(x + size))" y2="\#(format(y))" opacity="\#(format(opacity))" stroke-width="\#(format(lineWidth))"/>"#)
                    lines.append(#"<line x1="\#(format(x))" y1="\#(format(y - size))" x2="\#(format(x))" y2="\#(format(y + size))" opacity="\#(format(opacity))" stroke-width="\#(format(lineWidth))"/>"#)
                }
            }
        }

        lines.append("</g>")
        return lines.joined(separator: "\n")
    }

    private func translate(_ point: XYPosition, by offset: XYPosition) -> XYPosition {
        XYPosition(x: point.x + offset.x, y: point.y + offset.y)
    }

    private func format(_ value: Double) -> String {
        if abs(value) < 0.000_5 {
            return "0"
        }

        let rounded = (value * 1000).rounded() / 1000
        var string = String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), rounded)
        while string.contains(".") && (string.hasSuffix("0") || string.hasSuffix(".")) {
            string.removeLast()
        }
        return string
    }

    private func escapedText(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func escapedAttribute(_ value: String) -> String {
        escapedText(value)
    }

    private func sanitizedID(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_:."))
        let unicodeScalars = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let candidate = String(unicodeScalars)
        return candidate.isEmpty ? "swgraphui-id" : candidate
    }

    private func sanitizeColor(_ value: String?, fallback: String) -> String {
        guard let value, !value.isEmpty else { return fallback }
        return escapedAttribute(value)
    }
}
