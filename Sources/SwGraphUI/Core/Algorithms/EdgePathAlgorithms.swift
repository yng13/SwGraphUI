import Foundation

public struct EdgePathResult: Sendable, Equatable {
    public var path: String
    public var labelX: Double
    public var labelY: Double
    public var offsetX: Double
    public var offsetY: Double

    public init(path: String, labelX: Double, labelY: Double, offsetX: Double, offsetY: Double) {
        self.path = path
        self.labelX = labelX
        self.labelY = labelY
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
}

public enum EdgePathAlgorithms {
    public static func edgeCenter(
        sourceX: Double,
        sourceY: Double,
        targetX: Double,
        targetY: Double
    ) -> (x: Double, y: Double, offsetX: Double, offsetY: Double) {
        let offsetX = abs(targetX - sourceX) / 2
        let centerX = targetX < sourceX ? targetX + offsetX : targetX - offsetX
        let offsetY = abs(targetY - sourceY) / 2
        let centerY = targetY < sourceY ? targetY + offsetY : targetY - offsetY
        return (centerX, centerY, offsetX, offsetY)
    }

    public static func straightPath(
        sourceX: Double,
        sourceY: Double,
        targetX: Double,
        targetY: Double
    ) -> EdgePathResult {
        let center = edgeCenter(sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
        return EdgePathResult(
            path: "M \(sourceX),\(sourceY)L \(targetX),\(targetY)",
            labelX: center.x,
            labelY: center.y,
            offsetX: center.offsetX,
            offsetY: center.offsetY
        )
    }

    public static func bezierPath(
        sourceX: Double,
        sourceY: Double,
        sourcePosition: Position = .bottom,
        targetX: Double,
        targetY: Double,
        targetPosition: Position = .top,
        curvature: Double = 0.25
    ) -> EdgePathResult {
        let sourceControl = controlPoint(
            position: sourcePosition,
            x1: sourceX,
            y1: sourceY,
            x2: targetX,
            y2: targetY,
            curvature: curvature
        )
        let targetControl = controlPoint(
            position: targetPosition,
            x1: targetX,
            y1: targetY,
            x2: sourceX,
            y2: sourceY,
            curvature: curvature
        )
        let center = bezierCenter(
            sourceX: sourceX,
            sourceY: sourceY,
            targetX: targetX,
            targetY: targetY,
            sourceControlX: sourceControl.x,
            sourceControlY: sourceControl.y,
            targetControlX: targetControl.x,
            targetControlY: targetControl.y
        )

        return EdgePathResult(
            path: "M\(sourceX),\(sourceY) C\(sourceControl.x),\(sourceControl.y) \(targetControl.x),\(targetControl.y) \(targetX),\(targetY)",
            labelX: center.x,
            labelY: center.y,
            offsetX: center.offsetX,
            offsetY: center.offsetY
        )
    }

    public static func smoothStepPath(
        sourceX: Double,
        sourceY: Double,
        sourcePosition: Position = .bottom,
        targetX: Double,
        targetY: Double,
        targetPosition: Position = .top,
        borderRadius: Double = 5,
        centerX: Double? = nil,
        centerY: Double? = nil,
        offset: Double = 20,
        stepPosition: Double = 0.5
    ) -> EdgePathResult {
        let result = smoothStepPoints(
            source: .init(x: sourceX, y: sourceY),
            sourcePosition: sourcePosition,
            target: .init(x: targetX, y: targetY),
            targetPosition: targetPosition,
            center: (x: centerX, y: centerY),
            offset: offset,
            stepPosition: stepPosition
        )

        var path = "M\(result.points[0].x) \(result.points[0].y)"
        for index in 1..<(result.points.count - 1) {
            path += bend(from: result.points[index - 1], via: result.points[index], to: result.points[index + 1], size: borderRadius)
        }
        path += "L\(result.points[result.points.count - 1].x) \(result.points[result.points.count - 1].y)"

        return EdgePathResult(
            path: path,
            labelX: result.labelX,
            labelY: result.labelY,
            offsetX: result.offsetX,
            offsetY: result.offsetY
        )
    }

    private static func controlOffset(distance: Double, curvature: Double) -> Double {
        if distance >= 0 {
            return 0.5 * distance
        }
        return curvature * 25 * sqrt(-distance)
    }

    private static func controlPoint(
        position: Position,
        x1: Double,
        y1: Double,
        x2: Double,
        y2: Double,
        curvature: Double
    ) -> XYPosition {
        switch position {
        case .left:
            return XYPosition(x: x1 - controlOffset(distance: x1 - x2, curvature: curvature), y: y1)
        case .right:
            return XYPosition(x: x1 + controlOffset(distance: x2 - x1, curvature: curvature), y: y1)
        case .top:
            return XYPosition(x: x1, y: y1 - controlOffset(distance: y1 - y2, curvature: curvature))
        case .bottom:
            return XYPosition(x: x1, y: y1 + controlOffset(distance: y2 - y1, curvature: curvature))
        }
    }

    private static func bezierCenter(
        sourceX: Double,
        sourceY: Double,
        targetX: Double,
        targetY: Double,
        sourceControlX: Double,
        sourceControlY: Double,
        targetControlX: Double,
        targetControlY: Double
    ) -> (x: Double, y: Double, offsetX: Double, offsetY: Double) {
        let centerX = sourceX * 0.125 + sourceControlX * 0.375 + targetControlX * 0.375 + targetX * 0.125
        let centerY = sourceY * 0.125 + sourceControlY * 0.375 + targetControlY * 0.375 + targetY * 0.125
        return (centerX, centerY, abs(centerX - sourceX), abs(centerY - sourceY))
    }

    private static let handleDirections: [Position: XYPosition] = [
        .left: .init(x: -1, y: 0),
        .right: .init(x: 1, y: 0),
        .top: .init(x: 0, y: -1),
        .bottom: .init(x: 0, y: 1),
    ]

    private static func edgeDirection(source: XYPosition, sourcePosition: Position, target: XYPosition) -> XYPosition {
        if sourcePosition == .left || sourcePosition == .right {
            return source.x < target.x ? .init(x: 1, y: 0) : .init(x: -1, y: 0)
        }
        return source.y < target.y ? .init(x: 0, y: 1) : .init(x: 0, y: -1)
    }

    private static func distance(_ first: XYPosition, _ second: XYPosition) -> Double {
        sqrt(pow(second.x - first.x, 2) + pow(second.y - first.y, 2))
    }

    private static func smoothStepPoints(
        source: XYPosition,
        sourcePosition: Position,
        target: XYPosition,
        targetPosition: Position,
        center: (x: Double?, y: Double?),
        offset: Double,
        stepPosition: Double
    ) -> (points: [XYPosition], labelX: Double, labelY: Double, offsetX: Double, offsetY: Double) {
        let sourceDir = handleDirections[sourcePosition]!
        let targetDir = handleDirections[targetPosition]!
        let sourceGapped = XYPosition(x: source.x + sourceDir.x * offset, y: source.y + sourceDir.y * offset)
        let targetGapped = XYPosition(x: target.x + targetDir.x * offset, y: target.y + targetDir.y * offset)
        let direction = edgeDirection(source: sourceGapped, sourcePosition: sourcePosition, target: targetGapped)
        let primaryIsX = direction.x != 0
        let currentDirection = primaryIsX ? direction.x : direction.y
        let baseCenter = edgeCenter(sourceX: source.x, sourceY: source.y, targetX: target.x, targetY: target.y)

        var points: [XYPosition]
        var labelX: Double
        var labelY: Double

        if (primaryIsX ? sourceDir.x : sourceDir.y) * (primaryIsX ? targetDir.x : targetDir.y) == -1 {
            let bendX = center.x ?? (primaryIsX ? sourceGapped.x + (targetGapped.x - sourceGapped.x) * stepPosition : (sourceGapped.x + targetGapped.x) / 2)
            let bendY = center.y ?? (primaryIsX ? (sourceGapped.y + targetGapped.y) / 2 : sourceGapped.y + (targetGapped.y - sourceGapped.y) * stepPosition)
            let verticalSplit = [XYPosition(x: bendX, y: sourceGapped.y), XYPosition(x: bendX, y: targetGapped.y)]
            let horizontalSplit = [XYPosition(x: sourceGapped.x, y: bendY), XYPosition(x: targetGapped.x, y: bendY)]

            if (primaryIsX ? sourceDir.x : sourceDir.y) == currentDirection {
                points = primaryIsX ? verticalSplit : horizontalSplit
            } else {
                points = primaryIsX ? horizontalSplit : verticalSplit
            }

            labelX = bendX
            labelY = bendY
        } else {
            let corner = primaryIsX
                ? (sourceDir.x == currentDirection ? XYPosition(x: targetGapped.x, y: sourceGapped.y) : XYPosition(x: sourceGapped.x, y: targetGapped.y))
                : (sourceDir.y == currentDirection ? XYPosition(x: sourceGapped.x, y: targetGapped.y) : XYPosition(x: targetGapped.x, y: sourceGapped.y))
            points = [corner]

            let sourceGapPoint = sourceGapped
            let targetGapPoint = targetGapped
            let maxXDistance = max(abs(sourceGapPoint.x - corner.x), abs(targetGapPoint.x - corner.x))
            let maxYDistance = max(abs(sourceGapPoint.y - corner.y), abs(targetGapPoint.y - corner.y))

            if maxXDistance >= maxYDistance {
                labelX = (sourceGapPoint.x + targetGapPoint.x) / 2
                labelY = corner.y
            } else {
                labelX = corner.x
                labelY = (sourceGapPoint.y + targetGapPoint.y) / 2
            }
        }

        let pathPoints = [source, sourceGapped] + points + [targetGapped, target]
        let compacted: [XYPosition] = pathPoints.enumerated().compactMap { entry in
            let index = entry.offset
            let point = entry.element
            guard index == 0 || pathPoints[index - 1] != point else { return nil }
            return point
        }

        return (compacted, labelX, labelY, baseCenter.offsetX, baseCenter.offsetY)
    }

    private static func bend(from first: XYPosition, via middle: XYPosition, to third: XYPosition, size: Double) -> String {
        let bendSize = min(distance(first, middle) / 2, distance(middle, third) / 2, size)
        let x = middle.x
        let y = middle.y

        if (first.x == x && x == third.x) || (first.y == y && y == third.y) {
            return "L\(x) \(y)"
        }

        if first.y == y {
            let xDirection = first.x < third.x ? -1.0 : 1.0
            let yDirection = first.y < third.y ? 1.0 : -1.0
            return "L \(x + bendSize * xDirection),\(y)Q \(x),\(y) \(x),\(y + bendSize * yDirection)"
        }

        let xDirection = first.x < third.x ? 1.0 : -1.0
        let yDirection = first.y < third.y ? -1.0 : 1.0
        return "L \(x),\(y + bendSize * yDirection)Q \(x),\(y) \(x + bendSize * xDirection),\(y)"
    }
}
