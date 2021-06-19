//
// Created by Andreas Bauer on 23.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class RelationshipExporter: MockExporter<String> {
    var endpoints: [(AnyEndpoint, AnyRelationshipEndpoint)] = []

    override func export<H: Handler>(_ endpoint: Endpoint<H>) {
        let rendpoint = endpoint[AnyRelationshipEndpointInstance.self].instance
        
        endpoints.append((endpoint, rendpoint))
    }

    override func finishedExporting(_ webService: WebServiceModel) {
        // as we are accessing the endpoints via index, ensure a consistent order for the tests
        endpoints = endpoints
            .sorted(by: { lhs, rhs in
                let lhsString = lhs.0.absolutePath.asPathString()
                let rhsString = rhs.0.absolutePath.asPathString()

                if lhsString == rhsString {
                    return lhs.0[Operation.self] < rhs.0[Operation.self]
                }

                return lhs.0.absolutePath.asPathString() < rhs.0.absolutePath.asPathString()
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


extension Apodini.Operation: Comparable {
    func num() -> Int {
        switch self {
        case .read:
            return 0
        case .create:
            return 1
        case .update:
            return 2
        case .delete:
            return 3
        }
    }

    public static func < (lhs: Apodini.Operation, rhs: Apodini.Operation) -> Bool {
        lhs.num() < rhs.num()
    }
}
