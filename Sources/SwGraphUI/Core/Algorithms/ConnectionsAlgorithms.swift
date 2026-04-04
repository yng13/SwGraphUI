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

    public static func addEdge<Data>(
        _ edgeOrConnection: GraphEdge<Data>?,
        to edges: [GraphEdge<Data>]
    ) -> [GraphEdge<Data>] where Data: Sendable {
        guard let edgeOrConnection else { return edges }
        guard !edgeOrConnection.source.isEmpty, !edgeOrConnection.target.isEmpty else { return edges }
        guard !containsDuplicate(edgeOrConnection, in: edges) else { return edges }
        return edges + [edgeOrConnection]
    }

    public static func addEdge<Data>(
        from connection: Connection,
        to edges: [GraphEdge<Data>],
        data: Data? = nil,
        kind: String? = nil
    ) -> [GraphEdge<Data>] where Data: Sendable {
        guard !connection.source.isEmpty, !connection.target.isEmpty else { return edges }

        let edge = GraphEdge<Data>(
            id: edgeID(for: connection),
            kind: kind,
            source: connection.source,
            target: connection.target,
            sourceHandle: connection.sourceHandle,
            targetHandle: connection.targetHandle,
            data: data
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
            kind: edge.kind,
            source: connection.source,
            target: connection.target,
            sourceHandle: connection.sourceHandle,
            targetHandle: connection.targetHandle,
            animated: edge.animated,
            hidden: edge.hidden,
            deletable: edge.deletable,
            selectable: edge.selectable,
            data: edge.data,
            selected: edge.selected,
            markerStart: edge.markerStart,
            markerEnd: edge.markerEnd,
            zIndex: edge.zIndex,
            ariaLabel: edge.ariaLabel,
            interactionWidth: edge.interactionWidth
        )

        return edges.filter { $0.id != edge.id } + [replacement]
    }

    private static func containsDuplicate<Data>(
        _ edge: GraphEdge<Data>,
        in edges: [GraphEdge<Data>]
    ) -> Bool where Data: Sendable {
        edges.contains {
            $0.source == edge.source &&
            $0.target == edge.target &&
            $0.sourceHandle == edge.sourceHandle &&
            $0.targetHandle == edge.targetHandle
        }
    }
}
