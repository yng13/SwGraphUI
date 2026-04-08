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
    ///   - preserveAspectRatio: 比率を維持するかどうか
    public static func calculate(
        original: ResizeResult,
        handlePosition: ResizeControlPosition,
        deltaX: Double,
        deltaY: Double,
        minWidth: Double,
        minHeight: Double,
        maxWidth: Double = .infinity,
        maxHeight: Double = .infinity,
        preserveAspectRatio: Bool = false
    ) -> ResizeResult {
        var newX = original.x
        var newY = original.y
        var newWidth = original.width
        var newHeight = original.height

        if preserveAspectRatio {
            // アスペクト比の算出
            let ratio = original.width / original.height
            
            // 変化量が大きい方を主軸とする（より意図に近い拡大率を採用）
            let absDeltaX = abs(deltaX)
            let absDeltaY = abs(deltaY)
            
            if absDeltaX / original.width > absDeltaY / original.height {
                // Width 主導
                let isLeft = handlePosition == .left || handlePosition == .topLeft || handlePosition == .bottomLeft
                let sign: Double = isLeft ? -1 : 1
                let targetWidth = max(minWidth, min(maxWidth, original.width + deltaX * sign))
                newWidth = targetWidth
                newHeight = newWidth / ratio
                
                // Height 側の制約チェック
                if newHeight < minHeight {
                    newHeight = minHeight
                    newWidth = newHeight * ratio
                } else if newHeight > maxHeight {
                    newHeight = maxHeight
                    newWidth = newHeight * ratio
                }
            } else {
                // Height 主導
                let isTop = handlePosition == .top || handlePosition == .topLeft || handlePosition == .topRight
                let sign: Double = isTop ? -1 : 1
                let targetHeight = max(minHeight, min(maxHeight, original.height + deltaY * sign))
                newHeight = targetHeight
                newWidth = newHeight * ratio
                
                // Width 側の制約チェック
                if newWidth < minWidth {
                    newWidth = minWidth
                    newHeight = newWidth / ratio
                } else if newWidth > maxWidth {
                    newWidth = maxWidth
                    newHeight = newWidth / ratio
                }
            }
            
            // X/Y 座標の補正 (反対側を固定するため)
            // 左側/上側のハンドル操作時のみオフセットが必要
            switch handlePosition {
            case .topLeft:
                newX = original.x + (original.width - newWidth)
                newY = original.y + (original.height - newHeight)
            case .topRight:
                newY = original.y + (original.height - newHeight)
            case .bottomLeft:
                newX = original.x + (original.width - newWidth)
            default:
                break
            }
        } else {
            // 自由リサイズ (従来通り)
            // 水平方向のリサイズ
            switch handlePosition {
            case .left, .topLeft, .bottomLeft:
                let nextWidth = max(minWidth, min(maxWidth, original.width - deltaX))
                newX = original.x + (original.width - nextWidth)
                newWidth = nextWidth
            case .right, .topRight, .bottomRight:
                newWidth = max(minWidth, min(maxWidth, original.width + deltaX))
            default:
                break
            }

            // 垂直方向のリサイズ
            switch handlePosition {
            case .top, .topLeft, .topRight:
                let nextHeight = max(minHeight, min(maxHeight, original.height - deltaY))
                newY = original.y + (original.height - nextHeight)
                newHeight = nextHeight
            case .bottom, .bottomLeft, .bottomRight:
                newHeight = max(minHeight, min(maxHeight, original.height + deltaY))
            default:
                break
            }
        }

        return ResizeResult(x: newX, y: newY, width: newWidth, height: newHeight)
    }
}
