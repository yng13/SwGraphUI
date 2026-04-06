import SwiftUI

struct LogView: View {
    let appStore: ExampleAppStore
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LOGS").font(.caption).bold()
                Spacer()
                Button("Clear") { appStore.clearLogs() }
                    .buttonStyle(.plain)
                    .font(.caption)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(appStore.logs) { log in
                        Text(log.description)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
            }
            .textSelection(.enabled)
        }
    }
}
