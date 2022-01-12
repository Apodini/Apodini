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
    ///    - rootPath: Configures the root path for the HTTP endpoints
    public init(encoder: AnyEncoder = defaultEncoder, decoder: AnyDecoder = defaultDecoder, caseInsensitiveRouting: Bool = false, rootPath: RootPath? = nil) {
        self.configuration = ExporterConfiguration(encoder: encoder, decoder: decoder, caseInsensitiveRouting: caseInsensitiveRouting, rootPath: rootPath)
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
        // Note: a thing to consider here is that we might want to have per-route case sensitivity.
        // For example, if the REST IE wants case-insensitive routing, but the HTTP IE does not, that'd somehow need to be supported.
        app.httpServer.isCaseInsensitiveRoutingEnabled = configuration.caseInsensitiveRouting
    }
    
    static let parameterNamespace: [ParameterNamespace] = .individual
    
    func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
        let knowledge = endpoint[HTTPEndpointKnowledge.self]
        let path = path(from: knowledge)
        
        switch knowledge.pattern {
        case .requestResponse:
            logger.info("Exporting Request-Response Pattern on \(knowledge.method): \(path)")
            app.httpServer.registerRoute(
                knowledge.method,
                path,
                handler: buildRequestResponseClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .serviceSideStream:
            logger.info("Exporting Service-Side-Streaming Pattern on \(knowledge.method): \(path)")
            app.httpServer.registerRoute(
                knowledge.method,
                path,
                handler: buildServiceSideStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .clientSideStream:
            logger.info("Exporting Client-Side-Streaming Pattern on \(knowledge.method): \(path)")
            app.httpServer.registerRoute(
                knowledge.method,
                path,
                handler: buildClientSideStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .bidirectionalStream:
            logger.info("Exporting Bidirectional-Streaming Pattern on \(knowledge.method): \(path)")
            app.httpServer.registerRoute(
                knowledge.method,
                path,
                handler: buildBidirectionalStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        }
    }
    
    func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        let knowledge = endpoint[HTTPEndpointKnowledge.self]
        let path = path(from: knowledge)
        
        switch knowledge.pattern {
        case .requestResponse:
            app.httpServer.registerRoute(
                knowledge.method,
                path,
                handler: buildRequestResponseClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .serviceSideStream:
            app.httpServer.registerRoute(
                knowledge.method,
                path,
                handler: buildServiceSideStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        default:
            logger.warning("HTTP exporter can only handle 'CommunicationalPattern.requestResponse' for content type 'Blob'. Endpoint at \(knowledge.method) \(path) is exported with degraded functionality.")
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
                .transformedToHTTPRequestBasedStrategy()
        )
        .applied(to: endpoint)
        .typeErased
    }
    
    func multiInputDecodingStrategy(for endpoint: AnyEndpoint) -> AnyDecodingStrategy<(HTTPRequest, Int)> {
        ParameterTypeSpecific(
            lightweight: AllNamedAtIndexWithLightweightPattern(decoder: configuration.decoder)
                .transformed { request, index in
                    (request.bodyStorage.getFullBodyData() ?? Data(), index)
                },
            path: PathStrategy().transformed { request, _ in request },
            content: AllNamedAtIndexWithContentPattern(decoder: configuration.decoder)
                .transformed { request, index in
                    (request.bodyStorage.getFullBodyData() ?? Data(), index)
                }
        )
        .applied(to: endpoint)
        .typeErased
    }
    
    // MARK: Helpers
    
    private func path(from knowledge: HTTPEndpointKnowledge) -> [HTTPPathComponent] {
        var path = knowledge.path
        if let rootPath = configuration.rootPath {
            path.insert(.verbatim(rootPath.endpointPath(withVersion: app.version).description), at: 0)
        }
        return path
    }
    
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
