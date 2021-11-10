import Apodini
import ApodiniExtension
import ApodiniNetworking
import ApodiniUtils
import Logging
import Dispatch



struct GRPCv2Error: Swift.Error {
    let message: String
}


public class GRPCv2: Configuration {
    let packageName: String
    let serviceName: String
    let pathPrefix: String
    
    public init(packageName: String, serviceName: String, pathPrefix: String = "__grpc") {
        self.packageName = packageName
        self.serviceName = serviceName
        self.pathPrefix = pathPrefix
    }
    
    public func configure(_ app: Application) {
        let IE = GRPCv2InterfaceExporter(app: app, config: self)
        app.registerExporter(exporter: IE)
    }
}




class GRPCv2InterfaceExporter: InterfaceExporter {
    static let serverReflectionPackageName = "grpc.reflection.v1alpha"
    //static let serverReflectionServiceName = "\(serverReflectionPackageName).ServerReflection"
    static let serverReflectionServiceName = "ServerReflection"
    static let serverReflectionMethodName = "ServerReflectionInfo"
    
    
    // TODO this doesn't belong here.
    static let EmptyTypeFullyQualifiedTypeName = ".google.protobuf.Empty"
    
    private let app: Application
    private let config: GRPCv2 // would love to have a "GRPCConfig" typename or smth like that here, but that'd make the public API ugly and weird... :/
    
    // The proto/gRPC package into which all of the web service's stuff goes,
    //private var defaultPackageName: String { config.serviceName + "NS" }
    private let defaultPackageName: String
    
    private let server: GRPCv2Server
    
    private var logger: Logger { app.logger }
    
    
    init(app: Application, config: GRPCv2) {
        self.app = app
        self.config = config
        let defaultPackageName = config.packageName //config.serviceName// + "NS"
        self.defaultPackageName = defaultPackageName
        self.server = .init(defaultPackageName: defaultPackageName)
        // Configure HTTP/2
        app.http.supportVersions.insert(.two)
        app.http.tlsConfiguration?.applicationProtocols.append("h2") // h2, http/1.1, spdy/3
        
        // Create the default service (we only support one atm, but this implementation could also support multiple services
        server.createService(name: config.serviceName, associatedWithPackage: defaultPackageName)
        server.createService(name: Self.serverReflectionServiceName, associatedWithPackage: Self.serverReflectionPackageName)
        
        for ty in TODO_REMOVE_getReflectionAPIRelatedProtoTypess() {
            server.schema.informAboutMessageType(ty as! LKProtobufferMessage.Type)
        }
        server.schema.informAboutMessageType(FileDescriptorSet.self) // we're just gonna hope that this will be enough to pull in the entire Descriptors file...
//        fatalError()
        
//        app.httpServer.registerRoute(.GET, "/lk/rocket") { request in
//            let response = HTTPResponse(
//                version: request.version,
//                status: .ok,
//                headers: .init {
//                    $0[.contentType] = .init(string: "text/plain")!
//                },
//                bodyStorage: .stream()
//            )
//
//            let idx = Box<Int>(5)
//            func work() {
//                print("work")
//                switch idx.value {
//                case ...0:
//                    print("done.")
//                    response.bodyStorage.stream!.writeAndClose("LAUNCH!")
//                default:
//                    print("writing \(idx)")
//                    response.bodyStorage.write("\(idx.value)...\n")
//                    idx.value -= 1
//                    DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1) {
//                        work()
//                    }
//                }
//            }
//            work()
//            print("return first")
//            return response
//        }
    }
    
    deinit {
        logger.notice("-[\(Self.self) \(#function)]")
    }
    
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) -> () {
        let commPattern = endpoint[CommunicationalPattern.self]
        let methodName = getMethodName(for: endpoint)
        logger.notice("-[\(Self.self) \(#function)] registering method w/ commPattern: \(commPattern), endpoint: \(endpoint), methodName: \(methodName)")
        
        let serviceName = endpoint[Context.self].get(valueFor: GRPCv2ServiceNameContextKey.self) ?? config.serviceName
        if server.service(named: serviceName, inPackage: defaultPackageName) == nil {
            server.createService(name: serviceName, associatedWithPackage: defaultPackageName)
        }
        
        let endpointContext = GRPCv2EndpointContext()
        
        server.addMethod(
            toServiceNamed: serviceName,
            inPackage: defaultPackageName,
            GRPCMethod(
                name: methodName,
                endpoint: endpoint,
                endpointContext: endpointContext,
                decodingStrategy: GRPCv2EndpointDecodingStrategy(endpointContext).applied(to: endpoint).typeErased,
                schema: server.schema
            )
        )
        
        //let decodingStrategy = InterfaceExporterLegacyStrategy(self).applied(to: endpoint).typeErased
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
                type: .bidirectional,
                inputFQTN: ".\(Self.serverReflectionPackageName).ServerReflectionRequest",
                outputFQTN: ".\(Self.serverReflectionPackageName).ServerReflectionResponse",
                streamRPCHandlerMaker: { [unowned self] in makeServerReflectionStreamRPCHandler() }
            )
        )
        
        let greeterIn = server.schema.informAboutMessageType(GreeterRequest.self)
        let greeterOut = server.schema.informAboutMessageType(GreeterResponse.self)
        
        server.addMethod(toServiceNamed: config.serviceName, inPackage: defaultPackageName, GRPCMethod(
            name: "SayHello",
            type: .unary,
            inputFQTN: "GreeterRequest",//greeterIn.fullyQualifiedTypename,
            outputFQTN: "GreeterResponse",//greeterOut.fullyQualifiedTypename,
            streamRPCHandlerMaker: { HardcodedGreeter() }
        ))
        
        // Makes the types managed by the schema ready for use by the reflection API
        server.schema.finalize()
        server.createFileDescriptors()
        
        app.httpServer.addIncomingHTTP2StreamConfigurationHandler(forContentTypes: [.gRPC, .gRPC(.proto), .gRPC(.json)]) { channel in
            channel.pipeline.addHandlers([
                GRPCv2RequestDecoder(),
                GRPCv2ResponseEncoder(),
                GRPCv2MessageHandler(server: self.server)
            ])
        }
    }
    
    
    
    // MARK: Internal Stuff
    
    private func getMethodName<H>(for endpoint: Endpoint<H>) -> String {
        if let methodName = endpoint[Context.self].get(valueFor: GRPCv2MethodNameContextKey.self) {
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



extension GRPCv2InterfaceExporter {
    private func makeServerReflectionStreamRPCHandler() -> GRPCv2StreamRPCHandler {
        ServerReflectionInfoRPCHandler(server: self.server)
    }
}




struct GRPCv2EndpointDecodingStrategy: EndpointDecodingStrategy {
    typealias Input = GRPCv2MessageIn
    
    private let endpointContext: GRPCv2EndpointContext
    
    init(_ endpointContext: GRPCv2EndpointContext) {
        self.endpointContext = endpointContext
    }
    
    func strategy<Element: Codable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input> {
        //fatalError()
        return GRPCv2EndpointParameterDecodingStrategy<Element>(
            name: parameter.name,
            endpointContext: endpointContext
        ).typeErased // TODO pass the whole parameter?
    }
}


private struct GRPCv2EndpointParameterDecodingStrategy<T: Codable>: ParameterDecodingStrategy {
    typealias Element = T
    typealias Input = GRPCv2MessageIn
    
    let name: String
    let endpointContext: GRPCv2EndpointContext
    
    // TODO how would this deal w/ @Params that are arrays? we couldn't use .getLast for that. Do array params get properly wrapped? (ie in cases where that's the only param. but also in other cases.)
    func decode(from input: GRPCv2MessageIn) throws -> T {
        switch endpointContext.endpointRequestType! {
        case .builtinEmptyType, .enumTy, .primitive, .refdMessageType:
            fatalError()
        case let .compositeMessage(name: _, underlyingType: _, nestedOneofTypes: _, fields):
            guard let fieldNumber = fields.first(where: { $0.name == name })?.fieldNumber else {
                fatalError() // TODO throw
            }
            let decoder = _LKProtobufferDecoder(codingPath: [], buffer: input.payload)
            let keyedDecoder = try decoder.container(keyedBy: FakeCodingKey.self) // TODO maybe cache this instead of re-running the thing for every param request?! (the issue is that the keyedDecoder will read the message's proto format)
            return try keyedDecoder.decode(T.self, forKey: .init(intValue: fieldNumber))
            //fatalError("-[\(Self.self) \(#function)] name: \(name), input: \(input)")
        }
//        guard let fieldNumber = endpointContext.fieldNumber(forParamName: name) else {
//            fatalError() // TODO throw
//        }
//        let decoder = _LKProtobufferDecoder(codingPath: [], buffer: input.payload)
//        let keyedDecoder = try decoder.container(keyedBy: FakeCodingKey.self) // TODO maybe cache this instead of re-running the thing for every param request?! (the issue is that the keyedDecoder will read the message's proto format)
//        return try keyedDecoder.decode(T.self, forKey: .init(intValue: fieldNumber))
//        //fatalError("-[\(Self.self) \(#function)] name: \(name), input: \(input)")
    }
}



/// Helper type that stores information about an endpoint.
/// The main use case of this is to share the mapping of an endpoint's input and output protobuffer
/// message types with other parts of the interface exporter that need to access this information.
class GRPCv2EndpointContext: Hashable {
    let communicationalPattern: CommunicationalPattern
    var endpointRequestType: ProtoTypeDerivedFromSwift?
    var endpointResponseType: ProtoTypeDerivedFromSwift?
    
    init(communicationalPattern: CommunicationalPattern) {
        self.communicationalPattern = communicationalPattern
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    static func == (lhs: GRPCv2EndpointContext, rhs: GRPCv2EndpointContext) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}





struct GreeterRequest: Codable, LKProtobufferMessage {
    let name: String
//    enum CodingKeys: Int, CodingKey {
//        case name = 1
//    }
}


struct GreeterResponse: Codable, LKProtobufferMessage {
    let message: String
//    enum CodingKeys: Int, CodingKey {
//        case message = 1
//    }
}


class HardcodedGreeter: GRPCv2StreamRPCHandler {
    func handleStreamOpen(context: GRPCv2StreamConnectionContext) {
        print(Self.self, #function)
    }
    
    func handleStreamClose(context: GRPCv2StreamConnectionContext) {
        print(Self.self, #function)
    }
    
    func handle(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
        print(Self.self, #function, message.serviceAndMethodName)
        do {
            let request = try LKProtobufferDecoder().decode(GreeterRequest.self, from: message.payload)
            print(request)
            let response = GreeterResponse(message: "Hello, \(request.name)!!!!")
            let messageOut = GRPCv2MessageOut.singleMessage(
                headers: HPACKHeaders {
                    $0[.contentType] = .gRPC(.proto)
                },
                payload: try LKProtobufferEncoder().encode(response),
                closeStream: true
            )
            return context.eventLoop.makeSucceededFuture(messageOut)
        } catch {
            fatalError()
        }
    }
}











// MARK: TMP



struct LKTestPerson: Codable, LKProtobufferMessage, Equatable, LKProtobufferCodableWithCustomFieldMapping {
    enum Gender: Int32, LKProtobufferEnum {
        case male = 0
        case female = 1
    }
    
    let name: String
    let age: Int
    let gender: Gender
    let parents: [String]
    
    enum CodingKeys: Int, LKProtobufferMessageCodingKeys {
        case name = 12
        case age = 14
        case gender = 512
        case parents = 14006
    }
}


func testProtoCoding<T: LKProtobufferMessage & Codable & Equatable>(_ input: T) {
    let encoded = try! LKProtobufferEncoder().encode(input)
    print(T.self)
    try! ProtobufMessageLayoutDecoder.getFields(in: encoded).debugPrintFieldsInfo()
    let decoded = try! LKProtobufferDecoder().decode(T.self, from: encoded)
    precondition(decoded == input)
}



func doTheThing(server: GRPCv2Server) {
    return;
    let schema = GRPCv2SchemaManager(defaultPackageName: "fuck")
    schema.informAboutMessageType(FileDescriptorSet.self)
    schema.finalize()
    
    
    do {
        var buffer = ByteBuffer()
        buffer.writeProtoVarInt(Int(300))
        buffer.moveReaderIndex(to: 0)
        precondition(try! Int(buffer.getVarInt(at: 0)) == 300)
    }
    
    testProtoCoding(LKTestPerson(name: "Lukas", age: 23, gender: .male, parents: ["Sandra", "Stefan"]))
    
    
    let field = FieldDescriptorProto(
        name: "abc",
        number: 1,
        label: nil,
        type: .TYPE_STRING,
        typename: nil,
        extendee: nil,
        defaultValue: nil,
        oneofIndex: nil,
        jsonName: nil,
        options: nil,
        proto3Optional: false
    )
    testProtoCoding(field)
    
    let typeDesc = DescriptorProto(
        name: "TestMessage",
        fields: [field],
        extensions: [],
        nestedTypes: [],
        enumTypes: [],
        extensionRanges: [],
        oneofDecls: [],
        options: nil,
        reservedRanges: [],
        reservedNames: []
    )
    testProtoCoding(typeDesc)
    
//    fatalError()
}
