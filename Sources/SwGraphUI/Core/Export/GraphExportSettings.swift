import Foundation

/// グラフのエクスポート（PNG書き出し等）に関する設定を保持します。
public struct GraphExportSettings: Sendable {
    /// 書き出し時のスケール（1.0 が標準。2.0 や 3.0 で高解像度化）。
    public var scale: Double
    
    /// キャンバス周囲の余白（ポイント単位）。
    public var margin: Double
    
    /// 背景グリッドを含めるかどうか。
    public var includeBackground: Bool
    
    /// 背景グリッドのバリアント。
    public var backgroundVariant: BackgroundVariant
    
    /// 背景を透明にするかどうか。
    public var isTransparent: Bool
    
    public init(
        scale: Double = 2.0,
        margin: Double = 32.0,
        includeBackground: Bool = false,
        backgroundVariant: BackgroundVariant = .dots,
        isTransparent: Bool = false
    ) {
        self.scale = scale
        self.margin = margin
        self.includeBackground = includeBackground
        self.backgroundVariant = backgroundVariant
        self.isTransparent = isTransparent
    }
}
