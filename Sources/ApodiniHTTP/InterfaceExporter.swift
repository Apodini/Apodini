//
//  InterfaceExporter.swift
//  
//
//  Created by Max Obermeier on 30.06.21.
//

import Foundation
import Apodini
import ApodiniExtension
import ApodiniVaporSupport
import OpenCombine
import Vapor
import Logging

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
        self.app.vapor.app.routes.caseInsensitive = configuration.caseInsensitiveRouting
    }
    
    static let parameterNamespace: [ParameterNamespace] = .individual
    
    func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
        let knowledge = endpoint[VaporEndpointKnowledge.self]
        
        switch knowledge.pattern {
        case .requestResponse:
            logger.info("Exporting Request-Response Pattern on \(knowledge.method): \(knowledge.path)")
            app.vapor.app.on(knowledge.method,
                             knowledge.path,
                             use: buildRequestResponseClosure(for: endpoint, using: knowledge.defaultValues))
        case .serviceSideStream:
            logger.info("Exporting Service-Side-Streaming Pattern on \(knowledge.method): \(knowledge.path)")
            app.vapor.app.on(knowledge.method,
                             knowledge.path,
                             use: buildServiceSideStreamingClosure(for: endpoint, using: knowledge.defaultValues))
        case .clientSideStream:
            logger.info("Exporting Client-Side-Streaming Pattern on \(knowledge.method): \(knowledge.path)")
            app.vapor.app.on(knowledge.method,
                             knowledge.path,
                             use: buildClientSideStreamingClosure(for: endpoint, using: knowledge.defaultValues))
        case .bidirectionalStream:
            logger.info("Exporting Bidirectional-Streaming Pattern on \(knowledge.method): \(knowledge.path)")
            app.vapor.app.on(knowledge.method,
                             knowledge.path,
                             use: buildBidirectionalStreamingClosure(for: endpoint, using: knowledge.defaultValues))
        }
    }
    
    func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.BodyContent == Blob {
        let knowledge = endpoint[VaporEndpointKnowledge.self]
        
        switch knowledge.pattern {
        case .requestResponse:
            app.vapor.app.on(knowledge.method,
                             knowledge.path,
                             use: buildBlobRequestResponseClosure(for: endpoint, using: knowledge.defaultValues))
        default:
            logger.warning("HTTP exporter can only handle 'CommunicationalPatter.requestResponse' for content type 'Blob'. Endpoint at \(knowledge.method) \(knowledge.path) is exported with degraded functionality.")
            self.export(endpoint)
        }
    }
    
    
    // MARK: Response Transformers
    
    struct AbortTransformer<H: Handler>: ResultTransformer {
        func handle(error: ApodiniError) -> ErrorHandlingStrategy<Apodini.Response<H.Response.BodyContent>, Error> {
            .abort(error)
        }
        
        func transform(input: Apodini.Response<H.Response.BodyContent>) -> Apodini.Response<H.Response.BodyContent> {
            input
        }
    }
    
    
    // MARK: Decoding Strategies
    
    func singleInputDecodingStrategy(for endpoint: AnyEndpoint) -> AnyDecodingStrategy<Vapor.Request> {
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
    
    func multiInputDecodingStrategy(for endpoint: AnyEndpoint) -> AnyDecodingStrategy<(Vapor.Request, Int)> {
        ParameterTypeSpecific(
            lightweight: AllNamedAtIndexWithLightweightPattern(decoder: configuration.decoder)
                .transformed { request, index in (request.bodyData, index) },
            path: PathStrategy().transformed { request, _ in request },
            content: AllNamedAtIndexWithContentPattern(decoder: configuration.decoder)
                .transformed { request, index in (request.bodyData, index) }
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
