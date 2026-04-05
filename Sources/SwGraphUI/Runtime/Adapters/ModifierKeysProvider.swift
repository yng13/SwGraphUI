#if canImport(AppKit)
import AppKit
#endif
import Foundation
import Observation

/// プラットフォーム（現在は macOS）における修飾キー（Shift 等）の状態を監視するアダプター。
@Observable
@MainActor
public final class ModifierKeysProvider {
    // 内部キャッシュ
    private var _isShiftPressed: Bool = false
    
    /// 現在 Shift キーが押されているか
    public var isShiftPressed: Bool {
        #if os(macOS)
        // モニターによる非同期更新だけでなく、アクセス時に直接フラグも確認する
        return NSEvent.modifierFlags.contains(.shift)
        #else
        return _isShiftPressed
        #endif
    }
    
    #if os(macOS)
    /// モニターの保持と自動解除を行うヘルパー
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
        
        // 修飾キーが変更された際のモニターを追加
        holder.monitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            // Shift キーの状態が変更された際に再描画を促す
            Task { @MainActor in
                self?._isShiftPressed = event.modifierFlags.contains(.shift)
            }
            return event
        }
        #endif
    }
}
