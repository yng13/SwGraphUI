import SwiftUI

/// View providing node resizing operations. | ノードのリサイズ操作を提供する View。
/// Intended to be used as an overlay within the body of custom nodes. | カスタムノードの body 内でオーバーレイとして使用することを想定しています。
public struct NodeResizer<NodeData: Sendable>: View {
    @Environment(GraphStore<NodeData>.self) private var store
    @Environment(\.graphZoomLevel) private var zoomLevel
    let node: BaseNode<NodeData>
    let isVisible: Bool
    
    /// Creates a NodeResizer. | NodeResizer を作成します。
    /// - Parameters:
    ///   - node: Target node | 対象ノード
    ///   - isVisible: Resizer visibility (default is true. Determined in combination with store selection state) | リサイザーの可視性（デフォルトは true。store の選択状態と組み合わせて判定されます）
    public init(node: BaseNode<NodeData>, isVisible: Bool = true) {
        self.node = node
        self.isVisible = isVisible
    }
    
    @Environment(\.isGraphExporting) private var isGraphExporting
    
    public var body: some View {
        // Displayed only when selected and the model allows resizing | 選択中かつモデルがリサイズを許可している場合のみ表示
        // Hidden during export (isGraphExporting == true) | エクスポート時（isGraphExporting == true）は非表示
        if node.selected && isVisible && node.resizable && !isGraphExporting {
            let scale = max(CGFloat(zoomLevel), 0.0001)
            ZStack {
                // Guide border | ガイド枠線
                // lineWidth ensures visibility similar to SelectionBox (1.0 to 2.5 pt) | lineWidth も SelectionBox と同様に視認性を確保 (1.0 to 2.5 pt)
                Rectangle()
                    .stroke(Color.accentColor.opacity(0.6), lineWidth: min(max(1.0 / scale, 1.0), 2.5))
                
                // --- Edge Controls ---
                ResizeControlView<NodeData>(node: node, position: .top, variant: .line)
                ResizeControlView<NodeData>(node: node, position: .bottom, variant: .line)
                ResizeControlView<NodeData>(node: node, position: .left, variant: .line)
                ResizeControlView<NodeData>(node: node, position: .right, variant: .line)
                
                // --- Corner Controls ---
                ResizeControlView<NodeData>(node: node, position: .topLeft, variant: .handle)
                ResizeControlView<NodeData>(node: node, position: .topRight, variant: .handle)
                ResizeControlView<NodeData>(node: node, position: .bottomLeft, variant: .handle)
                ResizeControlView<NodeData>(node: node, position: .bottomRight, variant: .handle)
            }
            // Explicitly finalize the size of the resizer frame so it isn't affected by parent layout | 親側のレイアウトに左右されないよう、明示的にリサイザー枠のサイズを確定させる
            .frame(
                width: (node.width ?? node.measured?.width ?? 0) * scale,
                height: (node.height ?? node.measured?.height ?? 0) * scale
            )
        }
    }
}

private enum ControlVariant {
    case handle
    case line
}

private struct ResizeControlView<NodeData: Sendable>: View {
    @Environment(GraphStore<NodeData>.self) private var store
    @Environment(\.graphZoomLevel) private var zoomLevel
    let node: BaseNode<NodeData>
    let position: ResizeControlPosition
    let variant: ControlVariant
    
    @State private var startBounds: ResizeResult?
    @State private var modifierKeys = ModifierKeysProvider()
    
    private var isCorner: Bool {
        switch position {
        case .topLeft, .topRight, .bottomLeft, .bottomRight: return true
        default: return false
        }
    }
    
    var body: some View {
        Group {
            if variant == .handle {
                handleShape
            } else {
                lineShape
            }
        }
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    handleDrag(translation: value.translation)
                }
                .onEnded { _ in
                    store.stopResizing()
                    startBounds = nil
                }
        )
    }
    
    private var handleShape: some View {
        Circle()
            .fill(Color.white)
            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            .overlay(Circle().stroke(Color.accentColor, lineWidth: 1.5))
            .frame(width: 11, height: 11)
            // Visual size is clamped, but ensure hit detection area (outside the frame) | 視覚上のサイズはクランプするが、当たり判定（frameの外側）を確保
            // Limited to a range of about 8pt to 18pt on the screen | 画面上で 8pt 〜 18pt 程度の範囲に収まるように制限
            .scaleEffect(min(max(1.0 / CGFloat(zoomLevel), 0.8), 1.8))
            .contentShape(Circle().inset(by: -10)) // Maintains ease of operation (effective detection area of about 31pt) | 操作しやすさを維持 (実質 31pt 程度の判定領域)
            .modifier(ControlPositionModifier(position: position))
    }
    
    private var lineShape: some View {
        Rectangle()
            .fill(Color.accentColor.opacity(0.001)) // For hit detection | 当たり判定用
            .modifier(LinePositionModifier(position: position))
    }
    
    private func handleDrag(translation: CGSize) {
        let zoom = store.runtimeState.viewport.viewport.zoom
        
        if startBounds == nil {
            store.startResizing(id: node.id)
            startBounds = ResizeResult(
                x: node.position.x,
                y: node.position.y,
                width: node.width ?? node.measured?.width ?? 0,
                height: node.height ?? node.measured?.height ?? 0
            )
        }
        
        guard let start = startBounds else { return }
        
        // Convert translation to Graph Space delta | translation を Graph Space のデルタに変換
        let deltaX = translation.width / zoom
        let deltaY = translation.height / zoom
        
        // Maintain aspect ratio only for corner drags with Shift key pressed | コーナードラッグかつ Shift 押下時のみ比率維持
        let preserve = modifierKeys.isShiftPressed && isCorner
        
        let result = ResizeCalculation.calculate(
            original: start,
            handlePosition: position,
            deltaX: deltaX,
            deltaY: deltaY,
            minWidth: node.minWidth,
            minHeight: node.minHeight,
            maxWidth: node.maxWidth,
            maxHeight: node.maxHeight,
            preserveAspectRatio: preserve
        )
        
        store.updateNodeDimensionsAfterResize(
            id: node.id,
            width: result.width,
            height: result.height,
            position: XYPosition(x: result.x, y: result.y)
        )
    }
}

// MARK: - Layout Modifiers

private struct ControlPositionModifier: ViewModifier {
    let position: ResizeControlPosition
    
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .position(x: x(in: proxy.size), y: y(in: proxy.size))
        }
    }
    
    private func x(in size: CGSize) -> CGFloat {
        switch position {
        case .left, .topLeft, .bottomLeft: return 0
        case .right, .topRight, .bottomRight: return size.width
        case .top, .bottom: return size.width / 2
        }
    }
    
    private func y(in size: CGSize) -> CGFloat {
        switch position {
        case .top, .topLeft, .topRight: return 0
        case .bottom, .bottomLeft, .bottomRight: return size.height
        case .left, .right: return size.height / 2
        }
    }
}

private struct LinePositionModifier: ViewModifier {
    let position: ResizeControlPosition
    let thickness: CGFloat = 10
    
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .frame(width: width(in: proxy.size), height: height(in: proxy.size))
                .position(x: x(in: proxy.size), y: y(in: proxy.size))
        }
    }
    
    private func width(in size: CGSize) -> CGFloat? {
        switch position {
        case .top, .bottom: return size.width
        case .left, .right: return thickness
        default: return nil
        }
    }
    
    private func height(in size: CGSize) -> CGFloat? {
        switch position {
        case .top, .bottom: return thickness
        case .left, .right: return size.height
        default: return nil
        }
    }
    
    private func x(in size: CGSize) -> CGFloat {
        switch position {
        case .left: return 0
        case .right: return size.width
        default: return size.width / 2
        }
    }
    
    private func y(in size: CGSize) -> CGFloat {
        switch position {
        case .top: return 0
        case .bottom: return size.height
        default: return size.height / 2
        }
    }
}
