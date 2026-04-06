import SwiftUI
#if os(macOS)
import AppKit

struct CanvasKeyboardBridge: NSViewRepresentable {
    let onSelectAll: () -> Void
    let onDeleteSelection: () -> Void

    func makeNSView(context: Context) -> CanvasKeyboardView {
        let view = CanvasKeyboardView()
        view.onSelectAll = onSelectAll
        view.onDeleteSelection = onDeleteSelection
        return view
    }

    func updateNSView(_ nsView: CanvasKeyboardView, context: Context) {
        nsView.onSelectAll = onSelectAll
        nsView.onDeleteSelection = onDeleteSelection
    }
}

final class CanvasKeyboardView: NSView {
    var onSelectAll: (() -> Void)?
    var onDeleteSelection: (() -> Void)?

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

            let firstResponderIsInWindow = window.firstResponder != nil
            guard isCanvasActive || window.firstResponder === self || !firstResponderIsInWindow else {
                return event
            }

            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command],
               event.charactersIgnoringModifiers?.lowercased() == "a" {
                onSelectAll?()
                return nil
            }

            if event.keyCode == 51 || event.keyCode == 117 {
                onDeleteSelection?()
                return nil
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
