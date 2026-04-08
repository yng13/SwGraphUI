import SwiftUI

/// ノードのリサイズ操作を提供する View。
/// カスタムノードの body 内でオーバーレイとして使用することを想定しています。
public struct NodeResizer<Data: Sendable>: View {
    @Environment(GraphStore<Data>.self) private var store
    let node: BaseNode<Data>
    let isVisible: Bool
    
    /// NodeResizer を作成します。
    /// - Parameters:
    ///   - node: 対象ノード
    ///   - isVisible: リサイザーの可視性（デフォルトは true。store の選択状態と組み合わせて判定されます）
    public init(node: BaseNode<Data>, isVisible: Bool = true) {
        self.node = node
        self.isVisible = isVisible
    }
    
    public var body: some View {
        // 選択中かつモデルがリサイズを許可している場合のみ表示
        if node.selected && isVisible && node.resizable {
            ZStack {
                // ガイド枠線
                Rectangle()
                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                
                // --- Edge Controls ---
                ResizeControlView<Data>(node: node, position: .top, variant: .line)
                ResizeControlView<Data>(node: node, position: .bottom, variant: .line)
                ResizeControlView<Data>(node: node, position: .left, variant: .line)
                ResizeControlView<Data>(node: node, position: .right, variant: .line)
                
                // --- Corner Controls ---
                ResizeControlView<Data>(node: node, position: .topLeft, variant: .handle)
                ResizeControlView<Data>(node: node, position: .topRight, variant: .handle)
                ResizeControlView<Data>(node: node, position: .bottomLeft, variant: .handle)
                ResizeControlView<Data>(node: node, position: .bottomRight, variant: .handle)
            }
            // 親側のレイアウトに左右されないよう、明示的にリサイザー枠のサイズを確定させる
            .frame(
                width: node.width ?? node.measured?.width ?? 0,
                height: node.height ?? node.measured?.height ?? 0
            )
        }
    }
}

private enum ControlVariant {
    case handle
    case line
}

private struct ResizeControlView<Data: Sendable>: View {
    @Environment(GraphStore<Data>.self) private var store
    let node: BaseNode<Data>
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
            .modifier(ControlPositionModifier(position: position))
    }
    
    private var lineShape: some View {
        Rectangle()
            .fill(Color.accentColor.opacity(0.001)) // 当たり判定用
            .modifier(LinePositionModifier(position: position))
    }
    
    private func handleDrag(translation: CGSize) {
        let zoom = store.runtimeState.viewport.viewport.zoom
        
        if startBounds == nil {
            startBounds = ResizeResult(
                x: node.position.x,
                y: node.position.y,
                width: node.width ?? node.measured?.width ?? 0,
                height: node.height ?? node.measured?.height ?? 0
            )
        }
        
        guard let start = startBounds else { return }
        
        // translation を Graph Space のデルタに変換
        let deltaX = translation.width / zoom
        let deltaY = translation.height / zoom
        
        // コーナードラッグかつ Shift 押下時のみ比率維持
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
