//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import XCTApodini
@testable import Apodini
@testable import ApodiniREST

class RelationshipExporter: MockExporter<String> {
    struct EndpointRepresentation {
        let endpoint: AnyEndpoint
        let relationshipEndpoint: AnyRelationshipEndpoint
        let evaluateCallback: (_ request: String, _ parameters: [Any??], _ app: Application) throws -> EnrichedContent
        
        internal init(_ endpoint: AnyEndpoint,
                      _ relationshipEndpoint: AnyRelationshipEndpoint,
                      _ evaluateCallback: @escaping (String, [Any??], Application) throws -> EnrichedContent) {
            self.endpoint = endpoint
            self.relationshipEndpoint = relationshipEndpoint
            self.evaluateCallback = evaluateCallback
        }
    }
    
    var endpoints: [EndpointRepresentation] = []

    override func export<H: Handler>(_ endpoint: Endpoint<H>) {
        let rendpoint = endpoint[AnyRelationshipEndpointInstance.self].instance
        
        endpoints.append(EndpointRepresentation(endpoint, rendpoint, { request, parameters, app in
            self.append(injected: parameters)
            let context = endpoint.createConnectionContext(for: self)
            
            let (response, parameters) = try context.handleAndReturnParameters(
                request: request,
                eventLoop: app.eventLoopGroup.next(),
                final: true)
                .wait()
            return try XCTUnwrap(response.typeErasured.map { anyEncodable in
                EnrichedContent(for: rendpoint, response: anyEncodable, parameters: parameters)
            })
        }))
    }

    override func finishedExporting(_ webService: WebServiceModel) {
        // as we are accessing the endpoints via index, ensure a consistent order for the tests
        endpoints = endpoints
            .sorted(by: { lhs, rhs in
                let lhsString = lhs.endpoint.absolutePath.asPathString()
                let rhsString = rhs.endpoint.absolutePath.asPathString()

                if lhsString == rhsString {
                    return lhs.endpoint[Operation.self] < rhs.endpoint[Operation.self]
                }

                return lhs.endpoint.absolutePath.asPathString() < rhs.endpoint.absolutePath.asPathString()
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
