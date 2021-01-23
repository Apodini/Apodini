//
// Created by Andreas Bauer on 23.01.21.
//

import XCTest
@testable import Apodini

class RelationshipExporter: MockExporter<String> {
    var endpoints: [AnyEndpoint] = []

    override func export<H: Handler>(_ endpoint: Endpoint<H>) {
        endpoints.append(endpoint)
    }

    override func finishedExporting(_ webService: WebServiceModel) {
        endpoints = endpoints.sorted(by: {lhs, rhs in
            lhs.absolutePath.asPathString() < rhs.absolutePath.asPathString()
        })
    }
}

class RelationshipExporterRetriever: InterfaceExporterVisitor {
    private var exporter: RelationshipExporter?

    var retrieved: RelationshipExporter {
        guard let exporter = self.exporter else {
            fatalError("Failed to retrieve RelationshipExporter")
        }
        return exporter
    }

    init() {}

    func visit<I>(exporter: I) where I: InterfaceExporter {
        do {
            self.exporter = try XCTUnwrap(exporter as? RelationshipExporter)
        } catch {
            fatalError("Error retrieving RelationshipExporter: \(error)")
        }
    }

    func visit<I>(staticExporter: I) where I: StaticInterfaceExporter {}
}
