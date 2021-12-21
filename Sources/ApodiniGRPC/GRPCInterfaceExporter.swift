//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniExtension
import ApodiniNetworking
import ApodiniUtils
import Logging
import Dispatch
@_exported import ProtobufferCoding
import Foundation


extension HTTPMediaType {
    /// gRPC media type subtype suffix options
    enum GRPCEncodingOption: String {
        case proto
        case json
    }
    
    /// Creates a gRPC media type with the specified encoding appended as the subtype's suffix
    static func gRPC(_ encoding: GRPCEncodingOption) -> HTTPMediaType {
        HTTPMediaType(type: "application", subtype: "grpc+\(encoding.rawValue)")
    }
    
    /// The `application/grpc` media type without an explicitly specified encoding
    static let gRPCPlain = HTTPMediaType(type: "application", subtype: "grpc")
}


/// The gRPC interface exporter's configuration entry point.
public class GRPC: Configuration {
    let packageName: String
    let serviceName: String
    let pathPrefix: String
    let enableReflection: Bool
    
    public init(packageName: String, serviceName: String, pathPrefix: String = "__grpc", enableReflection: Bool = true) {
        self.packageName = packageName
        self.serviceName = serviceName
        self.pathPrefix = pathPrefix
        self.enableReflection = enableReflection
    }
    
    public func configure(_ app: Application) {
        let exporter = GRPCInterfaceExporter(app: app, config: self)
        app.registerExporter(exporter: exporter)
    }
}


class GRPCInterfaceExporter: InterfaceExporter {
    static let serverReflectionPackageName = "grpc.reflection.v1alpha"
    static let serverReflectionServiceName = "ServerReflection"
    static let serverReflectionMethodName = "ServerReflectionInfo"
    
    private let app: Application
    private let config: GRPC // would love to have a "GRPCConfig" typename or smth like that here, but that'd make the public API ugly and weird... :/
    
    // The proto/gRPC package into which all of the web service's stuff goes,
    private let defaultPackageName: String
    
    internal /* private but tests */ let server: GRPCServer
    
    private var logger: Logger { app.logger }
    
    private let reflectionInputType: ProtoType
    private let reflectionOutputType: ProtoType
    
    
    init(app: Application, config: GRPC) {
        self.app = app
        self.config = config
        let defaultPackageName = config.packageName
        self.defaultPackageName = defaultPackageName
        let server = GRPCServer(defaultPackageName: defaultPackageName)
        self.server = server
        // Configure HTTP/2
        guard app.httpConfiguration.supportVersions.contains(.two),
              let tlsConfig = app.httpConfiguration.tlsConfiguration,
              tlsConfig.applicationProtocols.contains("h2")
        else {
            fatalError("""
                Invalid HTTP configuration: the gRPC interface exporter requires both HTTP/2 and TLS be enabled.
                You might need to move your web service's HTTPConfiguration up so that it comes before the GRPC configuration.
                """
            )
        }
        
        // Create the default service (we only support one atm, but this implementation could also support multiple services
        server.createService(name: config.serviceName, associatedWithPackage: defaultPackageName)
        server.createService(name: Self.serverReflectionServiceName, associatedWithPackage: Self.serverReflectionPackageName)
        
        do {
            let reflectionTypes = try ServerReflectionInfoRPCHandler.registerReflectionServiceTypesWithSchema(server.schema)
            self.reflectionInputType = reflectionTypes.inputType
            self.reflectionOutputType = reflectionTypes.outputType
            try server.schema.informAboutMessageType(FileDescriptorSet.self) // this is enough to pull in the entire descriptors file
        } catch {
            fatalError("Error registering proto types with schema: \(error)")
        }
    }
    
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        let commPattern = endpoint[CommunicationalPattern.self]
        let methodName = getMethodName(for: endpoint)
        logger.notice("-[\(Self.self) \(#function)] registering method w/ commPattern: \(commPattern), endpoint: \(endpoint), methodName: \(methodName)")
        
        let serviceName = endpoint[Context.self].get(valueFor: GRPCServiceNameContextKey.self) ?? config.serviceName
        if server.service(named: serviceName, inPackage: defaultPackageName) == nil {
            server.createService(name: serviceName, associatedWithPackage: defaultPackageName)
        }
        
        let endpointContext = GRPCEndpointContext(communicationalPattern: endpoint[CommunicationalPattern.self])
        
        server.addMethod(
            toServiceNamed: serviceName,
            inPackage: defaultPackageName,
            GRPCMethod(
                name: methodName,
                endpoint: endpoint,
                endpointContext: endpointContext,
                decodingStrategy: GRPCEndpointDecodingStrategy(endpointContext).applied(to: endpoint).typeErased,
                schema: server.schema
            )
        )
        logger.notice("[gRPC] Added method \(defaultPackageName).\(serviceName).\(methodName)")
    }
    
    
    func export<H: Handler>(blob endpoint: Endpoint<H>) where H.Response.Content == Blob {
        logger.warning("Skipping endpoint \(endpoint). The gRPC interface exporter does not support Blob handlers")
    }
    
    
    func finishedExporting(_ webService: WebServiceModel) {
        // Add the reflection service
        server.addMethod(
            toServiceNamed: Self.serverReflectionServiceName,
            inPackage: Self.serverReflectionPackageName,
            GRPCMethod(
                name: Self.serverReflectionMethodName,
                type: .bidirectionalStream,
                inputType: reflectionInputType,
                outputType: reflectionOutputType,
                streamRPCHandlerMaker: { [unowned self] in
                    ServerReflectionInfoRPCHandler(server: self.server)
                }
            )
        )
        
        // Makes the types managed by the schema ready for use by the reflection API
        try! server.schema.finalize()
        server.createFileDescriptors()
        
        if config.enableReflection {
            setupReflectionHTTPRoutes()
        }
        
        // Configure ApodiniNetworking's HTTP server to use our gRPC-specific channel handlers for gRPC messages
        app.httpServer.addIncomingHTTP2StreamConfigurationHandler(forContentTypes: [.gRPCPlain, .gRPC(.proto), .gRPC(.json)]) { channel in
            channel.pipeline.addHandlers([
                GRPCRequestDecoder(),
                GRPCResponseEncoder(),
                GRPCMessageHandler(server: self.server)
            ])
        }
    }
    
    
    // MARK: Internal Stuff
    
    private func getMethodName<H>(for endpoint: Endpoint<H>) -> String {
        if let methodName = endpoint[Context.self].get(valueFor: GRPCMethodNameContextKey.self) {
            return methodName
        } else {
            // No explicit method name was specified, so we construct a default one based on the information we have about this handler.
            // The problem is that we don't exactly have a lot of information about the handler.
            // Essentially, there's only a handful of things we can use to construct a handler name:
            // - path of the handler
            // - handler type name (problematic w/ nested/generic handler types)
            // - operation type (this would allow us to prepend verbs like "get" or "create"
            // - communication pattern type (req-res, client-side stream, server-side stream, bidirectional stream). this is probaly the least useful one
            let methodName = endpoint.absolutePath.reduce(into: "") { partialResult, pathComponent in
                switch pathComponent {
                case .root:
                    break
                case .string(let value):
                    partialResult.append(value.capitalisingFirstCharacter)
                case .parameter(let parameter):
                    break
                }
            }
            return methodName
        }
    }
    
    
    /// Registers some HTTP routes for accessing the proto reflection schema
    private func setupReflectionHTTPRoutes() {
        /// Make a JSON version of the whole gRPC schema available as a regular HTTP GET endpoint.
        /// - NOTE this might not necessarily be the most desirable thing, since it might expose internal data. But then again the OpenAPI interface exporter works the exact same way...
        app.httpServer.registerRoute(.GET, ["__apodini", "grpc", "schema", "json", "full"]) { req -> HTTPResponse in
            let response = HTTPResponse(version: req.version, status: .ok, headers: HTTPHeaders {
                $0[.contentType] = .json(charset: .utf8)
            })
            let allFileDescriptors = FileDescriptorSet(files: self.server.fileDescriptors.map(\.fileDescriptor))
            try response.bodyStorage.write(encoding: allFileDescriptors, using: JSONEncoder(outputFormatting: [.withoutEscapingSlashes]))
            return response
        }
        
        app.httpServer.registerRoute(.GET, ["__apodini", "grpc", "schema", "files"]) { req -> HTTPResponse in
            let response = HTTPResponse(version: req.version, status: .ok, headers: HTTPHeaders {
                $0[.contentType] = .json(charset: .utf8)
            })
            let listOfFiles = self.server.fileDescriptors.map(\.fileDescriptor.name)
            try response.bodyStorage.write(encoding: listOfFiles, using: JSONEncoder(outputFormatting: [.withoutEscapingSlashes]))
            return response
        }
        
        enum OutputFormat: String, Codable {
            case json, proto
        }
        
        app.httpServer.registerRoute(
            .GET,
            ["__apodini", "grpc", "schema", .namedParameter("format"), "file", .wildcardMultiple("filename")]
        ) { req -> HTTPResponseConvertible in
            guard
                let outputFormat = try req.getParameter("format", as: OutputFormat.self),
                let filename = req.getMultipleWildcardParameter(named: "filename")?.joined(separator: "/")
            else {
                throw HTTPAbortError(status: .badRequest)
            }
            guard let fileDescriptor = self.server.fileDescriptors.first(where: { $0.fileDescriptor.name == filename })?.fileDescriptor else {
                return HTTPAbortError(status: .notFound)
            }
            let response = HTTPResponse(version: req.version, status: .ok, headers: HTTPHeaders())
            switch outputFormat {
            case .json:
                response.headers[.contentType] = .json(charset: .utf8)
                try response.bodyStorage.write(encoding: fileDescriptor, using: JSONEncoder(outputFormatting: [.withoutEscapingSlashes]))
            case .proto:
                response.headers[.contentType] = .text(.plain, charset: .utf8)
                response.bodyStorage.write(ProtoPrinter.print(fileDescriptor))
            }
            return response
        }
    }
}


struct GRPCEndpointDecodingStrategy: EndpointDecodingStrategy {
    typealias Input = GRPCMessageIn
    
    private let endpointContext: GRPCEndpointContext
    
    init(_ endpointContext: GRPCEndpointContext) {
        self.endpointContext = endpointContext
    }
    
    func strategy<Element: Codable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input> {
        GRPCEndpointParameterDecodingStrategy<Element>(
            name: parameter.name,
            endpointContext: endpointContext
        ).typeErased
    }
}


private struct GRPCEndpointParameterDecodingStrategy<T: Codable>: ParameterDecodingStrategy {
    typealias Element = T
    typealias Input = GRPCMessageIn
    
    struct DecodingError: Swift.Error {
        let message: String
    }
    
    let name: String
    let endpointContext: GRPCEndpointContext
    
    func decode(from input: GRPCMessageIn) throws -> T {
        switch endpointContext.endpointRequestType! {
        case .enumTy, .primitive, .refdMessageType:
            throw DecodingError(message: "Unable to decode from non-message proto type \(endpointContext.endpointRequestType!)")
        case let .message(name: _, underlyingType, nestedOneofTypes: _, fields):
            if underlyingType == T.self {
                return try ProtobufferDecoder().decode(T.self, from: input.payload)
            }
            guard let field = fields.first(where: { $0.name == name }) else {
                throw DecodingError(message: "Unable to find field named '\(name)' in proto message type.")
            }
            return try ProtobufferDecoder().decode(T.self, from: input.payload, atField: field)
        }
    }
}


/// Helper type that stores information about an endpoint.
/// The main use case of this is to share the mapping of an endpoint's input and output protobuffer
/// message types with other parts of the interface exporter that need to access this information.
class GRPCEndpointContext: Hashable {
    let communicationalPattern: CommunicationalPattern
    var endpointRequestType: ProtoType?
    var endpointResponseType: ProtoType?
    
    init(communicationalPattern: CommunicationalPattern) {
        self.communicationalPattern = communicationalPattern
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    static func == (lhs: GRPCEndpointContext, rhs: GRPCEndpointContext) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
