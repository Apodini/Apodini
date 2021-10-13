//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTApodini
import XCTest
@testable import ApodiniREST
@testable import Apodini
import ApodiniUtils


class RelationshipTestContext {
    let app: Application
    let exporter: RelationshipExporter
    
    var endpoints: [RelationshipExporter.MockRequestEnrichedContentHandler] {
        exporter.mockRequestEnrichedContentHandler
    }

    init<C: Component>(app: Application, service: C) {
        app.registerExporter(exporter: RelationshipExporter(app))
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

    func request(on index: Int, @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }) -> EnrichedContent {
        let executable = endpoints[index].evaluateCallback

        do {
            return try executable(AnyMockRequest(MockRequest<Empty>(parameters: parameters)))
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
