import SwiftUI

/// Variant specifying the background drawing style | 背景の描画スタイルを指定するバリアント
public enum BackgroundVariant: String, Codable, Sendable, CaseIterable {
    /// Dots | ドット（点）
    case dots
    /// Lines | ライン（線）
    case lines
    /// Cross | 十字（クロス）
    case cross
}
