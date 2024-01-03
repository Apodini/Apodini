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
public final class HTTP: DependableConfiguration {
    public typealias InternalConfiguration = HTTPExporterConfiguration
    
    let configuration: HTTPExporterConfiguration
    public var staticConfigurations = [any AnyDependentStaticConfiguration]()
    
    /// The default `AnyEncoder`, a `JSONEncoder` with certain set parameters
    public static var defaultEncoder: any AnyEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        return encoder
    }
    
    /// The default `AnyDecoder`, a `JSONDecoder`
    public static var defaultDecoder: any AnyDecoder {
        JSONDecoder()
    }
    
    /// Initializes the configuration of the ``HTTP`` exporter with (default) `AnyEncoder` and `AnyDecoder`
    /// - Parameters:
    ///    - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
    ///    - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
    ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitively
    ///    - rootPath: Configures the root path for the HTTP endpoints
    public init(
        encoder: any AnyEncoder = defaultEncoder,
        decoder: any AnyDecoder = defaultDecoder,
        urlParamDateDecodingStrategy: DateDecodingStrategy = .default,
        caseInsensitiveRouting: Bool = false,
        rootPath: RootPath? = nil
    ) {
        self.configuration = HTTPExporterConfiguration(
            encoder: encoder,
            decoder: decoder,
            urlParamDateDecodingStrategy: urlParamDateDecodingStrategy,
            caseInsensitiveRouting: caseInsensitiveRouting,
            rootPath: rootPath,
            useResponseContainer: false
        )
        
        staticConfigurations = []
    }
    
    public func configure(_ app: Apodini.Application) {
        /// Instantiate exporter
        let exporter = HTTPInterfaceExporter(app, self.configuration)
        
        /// Insert exporter into `InterfaceExporterStorage`
        app.registerExporter(exporter: exporter)
        
        self.staticConfigurations.configureAny(app, parentConfiguration: self.configuration)
    }
}

extension HTTP {
    /// Initializes the configuration of the `HTTPInterfaceExporter` with (default) JSON Coders and possibly associated configurations, e.g. OpenAPI or APIAuditor
    /// - Parameters:
    ///    - encoder: The to be used `JSONEncoder`, defaults to a `JSONEncoder`
    ///    - decoder: The to be used `JSONDecoder`, defaults to a `JSONDecoder`
    ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitively
    ///    - rootPath: Configures the root path for the HTTP endpoints
    ///    - staticConfigurations: A result builder that allows passing dependent static Exporters like the OpenAPI Exporter
    public convenience init(
        encoder: JSONEncoder = defaultEncoder as! JSONEncoder,
        decoder: JSONDecoder = defaultDecoder as! JSONDecoder,
        urlParamDateDecodingStrategy: ApodiniNetworking.DateDecodingStrategy = .default,
        caseInsensitiveRouting: Bool = false,
        rootPath: RootPath? = nil,
        @DependentStaticConfigurationBuilder<HTTPExporterConfiguration> staticConfigurations: () -> [any AnyDependentStaticConfiguration] = { [] }
    ) {
        self.init(
            encoder: encoder,
            decoder: decoder,
            urlParamDateDecodingStrategy: urlParamDateDecodingStrategy,
            caseInsensitiveRouting: caseInsensitiveRouting,
            rootPath: rootPath
        )
        self.staticConfigurations = staticConfigurations()
    }
}


// MARK: Exporter

class HTTPInterfaceExporter: InterfaceExporter {
    let app: Apodini.Application
    let configuration: HTTPExporterConfiguration
    let logger: Logger
    
    init(_ app: Apodini.Application, _ configuration: HTTPExporterConfiguration) {
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
            try! app.httpServer.registerRoute(
                knowledge.method,
                path,
                .requestResponse,
                handler: buildRequestResponseClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .serviceSideStream:
            logger.info("Exporting Service-Side-Streaming Pattern on \(knowledge.method): \(path)")
            try! app.httpServer.registerRoute(
                knowledge.method,
                path,
                .serviceSideStream,
                handler: buildServiceSideStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .clientSideStream:
            logger.info("Exporting Client-Side-Streaming Pattern on \(knowledge.method): \(path)")
            try! app.httpServer.registerRoute(
                knowledge.method,
                path,
                .clientSideStream,
                handler: buildClientSideStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .bidirectionalStream:
            logger.info("Exporting Bidirectional-Streaming Pattern on \(knowledge.method): \(path)")
            try! app.httpServer.registerRoute(
                knowledge.method,
                path,
                .bidirectionalStream,
                handler: buildBidirectionalStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        }
    }
    
    func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        let knowledge = endpoint[HTTPEndpointKnowledge.self]
        let path = path(from: knowledge)
        
        switch knowledge.pattern {
        case .requestResponse:
            try! app.httpServer.registerRoute(
                knowledge.method,
                path,
                .requestResponse,
                handler: buildRequestResponseClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .clientSideStream:
            try! app.httpServer.registerRoute(
                knowledge.method,
                path,
                .clientSideStream,
                handler: buildClientSideStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .serviceSideStream:
            try! app.httpServer.registerRoute(
                knowledge.method,
                path,
                .serviceSideStream,
                handler: buildServiceSideStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        case .bidirectionalStream:
            try! app.httpServer.registerRoute(
                knowledge.method,
                path,
                .bidirectionalStream,
                handler: buildBidirectionalStreamingClosure(for: endpoint, using: knowledge.defaultValues)
            )
        }
    }
    
    
    // MARK: Response Transformers
    
    struct AbortTransformer<H: Handler>: ResultTransformer {
        func handle(error: ApodiniError) -> ErrorHandlingStrategy<Apodini.Response<H.Response.Content>, any Error> {
            .abort(error)
        }
        
        func transform(input: Apodini.Response<H.Response.Content>) -> Apodini.Response<H.Response.Content> {
            input
        }
    }
    
    
    // MARK: Decoding Strategies
    
    func dataFrameDecodingStrategy(for endpoint: any AnyEndpoint) -> AnyDecodingStrategy<Data> {
        ParameterTypeSpecific(
            lightweight: LightweightFromBodyStrategy(decoder: configuration.decoder),
            path: LightweightFromBodyStrategy(decoder: configuration.decoder),
            content: ContentFromBodyStrategy(decoder: configuration.decoder))
        .applied(to: endpoint)
        .typeErased
    }
    
    func singleInputDecodingStrategy(for endpoint: any AnyEndpoint) -> AnyDecodingStrategy<HTTPRequest> {
        ParameterTypeSpecific(
            lightweight: LightweightStrategy(dateDecodingStrategy: configuration.urlParamDateDecodingStrategy),
            path: PathStrategy(dateDecodingStrategy: configuration.urlParamDateDecodingStrategy),
            content: NumberOfContentParameterAwareStrategy
                .oneIdentityOrAllNamedContentStrategy(configuration.decoder, for: endpoint)
                .transformedToHTTPRequestBasedStrategy()
        )
        .applied(to: endpoint)
        .typeErased
    }
    
    func multiInputDecodingStrategy(for endpoint: any AnyEndpoint) -> AnyDecodingStrategy<(HTTPRequest, Int)> {
        ParameterTypeSpecific(
            lightweight: AllNamedAtIndexWithLightweightPattern(decoder: configuration.decoder)
                .transformed { request, index in
                    (request.bodyStorage.getFullBodyData() ?? Data(), index)
                },
            path: PathStrategy(dateDecodingStrategy: configuration.urlParamDateDecodingStrategy).transformed { request, _ in request },
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
            path.insert(.constant(rootPath.endpointPath(withVersion: app.version).description), at: 0)
        }
        return path
    }
    
    struct ArrayCount: Decodable {
        let count: Int?
        
        init(from decoder: any Decoder) throws {
            self.count = try decoder.unkeyedContainer().count
        }
    }
    
    private struct LightweightPattern<E: DecodingPattern>: DecodingPattern {
        var value: E.Element
        
        init(from decoder: any Decoder) throws {
            self.value = try decoder.container(keyedBy: String.self).decode(E.self, forKey: "query").value
        }
    }
    
    private struct ContentPattern<E: DecodingPattern>: DecodingPattern {
        var value: E.Element
        
        init(from decoder: any Decoder) throws {
            self.value = try decoder.container(keyedBy: String.self).decode(E.self, forKey: "body").value
        }
    }
    
    private struct AllNamedAtIndexWithLightweightPattern: EndpointDecodingStrategy {
        let decoder: any AnyDecoder
        
        func strategy<Element>(
            for parameter: EndpointParameter<Element>
        ) -> AnyParameterDecodingStrategy<Element, (Data, Int)> where Element: Decodable, Element: Encodable {
            IndexedNamedChildPatternStrategy<
                DynamicIndexPattern<
                    LightweightPattern<
                        DynamicNamePattern<
                            IdentityPattern<Element>>>>>(parameter.name, decoder).typeErased
        }
    }
    
    private struct AllNamedAtIndexWithContentPattern: EndpointDecodingStrategy {
        let decoder: any AnyDecoder
        
        func strategy<Element>(
            for parameter: EndpointParameter<Element>
        ) -> AnyParameterDecodingStrategy<Element, (Data, Int)> where Element: Decodable, Element: Encodable {
            IndexedNamedChildPatternStrategy<
                DynamicIndexPattern<
                    ContentPattern<
                        DynamicNamePattern<
                            IdentityPattern<Element>>>>>(parameter.name, decoder).typeErased
        }
    }
    
    private struct LightweightFromBodyStrategy: EndpointDecodingStrategy {
        let decoder: any AnyDecoder
        
        func strategy<Element>(
            for parameter: EndpointParameter<Element>
        ) -> AnyParameterDecodingStrategy<Element, Data> where Element: Decodable, Element: Encodable {
            NamedChildPatternStrategy<
                LightweightPattern<
                    DynamicNamePattern<
                        IdentityPattern<Element>>>>(parameter.name, decoder).typeErased
        }
    }
    
    private struct ContentFromBodyStrategy: EndpointDecodingStrategy {
        let decoder: any AnyDecoder
        
        func strategy<Element>(
            for parameter: EndpointParameter<Element>
        ) -> AnyParameterDecodingStrategy<Element, Data> where Element: Decodable, Element: Encodable {
            NamedChildPatternStrategy<
                ContentPattern<
                    DynamicNamePattern<
                        IdentityPattern<Element>>>>(parameter.name, decoder).typeErased
        }
    }
}
