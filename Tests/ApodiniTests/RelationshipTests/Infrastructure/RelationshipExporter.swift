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
        // as we are accessing the endpoints via index, ensure a consistent order for the tests
        endpoints = endpoints
            .sorted(by: { lhs, rhs in
                let lhsString = lhs.absolutePath.asPathString()
                let rhsString = rhs.absolutePath.asPathString()

                if lhsString == rhsString {
                    return lhs.content[Operation.self] < rhs.content[Operation.self]
                }

                return lhs.absolutePath.asPathString() < rhs.absolutePath.asPathString()
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
