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
        let peers = edges
            .filter { !$0.hidden && unorderedPairKey($0.source, $0.target) == unorderedPairKey(edge.source, edge.target) }
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

    public static func applyLane(
        to result: EdgePathResult,
        source: XYPosition,
        target: XYPosition,
        sourceNodeID: String,
        targetNodeID: String,
        assignment: EdgeLaneAssignment
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

        let adjustedSegments = laneSegments(result.segments, source: source, target: target, offset: offset)
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

    private static func unorderedPairKey(_ first: String, _ second: String) -> String {
        first <= second ? "\(first)\u{1F}#\(second)" : "\(second)\u{1F}#\(first)"
    }

    private static func laneSegments(
        _ segments: [PathSegment],
        source: XYPosition,
        target: XYPosition,
        offset: XYPosition
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
        return segments.enumerated().map { index, segment in
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
    }

    private static func shifted(_ point: XYPosition, by offset: XYPosition) -> XYPosition {
        XYPosition(x: point.x + offset.x, y: point.y + offset.y)
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
