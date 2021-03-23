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
        }
        return "\(prefix):\(name)"
    }
}


/// An error which occurred while handling something related to the deployment
struct ApodiniDeployError: Swift.Error {
    let message: String
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
            hasher.combine(endpoint.identifier)
        }
        
        static func == (lhs: CollectedEndpointInfo, rhs: CollectedEndpointInfo) -> Bool {
            lhs.handlerType == rhs.handlerType
                && lhs.endpoint.identifier == rhs.endpoint.identifier
                && lhs.deploymentOptions.reduced().options.compareIgnoringOrder(
                    rhs.deploymentOptions.reduced().options,
                    computeHash: { option, hasher in hasher.combine(option) },
                    areEqual: { lhs, rhs in lhs.testEqual(rhs) }
                )
        }
    }
    
    
    let app: Apodini.Application
    var vaporApp: Vapor.Application { app.vapor.app }
    
    private(set) var collectedEndpoints: [CollectedEndpointInfo] = []
    private(set) var explicitlyCreatedDeploymentGroups: [DeploymentGroup.ID: Set<AnyHandlerIdentifier>] = [:]
    
    private(set) var deploymentProviderRuntime: DeploymentProviderRuntimeSupport?
    
    
    public required init(_ app: Apodini.Application) {
        self.app = app
        app.storage.set(ApplicationStorageKey.self, to: self)
    }
    
    
    public func export<H: Handler>(_ endpoint: Endpoint<H>) {
        if let groupId = endpoint.context.get(valueFor: DSLSpecifiedDeploymentGroupIdContextKey.self) {
            if explicitlyCreatedDeploymentGroups[groupId] == nil {
                explicitlyCreatedDeploymentGroups[groupId] = []
            }
            explicitlyCreatedDeploymentGroups[groupId]!.insert(endpoint.identifier) // swiftlint:disable:this force_unwrapping
        }
        collectedEndpoints.append(CollectedEndpointInfo(
            handlerType: HandlerTypeIdentifier(H.self),
            endpoint: endpoint,
            deploymentOptions: CollectedOptions(reducing: [
                endpoint.handler.getDeploymentOptions(),
                endpoint.context.get(valueFor: HandlerDeploymentOptionsContextKey.self)
            ].flatMap { $0.compactMap { $0.resolve(against: endpoint.handler) } })
        ))
        vaporApp.add(Vapor.Route(
            method: .POST,
            path: ["__apodini", "invoke", .constant(endpoint.identifier.rawValue)],
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
                    deploymentConfig: self.app.storage.get(ApodiniDeployConfiguration.StorageKey.self)?.config ?? .init()
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
                    let runtimes = self.app.storage.get(ApodiniDeployConfiguration.StorageKey.self)?.runtimes,
                    let DPRSType = runtimes.first(where: { $0.identifier == deployedSystem.deploymentProviderId })
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
        collectedEndpoints.first { $0.endpoint.identifier == identifier }?.endpoint as? Endpoint<H>
    }
    
    
    func getCollectedEndpointInfo(forHandlerWithIdentifier identifier: AnyHandlerIdentifier) -> CollectedEndpointInfo? {
        collectedEndpoints.first { $0.endpoint.identifier == identifier }
    }
    
    
    public func retrieveParameter<Type: Codable>(_ endpointParameter: EndpointParameter<Type>, for request: ExporterRequest) throws -> Type?? {
        guard let paramValueContainer = request.getValueOfCollectedParameter(for: endpointParameter) else {
            return Optional<Type?>.none // this should be a "top-level" nil value (ie `.none` instead of `.some(.none)`)
        }
        
        if endpointParameter.nilIsValidValue {
            switch paramValueContainer {
            case .value(let value):
                if let value: Type? = dynamicCast(value, to: Type?.self) {
                    return .some(value)
                }
            case .encoded(let data):
                return try .some(JSONDecoder().decode(Type?.self, from: data))
            }
        } else {
            switch paramValueContainer {
            case .value(let value):
                if let value = value as? Type {
                    return .some(.some(value))
                }
            case .encoded(let data):
                return try .some(.some(JSONDecoder().decode(Type.self, from: data)))
            }
        }
        throw ApodiniDeployError(
            message: "Unable to cast parameter value (\(paramValueContainer)) to expected type '\(Type.self)'"
        )
    }
}


// MARK: ApodiniDeployInterfaceExporter.ExporterRequest

extension ApodiniDeployInterfaceExporter {
    public struct ExporterRequest: Apodini.ExporterRequest {
        enum Param {
            case value(Any)    // the value, as-is
            case encoded(Data) // the value, encoded
        }
        
        private let parameterValues: [String: Param] // key: stable endpoint param identity
        
        init<H: Handler>(endpoint: Endpoint<H>, collectedParameters: [CollectedParameter<H>]) {
            parameterValues = .init(uniqueKeysWithValues: collectedParameters.map { param -> (String, Param) in
                guard let paramId = unsafelyCast(
                    endpoint.handler[keyPath: param.handlerKeyPath],
                    to: _PotentiallyParameterIdentifyingBinding.self
                ).parameterId else {
                    fatalError("Unable to get @Parameter id from collected parameter with key path \(param.handlerKeyPath)")
                }
                let endpointParam = endpoint.parameters.first { $0.id == paramId }!
                return (endpointParam.stableIdentity, .value(param.value))
            })
        }
        
        init(encodedParameters: [(String, Data)]) {
            parameterValues = Dictionary(
                uniqueKeysWithValues: encodedParameters.map { ($0.0, .encoded($0.1)) }
            )
        }
        
        func getValueOfCollectedParameter(for endpointParameter: AnyEndpointParameter) -> Param? {
            parameterValues[endpointParameter.stableIdentity]
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
