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
    let serviceName: String
    let pathPrefix: String
    
    public init(serviceName: String, pathPrefix: String = "__grpc") {
        self.serviceName = serviceName
        self.pathPrefix = pathPrefix
    }
    
    public func configure(_ app: Application) {
        let IE = GRPCv2InterfaceExporter(app: app, config: self)
        app.registerExporter(exporter: IE)
    }
}




class GRPCv2InterfaceExporter: InterfaceExporter {
    private let app: Application
    private let config: GRPCv2 // would love to have a "GRPCConfig" typename or smth like that here, but that'd make the public API ugly and weird... :/
    
    private var logger: Logger { app.logger }
    
    
    init(app: Application, config: GRPCv2) {
        self.app = app
        self.config = config
        app.http.supportVersions.insert(.two)
        app.http.tlsConfiguration?.applicationProtocols.append("h2") // h2, http/1.1, spdy/3
        
        app.httpServer.registerRoute(.GET, "/lk/rocket") { request in
            let response = HTTPResponse(
                version: request.version,
                status: .ok,
                headers: .init {
                    $0[.contentType] = .init(string: "text/plain")!
                },
                bodyStorage: .stream()
            )
            
            let idx = Box<Int>(5)
            func work() {
                print("work")
                switch idx.value {
                case ...0:
                    print("done.")
                    response.bodyStorage.stream!.writeAndClose("LAUNCH!")
                default:
                    print("writing \(idx)")
                    response.bodyStorage.write("\(idx.value)...\n")
                    idx.value -= 1
                    DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1) {
                        work()
                    }
                }
            }
            work()
            print("return first")
            return response
        }
    }
    
    deinit {
        logger.notice("-[\(Self.self) \(#function)]")
    }
    
    
    func export<H>(_ endpoint: Endpoint<H>) -> () where H : Handler {
        let commPattern = endpoint[ServiceType.self]
        let methodName = getMethodName(for: endpoint)
        logger.notice("-[\(Self.self) \(#function)] registering method w/ commPattern: \(commPattern), endpoint: \(endpoint), methodName: \(methodName)")
        
        app.httpServer.registerRoute(
            .POST,
            [.verbatim(config.pathPrefix), .verbatim(config.serviceName), .verbatim(methodName)],
            responder: GRPCv2HTTPResponder(endpoint: endpoint)
        )
    }
    
    
    func export<H>(blob endpoint: Endpoint<H>) -> () where H : Handler, H.Response.Content == Blob {
        //fatalError("\(endpoint)")
        print("-[\(Self.self) \(#function)] TODO!!!!")
    }
    
    
    func exportParameter<Type>(_ parameter: EndpointParameter<Type>) -> () where Type : Decodable, Type : Encodable {
        fatalError("\(parameter)")
    }
    
    
    func finishedExporting(_ webService: WebServiceModel) {
        // TODO do something here????
        logger.notice("gRPC export complete!")
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

