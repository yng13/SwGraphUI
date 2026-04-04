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
    /// - Parameters:
    ///   - draggedNodes: ドラッグ対象のアイテム。
    ///   - pointer: 現在のポインタ座標（Graph Space）。
    ///   - nodeLookup: ノードの実体（サイズ・親子参照用）。
    ///   - snapGrid: スナップ設定（任意）。
    ///   - defaultOrigin: 親ノードがない場合の基準点。
    /// - Returns: ノードIDと新しい算出座標のペア。
    public static func calculateNextPositions<Data>(
        draggedNodes: [NodeDragItem],
        pointer: XYPosition,
        nodeLookup: [String: BaseNode<Data>],
        snapGrid: SnapGrid? = nil,
        defaultOrigin: NodeOrigin = .zero
    ) -> [String: XYPosition] {
        var results: [String: XYPosition] = [:]
        
        for item in draggedNodes {
            guard let node = nodeLookup[item.id] else { continue }
            
            // 1. ポインタからのオフセットを維持した「理想の絶対座標」
            let baseAbsolutePos = pointer - item.distance
            
            // 2. スナップ適用 (グラフ空間のグリッドに対して)
            var nextPos = baseAbsolutePos
            if let snap = snapGrid {
                nextPos = NodePositioningAlgorithms.applySnap(position: baseAbsolutePos, snapGrid: snap)
            }
            
            // 3. 親ノードが存在する場合、絶対座標を相対座標へ変換
            if let parentID = node.parentID, let parent = nodeLookup[parentID] {
                // 階層解決のために全体の nodeLookup を渡す
                nextPos = NodePositioningAlgorithms.toRelativePosition(
                    nextPos,
                    parent: parent,
                    nodeLookup: nodeLookup,
                    defaultOrigin: defaultOrigin
                )
            }
            
            // 4. Extent (移動制限) 適用
            if let extent = node.extent {
                let width = node.measured?.width ?? node.width ?? node.initialWidth ?? 0
                let height = node.measured?.height ?? node.height ?? node.initialHeight ?? 0
                nextPos = NodePositioningAlgorithms.clampToExtent(
                    nextPos,
                    extent: extent,
                    dimensions: Dimensions(width: width, height: height)
                )
            }
            
            results[item.id] = nextPos
        }
        
        return results
    }
}
