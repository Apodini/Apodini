//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniExtension
import Logging
import ApodiniNetworking

// MARK: HTTP Declaration

/// Public Apodini Interface Exporter for basic HTTP
public final class HTTP: Configuration {
    let configuration: ExporterConfiguration
    
    /// The default `AnyEncoder`, a `JSONEncoder` with certain set parameters
    public static var defaultEncoder: AnyEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        return encoder
    }
    
    /// The default `AnyDecoder`, a `JSONDecoder`
    public static var defaultDecoder: AnyDecoder {
        JSONDecoder()
    }
    
    /// Initializes the configuration of the ``HTTP`` exporter with (default) `AnyEncoder` and `AnyDecoder`
    /// - Parameters:
    ///    - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
    ///    - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
    ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitively
    public init(encoder: AnyEncoder = defaultEncoder, decoder: AnyDecoder = defaultDecoder, caseInsensitiveRouting: Bool = false) {
        self.configuration = ExporterConfiguration(encoder: encoder, decoder: decoder, caseInsensitiveRouting: caseInsensitiveRouting)
    }
    
    public func configure(_ app: Apodini.Application) {
        /// Instantiate exporter
        let exporter = Exporter(app, self.configuration)
        
        /// Insert exporter into `InterfaceExporterStorage`
        app.registerExporter(exporter: exporter)
    }
}


// MARK: Exporter

struct Exporter: InterfaceExporter {
    let app: Apodini.Application
    let configuration: HTTP.ExporterConfiguration
    let logger: Logger
    
    init(_ app: Apodini.Application, _ configuration: HTTP.ExporterConfiguration) {
        self.app = app
        self.configuration = configuration
        self.logger = app.logger
        // Set option to activate case insensitive routing, default is false (so case-sensitive)
        //self.app.vapor.app.routes.caseInsensitive = configuration.caseInsensitiveRouting
        app.httpServer.isCaseInsensitiveRoutingEnabled = configuration.caseInsensitiveRouting // TODO what if we have both the REST and the HTTP IEs enabled, and their respective configurations specify different values for the routing case sensitivity???
    }
    
    static let parameterNamespace: [ParameterNamespace] = .individual
    
    func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
        let knowledge = endpoint[HTTPEndpointKnowledge.self]
        
        switch knowledge.pattern {
        case .requestResponse:
            logger.info("Exporting Request-Response Pattern on \(knowledge.method): \(knowledge.path)")
            app.httpServer.registerRoute(
                knowledge.method,
                knowledge.path,
                handler: buildRequestResponseClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .serviceSideStream:
            logger.info("Exporting Service-Side-Streaming Pattern on \(knowledge.method): \(knowledge.path)")
            app.httpServer.registerRoute(
                knowledge.method,
                knowledge.path,
                handler: buildServiceSideStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .clientSideStream:
            logger.info("Exporting Client-Side-Streaming Pattern on \(knowledge.method): \(knowledge.path)")
            app.httpServer.registerRoute(
                knowledge.method,
                knowledge.path,
                handler: buildClientSideStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .bidirectionalStream:
            logger.info("Exporting Bidirectional-Streaming Pattern on \(knowledge.method): \(knowledge.path)")
            app.httpServer.registerRoute(
                knowledge.method,
                knowledge.path,
                handler: buildBidirectionalStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        }
    }
    
    func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        let knowledge = endpoint[HTTPEndpointKnowledge.self]
        
        switch knowledge.pattern {
        case .requestResponse:
            app.httpServer.registerRoute(
                knowledge.method,
                knowledge.path,
                handler: buildRequestResponseClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .serviceSideStream:
            app.httpServer.registerRoute(
                knowledge.method,
                knowledge.path,
                handler: buildServiceSideStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        default:
            logger.warning("HTTP exporter can only handle 'CommunicationalPattern.requestResponse' for content type 'Blob'. Endpoint at \(knowledge.method) \(knowledge.path) is exported with degraded functionality.")
            self.export(endpoint)
        }
    }
    
    
    // MARK: Response Transformers
    
    struct AbortTransformer<H: Handler>: ResultTransformer {
        func handle(error: ApodiniError) -> ErrorHandlingStrategy<Apodini.Response<H.Response.Content>, Error> {
            .abort(error)
        }
        
        func transform(input: Apodini.Response<H.Response.Content>) -> Apodini.Response<H.Response.Content> {
            input
        }
    }
    
    
    // MARK: Decoding Strategies
    
    func singleInputDecodingStrategy(for endpoint: AnyEndpoint) -> AnyDecodingStrategy<HTTPRequest> {
        ParameterTypeSpecific(
            lightweight: LightweightStrategy(),
            path: PathStrategy(),
            content: NumberOfContentParameterAwareStrategy
                .oneIdentityOrAllNamedContentStrategy(configuration.decoder, for: endpoint)
                .transformedToVaporRequestBasedStrategy()
        )
        .applied(to: endpoint)
        .typeErased
    }
    
    func multiInputDecodingStrategy(for endpoint: AnyEndpoint) -> AnyDecodingStrategy<(HTTPRequest, Int)> {
        ParameterTypeSpecific(
            lightweight: AllNamedAtIndexWithLightweightPattern(decoder: configuration.decoder)
            // TODO this used to be simply request.bodyData. What should it look like for stream-based requests????
                //.transformed { request, index in (request.bodyData, index) },
                .transformed { (request, index) in
                    print("HMMM.1", request, index)
                    return (request.bodyStorage.getFullBodyData() ?? Data(), index)
                },
            path: PathStrategy().transformed { request, _ in request },
            content: AllNamedAtIndexWithContentPattern(decoder: configuration.decoder)
                //.transformed { request, index in (request.bodyData, index) }
                // TODO not sure about this one!
                .transformed { request, index in
                    print("HMMM.2", request, index)
                    return (request.bodyStorage.getFullBodyData() ?? Data(), index)
                }
            
        )
        .applied(to: endpoint)
        .typeErased
    }
    
    // MARK: Helpers
    
    struct ArrayCount: Decodable {
        let count: Int?
        
        init(from decoder: Decoder) throws {
            self.count = try decoder.unkeyedContainer().count
        }
    }
    
    private struct LightweightPattern<E: DecodingPattern>: DecodingPattern {
        var value: E.Element
        
        init(from decoder: Decoder) throws {
            self.value = try decoder.container(keyedBy: String.self).decode(E.self, forKey: "query").value
        }
    }
    
    private struct ContentPattern<E: DecodingPattern>: DecodingPattern {
        var value: E.Element
        
        init(from decoder: Decoder) throws {
            self.value = try decoder.container(keyedBy: String.self).decode(E.self, forKey: "body").value
        }
    }
    
    private struct AllNamedAtIndexWithLightweightPattern: EndpointDecodingStrategy {
        let decoder: AnyDecoder
        
        func strategy<Element>(for parameter: EndpointParameter<Element>)
            -> AnyParameterDecodingStrategy<Element, (Data, Int)> where Element: Decodable, Element: Encodable {
            IndexedNamedChildPatternStrategy<
                DynamicIndexPattern<
                    LightweightPattern<
                        DynamicNamePattern<
                            IdentityPattern<Element>>>>>(parameter.name, decoder).typeErased
        }
    }
    
    private struct AllNamedAtIndexWithContentPattern: EndpointDecodingStrategy {
        let decoder: AnyDecoder
        
        func strategy<Element>(for parameter: EndpointParameter<Element>)
            -> AnyParameterDecodingStrategy<Element, (Data, Int)> where Element: Decodable, Element: Encodable {
            IndexedNamedChildPatternStrategy<
                DynamicIndexPattern<
                    ContentPattern<
                        DynamicNamePattern<
                            IdentityPattern<Element>>>>>(parameter.name, decoder).typeErased
        }
    }
}
