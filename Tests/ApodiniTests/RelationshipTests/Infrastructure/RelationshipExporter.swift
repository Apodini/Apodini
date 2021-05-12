//
// Created by Andreas Bauer on 23.01.21.
//

import XCTApodini
@testable import Apodini


class RelationshipExporter: _MockExporter {
    override func finishedExporting(_ webService: WebServiceModel) {
        super.finishedExporting(webService)
        
        // as we are accessing the endpoints via index, ensure a consistent order for the tests
        endpoints = endpoints
            .sorted(by: { lhs, rhs in
                let lhsString = lhs.absolutePath.asPathString()
                let rhsString = rhs.absolutePath.asPathString()

                if lhsString == rhsString {
                    return lhs[Operation.self] < rhs[Operation.self]
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
