//
//  RHIInterfaceExporter.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-14.
//

import Foundation
@_implementationOnly import Vapor
import ApodiniDeployBuildSupport
import ApodiniDeployRuntimeSupport



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




/// A custom internal interface exporter, which:
/// a) compiles a list of all handlers (via their `Endpoint` objects). These are used to determine the target endpoint when manually invoking a handler.
/// b) is responsible for handling parameter retrieval when manually invoking handlers.
/// c) exports an additional endpoint used to manually invoke a handler remotely over the network.
class RHIInterfaceExporter: InterfaceExporter { // TODO rename to something different, since this class is doing a lot of things, not just the RHI handling
    struct ExporterRequest: Apodini.ExporterRequest {
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
    
    
    private struct CollectedEndpointInfo {
        let handlerType: String
        let endpoint: AnyEndpoint
        let deploymentOptions: DeploymentOptions
    }
    
    internal private(set) static var shared: RHIInterfaceExporter?
    
    let app: Apodini.Application
    
    private var collectedEndpoints: [CollectedEndpointInfo] = []
    private var explicitlyCreatedDeploymentGroups: [DeploymentGroup.ID: Set<AnyHandlerIdentifier>] = [:]
    
    var deploymentProviderRuntime: DeploymentProviderRuntimeSupport?
    var deployedSystemStructure: DeployedSystemStructure? { // TODO remove this
        deploymentProviderRuntime?.deployedSystem
    }
    
    
    required init(_ app: Apodini.Application) {
        self.app = app
        // NOTE: if this precondition fails while running tests, chances are you have to call `RHIInterfaceExporter.resetSingleton` in your -tearDown method
        precondition(Self.shared == nil, "-[\(Self.self) \(#function)] cannot be called multiple times")
        Self.shared = self
    }
    
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        if let groupId = endpoint.context.get(valueFor: DSLSpecifiedDeploymentGroupIdContextKey.self) {
            if explicitlyCreatedDeploymentGroups[groupId] == nil {
                explicitlyCreatedDeploymentGroups[groupId] = []
            }
            explicitlyCreatedDeploymentGroups[groupId]!.insert(endpoint.identifier)
        }
        collectedEndpoints.append(CollectedEndpointInfo(
            handlerType: "\(H.self)",
            endpoint: endpoint,
            deploymentOptions: CollectedOptions(reducing: [
                H.deploymentOptions,
                endpoint.handler.deploymentOptions,
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
    
    
    
    func getEndpoint<H: IdentifiableHandler>(withIdentifier identifier: H.HandlerIdentifier, ofType _: H.Type) -> Endpoint<H>? {
        collectedEndpoints.first { $0.endpoint.identifier == identifier }?.endpoint as? Endpoint<H>
    }
    
    
    func retrieveParameter<Type: Codable>(_ endpointParameter: EndpointParameter<Type>, for request: ExporterRequest) throws -> Type?? {
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


extension RHIInterfaceExporter {
    // Used by the tests to get a new object for every test case.
    // Ideally this function would be wrapped in some `#if TEST` condition, but that doesn't seem to be a thing
    internal static func resetSingleton() {
        Self.shared = nil
    }
}


/// Perform a dynamic cast from one type to another.
/// - returns: the casted value, or `nil` if the cast failed
/// - note: This is semantically equivalent to the `as?` operator.
///         The reason this function exists is to enable casting from `Any` to an optional type,
///         which is otherwise rejected by the type checker.
internal func dynamicCast<U>(_ value: Any, to _: U.Type) -> U? {
    value as? U
}


extension RHIInterfaceExporter {
    func exportWebServiceStructure(to outputUrl: URL, deploymentConfig: DeploymentConfig) throws {
        guard let openApiDocument = app.storage.get(OpenAPIStorageKey.self)?.document else {
            throw makeApodiniError("Unable to get OpenAPI document")
        }
        let openApiDefinitionData = try JSONEncoder().encode(openApiDocument)
        let webServiceStructure = WebServiceStructure(
            endpoints: Set(collectedEndpoints.map { endpointInfo -> ExportedEndpoint in
                let endpoint = endpointInfo.endpoint
                return ExportedEndpoint(
                    handlerType: endpointInfo.handlerType,
                    handlerIdRawValue: endpoint.identifier.rawValue,
                    deploymentOptions: endpointInfo.deploymentOptions,
                    httpMethod: Vapor.HTTPMethod(endpoint.operation).string, // TODO remove this and load it from the OpenAPI def instead?. same for the path...
                    absolutePath: endpoint.absolutePath.asPathString(parameterEncoding: .id),
                    userInfo: [:]
                )
            }),
            deploymentConfig: DeploymentConfig(
                //deploymentGroups: deploymentConfig.deploymentGroups + explicitlyCreatedDeploymentGroups.map({ key, value -> DeploymentGroup in
                //    return DeploymentGroup()
                //})
                deploymentGroups: DeploymentGroupsConfig(
                    defaultGrouping: deploymentConfig.deploymentGroups.defaultGrouping,
                    groups: deploymentConfig.deploymentGroups.groups + explicitlyCreatedDeploymentGroups.map { groupId, handlerIds -> DeploymentGroup in
                        return DeploymentGroup(id: groupId, inputKind: .handlerId, input: Set(handlerIds.map(\.rawValue)))
                    }
                )
            ),
            openApiDefinition: openApiDefinitionData
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(webServiceStructure)
        try data.write(to: outputUrl)
    }
}


extension Set {
    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }
    
    static func + <S> (lhs: Self, rhs: S) -> Self where S: Sequence, S.Element == Self.Element {
        lhs.union(rhs)
    }
    
    static func + <S> (lhs: S, rhs: Self) -> Self where S: Sequence, S.Element == Self.Element {
        rhs.union(lhs)
    }
}
