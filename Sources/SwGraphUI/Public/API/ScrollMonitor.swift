#if os(macOS)
import AppKit
import SwiftUI

/// キャンバス上での macOS のスクロールイベントを捕捉する監視クラス。
/// GraphView 内でローカルにスコープされ、GraphView のライフサイクルと isHovering 状態に追従します。
final class ScrollMonitor: ObservableObject {
    var isHovering: Bool = false
    var location: CGPoint = .zero
    var onEvent: ((NSEvent) -> NSEvent?)?
    
    private var monitor: Any?
    
    init() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self = self, self.isHovering else { return event }
            return self.onEvent?(event) ?? event
        }
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
#endif
