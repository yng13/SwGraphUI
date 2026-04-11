import SwiftUI
import SwGraphUI
#if os(macOS)
import AppKit
#endif

/// Xcode のプロジェクトナビゲーター風サイドバー。
struct SidebarView: View {
    @Bindable var appStore: ExampleAppStore
    let graphStore: GraphStore<String>

    var body: some View {
        let _ = appStore.selectedCategory
        let _ = appStore.selectedSample?.id

        #if os(macOS)
        MacSidebarOutlineView(appStore: appStore, graphStore: graphStore)
            .background(Color(nsColor: .windowBackgroundColor))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("サンプルナビゲータ")
        #else
        MobileSidebarView(appStore: appStore, graphStore: graphStore)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("サンプルナビゲータ")
        #endif
    }
}

#if os(macOS)
private final class SidebarTreeItem: NSObject {
    enum Kind {
        case root
        case category(ExampleAppStore.SampleCategory)
        case sample(String)
    }

    let id: String
    let title: String
    let kind: Kind
    let children: [SidebarTreeItem]

    init(id: String, title: String, kind: Kind, children: [SidebarTreeItem] = []) {
        self.id = id
        self.title = title
        self.kind = kind
        self.children = children
    }

    var isExpandable: Bool {
        !children.isEmpty
    }

    @MainActor
    static func makeTree(appStore: ExampleAppStore) -> SidebarTreeItem {
        let categories = ExampleAppStore.SampleCategory.allCases.map { category in
            let sampleItems = appStore.samples(in: category).map {
                SidebarTreeItem(id: "sample:\($0.id)", title: $0.title, kind: .sample($0.id))
            }
            return SidebarTreeItem(
                id: "category:\(category.rawValue)",
                title: category.rawValue,
                kind: .category(category),
                children: sampleItems
            )
        }

        return SidebarTreeItem(id: "root:SwGraphUI", title: "SwGraphUI", kind: .root, children: categories)
    }
}

private struct MacSidebarOutlineView: NSViewRepresentable {
    let appStore: ExampleAppStore
    let graphStore: GraphStore<String>

    func makeCoordinator() -> Coordinator {
        Coordinator(appStore: appStore, graphStore: graphStore)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.setAccessibilityElement(true)
        scrollView.setAccessibilityLabel("サンプルナビゲータ")

        let outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.rowHeight = 20
        outlineView.indentationPerLevel = 14
        outlineView.intercellSpacing = NSSize(width: 0, height: 0)
        outlineView.focusRingType = .none
        outlineView.backgroundColor = .clear
        outlineView.allowsEmptySelection = true
        outlineView.allowsColumnReordering = false
        outlineView.allowsColumnResizing = false
        outlineView.allowsTypeSelect = true
        outlineView.floatsGroupRows = false
        outlineView.style = .sourceList
        outlineView.delegate = context.coordinator
        outlineView.dataSource = context.coordinator
        outlineView.autoresizesOutlineColumn = true
        outlineView.setAccessibilityElement(true)
        outlineView.setAccessibilityLabel("サンプル一覧")

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
        column.isEditable = false
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        scrollView.documentView = outlineView

        context.coordinator.outlineView = outlineView
        context.coordinator.reload(using: appStore)

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.appStore = appStore
        context.coordinator.graphStore = graphStore
        context.coordinator.reload(using: appStore)
    }

    @MainActor
    final class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        weak var outlineView: NSOutlineView?
        var appStore: ExampleAppStore
        var graphStore: GraphStore<String>
        var rootItem: SidebarTreeItem
        var expandedItemIDs: Set<String>

        init(appStore: ExampleAppStore, graphStore: GraphStore<String>) {
            self.appStore = appStore
            self.graphStore = graphStore
            self.rootItem = SidebarTreeItem.makeTree(appStore: appStore)

            var expanded: Set<String> = [rootItem.id]
            for category in ExampleAppStore.SampleCategory.allCases {
                expanded.insert("category:\(category.rawValue)")
            }
            self.expandedItemIDs = expanded
        }

        func reload(using appStore: ExampleAppStore) {
            rootItem = SidebarTreeItem.makeTree(appStore: appStore)
            guard let outlineView else { return }

            outlineView.reloadData()
            expandPersistedItems(in: outlineView)
            syncSelection(in: outlineView)
        }

        private func expandPersistedItems(in outlineView: NSOutlineView) {
            if expandedItemIDs.contains(rootItem.id) {
                outlineView.expandItem(rootItem)
            }

            for child in rootItem.children where expandedItemIDs.contains(child.id) {
                outlineView.expandItem(child)
            }
        }

        private func syncSelection(in outlineView: NSOutlineView) {
            let targetSampleID = appStore.selectedSample?.id
                ?? appStore.samples(in: appStore.selectedCategory).first?.id

            guard let targetSampleID else {
                outlineView.deselectAll(nil)
                return
            }

            let targetItemID = "sample:\(targetSampleID)"
            let rowCount = outlineView.numberOfRows
            for row in 0..<rowCount {
                guard let item = outlineView.item(atRow: row) as? SidebarTreeItem else { continue }
                if item.id == targetItemID {
                    if outlineView.selectedRow != row {
                        outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                    }
                    return
                }
            }
        }

        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            let node = (item as? SidebarTreeItem) ?? rootItem
            return node.children.count
        }

        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            guard let node = item as? SidebarTreeItem else { return false }
            return node.isExpandable
        }

        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            let node = (item as? SidebarTreeItem) ?? rootItem
            return node.children[index]
        }

        func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
            guard let node = item as? SidebarTreeItem else { return false }
            if case .sample = node.kind {
                return true
            }
            return false
        }

        func outlineViewSelectionDidChange(_ notification: Notification) {
            guard let outlineView,
                  outlineView.selectedRow >= 0,
                  let node = outlineView.item(atRow: outlineView.selectedRow) as? SidebarTreeItem
            else { return }

            guard case .sample(let sampleID) = node.kind,
                  let sample = appStore.sample(id: sampleID)
            else { return }

            if appStore.selectedSample?.id != sample.id {
                appStore.switchSample(to: sample, in: graphStore)
            }
        }

        func outlineViewItemDidExpand(_ notification: Notification) {
            guard let node = notification.userInfo?["NSObject"] as? SidebarTreeItem else { return }
            expandedItemIDs.insert(node.id)
        }

        func outlineViewItemDidCollapse(_ notification: Notification) {
            guard let node = notification.userInfo?["NSObject"] as? SidebarTreeItem else { return }
            expandedItemIDs.remove(node.id)
        }

        func outlineView(
            _ outlineView: NSOutlineView,
            viewFor tableColumn: NSTableColumn?,
            item: Any
        ) -> NSView? {
            guard let node = item as? SidebarTreeItem else { return nil }

            let identifier = NSUserInterfaceItemIdentifier("SidebarCell")
            let cell = (outlineView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView)
                ?? makeCell(identifier: identifier)

            cell.textField?.stringValue = node.title
            cell.textField?.font = font(for: node)
            cell.imageView?.image = icon(for: node)
            cell.imageView?.contentTintColor = tint(for: node)

            return cell
        }

        private func makeCell(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
            let cell = NSTableCellView()
            cell.identifier = identifier

            let imageView = NSImageView(frame: NSRect(x: 2, y: 3, width: 14, height: 14))
            imageView.imageScaling = .scaleProportionallyDown
            imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 11, weight: .regular)
            cell.imageView = imageView
            cell.addSubview(imageView)

            let textField = NSTextField(labelWithString: "")
            textField.frame = NSRect(x: 22, y: 1, width: 200, height: 18)
            textField.lineBreakMode = .byTruncatingTail
            textField.backgroundColor = .clear
            cell.textField = textField
            cell.addSubview(textField)

            return cell
        }

        private func font(for node: SidebarTreeItem) -> NSFont {
            switch node.kind {
            case .root:
                return .systemFont(ofSize: 11, weight: .semibold)
            case .category:
                return .systemFont(ofSize: 11, weight: .regular)
            case .sample:
                return .systemFont(ofSize: 11, weight: .regular)
            }
        }

        private func icon(for node: SidebarTreeItem) -> NSImage? {
            let symbolName: String
            switch node.kind {
            case .root:
                symbolName = "folder.badge.gearshape"
            case .category:
                symbolName = "folder.fill"
            case .sample:
                symbolName = "doc.text"
            }
            return NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        }

        private func tint(for node: SidebarTreeItem) -> NSColor {
            switch node.kind {
            case .root, .category:
                return .systemBlue
            case .sample:
                return .secondaryLabelColor
            }
        }
    }
}
#endif

private struct MobileSidebarView: View {
    @Bindable var appStore: ExampleAppStore
    let graphStore: GraphStore<String>

    @State private var expandedCategories: Set<ExampleAppStore.SampleCategory> = Set(ExampleAppStore.SampleCategory.allCases)

    var body: some View {
        VStack(spacing: 0) {
            List {
                rootItem
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))

                ForEach(ExampleAppStore.SampleCategory.allCases) { category in
                    categoryGroup(for: category)
                        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                }
            }
            .listStyle(.sidebar)
            .environment(\.defaultMinListRowHeight, 20)
        }
    }

    private var rootItem: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.blue)
                .frame(width: 14)

            Text("SwGraphUI")
                .font(.system(size: 11, weight: .bold))
                .lineLimit(1)

            Spacer()
        }
        .frame(height: 20)
        .listRowSeparator(.hidden)
    }

    private func categoryGroup(for category: ExampleAppStore.SampleCategory) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedCategories.contains(category) },
                set: { isExpanded in
                    if isExpanded {
                        expandedCategories.insert(category)
                    } else {
                        expandedCategories.remove(category)
                    }
                }
            )
        ) {
            ForEach(appStore.samples(in: category), id: \.id) { sample in
                sampleRow(sample: sample)
                    .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 0, trailing: 8))
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.blue.opacity(0.8))
                    .frame(width: 14)

                Text(category.rawValue)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
            .frame(height: 20)
        }
    }

    private func sampleRow(sample: any GraphSample) -> some View {
        let isSelected = appStore.selectedSample?.id == sample.id

        return HStack(spacing: 4) {
            Image(systemName: "doc.text")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 14)

            Text(sample.title)
                .font(.system(size: 11))
                .lineLimit(1)
                .foregroundColor(isSelected ? .white : .primary)

            Spacer()
        }
        .frame(height: 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            appStore.switchSample(to: sample, in: graphStore)
        }
        .listRowBackground(isSelected ? Color.accentColor : Color.clear)
    }
}
