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
    ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitivly
    public init(encoder: AnyEncoder = defaultEncoder, decoder: AnyDecoder = defaultDecoder, caseInsensitiveRouting: Bool = false) {
        self.configuration = ExporterConfiguration(encoder: encoder, decoder: decoder, caseInsensitiveRouting: caseInsensitiveRouting)
    }
    
    public func configure(_ app: Apodini.Application) {
        /// Instanciate exporter
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
        var logger = app.logger
        logger.logLevel = .trace
        self.logger = logger
        
        // Set option to activate case insensitive routing, default is false (so case-sensitive)
        self.app.vapor.app.routes.caseInsensitive = configuration.caseInsensitiveRouting
    }
    
    static let parameterNamespace: [ParameterNamespace] = .individual
    
    func export<H>(_ endpoint: Endpoint<H>) -> () where H : Handler {
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
    
    func export<H>(blob endpoint: Endpoint<H>) -> () where H : Handler, H.Response.Content == Blob {
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
    
    // MARK: Request Response Closure
    
    private func buildRequestResponseClosure<H: Handler>(for endpoint: Endpoint<H>, using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        
        let transformer = VaporResponseTransformer<H>(configuration.encoder)
        
        return { (request: Vapor.Request) in
            var delegate = Delegate(endpoint.handler, .required)
            
            return strategy
                .decodeRequest(from: request, with: request, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                .evaluate(on: &delegate)
                .transform(using: transformer)
        }
    }
    
    // MARK: Blob Request Response Closure
    
    private func buildBlobRequestResponseClosure<H: Handler>(for endpoint: Endpoint<H>, using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> where H.Response.Content == Blob {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        
        let transformer = VaporBlobResponseTransformer()
        
        return { (request: Vapor.Request) in
            var delegate = Delegate(endpoint.handler, .required)
            
            return strategy
                .decodeRequest(from: request, with: request, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                .evaluate(on: &delegate)
                .transform(using: transformer)
        }
    }
    
    // MARK: Service Streaming Closure
    
    private func buildServiceSideStreamingClosure<H: Handler>(for endpoint: Endpoint<H>, using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        
        let abortAnyError = AbortTransformer<H>()
        
        return { (request: Vapor.Request) in
            var delegate = Delegate(endpoint.handler, .required)
            
            return Just(request)
                .map { request in (request, request) }
                .decode(using: strategy, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .validateParameterMutability()
                .cache()
                .subscribe(to: &delegate)
                .evaluate(on: &delegate)
                .transform(using: abortAnyError)
                .cancel(if: { response in
                    response.connectionEffect == .close
                })
                .collect()
                .tryMap { (responses: [Apodini.Response<H.Response.Content>]) in
                    let status: Status? = responses.last?.status
                    let information: Set<AnyInformation> = responses.last?.information ?? []
                    let content: [H.Response.Content] = responses.compactMap { response in
                        response.content
                    }
                    let body = try configuration.encoder.encode(content)
                    
                    return Vapor.Response(status: HTTPStatus(status ?? .ok),
                                                   headers: HTTPHeaders(information),
                                                   body: Vapor.Response.Body(data: body))
                }
                .firstFuture(on: request.eventLoop)
                .map { optionalResponse in
                    optionalResponse ?? Vapor.Response()
                }
        }
    }
    
    
    // MARK: Client Streaming Closure
    
    private func buildClientSideStreamingClosure<H: Handler>(for endpoint: Endpoint<H>, using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
        let strategy = multiInputDecodingStrategy(for: endpoint)
        
        let abortAnyError = AbortTransformer<H>()
        
        let transformer = VaporResponseTransformer<H>(configuration.encoder)
        
        return { (request: Vapor.Request) in
            guard let requestCount = try configuration.decoder.decode(ArrayCount.self, from: request.bodyData).count else {
                throw ApodiniError(type: .badInput, reason: "Expected array at top level of body.", description: "Input for client side steaming endpoints must be an array at top level.")
            }
            
            print(requestCount)
            
            var delegate = Delegate(endpoint.handler, .required)
            
            return Array(0..<requestCount)
                .publisher
                .map { index in
                    (request, (request, index))
                }
                .decode(using: strategy, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .validateParameterMutability()
                .cache()
                .handleEvents(receiveCompletion: { c in Swift.print(c) })
                .subscribe(to: &delegate)
                .evaluate(on: &delegate)
                .transform(using: abortAnyError)
                .cancel(if: { response in
                    response.connectionEffect == .close
                })
                .compactMap { (response: Apodini.Response<H.Response.Content>) in
                    if response.connectionEffect == .open && response.content == nil {
                        return nil
                    } else {
                        return response
                    }
                }
                .tryMap { (response: Apodini.Response<H.Response.Content>) -> Vapor.Response in
                    return try transformer.transform(input: response)
                }
                .firstFuture(on: request.eventLoop)
                .map { optionalResponse in
                    optionalResponse ?? Vapor.Response()
                }
        }
    }
    
    // MARK: Bidirectional Streaming Closure
    
    private func buildBidirectionalStreamingClosure<H: Handler>(for endpoint: Endpoint<H>, using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
        let strategy = multiInputDecodingStrategy(for: endpoint)
        
        let abortAnyError = AbortTransformer<H>()
        
        return { (request: Vapor.Request) in
            guard let requestCount = try configuration.decoder.decode(ArrayCount.self, from: request.bodyData).count else {
                throw ApodiniError(type: .badInput, reason: "Expected array at top level of body.", description: "Input for client side steaming endpoints must be an array at top level.")
            }
            
            var delegate = Delegate(endpoint.handler, .required)
            
            return Array(0..<requestCount)
                .publisher
                .map { index in
                    (request, (request, index))
                }
                .decode(using: strategy, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .validateParameterMutability()
                .cache()
                .subscribe(to: &delegate)
                .evaluate(on: &delegate)
                .transform(using: abortAnyError)
                .cancel(if: { response in
                    return response.connectionEffect == .close
                })
                .collect()
                .tryMap { (responses: [Apodini.Response<H.Response.Content>]) in
                    let status: Status? = responses.last?.status
                    let information: Set<AnyInformation> = responses.last?.information ?? []
                    let content: [H.Response.Content] = responses.compactMap { response in
                        response.content
                    }
                    let body = try configuration.encoder.encode(content)
                    
                    return Vapor.Response(status: HTTPStatus(status ?? .ok),
                                                   headers: HTTPHeaders(information),
                                                   body: Vapor.Response.Body(data: body))
                }
                .firstFuture(on: request.eventLoop)
                .map { optionalResponse in
                    optionalResponse ?? Vapor.Response()
                }
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
    
    private func singleInputDecodingStrategy(for endpoint: AnyEndpoint) -> AnyDecodingStrategy<Vapor.Request> {
        ParameterTypeSpecific(
            .path,
             using: PathStrategy(),
             otherwise: ParameterTypeSpecific(
                .lightweight,
                using: LightweightStrategy(),
                otherwise: NumberOfContentParameterDependentStrategy
                                .oneIdentityOrAllNamedContentStrategy(configuration.decoder, for: endpoint)
                                .transformedToVaporRequestBasedStrategy())
            ).applied(to: endpoint)
            .typeErased
    }
    
    private func multiInputDecodingStrategy(for endpoint: AnyEndpoint) -> AnyDecodingStrategy<(Vapor.Request, Int)> {
        ParameterTypeSpecific(
            .path,
            using: PathStrategy().transformed { (request, _) in request },
            otherwise: ParameterTypeSpecific(
                .lightweight,
                using: AllNamedAtIndexWithLightweightPattern(decoder: configuration.decoder).transformed { (request, index) in (request.bodyData, index)},
                otherwise: AllNamedAtIndexWithContentPattern(decoder: configuration.decoder).transformed { (request, index) in (request.bodyData, index)}
            )
        )
        .applied(to: endpoint)
        .typeErased
    }
    
    // MARK: Helpers
    
    private struct ArrayCount: Decodable {
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
        
        func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, (Data, Int)> where Element : Decodable, Element : Encodable {
            IndexedNamedChildPatternStrategy<
                DynamicIndexPattern<
                    LightweightPattern<
                        DynamicNamePattern<
                            IdentityPattern<Element>>>>>(parameter.name, decoder).typeErased
        }
    }
    
    private struct AllNamedAtIndexWithContentPattern: EndpointDecodingStrategy {
        let decoder: AnyDecoder
        
        func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, (Data, Int)> where Element : Decodable, Element : Encodable {
            IndexedNamedChildPatternStrategy<
                DynamicIndexPattern<
                    ContentPattern<
                        DynamicNamePattern<
                            IdentityPattern<Element>>>>>(parameter.name, decoder).typeErased
        }
    }
}
