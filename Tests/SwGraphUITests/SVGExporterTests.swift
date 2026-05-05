import Foundation
import Testing
@testable import SwGraphUI

@Suite
@MainActor
struct SVGExporterTests {
    @Test
    func exportProducesValidRoot() async throws {
        let store = GraphStore<String>()
        store.nodes = [
            BaseNode(id: "node-1", position: XYPosition(x: 10, y: 20), data: "A")
        ]
        store.updateNodeDimensions(id: "node-1", dimensions: Dimensions(width: 120, height: 48))

        let exporter = SVGExporter(store: store)
        let svg = try #require(exporter.export())

        #expect(svg.contains(#"<svg xmlns="http://www.w3.org/2000/svg""#))
        #expect(svg.contains(#"viewBox="0 0 "#))
        #expect(svg.contains("<title>SwGraphUI Graph</title>"))
        #expect(svg.contains(#"width=""#))
        #expect(svg.contains(#"height=""#))
    }

    @Test
    func exportWithEmptyGraphReturnsNil() async throws {
        let store = GraphStore<String>()
        let exporter = SVGExporter(store: store)
        #expect(exporter.export() == nil)
    }

    @Test
    func marginAffectsDimensionsAndTranslatedCoordinates() async throws {
        let store = GraphStore<String>()
        store.nodes = [
            BaseNode(id: "n1", position: XYPosition(x: 10, y: 20), data: "A")
        ]
        store.updateNodeDimensions(id: "n1", dimensions: Dimensions(width: 100, height: 50))

        let exporter = SVGExporter(store: store)
        let bounds = try #require(exporter.calculateExportBounds())
        let settings = GraphExportSettings(margin: 40, includeBackground: false, isTransparent: true)
        let svg = try #require(exporter.export(settings: settings))

        let width = bounds.width + settings.margin * 2
        let height = bounds.height + settings.margin * 2
        let translationX = -bounds.x + settings.margin
        let translationY = -bounds.y + settings.margin

        #expect(svg.contains(#"width="\#(svgNumber(width))""#))
        #expect(svg.contains(#"height="\#(svgNumber(height))""#))
        #expect(svg.contains(#"x="\#(svgNumber(10 + translationX))""#))
        #expect(svg.contains(#"y="\#(svgNumber(20 + translationY))""#))
    }

    @Test
    func nodeRectUsesAbsolutePosition() async throws {
        let store = GraphStore<String>()
        store.nodes = [
            BaseNode(id: "parent", position: XYPosition(x: 100, y: 50), data: "P"),
            BaseNode(id: "child", position: XYPosition(x: 20, y: 30), data: "C", parentID: "parent")
        ]
        store.updateNodeDimensions(id: "parent", dimensions: Dimensions(width: 200, height: 120))
        store.updateNodeDimensions(id: "child", dimensions: Dimensions(width: 80, height: 40))

        let exporter = SVGExporter(store: store)
        let bounds = try #require(exporter.calculateExportBounds())
        let svg = try #require(exporter.export(settings: GraphExportSettings(margin: 32, includeBackground: false, isTransparent: true)))
        let childAbsolute = store.absolutePosition(for: "child")
        let translatedX = childAbsolute.x - bounds.x + 32
        let translatedY = childAbsolute.y - bounds.y + 32

        #expect(svg.contains(#"<g id="node-child">"#))
        #expect(svg.contains(#"x="\#(svgNumber(translatedX))""#))
        #expect(svg.contains(#"y="\#(svgNumber(translatedY))""#))
    }

    @Test
    func nodeRectPrefersMeasuredSize() async throws {
        let store = GraphStore<String>()
        store.nodes = [
            BaseNode(id: "n1", position: XYPosition(x: 0, y: 0), data: "A", width: 90, height: 40)
        ]
        store.updateNodeDimensions(id: "n1", dimensions: Dimensions(width: 132, height: 44))

        let exporter = SVGExporter(store: store)
        let svg = try #require(exporter.export(settings: GraphExportSettings(margin: 32, includeBackground: false, isTransparent: true)))

        #expect(svg.contains(#"width="132""#))
        #expect(svg.contains(#"height="44""#))
        #expect(!svg.contains(#"width="90""#))
    }

    @Test
    func movingNodeChangesExportedCoordinates() async throws {
        let store = GraphStore<String>()
        store.nodes = [
            BaseNode(id: "n1", position: XYPosition(x: 0, y: 0), data: "A"),
            BaseNode(id: "n2", position: XYPosition(x: 300, y: 0), data: "B")
        ]
        store.updateNodeDimensions(id: "n1", dimensions: Dimensions(width: 100, height: 50))
        store.updateNodeDimensions(id: "n2", dimensions: Dimensions(width: 100, height: 50))

        let exporter = SVGExporter(store: store)
        let first = try #require(exporter.export(settings: GraphExportSettings(margin: 16, includeBackground: false, isTransparent: true)))
        store.updateNodePosition(id: "n1", position: XYPosition(x: 60, y: 40))
        let second = try #require(exporter.export(settings: GraphExportSettings(margin: 16, includeBackground: false, isTransparent: true)))

        #expect(first != second)
        #expect(second.contains(#"y="60""#))
    }

    @Test
    func edgePathUsesResolvedHandlePositions() async throws {
        let store = makeTwoNodeStore()
        let edge = BaseEdge<String>(
            id: "e1",
            source: "n1",
            target: "n2",
            kind: "straight",
            sourcePosition: .right,
            targetPosition: .left
        )
        store.edges = [edge]

        let exporter = SVGExporter(store: store)
        let bounds = try #require(exporter.calculateExportBounds())
        let svg = try #require(exporter.export(settings: GraphExportSettings(margin: 24, includeBackground: false, isTransparent: true)))

        let resolved = store.resolvedEdgePositions(for: edge)
        let sourceKey = HandleKey(nodeID: edge.source, handleID: nil, type: .source, placement: resolved.source)
        let targetKey = HandleKey(nodeID: edge.target, handleID: nil, type: .target, placement: resolved.target)
        let translation = XYPosition(x: -bounds.x + 24, y: -bounds.y + 24)
        let source = translate(store.resolvedHandlePosition(for: sourceKey), by: translation)
        let target = translate(store.resolvedHandlePosition(for: targetKey), by: translation)
        let expectedPath = EdgePathAlgorithms.calculatePath(
            source: source,
            target: target,
            sourcePosition: resolved.source,
            targetPosition: resolved.target,
            kind: edge.kind,
            curvature: edge.curvature ?? 0.25
        ).path

        #expect(svg.contains(#"d="\#(expectedPath)""#))
    }

    @Test
    func explicitEdgePositionsAffectPathEndpoints() async throws {
        let store = makeTwoNodeStore()
        let edge = BaseEdge<String>(
            id: "e1",
            source: "n1",
            target: "n2",
            kind: "default",
            sourcePosition: .top,
            targetPosition: .top
        )
        store.edges = [edge]

        let exporter = SVGExporter(store: store)
        let bounds = try #require(exporter.calculateExportBounds())
        let svg = try #require(exporter.export(settings: GraphExportSettings(margin: 20, includeBackground: false, isTransparent: true)))

        let translation = XYPosition(x: -bounds.x + 20, y: -bounds.y + 20)
        let source = translate(store.resolvedHandlePosition(for: HandleKey(nodeID: "n1", handleID: nil, type: .source, placement: .top)), by: translation)
        let target = translate(store.resolvedHandlePosition(for: HandleKey(nodeID: "n2", handleID: nil, type: .target, placement: .top)), by: translation)

        #expect(svg.contains("M\(source.x),\(source.y)"))
        #expect(svg.contains("\(target.x),\(target.y)"))
    }

    @Test
    func edgeKindsProduceDistinctPathData() async throws {
        let kinds = ["straight", "step", "smoothstep", "default"]
        var paths = Set<String>()

        for kind in kinds {
            let store = makeTwoNodeStore()
            store.edges = [
                BaseEdge<String>(id: "e-\(kind)", source: "n1", target: "n2", kind: kind)
            ]
            let exporter = SVGExporter(store: store)
            let svg = try #require(exporter.export(settings: GraphExportSettings(margin: 16, includeBackground: false, isTransparent: true)))
            let path = try #require(firstMatch(in: svg, pattern: #"d="([^"]+)""#))
            paths.insert(path)
        }

        #expect(paths.count == kinds.count)
    }

    @Test
    func labelsAreXMLEscaped() async throws {
        let store = GraphStore<String>()
        store.nodes = [
            BaseNode(
                id: "n1",
                position: XYPosition(x: 0, y: 0),
                data: "A",
                label: #"<node & "quote" 'apostrophe'>"#
            ),
            BaseNode(id: "n2", position: XYPosition(x: 200, y: 0), data: "B")
        ]
        store.updateNodeDimensions(id: "n1", dimensions: Dimensions(width: 100, height: 50))
        store.updateNodeDimensions(id: "n2", dimensions: Dimensions(width: 100, height: 50))
        store.edges = [
            BaseEdge<String>(id: "e1", source: "n1", target: "n2", kind: "straight", label: #"<edge & "quote" 'apostrophe'>"#)
        ]

        let exporter = SVGExporter(store: store)
        let svg = try #require(exporter.export(settings: GraphExportSettings(margin: 16, includeBackground: false, isTransparent: true)))

        #expect(svg.contains("&lt;node &amp; &quot;quote&quot; &apos;apostrophe&apos;&gt;"))
        #expect(svg.contains("&lt;edge &amp; &quot;quote&quot; &apos;apostrophe&apos;&gt;"))
    }

    @Test
    func exportIsDeterministic() async throws {
        let store = makeTwoNodeStore()
        store.edges = [
            BaseEdge<String>(id: "e1", source: "n1", target: "n2", kind: "default", label: "edge")
        ]
        let exporter = SVGExporter(store: store)
        let settings = GraphExportSettings(margin: 12, includeBackground: true, backgroundVariant: .dots, isTransparent: false)

        let first = try #require(exporter.export(settings: settings))
        let second = try #require(exporter.export(settings: settings))

        #expect(first == second)
    }

    @Test
    func transparentBackgroundToggleChangesBackgroundRect() async throws {
        let store = makeTwoNodeStore()
        let exporter = SVGExporter(store: store)

        let transparent = try #require(exporter.export(settings: GraphExportSettings(margin: 16, includeBackground: false, isTransparent: true)))
        let opaque = try #require(exporter.export(settings: GraphExportSettings(margin: 16, includeBackground: false, isTransparent: false)))

        #expect(!transparent.contains(#"id="background-fill""#))
        #expect(opaque.contains(#"id="background-fill""#))
    }

    @Test
    func edgeStrokeStyleSerializesToSVG() async throws {
        let store = makeTwoNodeStore()
        store.edges = [
            BaseEdge<String>(
                id: "styled",
                source: "n1",
                target: "n2",
                kind: "straight",
                strokeStyle: EdgeStrokeStyle(color: "#2563EB", width: 3.5, dash: .dashed)
            )
        ]

        let exporter = SVGExporter(store: store)
        let svg = try #require(exporter.export(settings: GraphExportSettings(margin: 16, includeBackground: false, isTransparent: true)))

        #expect(svg.contains("stroke=\"#2563EB\""))
        #expect(svg.contains(#"stroke-width="3.5""#))
        #expect(svg.contains(#"stroke-dasharray="10 5""#))
    }

    @Test
    func endpointLabelsSerializeToSVG() async throws {
        let store = makeTwoNodeStore()
        store.edges = [
            BaseEdge<String>(
                id: "endpoint-labels",
                source: "n1",
                target: "n2",
                kind: "straight",
                sourceEndpointLabel: EdgeEndpointLabel(text: #"Gi0/1 & "uplink""#, maxWidth: 80),
                targetEndpointLabel: EdgeEndpointLabel(text: "Te1/1", presentation: .plain)
            )
        ]

        let exporter = SVGExporter(store: store)
        let svg = try #require(exporter.export(settings: GraphExportSettings(margin: 16, includeBackground: false, isTransparent: true)))

        #expect(svg.contains("Gi0/1 &amp; &quot;uplink&quot;"))
        #expect(svg.contains("Te1/1"))
    }

    @Test
    func includeBackgroundAddsDeterministicBackgroundPrimitives() async throws {
        let store = makeTwoNodeStore()
        let exporter = SVGExporter(store: store)
        let svg = try #require(exporter.export(settings: GraphExportSettings(margin: 16, includeBackground: true, backgroundVariant: .dots, isTransparent: true)))

        #expect(svg.contains(#"<g id="background-grid""#))
        #expect(svg.contains("<circle"))
    }

    private func makeTwoNodeStore() -> GraphStore<String> {
        let store = GraphStore<String>()
        store.nodes = [
            BaseNode(id: "n1", position: XYPosition(x: 0, y: 0), data: "A"),
            BaseNode(id: "n2", position: XYPosition(x: 200, y: 120), data: "B")
        ]
        store.updateNodeDimensions(id: "n1", dimensions: Dimensions(width: 100, height: 50))
        store.updateNodeDimensions(id: "n2", dimensions: Dimensions(width: 120, height: 60))
        return store
    }

    private func translate(_ point: XYPosition, by offset: XYPosition) -> XYPosition {
        XYPosition(x: point.x + offset.x, y: point.y + offset.y)
    }

    private func svgNumber(_ value: Double) -> String {
        if abs(value) < 0.000_5 {
            return "0"
        }
        let rounded = (value * 1000).rounded() / 1000
        var string = String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), rounded)
        while string.contains(".") && (string.hasSuffix("0") || string.hasSuffix(".")) {
            string.removeLast()
        }
        return string
    }

    private func firstMatch(in string: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let match = regex.firstMatch(in: string, range: range),
              match.numberOfRanges > 1,
              let swiftRange = Range(match.range(at: 1), in: string) else {
            return nil
        }
        return String(string[swiftRange])
    }
}
