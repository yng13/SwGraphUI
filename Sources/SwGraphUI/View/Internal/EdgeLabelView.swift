import SwiftUI

/// 標準のエッジラベル表示。
/// 背景、パディング、角丸などのスタイル指定を反映します。
struct EdgeLabelView: View {
    let label: String
    let style: EdgeLabelStyle
    
    var body: some View {
        Text(label)
            .font(resolvedFont)
            .foregroundColor(resolvedTextColor)
            .padding(.horizontal, style.bgPadding)
            .padding(.vertical, style.bgPadding * 0.4)
            .background(backgroundView)
    }
    
    private var resolvedFont: Font {
        if let size = style.fontSize {
            return .system(size: size)
        }
        switch style.font?.lowercased() {
        case "caption": return .caption
        case "caption2": return .caption2
        case "footnote": return .footnote
        case "subheadline": return .subheadline
        case "callout": return .callout
        case "body": return .body
        default: return .caption2
        }
    }
    
    private var resolvedTextColor: Color {
        if let hex = style.textColor {
            return Color(hex: hex)
        }
        return .primary
    }
    
    @Environment(\.isGraphExporting) private var isGraphExporting
    
    @ViewBuilder
    private var backgroundView: some View {
        if style.showBg {
            #if os(macOS)
            Group {
                if isGraphExporting {
                    // エクスポート時は半透明マテリアルを避け、下の線や文字と重ならないよう不透明寄りの背景に固定します。
                    exportBgColor
                } else {
                    VisualEffectView()
                        .overlay(resolvedBgColor.opacity(0.5))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: style.bgBorderRadius))
            .shadow(color: .black.opacity(0.08), radius: 1)
            #else
            backgroundForMobile
                .clipShape(RoundedRectangle(cornerRadius: style.bgBorderRadius))
                .shadow(color: .black.opacity(0.1), radius: 2)
            #endif
        }
    }
    
    private var resolvedBgColor: Color {
        if let hex = style.bgStyle {
            return Color(hex: hex)
        }
        return Color.secondary.opacity(0.1)
    }

    private var exportBgColor: Color {
        if let hex = style.bgStyle {
            return Color(hex: hex)
        }
        #if os(macOS)
        return Color(nsColor: .textBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }

    #if os(iOS)
    @ViewBuilder
    private var backgroundForMobile: some View {
        if #available(iOS 15.0, *) {
            Rectangle()
                .fill(.thinMaterial)
                .overlay(resolvedBgColor.opacity(0.2))
        } else {
            resolvedBgColor
        }
    }
    #endif
}
