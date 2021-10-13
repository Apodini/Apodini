//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTApodini
import ApodiniExtension
@testable import Apodini
@testable import ApodiniREST


class RelationshipExporter: MockInterfaceExporter {
    struct MockRequestEnrichedContentHandler {
        #warning("See if we can remove some properties here ...")
        let endpoint: AnyEndpoint
        let relationshipEndpoint: AnyRelationshipEndpoint
        let evaluateCallback: (AnyMockRequest) throws -> EnrichedContent
        
        
        internal init(
            _ endpoint: AnyEndpoint,
            _ relationshipEndpoint: AnyRelationshipEndpoint,
            _ evaluateCallback: @escaping (AnyMockRequest) throws -> EnrichedContent
        ) {
            self.endpoint = endpoint
            self.relationshipEndpoint = relationshipEndpoint
            self.evaluateCallback = evaluateCallback
        }
    }
    
    
    var mockRequestEnrichedContentHandler: [MockRequestEnrichedContentHandler] = []
    
    
    override func export<H: Handler>(_ endpoint: Endpoint<H>) {
        let relationshipEndpoint = endpoint[AnyRelationshipEndpointInstance.self].instance
        
        mockRequestEnrichedContentHandler.append(MockRequestEnrichedContentHandler(endpoint, relationshipEndpoint) { request in
            let strategy = Self.decodingStrategy(for: endpoint)
            var delegate = Delegate(endpoint.handler, .required)
            
            return try strategy
                .decodeRequest(from: request, with: self.app.eventLoopGroup.next())
                .insertDefaults(with: endpoint[DefaultValueStore.self])
                .cache()
                .evaluate(on: &delegate)
                .flatMapThrowing { (responseAndRequest: ResponseWithRequest<H.Response.Content>) -> EnrichedContent in
                    let parameters: (UUID) -> Any? = responseAndRequest.unwrapped(to: CachingRequest.self)?.peak(_:) ?? { _ in nil }
                    
                    return try XCTUnwrap(
                        responseAndRequest.response.typeErasured
                            .map { content in
                                EnrichedContent(
                                    for: relationshipEndpoint,
                                    response: content,
                                    parameters: parameters
                                )
                            }
                            .content
                    )
                }
                .wait()
        })
    }
    
    override func finishedExporting(_ webService: WebServiceModel) {
        // as we are accessing the mockRequestEnrichedContentHandler via index, ensure a consistent order for the tests
        mockRequestEnrichedContentHandler = mockRequestEnrichedContentHandler
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
