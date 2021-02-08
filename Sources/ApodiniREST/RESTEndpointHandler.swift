//
// Created by Andi on 30.12.20.
//

import Foundation
import Apodini
import ApodiniVaporSupport
import Vapor

struct RESTEndpointHandler<H: Handler> {
    let configuration: RESTConfiguration
    var endpoint: Endpoint<H>
    var contextCreator: () -> ConnectionContext<RESTInterfaceExporter>

    
    init(
        configuration: RESTConfiguration,
        for endpoint: Endpoint<H>,
        using contextCreator: @escaping () -> ConnectionContext<RESTInterfaceExporter>
    ) {
        self.configuration = configuration
        self.endpoint = endpoint
        self.contextCreator = contextCreator
    }
    
    
    func register(at routesBuilder: Vapor.RoutesBuilder, with operation: Apodini.Operation) {
        routesBuilder.on(Vapor.HTTPMethod(operation), [], use: self.handleRequest)
    }

    func handleRequest(request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let context = contextCreator()

        let responseFuture = context.handle(request: request)

        return responseFuture.flatMap { (response: Apodini.Response<EnrichedContent>) in
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
