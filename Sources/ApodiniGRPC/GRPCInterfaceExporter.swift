import Apodini
import ApodiniExtension
import ApodiniNetworking
import ApodiniUtils
import Logging
import Dispatch
import ProtobufferCoding
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


struct GRPCError: Swift.Error {
    let message: String
}


public class GRPC: Configuration {
    let packageName: String
    let serviceName: String
    let pathPrefix: String
    
    public init(packageName: String, serviceName: String, pathPrefix: String = "__grpc") {
        self.packageName = packageName
        self.serviceName = serviceName
        self.pathPrefix = pathPrefix
    }
    
    public func configure(_ app: Application) {
        let IE = GRPCInterfaceExporter(app: app, config: self)
        app.registerExporter(exporter: IE)
    }
}




class GRPCInterfaceExporter: InterfaceExporter {
    static let serverReflectionPackageName = "grpc.reflection.v1alpha"
    //static let serverReflectionServiceName = "\(serverReflectionPackageName).ServerReflection"
    static let serverReflectionServiceName = "ServerReflection"
    static let serverReflectionMethodName = "ServerReflectionInfo"
    
    private let app: Application
    private let config: GRPC // would love to have a "GRPCConfig" typename or smth like that here, but that'd make the public API ugly and weird... :/
    
    // The proto/gRPC package into which all of the web service's stuff goes,
    //private var defaultPackageName: String { config.serviceName + "NS" }
    private let defaultPackageName: String
    
    private let server: GRPCServer
    
    private var logger: Logger { app.logger }
    
    
    init(app: Application, config: GRPC) {
        self.app = app
        self.config = config
        let defaultPackageName = config.packageName //config.serviceName// + "NS"
        self.defaultPackageName = defaultPackageName
        self.server = .init(defaultPackageName: defaultPackageName)
        // Configure HTTP/2
        guard app.httpConfiguration.supportVersions.contains(.two),
              let tlsConfig = app.httpConfiguration.tlsConfiguration,
              tlsConfig.applicationProtocols.contains("h2")
        else {
            fatalError("Invalid HTTP configuration: the gRPC interface exporter requires both HTTP/2 and TLS be enabled.")
        }
//        app.httpConfiguration.supportVersions.insert(.two)
//        app.httpConfiguration.tlsConfiguration!.applicationProtocols.append("h2") // h2, http/1.1, spdy/3
//        app.http.supportVersions.insert(.two)
//        app.http.tlsConfiguration!.applicationProtocols.append("h2") // h2, http/1.1, spdy/3
        
        // Create the default service (we only support one atm, but this implementation could also support multiple services
        server.createService(name: config.serviceName, associatedWithPackage: defaultPackageName)
        server.createService(name: Self.serverReflectionServiceName, associatedWithPackage: Self.serverReflectionPackageName)
        
        do {
            try ServerReflectionInfoRPCHandler.registerReflectionServiceTypesWithSchema(server.schema)
            try server.schema.informAboutMessageType(FileDescriptorSet.self) // this is enough to pull in the entire descriptors file
        } catch {
            if case ProtoValidationError.proto3EnumMissingCaseWithZeroValue(let enumTy) = error {
                print(enumTy, enumTy is Proto2Codable.Type, enumTy as? Proto2Codable.Type)
            }
            fatalError("Error registering proto types with schema: \(error)")
        }
    }
    
    deinit {
        logger.notice("-[\(Self.self) \(#function)]")
    }
    
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) -> () {
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
    }
    
    
    func export<H: Handler>(blob endpoint: Endpoint<H>) -> () where H.Response.Content == Blob {
        //fatalError("\(endpoint)")
        print("-[\(Self.self) \(#function)] TODO!!!!")
    }
    
    
    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) -> () {
        fatalError("\(parameter)")
    }
    
    
    func finishedExporting(_ webService: WebServiceModel) {
        // TODO do something here????
        logger.notice("gRPC export complete!")
        
//        // TODO long-term we'd want this to simply be implemented via a handler as well, as opposed to a hard-coded route...
//        app.httpServer.registerRoute(.POST, ["grpc.reflection.v1alpha.ServerReflection", "ServerReflectionInfo"]) { request in
//            precondition(request.version == .http2)
//            print(request.headers)
//            print(request.bodyStorage.getFullBodyData() as Any)
//            return HTTPResponse(
//                version: .http2,
//                status: .ok,
//                headers: HTTPHeaders {
//                    $0[.contentType] = .gRPC(.proto)
//                },
//                bodyStorage: .buffer(initialValue: []) // TODO
//            )
//        }
        
        server.addMethod(
            toServiceNamed: Self.serverReflectionServiceName,
            inPackage: Self.serverReflectionPackageName,
            GRPCMethod(
                name: Self.serverReflectionMethodName,
                type: .bidirectionalStream,
                inputFQTN: ".\(Self.serverReflectionPackageName).ServerReflectionRequest",
                outputFQTN: ".\(Self.serverReflectionPackageName).ServerReflectionResponse",
                streamRPCHandlerMaker: { [unowned self] in
                    ServerReflectionInfoRPCHandler(server: self.server)
                }
            )
        )
        
//        let greeterIn = server.schema.informAboutMessageType(GreeterRequest.self)
//        let greeterOut = server.schema.informAboutMessageType(GreeterResponse.self)
//
//        server.addMethod(toServiceNamed: config.serviceName, inPackage: defaultPackageName, GRPCMethod(
//            name: "SayHello",
//            type: .requestResponse,
//            inputFQTN: "GreeterRequest",//greeterIn.fullyQualifiedTypename,
//            outputFQTN: "GreeterResponse",//greeterOut.fullyQualifiedTypename,
//            streamRPCHandlerMaker: { HardcodedGreeter() }
//        ))
        
        // Makes the types managed by the schema ready for use by the reflection API
        server.schema.finalize()
        server.createFileDescriptors()
        
        /// Make a JSON version of the whole gRPC schema available as a regular HTTP GET endpoint.
        /// - NOTE this might not necessarily be the most dessirable thing, since it might expose internal data. But then again the OpenAPI interface exporter works the exact same way...
        app.httpServer.registerRoute(.GET, ["__apodini", "grpc_schema"]) { req -> HTTPResponse in
            let response = HTTPResponse(version: req.version, status: .ok, headers: HTTPHeaders {
                $0[.contentType] = .json(charset: .utf8)
            })
            let allFileDescriptors = FileDescriptorSet(files: self.server.fileDescriptors.map(\.fileDescriptor))
            try response.bodyStorage.write(encoding: allFileDescriptors, using: JSONEncoder())
            return response
        }
        
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
                    // TODO how should this be handled?
                    // Maybe pull an objc and turn this into a "withX" schema?
                    fatalError("TODO?")
                }
            }
            // TODO if the path-derived method name is the "root" thing (eg: "V1"), somehow give it special handling!!!
            return methodName
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
        //fatalError()
        return GRPCEndpointParameterDecodingStrategy<Element>(
            name: parameter.name,
            endpointContext: endpointContext
        ).typeErased // TODO pass the whole parameter?
    }
}



private struct GRPCEndpointParameterDecodingStrategy<T: Codable>: ParameterDecodingStrategy {
    typealias Element = T
    typealias Input = GRPCMessageIn
    
    let name: String
    let endpointContext: GRPCEndpointContext
    
    // TODO how would this deal w/ @Params that are arrays? we couldn't use .getLast for that. Do array params get properly wrapped? (ie in cases where that's the only param. but also in other cases.)
    func decode(from input: GRPCMessageIn) throws -> T {
        switch endpointContext.endpointRequestType! {
        case .builtinEmptyType, .enumTy, .primitive, .refdMessageType:
            fatalError()
        case let .compositeMessage(name: _, underlyingType: _, nestedOneofTypes: _, fields):
            guard let field = fields.first(where: { $0.name == name }) else {
                fatalError() // TODO throw
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
    var endpointRequestType: ProtoTypeDerivedFromSwift?
    var endpointResponseType: ProtoTypeDerivedFromSwift?
    
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





struct GreeterRequest: Codable, ProtobufMessage {
    let name: String
//    enum CodingKeys: Int, CodingKey {
//        case name = 1
//    }
}


struct GreeterResponse: Codable, ProtobufMessage {
    let message: String
//    enum CodingKeys: Int, CodingKey {
//        case message = 1
//    }
}


class HardcodedGreeter: GRPCStreamRPCHandler {
    func handleStreamOpen(context: GRPCStreamConnectionContext) {
        print(Self.self, #function)
    }
    
    func handleStreamClose(context: GRPCStreamConnectionContext) {
        print(Self.self, #function)
    }
    
    func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
        print(Self.self, #function, message.serviceAndMethodName)
        do {
            let request = try ProtobufferDecoder().decode(GreeterRequest.self, from: message.payload)
            print(request)
            let response = GreeterResponse(message: "Hello, \(request.name)!!!!")
            let messageOut = GRPCMessageOut.singleMessage(
                headers: HPACKHeaders {
                    $0[.contentType] = .gRPC(.proto)
                },
                payload: try ProtobufferEncoder().encode(response),
                closeStream: true
            )
            return context.eventLoop.makeSucceededFuture(messageOut)
        } catch {
            fatalError()
        }
    }
}
