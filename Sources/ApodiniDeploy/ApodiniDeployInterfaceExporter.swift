//
//  ApodiniDeployInterfaceExporter.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-14.
//

import Foundation
import Apodini
import ApodiniUtils
import ApodiniVaporSupport
import ApodiniDeployBuildSupport
import ApodiniDeployRuntimeSupport
@_implementationOnly import Vapor
@_implementationOnly import AssociatedTypeRequirementsVisitor


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
        case .header:
            prefix = "h"
        }
        return "\(prefix):\(name)"
    }
}


/// An error which occurred while handling something related to the deployment
struct ApodiniDeployError: Swift.Error {
    let message: String
}

public final class _ApodiniDeployInterfaceExporter: Configuration {
    let configuration: ApodiniDeployExporterConfiguration
    let staticConfigurations: [StaticConfiguration]
    
    public init(runtimes: [DeploymentProviderRuntime.Type] = [],
                config: DeploymentConfig = .init(),
                @StaticConfigurationBuilder staticConfigurations: () -> [StaticConfiguration] = {[]}) {
        self.configuration = ApodiniDeployExporterConfiguration(runtimes: runtimes, config: config)
        self.staticConfigurations = staticConfigurations()
    }
    
    public func configure(_ app: Apodini.Application) {
        guard var semanticModel = app.storage.get(SemanticModelBuilderKey.self) else {
            fatalError("Semantic Model in Storage is not set!")
        }
        
        /// Insert current exporter into `SemanticModelBuilder`
        let deployExporter = ApodiniDeployInterfaceExporter(app, self.configuration)
        semanticModel = semanticModel.with(exporter: deployExporter)
        
        /// Configure attached related static configurations
        self.staticConfigurations.configure(app, parentConfiguration: configuration)
        
        /// Doesn't have to be set again since it's by-reference
        //app.storage.set(SemanticModelBuilderKey.self, to: semanticModel)
    }
}


/// A custom internal interface exporter, which:
/// a) compiles a list of all handlers (via their `Endpoint` objects). These are used to determine the target endpoint when manually invoking a handler.
/// b) is responsible for handling parameter retrieval when manually invoking handlers.
/// c) exports an additional endpoint used to manually invoke a handler remotely over the network.
public class ApodiniDeployInterfaceExporter: InterfaceExporter {
    struct ApplicationStorageKey: Apodini.StorageKey {
        typealias Value = ApodiniDeployInterfaceExporter
    }
    
    /// The information collected about an `Endpoint`.
    /// - Note: This type's `Hashable`  implementation ignores deployment options.
    /// - Note: This type's `Equatable` implementation ignores all context of the endpoint other than its identifier,
    ///         and will only work if all deployment options of both objects being compared are reducible.
    struct CollectedEndpointInfo: Hashable, Equatable {
        let handlerType: HandlerTypeIdentifier
        let endpoint: AnyEndpoint
        let deploymentOptions: DeploymentOptions
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(endpoint[AnyHandlerIdentifier.self])
        }
        
        static func == (lhs: CollectedEndpointInfo, rhs: CollectedEndpointInfo) -> Bool {
            lhs.handlerType == rhs.handlerType
                && lhs.endpoint[AnyHandlerIdentifier.self] == rhs.endpoint[AnyHandlerIdentifier.self]
                && lhs.deploymentOptions.reduced().options.compareIgnoringOrder(
                    rhs.deploymentOptions.reduced().options,
                    computeHash: { option, hasher in hasher.combine(option) },
                    areEqual: { lhs, rhs in lhs.testEqual(rhs) }
                )
        }
    }
    
    
    let app: Apodini.Application
    let exporterConfiguration: ApodiniDeployExporterConfiguration
    var vaporApp: Vapor.Application { app.vapor.app }
    
    private(set) var collectedEndpoints: [CollectedEndpointInfo] = []
    private(set) var explicitlyCreatedDeploymentGroups: [DeploymentGroup.ID: Set<AnyHandlerIdentifier>] = [:]
    
    private(set) var deploymentProviderRuntime: DeploymentProviderRuntime?
    
    
    public required init(_ app: Apodini.Application, _ exporterConfiguration: TopLevelExporterConfiguration = ApodiniDeployExporterConfiguration()) {
        guard let castedConfiguration = dynamicCast(exporterConfiguration, to: ApodiniDeployExporterConfiguration.self) else {
            fatalError("Wrong configuration type passed to exporter!")
        }
        self.app = app
        self.exporterConfiguration = castedConfiguration
        app.storage.set(ApplicationStorageKey.self, to: self)
    }
    
    
    public func export<H: Handler>(_ endpoint: Endpoint<H>) {
        if let groupId = endpoint[Context.self].get(valueFor: DSLSpecifiedDeploymentGroupIdContextKey.self) {
            if explicitlyCreatedDeploymentGroups[groupId] == nil {
                explicitlyCreatedDeploymentGroups[groupId] = []
            }
            explicitlyCreatedDeploymentGroups[groupId]!.insert(endpoint[AnyHandlerIdentifier.self]) // swiftlint:disable:this force_unwrapping
        }
        collectedEndpoints.append(CollectedEndpointInfo(
            handlerType: HandlerTypeIdentifier(H.self),
            endpoint: endpoint,
            deploymentOptions: CollectedOptions(reducing: [
                endpoint.handler.getDeploymentOptions(),
                endpoint[Context.self].get(valueFor: HandlerDeploymentOptionsContextKey.self)
            ].flatMap { $0.compactMap { $0.resolve(against: endpoint.handler) } })
        ))
        vaporApp.add(Vapor.Route(
            method: .POST,
            path: ["__apodini", "invoke", .constant(endpoint[AnyHandlerIdentifier.self].rawValue)],
            responder: InternalInvocationResponder(internalInterfaceExporter: self, endpoint: endpoint),
            requestType: InternalInvocationResponder<H>.Request.self,
            responseType: InternalInvocationResponder<H>.Response.self
        ))
    }
    
    
    public func finishedExporting(_ webService: WebServiceModel) {
        do {
            try performDeploymentRelatedActions()
        } catch {
            fatalError("Error performing deployment-related actions: \(error)")
        }
    }
    
    
    private func performDeploymentRelatedActions() throws {
        let args = CommandLine.arguments
        guard args.count >= 3 else {
            return
        }
        
        switch args[1] {
        case WellKnownCLIArguments.exportWebServiceModelStructure:
            let outputUrl = URL(fileURLWithPath: args[2])
            do {
                try self.exportWebServiceStructure(
                    to: outputUrl,
                    apodiniDeployConfiguration: self.exporterConfiguration
                )
            } catch {
                fatalError("Error exporting web service structure: \(error)")
            }
            exit(EXIT_SUCCESS)
            
        case WellKnownCLIArguments.launchWebServiceInstanceWithCustomConfig:
            let configUrl = URL(fileURLWithPath: args[2])
            guard let currentNodeId = ProcessInfo.processInfo.environment[WellKnownEnvironmentVariables.currentNodeId] else {
                throw ApodiniDeployError(message: "Unable to find '\(WellKnownEnvironmentVariables.currentNodeId)' environment variable")
            }
            do {
                let deployedSystem = try DeployedSystem(decodingJSONAt: configUrl)
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
            
        default:
            break
        }
    }
    
    
    func getEndpoint<H: IdentifiableHandler>(withIdentifier identifier: H.HandlerIdentifier, ofType _: H.Type) -> Endpoint<H>? {
        collectedEndpoints.first { $0.endpoint[AnyHandlerIdentifier.self] == identifier }?.endpoint as? Endpoint<H>
    }
    
    
    func getCollectedEndpointInfo(forHandlerWithIdentifier identifier: AnyHandlerIdentifier) -> CollectedEndpointInfo? {
        collectedEndpoints.first { $0.endpoint[AnyHandlerIdentifier.self] == identifier }
    }
    
    
    public func retrieveParameter<Type: Codable>(_ endpointParameter: EndpointParameter<Type>, for request: ExporterRequest) throws -> Type?? {
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
    public struct ExporterRequest: Apodini.ExporterRequest {
        enum Argument {
            case value(Any)    // the value, as-is
            case encoded(Data) // the value, encoded
        }
        
        private let argumentValues: [String: Argument] // key: stable endpoint param identity
        
        init<H: Handler>(endpoint: Endpoint<H>, collectedArguments: [CollectedArgument<H>]) {
            argumentValues = .init(uniqueKeysWithValues: collectedArguments.map { argument -> (String, Argument) in
                guard let paramId = Apodini.Internal.getParameterId(ofBinding: endpoint.handler[keyPath: argument.handlerKeyPath]) else {
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


// MARK: Utils

private protocol HandlerWithDeploymentOptionsATRVisitorHelper: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = HandlerWithDeploymentOptionsATRVisitorHelper
    associatedtype Input = HandlerWithDeploymentOptions
    associatedtype Output
    func callAsFunction<T: HandlerWithDeploymentOptions>(_ value: T) -> Output
}


private struct HandlerWithDeploymentOptionsATRVisitor: HandlerWithDeploymentOptionsATRVisitorHelper {
    func callAsFunction<H: HandlerWithDeploymentOptions>(_: H) -> [AnyDeploymentOption] {
        H.deploymentOptions
    }
    
    @inline(never)
    @_optimize(none)
    fileprivate func _test() {
        struct TestHandler: HandlerWithDeploymentOptions {
            typealias Response = Never
            static var deploymentOptions: [AnyDeploymentOption] { [] }
        }
        _ = self(TestHandler())
    }
}


extension Handler {
    /// If `self` is an `IdentifiableHandler`, returns the handler's `handlerId`. Otherwise nil
    internal func getDeploymentOptions() -> [AnyDeploymentOption] {
        HandlerWithDeploymentOptionsATRVisitor()(self) ?? []
    }
}
