import SwiftUI

/// Standard edge label display. | 標準のエッジラベル表示。
/// Reflects style specifications such as background, padding, and corner radius. | 背景、パディング、角丸などのスタイル指定を反映します。
struct EdgeLabelView: View {
    let label: String
    let style: EdgeLabelStyle
    var maxWidth: Double? = nil
    
    var body: some View {
        Text(label)
            .font(resolvedFont)
            .foregroundColor(resolvedTextColor)
            .lineLimit(maxWidth == nil ? nil : 1)
            .truncationMode(.middle)
            .frame(maxWidth: resolvedMaxWidth)
            .padding(.horizontal, style.bgPadding * zoomLevel)
            .padding(.vertical, (style.bgPadding * 0.4) * zoomLevel)
            .background(backgroundView)
    }
    
    private var resolvedFont: Font {
        let baseSize: CGFloat = {
            if let size = style.fontSize { return size }
            switch style.font?.lowercased() {
            case "caption": return 12
            case "caption2": return 10
            case "footnote": return 13
            case "subheadline": return 15
            case "callout": return 16
            case "body": return 17
            default: return 10
            }
        }()
        return .system(size: baseSize * zoomLevel)
    }
    
    private var resolvedTextColor: Color {
        if let hex = style.textColor {
            return Color(hex: hex)
        }
        return .primary
    }
    
    @Environment(\.isGraphExporting) private var isGraphExporting
    @Environment(\.graphZoomLevel) private var zoomLevel

    private var resolvedMaxWidth: CGFloat? {
        maxWidth.map { CGFloat($0) * zoomLevel }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if style.showBg {
            #if os(macOS)
            Group {
                if isGraphExporting || zoomLevel > 1.0 {
                    // Use opaque background during export or when zoomed in to avoid blurring from materials | エクスポート時や拡大時はマテリアルによるにじみを避けるため不透明背景を使用
                    exportBgColor
                } else {
                    VisualEffectView()
                        .overlay(resolvedBgColor.opacity(0.5))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: style.bgBorderRadius))
            .shadow(color: .black.opacity(zoomLevel > 1.0 ? 0 : 0.08), radius: zoomLevel > 1.0 ? 0 : 1)
            #else
            backgroundForMobile
                .clipShape(RoundedRectangle(cornerRadius: style.bgBorderRadius))
                .shadow(color: .black.opacity(zoomLevel > 1.0 ? 0 : 0.1), radius: zoomLevel > 1.0 ? 0 : 2)
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
        if #available(iOS 15.0, *), zoomLevel <= 1.0 {
            Rectangle()
                .fill(.thinMaterial)
                .overlay(resolvedBgColor.opacity(0.2))
        } else {
            exportBgColor
        }
    }
    #endif
}
