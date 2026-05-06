public enum EdgeEndpointLabelAlgorithms {
    public static let defaultOffset: Double = 14.0
    public static let defaultLaneGap: Double = 4.0

    public struct CollisionCandidate: Sendable, Equatable {
        public let id: String
        public let center: XYPosition
        public let extent: Double

        public init(id: String, center: XYPosition, extent: Double) {
            self.id = id
            self.center = center
            self.extent = extent
        }
    }

    public static func graphPosition(
        handlePoint: XYPosition,
        placement: Position,
        offset: Double = defaultOffset,
        collisionLane: Int = 0,
        crossAxisExtent: Double = 0,
        laneGap: Double = defaultLaneGap
    ) -> XYPosition {
        let vector = directionVector(for: placement)
        let laneOffset = Double(max(collisionLane, 0)) * (max(crossAxisExtent, 0) + laneGap)
        return XYPosition(
            x: handlePoint.x + vector.x * (offset + laneOffset),
            y: handlePoint.y + vector.y * (offset + laneOffset)
        )
    }

    public static func screenPosition(
        handlePoint: XYPosition,
        placement: Position,
        viewport: Viewport,
        offset: Double = defaultOffset,
        collisionLane: Int = 0,
        crossAxisExtent: Double = 0,
        laneGap: Double = defaultLaneGap
    ) -> XYPosition {
        graphPosition(
            handlePoint: handlePoint,
            placement: placement,
            offset: offset,
            collisionLane: collisionLane,
            crossAxisExtent: crossAxisExtent,
            laneGap: laneGap
        )
            .toScreen(viewport: viewport)
    }

    public static func collisionLane(
        id: String,
        placement: Position,
        candidates: [CollisionCandidate],
        spacing: Double = 6.0
    ) -> Int {
        let sorted = candidates.sorted { lhs, rhs in
            let lhsAxis = axisValue(for: lhs.center, placement: placement)
            let rhsAxis = axisValue(for: rhs.center, placement: placement)
            if lhsAxis == rhsAxis {
                return lhs.id.localizedStandardCompare(rhs.id) == .orderedAscending
            }
            return lhsAxis < rhsAxis
        }

        var laneMax: [Double] = []
        for candidate in sorted {
            let center = axisValue(for: candidate.center, placement: placement)
            let halfExtent = max(candidate.extent, 0) / 2
            let minValue = center - halfExtent
            let maxValue = center + halfExtent

            var lane = 0
            while lane < laneMax.count, minValue < laneMax[lane] + spacing {
                lane += 1
            }

            if lane == laneMax.count {
                laneMax.append(maxValue)
            } else {
                laneMax[lane] = maxValue
            }

            if candidate.id == id {
                return lane
            }
        }

        return 0
    }

    private static func directionVector(for placement: Position) -> XYPosition {
        switch placement {
        case .top:
            XYPosition(x: 0, y: -1)
        case .right:
            XYPosition(x: 1, y: 0)
        case .bottom:
            XYPosition(x: 0, y: 1)
        case .left:
            XYPosition(x: -1, y: 0)
        }
    }

    private static func axisValue(for position: XYPosition, placement: Position) -> Double {
        switch placement {
        case .top, .bottom:
            position.x
        case .left, .right:
            position.y
        }
    }
}
