import Foundation

public struct EdgePathResult: Sendable, Equatable {
    public var segments: [PathSegment]
    public var labelX: Double
    public var labelY: Double
    public var offsetX: Double
    public var offsetY: Double

    /// SVG 互換のパス文字列。segments から動的に生成します。
    public var path: String {
        segments.toSVGString()
    }

    /// ターゲット地点におけるパスの接線角度（ラジアン）。マーカーの向きに使用。
    public var targetTangentAngle: Double?

    /// ソース地点におけるパスの接線角度（ラジアン）。始点マーカーの向きに使用。
    public var sourceTangentAngle: Double?

    public init(
        segments: [PathSegment],
        labelX: Double,
        labelY: Double,
        offsetX: Double,
        offsetY: Double,
        targetTangentAngle: Double? = nil,
        sourceTangentAngle: Double? = nil
    ) {
        self.segments = segments
        self.labelX = labelX
        self.labelY = labelY
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.targetTangentAngle = targetTangentAngle
        self.sourceTangentAngle = sourceTangentAngle
    }
}

extension Array where Element == PathSegment {
    /// SVG 互換のパス文字列に変換します。
    public func toSVGString() -> String {
        self.map { segment in
            switch segment {
            case .move(let to):
                return "M\(to.x),\(to.y)"
            case .line(let to):
                return "L\(to.x),\(to.y)"
            case .bezier(let to, let c1, let c2):
                return "C\(c1.x),\(c1.y) \(c2.x),\(c2.y) \(to.x),\(to.y)"
            case .quadratic(let to, let c):
                return "Q\(c.x),\(c.y) \(to.x),\(to.y)"
            }
        }.joined(separator: " ")
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
        let angle = atan2(targetY - sourceY, targetX - sourceX)
        return EdgePathResult(
            segments: [
                .move(to: XYPosition(x: sourceX, y: sourceY)),
                .line(to: XYPosition(x: targetX, y: targetY))
            ],
            labelX: center.x,
            labelY: center.y,
            offsetX: center.offsetX,
            offsetY: center.offsetY,
            targetTangentAngle: angle,
            sourceTangentAngle: angle
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

        let p0 = XYPosition(x: sourceX, y: sourceY)
        let p3 = XYPosition(x: targetX, y: targetY)
        
        return EdgePathResult(
            segments: [
                .move(to: p0),
                .bezier(to: p3, control1: sourceControl, control2: targetControl)
            ],
            labelX: center.x,
            labelY: center.y,
            offsetX: center.offsetX,
            offsetY: center.offsetY,
            targetTangentAngle: bezierTangentAngle(t: 1.0, p0: p0, p1: sourceControl, p2: targetControl, p3: p3),
            sourceTangentAngle: bezierTangentAngle(t: 0.0, p0: p0, p1: sourceControl, p2: targetControl, p3: p3)
        )
    }

    private static func bezierTangentAngle(t: Double, p0: XYPosition, p1: XYPosition, p2: XYPosition, p3: XYPosition) -> Double {
        let t1 = 1.0 - t
        // B'(t) = 3(1-t)^2(P1-P0) + 6(1-t)t(P2-P1) + 3t^2(P3-P2)
        let dx = 3 * t1 * t1 * (p1.x - p0.x) + 6 * t1 * t * (p2.x - p1.x) + 3 * t * t * (p3.x - p2.x)
        let dy = 3 * t1 * t1 * (p1.y - p0.y) + 6 * t1 * t * (p2.y - p1.y) + 3 * t * t * (p3.y - p2.y)
        return atan2(dy, dx)
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

        var segments: [PathSegment] = [.move(to: result.points[0])]
        for index in 1..<(result.points.count - 1) {
            segments.append(contentsOf: bendSegments(from: result.points[index - 1], via: result.points[index], to: result.points[index + 1], size: borderRadius))
        }
        segments.append(.line(to: result.points[result.points.count - 1]))

        // 接線角度: 最後のセグメントの方向
        let lastPoint = result.points[result.points.count - 1]
        let prevPoint = result.points[result.points.count - 2]
        let targetTangent = atan2(lastPoint.y - prevPoint.y, lastPoint.x - prevPoint.x)

        // 始点の接線角度: 最初のセグメントの方向
        let firstPoint = result.points[0]
        let secondPoint = result.points[1]
        let sourceTangent = atan2(secondPoint.y - firstPoint.y, secondPoint.x - firstPoint.x)

        return EdgePathResult(
            segments: segments,
            labelX: result.labelX,
            labelY: result.labelY,
            offsetX: result.offsetX,
            offsetY: result.offsetY,
            targetTangentAngle: targetTangent,
            sourceTangentAngle: sourceTangent
        )
    }

    public static func stepPath(
        sourceX: Double,
        sourceY: Double,
        sourcePosition: Position = .bottom,
        targetX: Double,
        targetY: Double,
        targetPosition: Position = .top,
        centerX: Double? = nil,
        centerY: Double? = nil,
        offset: Double = 20,
        stepPosition: Double = 0.5
    ) -> EdgePathResult {
        return smoothStepPath(
            sourceX: sourceX,
            sourceY: sourceY,
            sourcePosition: sourcePosition,
            targetX: targetX,
            targetY: targetY,
            targetPosition: targetPosition,
            borderRadius: 0,
            centerX: centerX,
            centerY: centerY,
            offset: offset,
            stepPosition: stepPosition
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

    internal static func smoothStepPoints(
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
        
        var points: [XYPosition] = []
        var centerX: Double
        var centerY: Double
        
        var sourceGapOffset = XYPosition(x: 0, y: 0)
        var targetGapOffset = XYPosition(x: 0, y: 0)

        let (_, _, defaultOffsetX, defaultOffsetY) = edgeCenter(sourceX: source.x, sourceY: source.y, targetX: target.x, targetY: target.y)

        // opposite handle positions, default case
        if (primaryIsX ? sourceDir.x : sourceDir.y) * (primaryIsX ? targetDir.x : targetDir.y) == -1 {
            if primaryIsX {
                centerX = center.x ?? sourceGapped.x + (targetGapped.x - sourceGapped.x) * stepPosition
                centerY = center.y ?? (sourceGapped.y + targetGapped.y) / 2
            } else {
                centerX = center.x ?? (sourceGapped.x + targetGapped.x) / 2
                centerY = center.y ?? sourceGapped.y + (targetGapped.y - sourceGapped.y) * stepPosition
            }

            let verticalSplit = [XYPosition(x: centerX, y: sourceGapped.y), XYPosition(x: centerX, y: targetGapped.y)]
            let horizontalSplit = [XYPosition(x: sourceGapped.x, y: centerY), XYPosition(x: targetGapped.x, y: centerY)]

            if (primaryIsX ? sourceDir.x : sourceDir.y) == currentDirection {
                points = primaryIsX ? verticalSplit : horizontalSplit
            } else {
                points = primaryIsX ? horizontalSplit : verticalSplit
            }
        } else {
            let sourceTarget = [XYPosition(x: sourceGapped.x, y: targetGapped.y)]
            let targetSource = [XYPosition(x: targetGapped.x, y: sourceGapped.y)]

            if primaryIsX {
                points = sourceDir.x == currentDirection ? targetSource : sourceTarget
            } else {
                points = sourceDir.y == currentDirection ? sourceTarget : targetSource
            }

            if sourcePosition == targetPosition {
                let diff = abs(primaryIsX ? (source.x - target.x) : (source.y - target.y))
                if diff <= offset {
                    let gapOffsetVal = min(offset - 1, offset - diff)
                    if (primaryIsX ? sourceDir.x : sourceDir.y) == currentDirection {
                        if primaryIsX {
                            sourceGapOffset.x = (sourceGapped.x > source.x ? -1 : 1) * gapOffsetVal
                        } else {
                            sourceGapOffset.y = (sourceGapped.y > source.y ? -1 : 1) * gapOffsetVal
                        }
                    } else {
                        if primaryIsX {
                            targetGapOffset.x = (targetGapped.x > target.x ? -1 : 1) * gapOffsetVal
                        } else {
                            targetGapOffset.y = (targetGapped.y > target.y ? -1 : 1) * gapOffsetVal
                        }
                    }
                }
            }

            if sourcePosition != targetPosition {
                let isSameDir = primaryIsX ? (sourceDir.x == targetDir.y) : (sourceDir.y == targetDir.x)
                let sourceGtTargetOppo = primaryIsX ? (sourceGapped.y > targetGapped.y) : (sourceGapped.x > targetGapped.x)
                let sourceLtTargetOppo = primaryIsX ? (sourceGapped.y < targetGapped.y) : (sourceGapped.x < targetGapped.x)
                
                let flipSourceTarget = (primaryIsX ? (sourceDir.x == 1) : (sourceDir.y == 1))
                    ? ((!isSameDir && sourceGtTargetOppo) || (isSameDir && sourceLtTargetOppo))
                    : ((!isSameDir && sourceLtTargetOppo) || (isSameDir && sourceGtTargetOppo))

                if flipSourceTarget {
                    points = primaryIsX ? sourceTarget : targetSource
                }
            }

            let sourceGapPoint = XYPosition(x: sourceGapped.x + sourceGapOffset.x, y: sourceGapped.y + sourceGapOffset.y)
            let targetGapPoint = XYPosition(x: targetGapped.x + targetGapOffset.x, y: targetGapped.y + targetGapOffset.y)
            let maxXDistance = max(abs(sourceGapPoint.x - points[0].x), abs(targetGapPoint.x - points[0].x))
            let maxYDistance = max(abs(sourceGapPoint.y - points[0].y), abs(targetGapPoint.y - points[0].y))

            if maxXDistance >= maxYDistance {
                centerX = (sourceGapPoint.x + targetGapPoint.x) / 2
                centerY = points[0].y
            } else {
                centerX = points[0].x
                centerY = (sourceGapPoint.y + targetGapPoint.y) / 2
            }
        }

        // 視覚的中心の最終調整: 
        // 複雑なパスや曲げがある場合でも、主たる水平または垂直なセグメントの中央を指すようにし、
        // 意図しない「端」への寄りを防ぐ（現状の実装で主セグメントの中央を捉えていることを確認済み）。

        let gappedSource = XYPosition(x: sourceGapped.x + sourceGapOffset.x, y: sourceGapped.y + sourceGapOffset.y)
        let gappedTarget = XYPosition(x: targetGapped.x + targetGapOffset.x, y: targetGapped.y + targetGapOffset.y)

        let pathPoints = [source] +
            (gappedSource != points[0] ? [gappedSource] : []) +
            points +
            (gappedTarget != points[points.count - 1] ? [gappedTarget] : []) +
            [target]

        return (pathPoints, centerX, centerY, defaultOffsetX, defaultOffsetY)
    }

    private static func bendSegments(from first: XYPosition, via middle: XYPosition, to third: XYPosition, size: Double) -> [PathSegment] {
        let bendSize = min(distance(first, middle) / 2, distance(middle, third) / 2, size)
        let x = middle.x
        let y = middle.y

        if (first.x == x && x == third.x) || (first.y == y && y == third.y) {
            return [.line(to: XYPosition(x: x, y: y))]
        }

        if first.y == y {
            let xDirection = first.x < third.x ? -1.0 : 1.0
            let yDirection = first.y < third.y ? 1.0 : -1.0
            return [
                .line(to: XYPosition(x: x + bendSize * xDirection, y: y)),
                .quadratic(to: XYPosition(x: x, y: y + bendSize * yDirection), control: XYPosition(x: x, y: y))
            ]
        }

        let xDirection = first.x < third.x ? 1.0 : -1.0
        let yDirection = first.y < third.y ? -1.0 : 1.0
        return [
            .line(to: XYPosition(x: x, y: y + bendSize * yDirection)),
            .quadratic(to: XYPosition(x: x + bendSize * xDirection, y: y), control: XYPosition(x: x, y: y))
        ]
    }
}
