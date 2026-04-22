#if canImport(AppKit)
import AppKit
#endif
import Foundation
import Observation

/// Adapter that monitors the status of modifier keys (e.g., Shift) on the platform (currently macOS). | プラットフォーム（現在は macOS）における修飾キー（Shift 等）の状態を監視するアダプター。
@Observable
@MainActor
public final class ModifierKeysProvider {
    // Internal cache | 内部キャッシュ
    private var _isShiftPressed: Bool = false
    
    /// Whether the Shift key is currently pressed | 現在 Shift キーが押されているか
    public var isShiftPressed: Bool {
        #if os(macOS)
        // Check the flags directly upon access, in addition to asynchronous updates via the monitor | モニターによる非同期更新だけでなく、アクセス時に直接フラグも確認する
        return NSEvent.modifierFlags.contains(.shift)
        #else
        return _isShiftPressed
        #endif
    }
    
    #if os(macOS)
    /// Helper that holds and automatically releases the monitor | モニターの保持と自動解除を行うヘルパー
    private final class MonitorHolder: @unchecked Sendable {
        var monitor: Any?
        deinit {
            #if os(macOS)
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
            #endif
        }
    }
    private let holder = MonitorHolder()
    #endif
    
    public init() {
        #if os(macOS)
        self._isShiftPressed = NSEvent.modifierFlags.contains(.shift)
        
        // Add a monitor for when modifier keys are changed | 修飾キーが変更された際のモニターを追加
        holder.monitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            // Prompt a redraw when the state of the Shift key changes | Shift キーの状態が変更された際に再描画を促す
            Task { @MainActor in
                self?._isShiftPressed = event.modifierFlags.contains(.shift)
            }
            return event
        }
        #endif
    }
}
