import SwiftUI
import SwGraphUI
#if os(macOS)
import AppKit

struct CanvasKeyboardBridge: NSViewRepresentable {
    let onSelectAll: () -> Void
    let onDeleteSelection: () -> Void
    let onMoveNodes: (XYPosition) -> Void

    func makeNSView(context: Context) -> CanvasKeyboardView {
        let view = CanvasKeyboardView()
        view.onSelectAll = onSelectAll
        view.onDeleteSelection = onDeleteSelection
        view.onMoveNodes = onMoveNodes
        return view
    }

    func updateNSView(_ nsView: CanvasKeyboardView, context: Context) {
        nsView.onSelectAll = onSelectAll
        nsView.onDeleteSelection = onDeleteSelection
        nsView.onMoveNodes = onMoveNodes
    }
}

final class CanvasKeyboardView: NSView {
    var onSelectAll: (() -> Void)?
    var onDeleteSelection: (() -> Void)?
    var onMoveNodes: ((XYPosition) -> Void)?

    private var keyMonitor: Any?
    private var mouseMonitor: Any?
    private var isCanvasActive = false

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        installMonitorsIfNeeded()
        DispatchQueue.main.async { [weak self] in
            guard let self, let window else { return }
            window.makeFirstResponder(self)
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            removeMonitors()
        }
        super.viewWillMove(toWindow: newWindow)
    }

    private func installMonitorsIfNeeded() {
        guard keyMonitor == nil, mouseMonitor == nil else { return }

        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self, let window else { return event }
            let point = convert(event.locationInWindow, from: nil)
            if bounds.contains(point) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                isCanvasActive = true
                window.makeFirstResponder(self)
            } else {
                isCanvasActive = false
            }
            return event
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self, let window else { return event }

            // ガード: テキストフィールドなどがフォーカスされている場合は処理しない
            if let firstResponder = window.firstResponder {
                // NSTextView (SwiftUI TextFieldの内部実装) や NSTextField を除外
                if firstResponder is NSText || firstResponder is NSTextField {
                    return event
                }
            }

            let firstResponderIsInWindow = window.firstResponder != nil
            guard isCanvasActive || window.firstResponder === self || !firstResponderIsInWindow else {
                return event
            }

            // Command + A: Select All
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command],
               event.charactersIgnoringModifiers?.lowercased() == "a" {
                onSelectAll?()
                return nil
            }

            // Delete / Backspace: Delete Selection
            if event.keyCode == 51 || event.keyCode == 117 {
                onDeleteSelection?()
                return nil
            }

            // Arrow Keys: Move Nodes
            let step: CGFloat = event.modifierFlags.contains(.shift) ? 10 : 1
            switch event.keyCode {
            case 123: // Left
                onMoveNodes?(XYPosition(x: -step, y: 0))
                return nil
            case 124: // Right
                onMoveNodes?(XYPosition(x: step, y: 0))
                return nil
            case 125: // Down
                onMoveNodes?(XYPosition(x: 0, y: step))
                return nil
            case 126: // Up
                onMoveNodes?(XYPosition(x: 0, y: -step))
                return nil
            default:
                break
            }

            return event
        }
    }

    private func removeMonitors() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
            self.mouseMonitor = nil
        }
    }
}
#endif
