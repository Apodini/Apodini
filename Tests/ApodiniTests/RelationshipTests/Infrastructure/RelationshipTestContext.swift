//
// Created by Andreas Bauer on 23.01.21.
//


import XCTApodini
import XCTest
@testable import ApodiniREST
@testable import Apodini
import ApodiniUtils

@available(macOS 12.0, *)
class RelationshipTestContext {
    let app: Application
    let exporter: RelationshipExporter
    
    var endpoints: [RelationshipExporter.EndpointRepresentation] {
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
        endpoints[index].endpoint
    }

    func request(on index: Int, request: String = "Example Request", parameters: Any??...) -> EnrichedContent {
        let executable = endpoints[index].evaluateCallback

        do {
            return try executable(request, parameters, app)
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
