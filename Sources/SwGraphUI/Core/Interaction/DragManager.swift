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
            var nextPos = pointer - item.distance
            
            // ノードのサイズ取得
            let width = node.measured?.width ?? node.width ?? node.initialWidth ?? 0
            let height = node.measured?.height ?? node.height ?? node.initialHeight ?? 0
            let dimensions = Dimensions(width: width, height: height)

            // 2. Absolute Clamp (固定座標制約がある場合、スナップ前に絶対空間でかける)
            if let extent = node.extent, case .coordinate = extent {
                nextPos = NodePositioningAlgorithms.clampToExtent(
                    nextPos,
                    extent: extent,
                    dimensions: dimensions
                )
            }
            
            // 3. スナップ適用 (グラフ空間のグリッドに対して)
            if let snap = snapGrid {
                nextPos = NodePositioningAlgorithms.applySnap(position: nextPos, snapGrid: snap)
            }
            
            // 4. 親ノードが存在する場合、絶対座標を相対座標へ変換
            if let parentID = node.parentID, let parent = nodeLookup[parentID] {
                // 階層解決のために全体の nodeLookup を渡す
                nextPos = NodePositioningAlgorithms.toRelativePosition(
                    nextPos,
                    parent: parent,
                    nodeLookup: nodeLookup,
                    defaultOrigin: defaultOrigin
                )
                
                // 5. Parent Extent (親相対空間での移動制限)
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
            } else {
                // 親がいない場合で .parent 指定がある場合は制限なし（fallback）
            }
            
            results[item.id] = nextPos
        }
        
        return results
    }
}
