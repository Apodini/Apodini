//
// Created by Andreas Bauer on 23.01.21.
//


import XCTApodini
import XCTest
@testable import ApodiniREST
@testable import Apodini
import ApodiniUtils

class RelationshipTestContext {
    let app: Application
    let exporter: RelationshipExporter

    var endpoints: [(AnyEndpoint, AnyRelationshipEndpoint)] {
        exporter.endpoints
    }

    init<C: Component>(app: Application, service: C) {
        app.registerExporter(exporter: RelationshipExporter())
        let builder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        service.accept(visitor)
        visitor.finishParsing()

        let anyExporter: AnyInterfaceExporter
        do {
            anyExporter = try XCTUnwrap(app.interfaceExporters.first)
        } catch {
            fatalError("Failed to unwrap interface exporter: \(error)")
        }

        let retrieval = RelationshipExporterRetriever()
        anyExporter.accept(retrieval)

        self.app = app
        self.exporter = retrieval.retrieved
    }

    func endpoint(on index: Int) -> AnyEndpoint {
        endpoints[index].0
    }

    func request(on index: Int, request: String = "Example Request", parameters: Any??...) -> EnrichedContent {
        exporter.append(injected: parameters)

        let (endpoint, rendpoint) = endpoints[index]
        let context = endpoint.createAnyConnectionContext(for: exporter)

        do {
            let (response, parameters) = try context.handleAndReturnParameters(
                request: request,
                eventLoop: app.eventLoopGroup.next(),
                final: true)
                .wait()
            return try XCTUnwrap(response.map { anyEncodable in
                EnrichedContent(for: rendpoint, response: anyEncodable, parameters: parameters)
            })
        } catch {
            fatalError("Error when handling Relationship request: \(error)")
        }
    }
}

extension EnrichedContent {
    func formatTestRelationships(hideHidden: Bool = false) -> [String: String] {
        let formatter = TestingRelationshipFormatter(hideHidden: hideHidden)

        let links = formatRelationships(into: [:], with: formatter)
        return formatSelfRelationships(into: links, with: formatter)
    }
}
