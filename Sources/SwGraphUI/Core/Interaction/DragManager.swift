import Foundation

/// ドラッグ中のノードの初期状態と管理情報を保持します。
public struct NodeDragItem: Sendable, Equatable {
    public let id: String
    /// ドラッグ開始時の絶対座標
    public let lastPosition: XYPosition
    /// ドラッグ開始点からのオフセット（マウス座標等との相対距離）
    public let distance: XYPosition
    
    public init(id: String, lastPosition: XYPosition, distance: XYPosition) {
        self.id = id
        self.lastPosition = lastPosition
        self.distance = distance
    }
}

/// ドラッグ操作に関する純粋な幾何計算ロジックを提供します（Stateless）。
public enum DragManager {
    
    /// ドラッグ中のノード群の次の座標を計算します。
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
            
            // ポインタからのオフセットを維持した「理想の絶対座標」
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
    
    /// 特定のノードに対し、制約（extent, snap）を適用した「次の相対座標」を算出します。
    /// - Parameters:
    ///   - targetAbsPos: 目標とする絶対座標。
    ///   - node: 対象ノード。
    ///   - nodeLookup: ノードの実体。
    ///   - snapGrid: スナップ設定。
    ///   - applySnap: スナップを適用するかどうか。
    ///   - defaultOrigin: 基準点。
    /// - Returns: 制約適用後のノードの「相対（position）」座標。
    public static func applyConstraints<NodeData>(
        to targetAbsPos: XYPosition,
        node: BaseNode<NodeData>,
        nodeLookup: [String: BaseNode<NodeData>],
        snapGrid: SnapGrid? = nil,
        applySnap: Bool = true,
        defaultOrigin: NodeOrigin = .zero
    ) -> XYPosition {
        var currentAbsPos = targetAbsPos
        
        // ノードのサイズ取得
        let width = node.measured?.width ?? node.width ?? node.initialWidth ?? 0
        let height = node.measured?.height ?? node.height ?? node.initialHeight ?? 0
        let dimensions = Dimensions(width: width, height: height)

        // 1. Absolute Clamp (固定座標制約がある場合、スナップ前に絶対空間でかける)
        if let extent = node.extent, case .coordinate = extent {
            currentAbsPos = NodePositioningAlgorithms.clampToExtent(
                currentAbsPos,
                extent: extent,
                dimensions: dimensions
            )
        }
        
        // 2. スナップ適用 (グラフ空間のグリッドに対して)
        if applySnap, let snap = snapGrid {
            currentAbsPos = NodePositioningAlgorithms.applySnap(position: currentAbsPos, snapGrid: snap)
        }
        
        // 3. 親ノードが存在する場合、絶対座標を相対座標へ変換しつつ Parent Extent を適用
        if let parentID = node.parentID, let parent = nodeLookup[parentID] {
            // 絶対座標を相対座標へ変換
            var nextPos = NodePositioningAlgorithms.toRelativePosition(
                currentAbsPos,
                parent: parent,
                nodeLookup: nodeLookup,
                defaultOrigin: defaultOrigin
            )
            
            // Parent Extent (親相対空間での移動制限)
            if let extent = node.extent, case .parent = extent {
                let pWidth = parent.measured?.width ?? parent.width ?? parent.initialWidth ?? 0
                let pHeight = parent.measured?.height ?? parent.height ?? parent.initialHeight ?? 0
                
                // 親のサイズが確定している場合のみ制限を適用
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
            // 親がいない場合はそのまま（既に絶対座標が入っている）
            return currentAbsPos
        }
    }
}
