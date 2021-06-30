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
    
    init(_ app: Apodini.Application, _ configuration: HTTP.ExporterConfiguration) {
        self.app = app
        self.configuration = configuration
    }
    
    static let parameterNamespace: [ParameterNamespace] = .individual
    
    func export<H>(_ endpoint: Endpoint<H>) -> () where H : Handler {
        let knowledge = endpoint[VaporEndpointKnowledge.self]
        
        switch knowledge.pattern {
        case .requestResponse:
            app.vapor.app.on(knowledge.method,
                             knowledge.path,
                             use: buildRequestResponseClosure(for: endpoint, using: knowledge.defaultValues))
        default:
            app.logger.warning("HTTP exporter can only handle 'CommunicationalPatter.requestResponse'. Ignored endpoint at \(knowledge.method) \(knowledge.path).")
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
            app.logger.warning("HTTP exporter can only handle 'CommunicationalPatter.requestResponse' for content type 'Blob'. Endpoint at \(knowledge.method) \(knowledge.path) is exported with degraded functionality.")
            self.export(endpoint)
        }
    }
    
    // MARK: Closure Builders
    
    private func buildRequestResponseClosure<H: Handler>(for endpoint: Endpoint<H>, using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
        let strategy = baseDecodingStrategy(for: endpoint)
        
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
    
    private func buildBlobRequestResponseClosure<H: Handler>(for endpoint: Endpoint<H>, using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> where H.Response.Content == Blob {
        let strategy = baseDecodingStrategy(for: endpoint)
        
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
    
    
    // MARK: Decoding Strategies
    
    private func baseDecodingStrategy(for endpoint: AnyEndpoint) -> AnyDecodingStrategy<Vapor.Request> {
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
}
