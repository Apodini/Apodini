import Apodini
import ApodiniDeploy
import ApodiniREST
import ApodiniOpenAPI
import DeploymentTargetLocalhostRuntime


struct WebServiceError: Swift.Error {
    let message: String
}

struct ResponseWithPid<T: Codable>: Content, Codable {
    let pid: pid_t
    let value: T

    init(_ value: T) {
        self.pid = getpid()
        self.value = value
    }
}


struct TextMut: InvocableHandler {
    class HandlerIdentifier: ScopedHandlerIdentifier<TextMut> {
        static let main = HandlerIdentifier("main")
    }
    let handlerId: HandlerIdentifier
    
    @Parameter var text: String
    
    func handle() -> ResponseWithPid<String> {
        return ResponseWithPid(text.lowercased())
    }
}


struct GreeterResponse: Codable {
    let text: String
    let textMutPid: pid_t
}

struct Greeter: Handler {
    @Apodini.Environment(\.RHI) private var RHI
    
    @Parameter(.http(.path)) var name: String
    
    
    func handle() -> EventLoopFuture<ResponseWithPid<GreeterResponse>> {
        return RHI.invoke(
            TextMut.self,
            identifiedBy: .main,
            arguments: [.init(\.$text, name)]
        )
        .map { response -> ResponseWithPid<GreeterResponse> in
            //ResponseWithPid("Hello, \(name)!")
            ResponseWithPid(GreeterResponse(
                text: "Hello, \(response.value)!",
                textMutPid: response.pid
            ))
        }
    }
}



struct WebService: Apodini.WebService {
    var content: some Component {
        Group("textmut") {
            TextMut(handlerId: .main)
        }
        Group("greet") {
            Greeter()
        }
        Text("change is")
        Text("the only constant").operation(.delete)
    }
    
    var configuration: Configuration {
        ExporterConfiguration()
            .exporter(RESTInterfaceExporter.self)
            .exporter(OpenAPIInterfaceExporter.self)
            .exporter(ApodiniDeployInterfaceExporter.self)
        ApodiniDeployConfiguration(
            runtimes: [LocalhostRuntime.self],
            config: DeploymentConfig(defaultGrouping: .separateNodes, deploymentGroups: [
                .allHandlers(ofType: Text.self)
            ])
        )
    }
}


try WebService.main()

