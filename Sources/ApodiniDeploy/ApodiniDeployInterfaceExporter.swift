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
    var lk_stableIdentity: String {
        switch self.parameterType {
        case .content:
            return "c:\(self.name)"
        case .lightweight:
            return "l:\(self.name)"
        case .path:
            return "p:\(self.name)"
        }
    }
}




struct TmpErrorType: Swift.Error {
    let message: String
}


/// A custom internal interface exporter, which:
/// a) compiles a list of all handlers (via their `Endpoint` objects). These are used to determine the target endpoint when manually invoking a handler.
/// b) is responsible for handling parameter retrieval when manually invoking handlers.
/// c) exports an additional endpoint used to manually invoke a handler remotely over the network.
public class ApodiniDeployInterfaceExporter: InterfaceExporter { // TODO rename to something different, since this class is doing a lot of things, not just the RHI handling
    struct CollectedEndpointInfo {
        let handlerType: HandlerTypeIdentifier
        let endpoint: AnyEndpoint
        let deploymentOptions: DeploymentOptions
    }
    
    // TODO if we put this into the app storage we can get rid of the singleton!
    internal private(set) static var shared: ApodiniDeployInterfaceExporter?
    
    let app: Apodini.Application
    
    var collectedEndpoints: [CollectedEndpointInfo] = []
    var explicitlyCreatedDeploymentGroups: [DeploymentGroup.ID: Set<AnyHandlerIdentifier>] = [:]
    
    var deploymentProviderRuntime: DeploymentProviderRuntimeSupport?
    var deployedSystemStructure: DeployedSystemStructure? { // TODO remove this
        deploymentProviderRuntime?.deployedSystem
    }
    
    
    public required init(_ app: Apodini.Application) {
        self.app = app
        // NOTE: if this precondition fails while running tests, chances are you have to call `ApodiniDeployInterfaceExporter.resetSingleton` in your -tearDown method
        precondition(Self.shared == nil, "-[\(Self.self) \(#function)] cannot be called multiple times")
        Self.shared = self
    }
    
    
    public func export<H: Handler>(_ endpoint: Endpoint<H>) {
        if let groupId = endpoint.context.get(valueFor: DSLSpecifiedDeploymentGroupIdContextKey.self) {
            if explicitlyCreatedDeploymentGroups[groupId] == nil {
                explicitlyCreatedDeploymentGroups[groupId] = []
            }
            explicitlyCreatedDeploymentGroups[groupId]!.insert(endpoint.identifier)
        }
        collectedEndpoints.append(CollectedEndpointInfo(
            handlerType: HandlerTypeIdentifier(H.self),
            endpoint: endpoint,
            deploymentOptions: CollectedOptions(reducing: [
                endpoint.handler.getDeploymentOptions(),
                endpoint.context.get(valueFor: HandlerDeploymentOptionsSyntaxNodeContextKey.self)
            ].flatMap { $0.compactMap { $0.resolve(against: endpoint.handler) } })
        ))
        app.vapor.app.add(Vapor.Route(
            method: .POST,
            path: ["__apodini", "invoke", .constant(endpoint.identifier.rawValue)],
            responder: InternalInvocationResponder(RHIIE: self, endpoint: endpoint),
            requestType: InternalInvocationResponder<H>.Request.self,
            responseType: InternalInvocationResponder<H>.Response.self
        ))
    }
    
    
    public func finishedExporting(_ webService: WebServiceModel) {
        do {
            try performDeploymentStuff()
        } catch {
            fatalError("ugh \(error)")
        }
    }
    
    
    private func performDeploymentStuff() throws {
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
                throw TmpErrorType(message: "Unable to find '\(WellKnownEnvironmentVariables.currentNodeId)' environment variable")
            }
            do {
                let deployedSystem = try DeployedSystemStructure(contentsOf: configUrl)
                guard
                    let runtimes = self.app.storage.get(ApodiniDeployConfiguration.StorageKey.self)?.runtimes,
                    let DPRSType = runtimes.first(where: { $0.deploymentProviderId == deployedSystem.deploymentProviderId })
                else {
                    throw TmpErrorType(message: "Unable to find deployment runtime with id '\(deployedSystem.deploymentProviderId.rawValue)'")
                }
                let runtimeSupport = try DPRSType.init(deployedSystem: deployedSystem, currentNodeId: currentNodeId)
                self.deploymentProviderRuntime = runtimeSupport
                try runtimeSupport.configure(app)
            } catch {
                throw TmpErrorType(message: "Unable to launch with custom config: \(error)")
            }
            
        default:
            break
        }
    }
    
    
    func getEndpoint<H: IdentifiableHandler>(withIdentifier identifier: H.HandlerIdentifier, ofType _: H.Type) -> Endpoint<H>? {
        collectedEndpoints.first { $0.endpoint.identifier == identifier }?.endpoint as? Endpoint<H>
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
        throw makeApodiniError("Unable to cast parameter value (\(paramValueContainer)) to expected type '\(Type.self)'")
    }
}


extension ApodiniDeployInterfaceExporter {
    // Used by the tests to get a new object for every test case.
    // Ideally this function would be wrapped in some `#if TEST` condition, but that doesn't seem to be a thing
    internal static func resetSingleton() {
        Self.shared = nil
    }
}



// MARK: ApodiniDeployInterfaceExporter.ExporterRequest

extension ApodiniDeployInterfaceExporter {
    public struct ExporterRequest: Apodini.ExporterRequest {
        enum Param {
            case value(Any)    // the value, as is
            case encoded(Data) // the value, encoded
        }
        
        private let parameterValues: [String: Param] // key: stable endpoint param identity
        
        init<H: Handler>(endpoint: Endpoint<H>, collectedParameters: [CollectedParameter<H>]) {
            parameterValues = .init(uniqueKeysWithValues: collectedParameters.map { param -> (String, Param) in
                let paramId = (endpoint.handler[keyPath: param.handlerKeyPath] as! AnyParameterID).value
                let endpointParam = endpoint.parameters.first { $0.id == paramId }!
                return (endpointParam.lk_stableIdentity, .value(param.value))
            })
        }
        
        init(encodedParameters: [(String, Data)]) {
            parameterValues = Dictionary(
                uniqueKeysWithValues: encodedParameters.map { ($0.0, .encoded($0.1)) }
            )
        }
        
        func getValueOfCollectedParameter(for endpointParameter: AnyEndpointParameter) -> Param? {
            parameterValues[endpointParameter.lk_stableIdentity]
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
        return H.deploymentOptions
    }
    
    @inline(never) @_optimize(none)
    fileprivate func _test() {
        // TODO is this actually necessary?
        struct TestHandler: HandlerWithDeploymentOptions {
            typealias Response = Never
            static var deploymentOptions: [AnyDeploymentOption] { return [] }
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
