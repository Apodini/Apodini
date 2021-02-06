//
//  WebService.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Foundation
import Logging
import ApodiniDeployBuildSupport
import ApodiniDeployRuntimeSupport


/// Each Apodini program consists of a `WebService`component that is used to describe the Web API of the Web Service
public protocol WebService: Component, ConfigurationCollection, DeploymentConfigProvider {
    /// The current version of the `WebService`
    var version: Version { get }
    
    /// An empty initializer used to create an Apodini `WebService`
    init()
}


extension WebService {
    /// This function is executed to start up an Apodini `WebService`
    public static func main(deploymentProviders: [DeploymentProviderRuntimeSupport.Type] = []) throws {
        try main(waitForCompletion: true, deploymentProviderRuntimes: deploymentProviders)
    }

    
    /// This function is executed to start up an Apodini `WebService`
    @discardableResult
    static func main(
        waitForCompletion: Bool,
        deploymentProviderRuntimes: [DeploymentProviderRuntimeSupport.Type] = []
    ) throws -> Application {
        let app = Application()
        LoggingSystem.bootstrap(StreamLogHandler.standardError)

        main(app: app)
        try lk_handleDeploymentStuff(app: app, deploymentProviderRuntimes: deploymentProviderRuntimes)
        
        //return app;

        guard waitForCompletion else {
            try app.boot()
            return app
        }

        defer {
            app.shutdown()
        }

        try app.run()
        return app
    }
    

    /// This function is provided to start up an Apodini `WebService`. The `app` parameter can be injected for testing purposes only. Use `WebService.main()` to startup an Apodini `WebService`.
    /// - Parameter app: The app instance that should be injected in the Apodini `WebService`
    static func main(app: Application) {
        print("Apodini.args", CommandLine.arguments)
        let webService = Self()

        webService.configuration.configure(app)

        webService.register(
            SemanticModelBuilder(app)
                .with(exporter: RESTInterfaceExporter.self)
                .with(exporter: WebSocketInterfaceExporter.self)
                .with(exporter: OpenAPIInterfaceExporter.self)
                .with(exporter: GRPCInterfaceExporter.self)
                .with(exporter: ProtobufferInterfaceExporter.self)
                .with(exporter: RHIInterfaceExporter.self) // Note that this one should always be last
        )
        
        app.vapor.app.routes.defaultMaxBodySize = "1mb"
    }
    
    
    /// The current version of the `WebService`
    public var version: Version {
        Version()
    }
}


extension WebService {
    func register(_ modelBuilder: SemanticModelBuilder) {
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        self.visit(visitor)
        visitor.finishParsing()
    }
    
    private func visit(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)
        Group {
            content
        }.accept(visitor)
    }
}


public struct ApodiniStartupError: Swift.Error {
    public let message: String
}


private extension WebService {
    static func lk_handleDeploymentStuff(app: Application, deploymentProviderRuntimes: [DeploymentProviderRuntimeSupport.Type]) throws {
        let args = CommandLine.arguments
        guard args.count >= 3 else {
            return
        }
        guard let RHIIE = RHIInterfaceExporter.shared else {
            return
        }

        switch args[1] {
        case WellKnownCLIArguments.exportWebServiceModelStructure:
            let outputUrl = URL(fileURLWithPath: args[2])
            do {
                try RHIIE.exportWebServiceStructure(
                    to: outputUrl,
                    deploymentConfig: Self().deploymentConfig  // TODO ideally we'd get this from the already-initialised object
                )
            } catch {
                fatalError("Error exporting web service structure: \(error)")
            }
            exit(EXIT_SUCCESS)

        case WellKnownCLIArguments.launchWebServiceInstanceWithCustomConfig:
            let configUrl = URL(fileURLWithPath: args[2])
            guard let currentNodeId = ProcessInfo.processInfo.environment[WellKnownEnvironmentVariables.currentNodeId] else {
                throw ApodiniStartupError(message: "Unable to find '\(WellKnownEnvironmentVariables.currentNodeId)' environment variable")
            }
            do {
                let deployedSystem = try DeployedSystemStructure(contentsOf: configUrl)
                guard
                    let DPRSType = deploymentProviderRuntimes.first(where: { $0.deploymentProviderId == deployedSystem.deploymentProviderId })
                else {
                    throw ApodiniStartupError(message: "Unable to find deployment runtime with id '\(deployedSystem.deploymentProviderId.rawValue)'")
                }
                let runtimeSupport = try DPRSType.init(deployedSystem: deployedSystem, currentNodeId: currentNodeId)
                RHIIE.deploymentProviderRuntime = runtimeSupport
                try runtimeSupport.configure(app.vapor.app)
            } catch {
                throw ApodiniStartupError(message: "Unable to launch with custom config: \(error)")
            }

        default:
            break
        }
    }
}



// TODO move all this somewhere else

extension DeploymentGroup {
    /// Creates a single deployment group containing all handlers of type `H`.
    public static func allHandlers<H: Handler>(ofType _: H.Type, groupId: String? = nil) -> DeploymentGroup {
        DeploymentGroup(id: groupId, inputKind: .handlerType, input: ["\(H.self)"])
    }
    
    /// Creates a deployment group containing the handlers with the specifiec identifiers
    public static func handlers(withIds handlerIds: Set<AnyHandlerIdentifier>, groupId: String? = nil) -> DeploymentGroup {
        DeploymentGroup(id: groupId, inputKind: .handlerId, input: Set(handlerIds.map(\.rawValue)))
    }
}


struct DSLSpecifiedDeploymentGroupIdContextKey: OptionalContextKey {
    typealias Value = DeploymentGroup.ID
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        fatalError("Component cannot have multiple explicitly specified deployment groups. Cconflicting groups are '\(value)' and '\(nextValue())'")
    }
}



public struct DeploymentGroupModifier<Content: Component>: Modifier, SyntaxTreeVisitable {
    public let component: Content
    let groupId: DeploymentGroup.ID
    let options: [AnyDeploymentOption]
    
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DSLSpecifiedDeploymentGroupIdContextKey.self, value: groupId, scope: .environment)
        visitor.addContext(HandlerDeploymentOptionsSyntaxNodeContextKey.self, value: options, scope: .environment)
        component.accept(visitor)
    }
}



extension Group {
    public func formDeploymentGroup(withId groupId: DeploymentGroup.ID? = nil, options: [AnyDeploymentOption] = []) -> DeploymentGroupModifier<Self> {
        DeploymentGroupModifier(
            component: self,
            groupId: groupId ?? DeploymentGroup.generateGroupId(),
            options: options
        )
    }
}




public protocol Condition {
    // the type on which the condition is tested
    associatedtype Subject
    func test(on subject: Subject) -> Bool
}


struct ConditionEQ<Subject, Property: Equatable>: Condition {
    let keyPath: KeyPath<Subject, Property>
    let value: Property
    
    func test(on subject: Subject) -> Bool {
        subject[keyPath: keyPath] == value
    }
}


struct BlockCondition<Subject>: Condition {
    let imp: (Subject) -> Bool
    
    func test(on subject: Subject) -> Bool {
        imp(subject)
    }
}



public struct AnyCondition {
    let imp: (Any) -> Bool
    private let handlerTy: ObjectIdentifier
    
    init<H: Handler>(_: H.Type = H.self, _ imp: @escaping (H) -> Bool) {
        //self.imp = imp as! (Any) -> Bool
        self.imp = { imp($0 as! H) }
        self.handlerTy = ObjectIdentifier(H.self)
    }
    
    func test<H: Handler>(on subject: H) -> Bool {
        //(imp as! (H) -> Bool)(subject)
        print("-\(Self.self) \(#function)]", self.handlerTy, ObjectIdentifier(H.self))
        return imp(subject)
    }
}



public func == <H: Handler, P: Equatable> (lhs: KeyPath<H, P>, rhs: P) -> AnyCondition {
    //ConditionEQ(keyPath: lhs, value: rhs)
    //BlockCondition<T> { $0[keyPath: lhs] == rhs }
    AnyCondition(H.self) { $0[keyPath: lhs] == rhs }
}


extension AnyDeploymentOption {
    public static func ugh_memory(_ size: MemorySize, where condition: AnyCondition) -> AnyDeploymentOption {
        return XConditionalDeploymentOption(key: .memorySize, value: size, condition: condition)
    }
}




extension AnyDeploymentOption {
    func resolve<H: Handler>(against handler: H) -> ResolvedDeploymentOption? {
//        // the idea here is that, since the function is dynamically dispatched and XConditionalDeploymentOption overrides it,
//        // we only ever end up here for ResolvedDeploymentOption objects (which always resolve againsy any handler)
//        return self as! ResolvedDeploymentOption
        if let resolvedOption = self as? ResolvedDeploymentOption {
            return resolvedOption
        } else if let conditionalOption = self as? XConditionalDeploymentOption {
            return conditionalOption.resolve_imp(against: handler)
        } else {
            fatalError()
        }
    }
}


public final class XConditionalDeploymentOption: AnyDeploymentOption {
    let condition: AnyCondition
    // we internally store this option's value as a resolved option object,
    // this means we don't have to re-create the whole en/decoding logic in here
    private let underlyingOption: ResolvedDeploymentOption
    
    init<NS: OptionNamespace, Value: DeploymentOption>(
        key: OptionKey<NS, Value>,
        value: Value,
        condition: AnyCondition
    ) {
        self.condition = condition
        self.underlyingOption = ResolvedDeploymentOption(key: key, value: value)
        super.init(key: key)
    }
    
    required init(from decoder: Decoder) throws {
        // TODO explain that these cant be decoded (which isnt much of an issue since they cant be encoded either)
        fatalError("init(from:) has not been implemented")
    }
    
    public override func encode(to encoder: Encoder) throws {
        fatalError("Cannot encode unresolved conditional deployment option")
    }
    
    
    // the _imp is needed to work around a selector ambiguity when calling this function from the AnyDeploymentOption.resolve extension
    fileprivate func resolve_imp<H: Handler>(against handler: H) -> ResolvedDeploymentOption? {
        condition.test(on: handler) ? underlyingOption : nil
    }
}

