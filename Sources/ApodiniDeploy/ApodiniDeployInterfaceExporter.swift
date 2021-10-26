//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import ArgumentParser
import Apodini
import ApodiniExtension
import ApodiniUtils
import ApodiniDeployBuildSupport
import ApodiniDeployRuntimeSupport
import ApodiniNetworking
@_implementationOnly import AssociatedTypeRequirementsVisitor
@_implementationOnly import AsyncHTTPClient


extension AnyEndpointParameter {
    var stableIdentity: String {
        let prefix: String
        switch parameterType {
        case .content:
            prefix = "c"
        case .lightweight:
            prefix = "l"
        case .path:
            prefix = "p"
        }
        return "\(prefix):\(name)"
    }
}


/// An error which occurred while handling something related to the deployment
struct ApodiniDeployError: Swift.Error {
    let message: String
}

public final class ApodiniDeploy: Configuration {
    let configuration: ApodiniDeploy.ExporterConfiguration
    
    public init(runtimes: [DeploymentProviderRuntime.Type] = [], config: DeploymentConfig = .init()) {
        self.configuration = ApodiniDeploy.ExporterConfiguration(runtimes: runtimes, config: config)
    }
    
    public func configure(_ app: Apodini.Application) {
        /// Instanciate exporter
        let deployExporter = ApodiniDeployInterfaceExporter(app, self.configuration)
        /// Insert exporter into `InterfaceExporterStorage`
        app.registerExporter(exporter: deployExporter)
    }
    
    public var command: ParsableCommand.Type {
        ApodiniDeployCommand.withSubcommands(
            ExportStructureCommand.withSubcommands(
                configuration.runtimes.map { $0.exportCommand }
            ),
            StartupCommand.withSubcommands(
                configuration.runtimes.map { $0.startupCommand }
            )
        )
    }
}


extension Apodini.Application.Lifecycle {
    private struct BlockBasedLifecycleHandler: LifecycleHandler {
        let didBootHandler: (Application) throws -> Void
        let shutdownHandler: (Application) throws -> Void
        
        func didBoot(_ application: Application) throws {
            try didBootHandler(application)
        }
        
        func shutdown(_ application: Application) throws {
            try shutdownHandler(application)
        }
    }
    
    /// Add a closure-based
    public mutating func use(
        didBoot didBootHandler: @escaping (Application) throws -> Void,
        shutdown shutdownHandler: @escaping (Application) throws -> Void
    ) {
        use(BlockBasedLifecycleHandler(didBootHandler: didBootHandler, shutdownHandler: shutdownHandler))
    }
}


private struct ApodiniDeployLifecycleHandler: LifecycleHandler {
    func didBoot(_ app: Application) throws {}
    
    func shutdown(_ app: Application) throws {
        app.storage.get(ApodiniDeployInterfaceExporter.StorageKey.self)?.shutdownHTTPClient()
    }
}


/// A custom internal interface exporter, which:
/// a) compiles a list of all handlers (via their `Endpoint` objects). These are used to determine the target endpoint when manually invoking a handler.
/// b) is responsible for handling parameter retrieval when manually invoking handlers.
/// c) exports an additional endpoint used to manually invoke a handler remotely over the network.
class ApodiniDeployInterfaceExporter: LegacyInterfaceExporter {
    struct StorageKey: Apodini.StorageKey {
        typealias Value = ApodiniDeployInterfaceExporter
    }
    
    let app: Apodini.Application
    let exporterConfiguration: ApodiniDeploy.ExporterConfiguration
    let httpClient: AsyncHTTPClient.HTTPClient
    
    private(set) var collectedEndpoints: [CollectedEndpointInfo] = []
    private(set) var explicitlyCreatedDeploymentGroups: [DeploymentGroup.ID: Set<AnyHandlerIdentifier>] = [:]
    private(set) var deploymentProviderRuntime: DeploymentProviderRuntime?
    
    init(_ app: Apodini.Application,
         _ exporterConfiguration: ApodiniDeploy.ExporterConfiguration = ApodiniDeploy.ExporterConfiguration()
    ) {
        self.app = app
        self.exporterConfiguration = exporterConfiguration
        self.httpClient = .init(eventLoopGroupProvider: .shared(app.eventLoopGroup), configuration: .init())
        app.storage.set(StorageKey.self, to: self)
        app.lifecycle.use(ApodiniDeployLifecycleHandler())
    }
    
    
    fileprivate func shutdownHTTPClient() {
        do {
            try self.httpClient.syncShutdown()
        } catch {
            app.logger.error("[\(Self.self)] error shutting down httpClient: \(error)")
        }
    }
    
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        if let groupId = endpoint[Context.self].get(valueFor: DSLSpecifiedDeploymentGroupIdContextKey.self) {
            if explicitlyCreatedDeploymentGroups[groupId] == nil {
                explicitlyCreatedDeploymentGroups[groupId] = []
            }
            explicitlyCreatedDeploymentGroups[groupId]!.insert(endpoint[AnyHandlerIdentifier.self]) // swiftlint:disable:this force_unwrapping
        }
        collectedEndpoints.append(CollectedEndpointInfo(
            handlerType: HandlerTypeIdentifier(H.self),
            endpoint: endpoint,
            deploymentOptions: endpoint[Context.self].get(valueFor: DeploymentOptionsContextKey.self) ?? .init()
        ))
        app.httpServer.registerRoute(
            .POST,
            ["__apodini", "invoke", .verbatim(endpoint[AnyHandlerIdentifier.self].rawValue)],
            responder: InternalInvocationResponder(internalInterfaceExporter: self, endpoint: endpoint)
        )
    }
    
    
    func finishedExporting(_ webService: WebServiceModel) {
        do {
            try performDeploymentRelatedActions()
        } catch {
            fatalError("Error performing deployment-related actions: \(error)")
        }
    }
    
    
    private func performDeploymentRelatedActions() throws {
        try self.exportDeployedSystemIfNeeded()
        
        let currentNodeId: String
        let deployedSystem: AnyDeployedSystem
        
        if let deploymentConfig = app.storage[DeploymentStartUpStorageKey.self] {
            // check if any startup data are available
            currentNodeId = deploymentConfig.nodeId
            let configUrl = URL(fileURLWithPath: deploymentConfig.filePath)
            // swiftlint:disable:next identifier_name
            let DeployedSystemStructureType = deploymentConfig.deployedSystemType
            // swiftlint:disable:next explicit_init
            deployedSystem = try DeployedSystemStructureType.init(decodingJSONAt: configUrl)
        } else {
            // If no startup data are available, web service was started without deployment. Just return, there's nothing to do.
            return
        }
        
        do {
            guard
                let DPRSType = self.exporterConfiguration.runtimes.first(where: { $0.identifier == deployedSystem.deploymentProviderId })
            else {
                throw ApodiniDeployError(
                    message: "Unable to find deployment runtime with id '\(deployedSystem.deploymentProviderId.rawValue)'"
                )
            }
            // initializing from a metatype, which requires the '.init'
            // swiftlint:disable:next explicit_init
            let runtimeSupport = try DPRSType.init(
                deployedSystem: deployedSystem,
                currentNodeId: currentNodeId
            )
            self.deploymentProviderRuntime = runtimeSupport
            try runtimeSupport.configure(app)
        } catch {
            throw ApodiniDeployError(message: "Unable to launch with custom config: \(error)")
        }
    }
    
    
    func getEndpoint<H: IdentifiableHandler>(withIdentifier identifier: H.HandlerIdentifier, ofType _: H.Type) -> Endpoint<H>? {
        collectedEndpoints.first { $0.endpoint[AnyHandlerIdentifier.self] == identifier }?.endpoint as? Endpoint<H>
    }
    
    
    func getCollectedEndpointInfo(forHandlerWithIdentifier identifier: AnyHandlerIdentifier) -> CollectedEndpointInfo? {
        collectedEndpoints.first { $0.endpoint[AnyHandlerIdentifier.self] == identifier }
    }
    
    
    func retrieveParameter<Type: Codable>(_ endpointParameter: EndpointParameter<Type>, for request: ExporterRequest) throws -> Type?? {
        guard let argumentValueContainer = request.collectedArgumentValue(for: endpointParameter) else {
            return Optional<Type?>.none // this should be a "top-level" nil value (ie `.none` instead of `.some(.none)`)
        }
        
        if endpointParameter.nilIsValidValue {
            switch argumentValueContainer {
            case .value(let value):
                if let value: Type? = dynamicCast(value, to: Type?.self) {
                    return .some(value)
                }
            case .encoded(let data):
                return try .some(JSONDecoder().decode(Type?.self, from: data))
            }
        } else {
            switch argumentValueContainer {
            case .value(let value):
                if let value = value as? Type {
                    return .some(.some(value))
                }
            case .encoded(let data):
                return try .some(.some(JSONDecoder().decode(Type.self, from: data)))
            }
        }
        throw ApodiniDeployError(
            message: "Unable to cast argument (container: \(argumentValueContainer)) to expected type '\(Type.self)'"
        )
    }
}


// MARK: ApodiniDeployInterfaceExporter.ExporterRequest

extension ApodiniDeployInterfaceExporter {
    struct ExporterRequest {
        enum Argument {
            case value(Any)    // the value, as-is
            case encoded(Data) // the value, encoded
        }
        
        private let argumentValues: [String: Argument] // key: stable endpoint param identity
        
        init<H: Handler>(endpoint: Endpoint<H>, collectedArguments: [CollectedArgument<H>]) {
            argumentValues = .init(uniqueKeysWithValues: collectedArguments.map { argument -> (String, Argument) in
                guard let paramId = Apodini._Internal.getParameterId(ofBinding: endpoint.handler[keyPath: argument.handlerKeyPath]) else {
                    fatalError("Unable to get @Parameter id from collected parameter with key path \(argument.handlerKeyPath)")
                }
                let endpointParam = endpoint.parameters.first { $0.id == paramId }!
                return (endpointParam.stableIdentity, .value(argument.value))
            })
        }
        
        init(encodedArguments: [(String, Data)]) {
            argumentValues = Dictionary(
                uniqueKeysWithValues: encodedArguments.map { ($0.0, .encoded($0.1)) }
            )
        }
        
        func collectedArgumentValue(for endpointParameter: AnyEndpointParameter) -> Argument? {
            argumentValues[endpointParameter.stableIdentity]
        }
    }
}
