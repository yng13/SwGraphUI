public enum NodeChange<NodeValue: Sendable>: Sendable {
    case dimensions(id: String, dimensions: Dimensions?, resizing: Bool = false)
    case position(id: String, position: XYPosition?, absolutePosition: XYPosition? = nil, dragging: Bool = false)
    case selection(id: String, selected: Bool)
    case remove(id: String)
    case add(NodeValue, index: Int? = nil)
    case replace(id: String, item: NodeValue)
}

public enum EdgeChange<EdgeValue: Sendable>: Sendable {
    case selection(id: String, selected: Bool)
    case remove(id: String)
    case add(EdgeValue, index: Int? = nil)
    case replace(id: String, item: EdgeValue)
}
