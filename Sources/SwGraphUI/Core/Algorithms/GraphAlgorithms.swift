public enum GraphAlgorithms {
    public static func isEdge<NodeData>(_ value: GraphEdge<NodeData>) -> Bool where NodeData: Sendable {
        guard !value.id.isEmpty else { return false }
        switch (value.sourceEndpoint, value.targetEndpoint) {
        case (.node(let source, _), .node(let target, _)):
            return !source.isEmpty && !target.isEmpty
        case (.node(let source, _), .point(let point)):
            return !source.isEmpty && point.x.isFinite && point.y.isFinite
        case (.point(let point), .node(let target, _)):
            return point.x.isFinite && point.y.isFinite && !target.isEmpty
        case (.point(let source), .point(let target)):
            return source.x.isFinite && source.y.isFinite && target.x.isFinite && target.y.isFinite
        }
    }

    public static func isNode<NodeData>(_ value: GraphNode<NodeData>) -> Bool where NodeData: Sendable {
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

    public static func nodeBounds<NodeData>(
        for nodes: [GraphNode<NodeData>],
        defaultOrigin: NodeOrigin = .topLeft
    ) -> Rect where NodeData: Sendable {
        let rects = nodes.map { nodeRect(for: $0, defaultOrigin: defaultOrigin) }
        return GeometryAlgorithms.union(of: rects) ?? Rect(x: 0, y: 0, width: 0, height: 0)
    }

    public static func nodeRect<NodeData>(
        for node: GraphNode<NodeData>,
        defaultOrigin: NodeOrigin = .topLeft
    ) -> Rect where NodeData: Sendable {
        let size = nodeDimensions(for: node)
        let origin = node.origin ?? defaultOrigin
        let x = node.position.x - size.width * origin.x
        let y = node.position.y - size.height * origin.y
        return Rect(x: x, y: y, width: size.width, height: size.height)
    }

    public static func nodeDimensions<NodeData>(for node: GraphNode<NodeData>) -> Dimensions where NodeData: Sendable {
        if let measured = node.measured {
            return measured
        }
        return Dimensions(width: node.width ?? node.initialWidth ?? 0, height: node.height ?? node.initialHeight ?? 0)
    }
}
