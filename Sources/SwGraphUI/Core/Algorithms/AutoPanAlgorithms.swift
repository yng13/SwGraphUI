import Foundation

/// オートパン（自動スクロール）の計算に関する純粋な幾何ロジックを提供します。
public enum AutoPanAlgorithms {
    
    /// 画面端付近でのパン速度を算出します。
    /// - Parameters:
    ///   - mousePosition: マウスまたはポインタの現在の画面内座標。
    ///   - containerSize: ビューポートを表示しているコンテナの寸法。
    ///   - speed: 基本移動速度（デフォルト 15）。
    ///   - threshold: 端からの距離のしきい値（デフォルト 40）。
    /// - Returns: ビューポートに加算すべき移動量。
    public static func calculateVelocity(
        mousePosition: XYPosition,
        containerSize: Dimensions,
        speed: Double = 15,
        threshold: Double = 40
    ) -> XYPosition {
        // ゼロサイズや負の閾値による 0 除算 (NaN/Infinity) 回避
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
    
    /// 1次元（XまたはYチャネル）での速度係数を算出します。
    /// - Parameters:
    ///   - value: 現在の、しきい値。
    ///   - min: 下限（しきい値）。
    ///   - max: 上限（サイズ - しきい値）。
    ///   - threshold: しきい値。
    /// - Returns: -1.0 〜 1.0 の係数。
    private static func calculateVelocity1D(
        value: Double,
        min: Double,
        max: Double,
        threshold: Double
    ) -> Double {
        if value < min {
            // 左・上端に近い場合：Viewport をプラス方向に動かす（コンテンツを右・下に送る）
            let delta = Swift.abs(value - min)
            let clamped = Swift.min(Swift.max(delta, 1), threshold)
            return clamped / threshold
        } else if value > max {
            // 右・下端に近い場合：Viewport をマイナス方向に動かす（コンテンツを左・上に送る）
            let delta = Swift.abs(value - max)
            let clamped = Swift.min(Swift.max(delta, 1), threshold)
            return -clamped / threshold
        }
        
        return 0
    }
}
