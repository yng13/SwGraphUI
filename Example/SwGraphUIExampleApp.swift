import SwiftUI
import SwGraphUI

@main
struct SwGraphUIExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SwGraphUI Example")
                .font(.title)
                .fontWeight(.semibold)

            Text("This app will host SwiftUI ports of the React Flow examples.")
                .foregroundStyle(.secondary)

            Text("Library module loaded: \(String(describing: SwGraphUIVersionMarker.self))")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(minWidth: 720, minHeight: 480, alignment: .topLeading)
        .padding(24)
    }
}
