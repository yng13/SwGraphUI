public enum GraphAlgorithms {
    public static func isEdge<Data>(_ value: GraphEdge<Data>) -> Bool where Data: Sendable {
        !value.id.isEmpty && !value.source.isEmpty && !value.target.isEmpty
    }

    public static func isNode<Data>(_ value: GraphNode<Data>) -> Bool where Data: Sendable {
        !value.id.isEmpty
    }

    public static func outgoers<NodeData, EdgeData>(
        for nodeID: String,
        nodes: [GraphNode<NodeData>],
        edges: [GraphEdge<EdgeData>]
    ) -> [GraphNode<NodeData>] where NodeData: Sendable, EdgeData: Sendable {
        guard !nodeID.isEmpty else { return [] }
        let outgoerIDs = Set(edges.compactMap { $0.source == nodeID ? $0.target : nil })
        return nodes.filter { outgoerIDs.contains($0.id) }
    }

    public static func incomers<NodeData, EdgeData>(
        for nodeID: String,
        nodes: [GraphNode<NodeData>],
        edges: [GraphEdge<EdgeData>]
    ) -> [GraphNode<NodeData>] where NodeData: Sendable, EdgeData: Sendable {
        guard !nodeID.isEmpty else { return [] }
        let incomerIDs = Set(edges.compactMap { $0.target == nodeID ? $0.source : nil })
        return nodes.filter { incomerIDs.contains($0.id) }
    }

    public static func connectedEdges<NodeData, EdgeData>(
        for nodes: [GraphNode<NodeData>],
        edges: [GraphEdge<EdgeData>]
    ) -> [GraphEdge<EdgeData>] where NodeData: Sendable, EdgeData: Sendable {
        let ids = Set(nodes.map(\.id))
        return edges.filter { ids.contains($0.source) || ids.contains($0.target) }
    }

    public static func nodeBounds<Data>(
        for nodes: [GraphNode<Data>],
        defaultOrigin: NodeOrigin = .topLeft
    ) -> Rect where Data: Sendable {
        let rects = nodes.map { nodeRect(for: $0, defaultOrigin: defaultOrigin) }
        return GeometryAlgorithms.union(of: rects) ?? Rect(x: 0, y: 0, width: 0, height: 0)
    }

    public static func nodeRect<Data>(
        for node: GraphNode<Data>,
        defaultOrigin: NodeOrigin = .topLeft
    ) -> Rect where Data: Sendable {
        let size = nodeDimensions(for: node)
        let origin = node.origin ?? defaultOrigin
        let x = node.position.x - size.width * origin.x
        let y = node.position.y - size.height * origin.y
        return Rect(x: x, y: y, width: size.width, height: size.height)
    }

    public static func nodeDimensions<Data>(for node: GraphNode<Data>) -> Dimensions where Data: Sendable {
        if let measured = node.measured {
            return measured
        }
        return Dimensions(width: node.width ?? node.initialWidth ?? 0, height: node.height ?? node.initialHeight ?? 0)
    }
}
