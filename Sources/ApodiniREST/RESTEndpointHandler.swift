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
    let exporter: _RESTInterfaceExporter
    
    init(
        with configuration: RESTConfiguration,
        for endpoint: Endpoint<H>,
        on exporter: _RESTInterfaceExporter
    ) {
        self.configuration = configuration
        self.endpoint = endpoint
        self.exporter = exporter
    }
    
    
    func register(at routesBuilder: Vapor.RoutesBuilder, using operation: Apodini.Operation) {
        routesBuilder.on(Vapor.HTTPMethod(operation), [], use: self.handleRequest)
    }

    func handleRequest(request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let context = endpoint.createConnectionContext(for: exporter)

        let responseFuture = context.handle(request: request)

        return responseFuture.flatMap { (response: Apodini.Response<EnrichedContent>) in
            guard let enrichedContent = response.content else {
                return ResponseContainer(Empty.self, status: response.status, encoder: self.configuration.exporterConfiguration.encoder).encodeResponse(for: request)
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

            let container = ResponseContainer(status: response.status, data: enrichedContent, links: links, encoder: self.configuration.exporterConfiguration.encoder)
            return container.encodeResponse(for: request)
        }
    }
}
