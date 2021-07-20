//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniVaporSupport
import Vapor
import ApodiniExtension


struct RESTEndpointHandler<H: Handler> {
    let configuration: REST.Configuration
    let exporterConfiguration: REST.ExporterConfiguration
    let endpoint: Endpoint<H>
    let relationshipEndpoint: AnyRelationshipEndpoint
    let exporter: RESTInterfaceExporter
    let delegateFactory: DelegateFactory<H>
    
    private let strategy: AnyDecodingStrategy<Vapor.Request>
    
    let defaultStore: DefaultValueStore
    
    init(
        with configuration: REST.Configuration,
        withExporterConfiguration exporterConfiguration: REST.ExporterConfiguration,
        for endpoint: Endpoint<H>,
        _ relationshipEndpoint: AnyRelationshipEndpoint,
        on exporter: RESTInterfaceExporter
    ) {
        self.configuration = configuration
        self.exporterConfiguration = exporterConfiguration
        self.endpoint = endpoint
        self.relationshipEndpoint = relationshipEndpoint
        self.exporter = exporter
        
        self.strategy = ParameterTypeSpecific(
                            lightweight: LightweightStrategy(),
                            path: PathStrategy(useNameAsIdentifier: false),
                            content: AllIdentityStrategy(exporterConfiguration.decoder).transformedToVaporRequestBasedStrategy()
        ).applied(to: endpoint)
        
        self.defaultStore = endpoint[DefaultValueStore.self]
        self.delegateFactory = endpoint[DelegateFactory<H>.self]
    }
    
    
    func register(at routesBuilder: Vapor.RoutesBuilder, using operation: Apodini.Operation) {
        routesBuilder.on(Vapor.HTTPMethod(operation), [], use: self.handleRequest)
    }

    func handleRequest(request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let delegate = delegateFactory.instance()
        
        return strategy
            .decodeRequest(from: request,
                           with: request.eventLoop)
            .insertDefaults(with: defaultStore)
            .cache()
            .evaluate(on: delegate)
            .map { (responseAndRequest: ResponseWithRequest<H.Response.Content>) in
                let parameters: (UUID) -> Any? = responseAndRequest.unwrapped(to: CachingRequest.self)?.peak(_:) ?? { _ in nil }
                
                
                return responseAndRequest.response.typeErasured.map { content in
                    EnrichedContent(for: relationshipEndpoint,
                                    response: content,
                                    parameters: parameters)
                }
            }
            .flatMap { (response: Apodini.Response<EnrichedContent>) in
                guard let enrichedContent = response.content else {
                    return ResponseContainer(Empty.self, status: response.status, information: response.information)
                        .encodeResponse(for: request)
                }
                
                if let blob = response.content?.response.typed(Blob.self) {
                    let vaporResponse = Vapor.Response()
                    
                    var information = response.information
                    if let contentType = blob.type?.description {
                        information = information.union([AnyHTTPInformation(key: "Content-Type", rawValue: contentType)])
                    }
                    vaporResponse.headers = HTTPHeaders(information)
                    
                    if let status = response.status {
                        vaporResponse.status = HTTPStatus(status)
                    }
                    
                    vaporResponse.body = Vapor.Response.Body(buffer: blob.byteBuffer)
                    
                    return request.eventLoop.makeSucceededFuture(vaporResponse)
                }
                
                let formatter = LinksFormatter(configuration: self.configuration)
                var links = enrichedContent.formatRelationships(into: [:], with: formatter, sortedBy: \.linksOperationPriority)

                let readExisted = enrichedContent.formatSelfRelationship(into: &links, with: formatter, for: .read)
                if !readExisted {
                    // by default (if it exists) we point self to .read (which is the most probably of being inherited).
                    // Otherwise we guarantee a "self" relationship, by adding the self relationship
                    // for the operation of the endpoint which is guaranteed to exist.
                    enrichedContent.formatSelfRelationship(into: &links, with: formatter)
                }

                let container = ResponseContainer(status: response.status,
                                                  information: response.information,
                                                  data: enrichedContent,
                                                  links: links,
                                                  encoder: exporterConfiguration.encoder)
                                                  
                return container.encodeResponse(for: request)
            }
    }
}
