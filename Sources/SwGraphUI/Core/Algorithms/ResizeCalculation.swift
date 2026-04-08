import Foundation

/// リサイズ操作用のハンドル/ラインの位置
public enum ResizeControlPosition: String, Sendable, CaseIterable {
    case top = "top"
    case bottom = "bottom"
    case left = "left"
    case right = "right"
    case topLeft = "top-left"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomRight = "bottom-right"
}

/// リサイズ計算の結果
public struct ResizeResult: Sendable, Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// リサイズ計算ロジック。ドラッグ操作による寸法変化と位置の変化を計算します。
public struct ResizeCalculation {
    /// 与えられたパラメータに基づき、新しいノードの矩形を計算します。
    /// - Parameters:
    ///   - original: ドラッグ開始時点の座標と寸法
    ///   - position: 操作しているハンドルの位置
    ///   - deltaX: ドラッグの開始点からの累積変位 (Graph Space)
    ///   - deltaY: ドラッグの開始点からの累積変位 (Graph Space)
    ///   - minWidth: 最小幅制約
    ///   - minHeight: 最小高さ制約
    ///   - maxWidth: 最大幅制約
    ///   - maxHeight: 最大高さ制約
    public static func calculate(
        original: ResizeResult,
        handlePosition: ResizeControlPosition,
        deltaX: Double,
        deltaY: Double,
        minWidth: Double,
        minHeight: Double,
        maxWidth: Double = .infinity,
        maxHeight: Double = .infinity
    ) -> ResizeResult {
        var newX = original.x
        var newY = original.y
        var newWidth = original.width
        var newHeight = original.height

        // 水平方向のリサイズ
        switch handlePosition {
        case .left, .topLeft, .bottomLeft:
            // 左側をドラッグする場合：幅を変え、その分 X 座標をオフセットする
            let nextWidth = max(minWidth, min(maxWidth, original.width - deltaX))
            newX = original.x + (original.width - nextWidth)
            newWidth = nextWidth
        case .right, .topRight, .bottomRight:
            // 右側をドラッグする場合：幅を変えるだけ
            newWidth = max(minWidth, min(maxWidth, original.width + deltaX))
        default:
            break
        }

        // 垂直方向のリサイズ
        switch handlePosition {
        case .top, .topLeft, .topRight:
            // 上側をドラッグする場合：高さを変え、その分 Y 座標をオフセットする
            let nextHeight = max(minHeight, min(maxHeight, original.height - deltaY))
            newY = original.y + (original.height - nextHeight)
            newHeight = nextHeight
        case .bottom, .bottomLeft, .bottomRight:
            // 下側をドラッグする場合：高さを変えるだけ
            newHeight = max(minHeight, min(maxHeight, original.height + deltaY))
        default:
            break
        }

        return ResizeResult(x: newX, y: newY, width: newWidth, height: newHeight)
    }
}
