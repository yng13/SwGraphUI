import Foundation

public struct EdgeLaneAssignment: Sendable, Equatable {
    public var index: Double
    public var count: Int
    public var spacing: Double

    public init(index: Double = 0, count: Int = 1, spacing: Double = EdgeLaneAlgorithms.defaultSpacing) {
        self.index = index
        self.count = count
        self.spacing = spacing
    }

    public var offset: Double {
        index * spacing
    }

    public var isCentered: Bool {
        abs(offset) < 0.000_001
    }
}

public enum EdgeLaneAlgorithms {
    public static let defaultSpacing: Double = 18.0

    public static func assignment<NodeData: Sendable>(
        for edge: BaseEdge<NodeData>,
        in edges: [BaseEdge<NodeData>],
        spacing: Double = defaultSpacing
    ) -> EdgeLaneAssignment {
        let edgeKey = parallelLaneKey(for: edge)
        let peers = edges
            .filter { !$0.hidden && parallelLaneKey(for: $0) == edgeKey }
            .sorted { $0.id < $1.id }

        guard peers.count > 1,
              let ordinal = peers.firstIndex(where: { $0.id == edge.id }) else {
            return EdgeLaneAssignment(index: 0, count: max(peers.count, 1), spacing: spacing)
        }

        return EdgeLaneAssignment(
            index: Double(ordinal) - Double(peers.count - 1) / 2.0,
            count: peers.count,
            spacing: spacing
        )
    }

    public static func assignments<NodeData: Sendable>(
        for edges: [BaseEdge<NodeData>],
        spacing: Double = defaultSpacing
    ) -> [String: EdgeLaneAssignment] {
        var groups: [String: [BaseEdge<NodeData>]] = [:]
        for edge in edges where !edge.hidden {
            groups[parallelLaneKey(for: edge), default: []].append(edge)
        }

        var assignments: [String: EdgeLaneAssignment] = [:]
        assignments.reserveCapacity(edges.count)

        for (_, peers) in groups {
            let sortedPeers = peers.sorted { $0.id < $1.id }
            let count = sortedPeers.count
            for (ordinal, edge) in sortedPeers.enumerated() {
                assignments[edge.id] = count > 1
                    ? EdgeLaneAssignment(
                        index: Double(ordinal) - Double(count - 1) / 2.0,
                        count: count,
                        spacing: spacing
                    )
                    : EdgeLaneAssignment(index: 0, count: 1, spacing: spacing)
            }
        }

        for edge in edges where assignments[edge.id] == nil {
            let visiblePeerCount = groups[parallelLaneKey(for: edge)]?.count ?? 0
            assignments[edge.id] = EdgeLaneAssignment(index: 0, count: max(visiblePeerCount, 1), spacing: spacing)
        }

        return assignments
    }

    public static func applyLane(
        to result: EdgePathResult,
        source: XYPosition,
        target: XYPosition,
        sourceNodeID: String,
        targetNodeID: String,
        assignment: EdgeLaneAssignment,
        sourcePosition: Position? = nil,
        targetPosition: Position? = nil
    ) -> EdgePathResult {
        guard !assignment.isCentered else { return result }
        let offset = offsetVector(
            source: source,
            target: target,
            sourceNodeID: sourceNodeID,
            targetNodeID: targetNodeID,
            assignment: assignment
        )
        guard offset.x.isFinite, offset.y.isFinite else { return result }

        let adjustedSegments = laneSegments(
            result.segments,
            source: source,
            target: target,
            offset: offset,
            sourcePosition: sourcePosition,
            targetPosition: targetPosition
        )
        let sourceTangent = sourceTangentAngle(in: adjustedSegments) ?? result.sourceTangentAngle
        let targetTangent = targetTangentAngle(in: adjustedSegments) ?? result.targetTangentAngle

        return EdgePathResult(
            segments: adjustedSegments,
            labelX: result.labelX + offset.x,
            labelY: result.labelY + offset.y,
            offsetX: result.offsetX,
            offsetY: result.offsetY,
            targetTangentAngle: targetTangent,
            sourceTangentAngle: sourceTangent
        )
    }

    public static func offsetVector(
        source: XYPosition,
        target: XYPosition,
        sourceNodeID: String,
        targetNodeID: String,
        assignment: EdgeLaneAssignment
    ) -> XYPosition {
        let dx = target.x - source.x
        let dy = target.y - source.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0.000_001 else { return .zero }

        var normal = XYPosition(x: -dy / length, y: dx / length)
        if sourceNodeID > targetNodeID {
            normal = XYPosition(x: -normal.x, y: -normal.y)
        }

        let offset = assignment.offset
        return XYPosition(x: normal.x * offset, y: normal.y * offset)
    }

    private static func parallelLaneKey<NodeData: Sendable>(for edge: BaseEdge<NodeData>) -> String {
        let source = endpointKey(edge.sourceEndpoint)
        let target = endpointKey(edge.targetEndpoint)
        return source <= target ? "\(source)\u{1F}#\(target)" : "\(target)\u{1F}#\(source)"
    }

    private static func endpointKey(_ endpoint: EdgeEndpoint) -> String {
        switch endpoint {
        case .node(let id, let handleID):
            return "n\u{1E}#\(id)\u{1E}#\(handleID ?? "")"
        case .point(let point):
            return "p\u{1E}#\(point.x)\u{1E}#\(point.y)"
        }
    }

    private static func laneSegments(
        _ segments: [PathSegment],
        source: XYPosition,
        target: XYPosition,
        offset: XYPosition,
        sourcePosition: Position?,
        targetPosition: Position?
    ) -> [PathSegment] {
        guard segments.count >= 2 else { return segments }

        if case .move = segments.first,
           case .line = segments.last,
           segments.count == 2 {
            let midpoint = XYPosition(
                x: (source.x + target.x) / 2.0 + offset.x,
                y: (source.y + target.y) / 2.0 + offset.y
            )
            return [
                .move(to: source),
                .quadratic(to: target, control: midpoint)
            ]
        }

        let lastIndex = segments.count - 1
        let shiftedSegments: [PathSegment] = segments.enumerated().map { index, segment in
            switch segment {
            case .move(let to):
                return index == 0 ? .move(to: to) : .move(to: shifted(to, by: offset))
            case .line(let to):
                return .line(to: index == lastIndex ? to : shifted(to, by: offset))
            case .bezier(let to, let control1, let control2):
                return .bezier(
                    to: index == lastIndex ? to : shifted(to, by: offset),
                    control1: shifted(control1, by: offset),
                    control2: shifted(control2, by: offset)
                )
            case .quadratic(let to, let control):
                return .quadratic(
                    to: index == lastIndex ? to : shifted(to, by: offset),
                    control: shifted(control, by: offset)
                )
            }
        }

        return orthogonalizedEndpointSegments(
            shiftedSegments,
            source: source,
            target: target,
            sourcePosition: sourcePosition,
            targetPosition: targetPosition
        )
    }

    private static func shifted(_ point: XYPosition, by offset: XYPosition) -> XYPosition {
        XYPosition(x: point.x + offset.x, y: point.y + offset.y)
    }

    private static func orthogonalizedEndpointSegments(
        _ segments: [PathSegment],
        source: XYPosition,
        target: XYPosition,
        sourcePosition: Position?,
        targetPosition: Position?
    ) -> [PathSegment] {
        guard segments.count >= 3 else { return segments }
        var result = segments

        if let sourcePosition,
           let firstLineIndex = result.indices.dropFirst().first(where: { result[$0].isLine }) {
            let firstPoint = result[firstLineIndex].target
            let lead = orthogonalLead(from: source, toward: firstPoint, placement: sourcePosition)
            if !lead.isApproximatelyEqual(to: source), !lead.isApproximatelyEqual(to: firstPoint) {
                result.insert(.line(to: lead), at: firstLineIndex)
            }
        }

        if let targetPosition,
           let lastLineIndex = result.indices.reversed().first(where: { result[$0].isLine && result[$0].target.isApproximatelyEqual(to: target) }),
           lastLineIndex > result.startIndex {
            let previousPoint = result[result.index(before: lastLineIndex)].target
            let lead = orthogonalLead(from: target, toward: previousPoint, placement: targetPosition)
            if !lead.isApproximatelyEqual(to: target), !lead.isApproximatelyEqual(to: previousPoint) {
                result.insert(.line(to: lead), at: lastLineIndex)
            }
        }

        return result
    }

    private static func orthogonalLead(from endpoint: XYPosition, toward point: XYPosition, placement: Position) -> XYPosition {
        switch placement {
        case .top, .bottom:
            return XYPosition(x: endpoint.x, y: point.y)
        case .left, .right:
            return XYPosition(x: point.x, y: endpoint.y)
        }
    }

    private static func sourceTangentAngle(in segments: [PathSegment]) -> Double? {
        guard let first = segments.first else { return nil }
        let start = first.target
        for segment in segments.dropFirst() {
            switch segment {
            case .move:
                continue
            case .line(let to):
                return atan2(to.y - start.y, to.x - start.x)
            case .quadratic(let to, let control):
                let point = control == start ? to : control
                return atan2(point.y - start.y, point.x - start.x)
            case .bezier(let to, let control1, _):
                let point = control1 == start ? to : control1
                return atan2(point.y - start.y, point.x - start.x)
            }
        }
        return nil
    }

    private static func targetTangentAngle(in segments: [PathSegment]) -> Double? {
        guard segments.count >= 2 else { return nil }
        let last = segments[segments.count - 1]
        let target = last.target

        switch last {
        case .move:
            return nil
        case .line:
            let previous = segments[segments.count - 2].target
            return atan2(target.y - previous.y, target.x - previous.x)
        case .quadratic(_, let control):
            return atan2(target.y - control.y, target.x - control.x)
        case .bezier(_, _, let control2):
            return atan2(target.y - control2.y, target.x - control2.x)
        }
    }
}

private extension PathSegment {
    var isLine: Bool {
        if case .line = self {
            return true
        }
        return false
    }
}

private extension XYPosition {
    func isApproximatelyEqual(to other: XYPosition) -> Bool {
        abs(x - other.x) < 0.000_001 && abs(y - other.y) < 0.000_001
    }
}
