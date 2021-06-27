//
// Created by Andreas Bauer on 30.12.20.
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
                            .lightweight,
                            using: LightweightStrategy(),
                            otherwise: ParameterTypeSpecific(
                                        .path,
                                        using: PathStrategy(),
                                        otherwise: AllIdentityStrategy(exporterConfiguration.decoder).transformed { request in
                                                        if let buffer = request.body.data {
                                                            return buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes) ?? Data()
                                                        } else {
                                                            return Data()
                                                        }
        })).applied(to: endpoint)
        
        self.defaultStore = DefaultValueStore(for: endpoint)
    }
    
    
    func register(at routesBuilder: Vapor.RoutesBuilder, using operation: Apodini.Operation) {
        routesBuilder.on(Vapor.HTTPMethod(operation), [], use: self.handleRequest)
    }

    func handleRequest(request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let apodiniRequest = strategy
                                .decodeRequest(from: request,
                                               with: DefaultRequestBasis(base: request),
                                               on: request.eventLoop)
                                .insertDefaults(with: defaultStore)
                                .cache()
        
        let responseAndRequestFuture: EventLoopFuture<ResponseWithRequest<H.Response.Content>> = apodiniRequest.evaluate(on: endpoint.handler)

        return responseAndRequestFuture
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


private struct LightweightStrategy: EndpointDecodingStrategy {
    func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Vapor.Request> {
        LightweightParameterStrategy<Element>(name: parameter.name).typeErased
    }
}

private struct LightweightParameterStrategy<E: Decodable>: ParameterDecodingStrategy {
    let name: String
    
    func decode(from request: Vapor.Request) throws -> E {
        guard let query = request.query[E.self, at: name] else {
            throw DecodingError.keyNotFound(
                name,
                DecodingError.Context(codingPath: [name],
                                      debugDescription: "No query parameter with name \(name) present in request \(request.description)",
                                      underlyingError: nil)) // the query parameter doesn't exists
        }
        return query
    }
}

private struct PathStrategy: EndpointDecodingStrategy {
    func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Vapor.Request> {
        PathParameterStrategy(parameter: parameter).typeErased
    }
}


private struct PathParameterStrategy<E: Codable>: ParameterDecodingStrategy {
    let parameter: EndpointParameter<E>
    
    func decode(from request: Vapor.Request) throws -> E {
        guard let stringParameter = request.parameters.get(parameter.pathId) else {
            throw DecodingError.keyNotFound(
                parameter.pathId,
                DecodingError.Context(
                    codingPath: [parameter.pathId],
                    debugDescription: "No path parameter with id \(parameter.pathId) present in request \(request.description)",
                    underlyingError: nil
                )) // the path parameter didn't exist on that request
        }
        
        guard let value = parameter.initLosslessStringConvertibleParameterValue(from: stringParameter) else {
            throw ApodiniError(type: .badInput, reason: """
                                                        Encountered illegal input for path parameter \(parameter.name).
                                                        \(Element.self) can't be initialized from \(stringParameter).
                                                        """)
        }
        
        return value
    }
}
