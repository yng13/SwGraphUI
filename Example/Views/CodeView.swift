import SwiftUI
import SwGraphUI

struct CodeView: View {
    let graphStore: GraphStore<String>
    
    private var jsonString: String {
        let nodesPart = graphStore.nodes.map { node in
            let absPos = graphStore.absolutePosition(for: node.id)
            let measured = node.measured.map { "[\(Int($0.width)), \(Int($0.height))]" } ?? "null"
            return """
              {
                "id": "\(node.id)",
                "kind": "\(node.kind ?? "default")",
                "pos": [\(Int(node.position.x)), \(Int(node.position.y))],
                "absPos": [\(Int(absPos.x)), \(Int(absPos.y))],
                "measured": \(measured)
              }
            """
        }.joined(separator: ",\n")
        return "{\n \"nodes\": [\n\(nodesPart)\n ]\n}"
    }
    
    var body: some View {
        ScrollView {
            Text(jsonString)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(.caption, design: .monospaced))
        }
        .background(Color.black.opacity(0.05))
    }
}
