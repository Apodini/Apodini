//
// Created by Andreas Bauer on 30.12.20.
//

import Foundation
import Apodini
import ApodiniVaporSupport
import Vapor

struct RESTEndpointHandler<H: Handler> {
    let configuration: RESTConfiguration
    let endpoint: Endpoint<H>
    let relationshipEndpoint: AnyRelationshipEndpoint
    let exporter: RESTInterfaceExporter
    
    init(
        with configuration: RESTConfiguration,
        for endpoint: Endpoint<H>,
        _ relationshipEndpoint: AnyRelationshipEndpoint,
        on exporter: RESTInterfaceExporter
    ) {
        self.configuration = configuration
        self.endpoint = endpoint
        self.relationshipEndpoint = relationshipEndpoint
        self.exporter = exporter
    }
    
    
    func register(at routesBuilder: Vapor.RoutesBuilder, using operation: Apodini.Operation) {
        routesBuilder.on(Vapor.HTTPMethod(operation), [], use: self.handleRequest)
    }

    func handleRequest(request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let context = endpoint.createConnectionContext(for: exporter)

        let responseFuture = context.handleAndReturnParameters(request: request, eventLoop: request.eventLoop)

        return responseFuture
            .map { (response, parameters) in
                response.typeErasured.map { content in
                    EnrichedContent(for: relationshipEndpoint,
                                    response: content,
                                    parameters: parameters) }
                }
            .flatMap { (response: Apodini.Response<EnrichedContent>) in
            guard let enrichedContent = response.content else {
                return ResponseContainer(Empty.self, status: response.status)
                    .encodeResponse(for: request)
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

            let container = ResponseContainer(status: response.status, data: enrichedContent, links: links)
            return container.encodeResponse(for: request)
        }
    }
}
