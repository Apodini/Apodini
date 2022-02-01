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
import ApodiniMigrationCommon
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

        app.apodiniMigration.register(
            configuration: GRPCExporterConfiguration(
                packageName: packageName,
                serviceName: serviceName,
                pathPrefix: pathPrefix,
                reflectionEnabled: enableReflection
            ),
            for: .grpc
        )
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
              tlsConfig.applicationProtocols.contains("h2") else {
            fatalError(
                """
                Invalid HTTP configuration: the gRPC interface exporter requires both HTTP/2 and TLS be enabled. \
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
        let methodName = endpoint.getEndointName(.verb, format: .pascalCase)
        let apodiniIdentifier = endpoint[AnyHandlerIdentifier.self]
        let handlerName = endpoint[HandlerDescription.self]

        logger.notice("-[\(Self.self) \(#function)] registering method w/ commPattern: \(commPattern), endpoint: \(endpoint), methodName: \(methodName)")
        
        let serviceName = endpoint[Context.self].get(valueFor: GRPCServiceNameContextKey.self) ?? config.serviceName
        if server.service(named: serviceName, inPackage: defaultPackageName) == nil {
            server.createService(name: serviceName, associatedWithPackage: defaultPackageName)
        }
        
        let endpointContext = GRPCEndpointContext(communicationalPattern: endpoint[CommunicationalPattern.self])

        // Apodini Migration support
        app.apodiniMigration.register(identifier: GRPCServiceName(serviceName), for: endpoint)
        app.apodiniMigration.register(identifier: GRPCMethodName(methodName), for: endpoint)
        
        server.addMethod(
            toServiceNamed: serviceName,
            inPackage: defaultPackageName,
            GRPCMethod(
                name: methodName,
                endpoint: endpoint,
                endpointContext: endpointContext,
                decodingStrategy: GRPCEndpointDecodingStrategy(endpointContext).applied(to: endpoint).typeErased,
                schema: server.schema,
                sourceCodeComments: [
                    "APODINI-identifier: \(apodiniIdentifier.rawValue)",
                    "APODINI-handlerName: \(handlerName)"
                ]
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

        handleMigratorSchemaTypes()
        
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

    // TODO naming + moving!
    private func handleMigratorSchemaTypes() {
        for (unit, package) in server.schema.finalizedPackages {
            let packageName = "[\(unit.packageName)]"

            for enumType in package.enumTypes {
                handle(enum: enumType, parentName: packageName)
            }
        }
    }

    private func handle(enum: EnumDescriptorProto, parentName: String) {
        guard let swiftTypeName = `enum`.swiftTypeName(with: server.schema, parentName: parentName) else {
            print("Custom type \(`enum`)") // TODO handle in configuration storage
            return
        }

        let fullName = "\(parentName).\(`enum`.name)"

        let swiftType = SwiftTypeIdentifier(rawValue: swiftTypeName)
        app.apodiniMigration.register(identifier: GRPCName(fullName), for: swiftType)

        for enumValue in `enum`.values {
            app.apodiniMigration.register(identifier: GRPCNumber(number: enumValue.number), for: swiftType, children: enumValue.name)
        }
    }

    private func handle(message: DescriptorProto, parentName: String) {
        guard let swiftTypeName = message.swiftTypeName(with: server.schema, parentName: parentName) else {
            print("Custom type \(message)") // TODO handle in configuration storage
            return
        }

        let fullName = "\(parentName).\(message.name)"

        let swiftType = SwiftTypeIdentifier(rawValue: swiftTypeName)
        app.apodiniMigration.register(identifier: GRPCName(fullName), for: swiftType)

        for field in message.fields {
            guard let fieldType = field.type else {
                preconditionFailure("Expectation that field type is always set by the ProtoScheme broke! Raised for \(field)!")
            }

            app.apodiniMigration.register(identifier: GRPCNumber(number: field.number), for: swiftType, children: field.name)
            app.apodiniMigration.register(identifier: GRPCFieldType(type: fieldType.rawValue), for: swiftType, children: field.name)
        }


        // now handle any nested types recursively
        for nestedEnum in message.enumTypes {
            handle(enum: nestedEnum, parentName: fullName)
        }

        for nestedMessage in message.nestedTypes {
            handle(message: nestedMessage, parentName: fullName)
        }
    }
    
    
    // MARK: Internal Stuff

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
