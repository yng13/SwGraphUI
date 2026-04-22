import Foundation

/// Holds the initial state and management information for a node being dragged. | ドラッグ中のノードの初期状態と管理情報を保持します。
public struct NodeDragItem: Sendable, Equatable {
    public let id: String
    /// Absolute coordinates at the start of the drag | ドラッグ開始時の絶対座標
    public let lastPosition: XYPosition
    /// Offset from the drag start point (relative distance from the mouse coordinates, etc.) | ドラッグ開始点からのオフセット（マウス座標等との相対距離）
    public let distance: XYPosition
    
    public init(id: String, lastPosition: XYPosition, distance: XYPosition) {
        self.id = id
        self.lastPosition = lastPosition
        self.distance = distance
    }
}

/// Provides pure geometric calculation logic for drag operations (stateless). | ドラッグ操作に関する純粋な幾何計算ロジックを提供します（Stateless）。
public enum DragManager {
    
    /// Calculates the next coordinates for a group of nodes being dragged. | ドラッグ中のノード群の次の座標を計算します。
    public static func calculateNextPositions<NodeData>(
        draggedNodes: [NodeDragItem],
        pointer: XYPosition,
        nodeLookup: [String: BaseNode<NodeData>],
        snapGrid: SnapGrid? = nil,
        defaultOrigin: NodeOrigin = .zero
    ) -> [String: XYPosition] {
        var results: [String: XYPosition] = [:]
        
        for item in draggedNodes {
            guard let node = nodeLookup[item.id] else { continue }
            
            // "Ideal absolute coordinates" maintaining the offset from the pointer | ポインタからのオフセットを維持した「理想の絶対座標」
            let targetAbsPos = pointer - item.distance
            
            let nextPos = applyConstraints(
                to: targetAbsPos,
                node: node,
                nodeLookup: nodeLookup,
                snapGrid: snapGrid,
                applySnap: true,
                defaultOrigin: defaultOrigin
            )
            
            results[item.id] = nextPos
        }
        
        return results
    }
    
    /// Calculates the "next relative coordinates" for a specific node, applying constraints (extent, snap). | 特定のノードに対し、制約（extent, snap）を適用した「次の相対座標」を算出します。
    /// - Parameters:
    ///   - targetAbsPos: Target absolute coordinates. | 目標とする絶対座標。
    ///   - node: Target node. | 対象ノード。
    ///   - nodeLookup: Node lookup map. | ノードの実体。
    ///   - snapGrid: Snap grid settings. | スナップ設定。
    ///   - applySnap: Whether to apply snapping. | スナップを適用するかどうか。
    ///   - defaultOrigin: Coordinate origin. | 基準点。
    /// - Returns: "Relative (position)" coordinates of the node after applying constraints. | 制約適用後のノードの「相対（position）」座標。
    public static func applyConstraints<NodeData>(
        to targetAbsPos: XYPosition,
        node: BaseNode<NodeData>,
        nodeLookup: [String: BaseNode<NodeData>],
        snapGrid: SnapGrid? = nil,
        applySnap: Bool = true,
        defaultOrigin: NodeOrigin = .zero
    ) -> XYPosition {
        var currentAbsPos = targetAbsPos
        
        // Get node dimensions | ノードのサイズ取得
        let width = node.measured?.width ?? node.width ?? node.initialWidth ?? 0
        let height = node.measured?.height ?? node.height ?? node.initialHeight ?? 0
        let dimensions = Dimensions(width: width, height: height)

        // 1. Absolute Clamp (apply in absolute space before snapping if fixed coordinate constraints exist) | 1. Absolute Clamp (固定座標制約がある場合、スナップ前に絶対空間でかける)
        if let extent = node.extent, case .coordinate = extent {
            currentAbsPos = NodePositioningAlgorithms.clampToExtent(
                currentAbsPos,
                extent: extent,
                dimensions: dimensions
            )
        }
        
        // 2. Apply snapping (to the graph space grid) | 2. スナップ適用 (グラフ空間のグリッドに対して)
        if applySnap, let snap = snapGrid {
            currentAbsPos = NodePositioningAlgorithms.applySnap(position: currentAbsPos, snapGrid: snap)
        }
        
        // 3. If a parent node exists, apply Parent Extent while converting absolute coordinates to relative coordinates | 3. 親ノードが存在する場合、絶対座標を相対座標へ変換しつつ Parent Extent を適用
        if let parentID = node.parentID, let parent = nodeLookup[parentID] {
            // Convert absolute coordinates to relative coordinates | 絶対座標を相対座標へ変換
            var nextPos = NodePositioningAlgorithms.toRelativePosition(
                currentAbsPos,
                parent: parent,
                nodeLookup: nodeLookup,
                defaultOrigin: defaultOrigin
            )
            
            // Parent Extent (movement restriction in the parent's relative space) | Parent Extent (親相対空間での移動制限)
            if let extent = node.extent, case .parent = extent {
                let pWidth = parent.measured?.width ?? parent.width ?? parent.initialWidth ?? 0
                let pHeight = parent.measured?.height ?? parent.height ?? parent.initialHeight ?? 0
                
                // Apply restrictions only if the parent's size is determined | 親のサイズが確定している場合のみ制限を適用
                if pWidth > 0 && pHeight > 0 {
                    nextPos = NodePositioningAlgorithms.clampToExtent(
                        nextPos,
                        extent: .parent,
                        dimensions: dimensions,
                        containerSize: Dimensions(width: pWidth, height: pHeight)
                    )
                }
            }
            return nextPos
        } else {
            // If no parent, use as is (already in absolute coordinates) | 親がいない場合はそのまま（既に絶対座標が入っている）
            return currentAbsPos
        }
    }
}
