//
// Created by Andi on 30.12.20.
//

import Foundation
import Apodini
import ApodiniVaporSupport
import Vapor

struct RESTEndpointHandler {
    var contextCreator: () -> ConnectionContext<RESTInterfaceExporter>
    let configuration: RESTConfiguration
    
    
    init(configuration: RESTConfiguration, using contextCreator: @escaping () -> ConnectionContext<RESTInterfaceExporter>) {
        self.configuration = configuration
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
            var links = enrichedContent.formatRelationships(
                into: [:],
                with: formatter,
                for: .read
            )
            enrichedContent.formatSelfRelationship(into: &links, with: formatter)

            let container = ResponseContainer(status: response.status, data: enrichedContent, links: links)
            return container.encodeResponse(for: request)
        }
    }
}
