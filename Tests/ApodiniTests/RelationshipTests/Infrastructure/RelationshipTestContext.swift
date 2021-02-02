//
// Created by Andreas Bauer on 23.01.21.
//


import XCTest
import XCTApodini
@testable import Apodini

class RelationshipTestContext {
    let app: Application
    let exporter: RelationshipExporter

    var endpoints: [AnyEndpoint] {
        exporter.endpoints
    }

    init<C: Component>(app: Application, service: C) {
        let builder = SemanticModelBuilder(app)
            .with(exporter: RelationshipExporter.self)
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        service.accept(visitor)
        visitor.finishParsing()

        let anyExporter: AnyInterfaceExporter
        do {
            anyExporter = try XCTUnwrap(builder.interfaceExporters.first)
        } catch {
            fatalError("Failed to unwrap interface exporter: \(error)")
        }

        let retrieval = RelationshipExporterRetriever()
        anyExporter.accept(retrieval)

        self.app = app
        self.exporter = retrieval.retrieved
    }

    func endpoint(on index: Int) -> AnyEndpoint {
        endpoints[index]
    }

    func request(on index: Int, request: String = "Example Request", parameters: Any??...) -> EnrichedContent {
        exporter.append(injected: parameters)

        let endpoint = endpoints[index]
        let context = endpoint.createConnectionContext(for: exporter)

        do {
            return try XCTUnwrap(
                try context.handle(request: request, eventLoop: app.eventLoopGroup.next())
                .wait()
            )
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
