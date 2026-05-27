public enum ConnectionStatus: Sendable, Equatable {
    case valid
    case invalid
}

public enum ConnectionsAlgorithms {
    public static func areConnectionMapsEqual(
        _ lhs: [String: HandleConnection]?,
        _ rhs: [String: HandleConnection]?
    ) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            guard lhs.count == rhs.count else { return false }
            return lhs.keys.allSatisfy(rhs.keys.contains)
        default:
            return false
        }
    }

    public static func removedConnections(
        from source: [String: HandleConnection],
        comparedTo target: [String: HandleConnection]
    ) -> [HandleConnection] {
        source.compactMap { key, value in
            target[key] == nil ? value : nil
        }
    }

    public static func connectionStatus(isValid: Bool?) -> ConnectionStatus? {
        guard let isValid else { return nil }
        return isValid ? .valid : .invalid
    }

    public static func edgeID(for connection: Connection) -> String {
        "xy-edge__\(connection.source)\(connection.sourceHandle ?? "")-\(connection.target)\(connection.targetHandle ?? "")"
    }

    public static func getEdges<NodeData>(
        for node: BaseNode<NodeData>,
        in edges: [BaseEdge<NodeData>]
    ) -> [BaseEdge<NodeData>] where NodeData: Sendable {
        edges.filter { $0.source == node.id || $0.target == node.id }
    }
    
    public static func getIncomers<NodeData>(
        for node: BaseNode<NodeData>,
        in nodes: [BaseNode<NodeData>],
        edges: [BaseEdge<NodeData>]
    ) -> [BaseNode<NodeData>] where NodeData: Sendable {
        let incomerIDs = Set(edges.filter { $0.target == node.id }.map { $0.source })
        return nodes.filter { incomerIDs.contains($0.id) }
    }
    
    public static func getOutgoers<NodeData>(
        for node: BaseNode<NodeData>,
        in nodes: [BaseNode<NodeData>],
        edges: [BaseEdge<NodeData>]
    ) -> [BaseNode<NodeData>] where NodeData: Sendable {
        let outgoerIDs = Set(edges.filter { $0.source == node.id }.map { $0.target })
        return nodes.filter { outgoerIDs.contains($0.id) }
    }

    public static func isInternalConnection<NodeData>(
        edge: BaseEdge<NodeData>,
        selectedIDs: Set<String>
    ) -> Bool where NodeData: Sendable {
        selectedIDs.contains(edge.source) && selectedIDs.contains(edge.target)
    }

    public static func addEdge<NodeData>(
        _ edgeOrConnection: GraphEdge<NodeData>?,
        to edges: [GraphEdge<NodeData>]
    ) -> [GraphEdge<NodeData>] where NodeData: Sendable {
        guard let edgeOrConnection else { return edges }
        guard isValidEndpoint(edgeOrConnection.sourceEndpoint),
              isValidEndpoint(edgeOrConnection.targetEndpoint) else { return edges }
        guard !containsDuplicate(edgeOrConnection, in: edges) else { return edges }
        return edges + [edgeOrConnection]
    }

    public static func addEdge<NodeData>(
        from connection: Connection,
        to edges: [GraphEdge<NodeData>],
        data: NodeData? = nil,
        kind: String? = nil
    ) -> [GraphEdge<NodeData>] where NodeData: Sendable {
        guard !connection.source.isEmpty, !connection.target.isEmpty else { return edges }

        let edge = GraphEdge<NodeData>(
            id: edgeID(for: connection),
            source: connection.source,
            target: connection.target,
            data: data,
            kind: kind,
            sourceHandle: connection.sourceHandle,
            targetHandle: connection.targetHandle
        )

        return addEdge(edge, to: edges)
    }

    public static func reconnectEdge<Data>(
        _ edge: GraphEdge<Data>,
        using connection: Connection,
        in edges: [GraphEdge<Data>],
        shouldReplaceID: Bool = true
    ) -> [GraphEdge<Data>] where Data: Sendable {
        guard !connection.source.isEmpty, !connection.target.isEmpty else { return edges }
        guard edges.contains(where: { $0.id == edge.id }) else { return edges }

        let replacement = GraphEdge<Data>(
            id: shouldReplaceID ? edgeID(for: connection) : edge.id,
            source: connection.source,
            target: connection.target,
            data: edge.data,
            kind: edge.kind,
            sourceHandle: connection.sourceHandle,
            targetHandle: connection.targetHandle,
            animated: edge.animated,
            markerStart: edge.markerStart,
            markerEnd: edge.markerEnd,
            zIndex: edge.zIndex,
            ariaLabel: edge.ariaLabel,
            interactionWidth: edge.interactionWidth,
            hidden: edge.hidden,
            deletable: edge.deletable,
            selectable: edge.selectable,
            selected: edge.selected
        )

        return edges.filter { $0.id != edge.id } + [replacement]
    }


    private static func containsDuplicate<Data>(
        _ edge: GraphEdge<Data>,
        in edges: [GraphEdge<Data>]
    ) -> Bool where Data: Sendable {
        edges.contains {
            $0.sourceEndpoint == edge.sourceEndpoint &&
            $0.targetEndpoint == edge.targetEndpoint
        }
    }

    private static func isValidEndpoint(_ endpoint: EdgeEndpoint) -> Bool {
        switch endpoint {
        case .node(let id, _):
            return !id.isEmpty
        case .point(let point):
            return point.x.isFinite && point.y.isFinite
        }
    }
}
