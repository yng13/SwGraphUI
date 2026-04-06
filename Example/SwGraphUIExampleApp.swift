import SwiftUI
#if os(macOS)
import AppKit
#endif
import SwGraphUI

@main
struct SwGraphUIExampleApp: App {
    @State private var appStore = ExampleAppStore()
    @State private var graphStore: GraphStore<String> = GraphStore(nodes: [])

    init() {
        #if os(macOS)
        NSApplication.shared.setActivationPolicy(.regular)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(appStore: appStore, graphStore: graphStore)
                .onAppear {
                    appStore.switchSample(to: .basic, in: graphStore)
                }
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        #endif
        .commands {
            // macOSデフォルトメニューが表示されない環境でも確実に出すために明示的に "Edit" メニューを設ける
            CommandMenu("Edit") {
                Button("Select All") {
                    graphStore.selectAll()
                }
                .keyboardShortcut("a", modifiers: .command)
                
                Divider()
                
                Button("Delete Selected") {
                    graphStore.deleteSelection()
                }
                .keyboardShortcut(.delete, modifiers: [])
                
                Button("Forward Delete Selected") {
                    graphStore.deleteSelection()
                }
                .keyboardShortcut(.deleteForward, modifiers: [])
            }
        }
    }
}
