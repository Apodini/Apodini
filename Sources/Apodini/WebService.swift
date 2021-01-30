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
    static func main(waitForCompletion: Bool, deploymentProviderRuntimes: [DeploymentProviderRuntimeSupport.Type]) throws -> Application {
        let app = Application()
        LoggingSystem.bootstrap(StreamLogHandler.standardError)

        main(app: app)
        try lk_handleDeploymentStuff(app: app, deploymentProviderRuntimes: deploymentProviderRuntimes)

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
        let webService = Self()

        webService.configuration.configure(app)

        webService.register(
            SharedSemanticModelBuilder(app)
                .with(exporter: RESTInterfaceExporter.self)
                .with(exporter: WebSocketInterfaceExporter.self)
                .with(exporter: OpenAPIInterfaceExporter.self)
                .with(exporter: GRPCInterfaceExporter.self)
                .with(exporter: ProtobufferInterfaceExporter.self),
            GraphQLSemanticModelBuilder(app)
        )
        
        // Adds the created application instance to `EnvironmentValues`.
        // Can be used `@Environment` to access properties.
        EnvironmentValues.shared.values[ObjectIdentifier(Application.Type.self)] = app

        app.vapor.app.routes.defaultMaxBodySize = "1mb"
    }
    
    
    /// The current version of the `WebService`
    public var version: Version {
        Version()
    }
}


extension WebService {
    func register(_ semanticModelBuilders: SemanticModelBuilder...) {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: semanticModelBuilders)
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
            do {
                let deployedSystemConfiguration = try DeployedSystemConfiguration(contentsOf: configUrl)
                RHIIE.deployedSystemStructure = deployedSystemConfiguration
                guard
                    let DPRSType = deploymentProviderRuntimes.first(where: { $0.deploymentProviderId == deployedSystemConfiguration.deploymentProviderId })
                else {
                    throw ApodiniStartupError(message: "Unable to find deployment runtime with id '\(deployedSystemConfiguration.deploymentProviderId.rawValue)'")
                }
                let runtimeSupport = try DPRSType.init(deployedSystemStructure: deployedSystemConfiguration)
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
