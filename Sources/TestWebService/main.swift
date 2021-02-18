
import Foundation
import NIO
import Apodini
import ApodiniDeployBuildSupport
import DeploymentTargetLocalhostRuntimeSupport
import DeploymentTargetAWSLambdaRuntime
import ApodiniDeploy
import ApodiniREST
import ApodiniOpenAPI




struct RandomNumberGenerator: InvocableHandler, HandlerWithDeploymentOptions {
    class HandlerIdentifier: ScopedHandlerIdentifier<RandomNumberGenerator> {
        static let main = HandlerIdentifier("main")
        static let other = HandlerIdentifier("other")
    }
    let handlerId: HandlerIdentifier
    
    @Parameter var lowerBound: Int = 0
    @Parameter var upperBound: Int = .max
    
    func handle() -> Int {
        print("\(Self.self) invoked at pid \(getpid())")
        guard lowerBound <= upperBound else {
            return 0 // TODO have this throw an error, and test how the RHI API would deal w/ that
        }
        return Int.random(in: lowerBound...upperBound)
    }
    
    static var deploymentOptions: [AnyDeploymentOption] {
        return [
            // NOTE: starting with swift 5.4 (i believe) we'll be able to drop the leading `AnyOption` here and use the implicit member thing w/ chaining
            AnyOption.memory(.mb(150)).when(\Self.handlerId == .main)
        ]
    }
}


struct Greeter: Handler {
    @Apodini.Environment(\.RHI) private var RHI
    
    @Parameter var age: Int
    @Parameter(.http(.path)) var name: String
    
//    init(name: Parameter<String>) {
//        _name = name
//    }
    
    func handle() -> EventLoopFuture<String> {
        print("\(Self.self) invoked at pid \(getpid())")
        return RHI.invoke(
            RandomNumberGenerator.self,
            identifiedBy: .main,
            parameters: [
                .init(\.$lowerBound, age),
                .init(\.$upperBound, age * 2)
            ]
        )
        .map { randomNumber -> String in
            "Hello, \(name). Your random number in range \(age)...\(2 * age) is \(randomNumber)!"
        }
    }
}


struct BlockHandler<T: Apodini.ResponseTransformable>: Handler {
    private let block: () throws -> T
    
    init(_ block: @escaping () throws -> T) {
        self.block = block
    }
    
    func handle() throws -> T {
        try block()
    }
}


struct WebService: Apodini.WebService {
    var content: some Component {
        Group("rand") {
            RandomNumberGenerator(handlerId: .main)
        }.formDeploymentGroup(withId: "rand.2")
        Group("greet") {
            Greeter()
                .deploymentOptions(
                    .memory(.mb(169)),
                    .timeout(.seconds(12))
                )
        }.formDeploymentGroup(withId: "greeter")
//        Text("").operation(.create)
//        Text("").operation(.read)
//        Text("").operation(.delete)
//        Text("").operation(.update)
        BlockHandler { fatalError() }
    }
    
    var configuration: Configuration {
        ExporterConfiguration()
            .exporter(RESTInterfaceExporter.self)
            .exporter(OpenAPIInterfaceExporter.self)
            .exporter(ApodiniDeployInterfaceExporter.self)
        ApodiniDeployConfiguration(
            runtimes: [LocalhostRuntimeSupport.self, LambdaRuntime.self],
            config: DeploymentConfig(deploymentGroups: DeploymentGroupsConfig(defaultGrouping: .singleNode, groups: []))
        )
    }
}


try WebService.main()

