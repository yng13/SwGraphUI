import Foundation

/// Provides pure geometric logic for calculating auto-pan (automatic scrolling). | オートパン（自動スクロール）の計算に関する純粋な幾何ロジックを提供します。
public enum AutoPanAlgorithms {
    
    /// Calculates the pan velocity near the edge of the screen. | 画面端付近でのパン速度を算出します。
    /// - Parameters:
    ///   - mousePosition: The current screen coordinates of the mouse or pointer. | マウスまたはポインタの現在の画面内座標。
    ///   - containerSize: Dimensions of the container displaying the viewport. | コンテナの寸法。
    ///   - speed: Base movement speed (default 15). | 基本移動速度（デフォルト 15）。
    ///   - threshold: Distance threshold from the edge (default 40). | 端からの距離のしきい値（デフォルト 40）。
    /// - Returns: The amount of velocity to be added to the viewport. | ビューポートに加算すべき移動量。
    public static func calculateVelocity(
        mousePosition: XYPosition,
        containerSize: Dimensions,
        speed: Double = 15,
        threshold: Double = 40
    ) -> XYPosition {
        // Avoid division by zero (NaN/Infinity) caused by zero size or negative threshold | ゼロサイズや負の閾値による 0 除算 (NaN/Infinity) 回避
        guard containerSize.width > 0, containerSize.height > 0, threshold > 0 else {
            return .zero
        }
        
        let xMovement = calculateVelocity1D(
            value: mousePosition.x,
            min: threshold,
            max: containerSize.width - threshold,
            threshold: threshold
        ) * speed
        
        let yMovement = calculateVelocity1D(
            value: mousePosition.y,
            min: threshold,
            max: containerSize.height - threshold,
            threshold: threshold
        ) * speed
        
        return XYPosition(x: xMovement, y: yMovement)
    }
    
    /// Calculates the velocity coefficient in one dimension (X or Y channel). | 1次元（XまたはYチャネル）での速度係数を算出します。
    /// - Parameters:
    ///   - value: Current coordinate value. | 現在の座標値。
    ///   - min: Lower limit (threshold). | 下限（しきい値）。
    ///   - max: Upper limit (size - threshold). | 上限（サイズ - しきい値）。
    ///   - threshold: Threshold. | しきい値。
    /// - Returns: Coefficient between -1.0 and 1.0. | -1.0 〜 1.0 の係数。
    private static func calculateVelocity1D(
        value: Double,
        min: Double,
        max: Double,
        threshold: Double
    ) -> Double {
        if value < min {
            // Near left/top edge: Move viewport in positive direction (scroll content right/down) | 左・上端に近い場合：Viewport をプラス方向に動かす（コンテンツを右・下に送る）
            let delta = Swift.abs(value - min)
            let clamped = Swift.min(Swift.max(delta, 1), threshold)
            return clamped / threshold
        } else if value > max {
            // Near right/bottom edge: Move viewport in negative direction (scroll content left/up) | 右・下端に近い場合：Viewport をマイナス方向に動かす（コンテンツを左・上に送る）
            let delta = Swift.abs(value - max)
            let clamped = Swift.min(Swift.max(delta, 1), threshold)
            return -clamped / threshold
        }
        
        return 0
    }
}
