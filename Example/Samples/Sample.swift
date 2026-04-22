import Foundation
import SwGraphUI

/// A protocol that abstracts the definition of each sample | 各サンプルの定義を抽象化するプロトコル
public protocol GraphSample: Identifiable {
    var id: String { get }
    var title: String { get }
    var category: ExampleAppStore.SampleCategory { get }
    var description: String { get }
    
    /// Expands sample data into GraphStore. | サンプルデータを GraphStore に展開します。
    @MainActor
    func setup(in graphStore: GraphStore<String>, appStore: ExampleAppStore)
}

extension GraphSample {
    public var id: String { title }
}
