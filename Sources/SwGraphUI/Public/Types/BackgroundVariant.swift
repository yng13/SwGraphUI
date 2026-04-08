import SwiftUI

/// 背景の描画スタイルを指定するバリアント
public enum BackgroundVariant: String, Codable, Sendable, CaseIterable {
    /// ドット（点）
    case dots
    /// ライン（線）
    case lines
    /// 十字（クロス）
    case cross
}
