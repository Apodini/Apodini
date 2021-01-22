//
//  RHIInterfaceExporter.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-14.
//

import Foundation
@_implementationOnly import Vapor
import ApodiniDeployBuildSupport


/// A custom internal interface exporter, which:
/// a) compiles a list of all handlers (via their `Endpoint` objects). These are used to determine the target endpoint when manually invoking a handler.
/// b) is responsible for handling parameter retrieval when manually invoking handlers.
/// c) exports an additional endpoint used to manually invoke a handler remotely over the network.
class RHIInterfaceExporter: InterfaceExporter {
    struct ExporterRequest: Apodini.ExporterRequest {
        private let imp: (_ endpointParamId: UUID) -> Any?
        
        init<H: InvocableHandler>(endpoint: Endpoint<H>, collectedParameters: [CollectedParameter<H>]) {
            self.imp = { endpointParamId -> Any? in
                collectedParameters.first { collectedParam in
                    (endpoint.handler[keyPath: collectedParam.handlerKeyPath] as? AnyParameterID)?.value == endpointParamId
                }?.value
            }
        }
        
        func getValueOfCollectedParameter(for endpointParameter: AnyEndpointParameter) -> Any? {
            imp(endpointParameter.id)
        }
    }
    
    internal private(set) static var shared: RHIInterfaceExporter?
    
    let app: Apodini.Application
    private var endpointsById: [AnyHandlerIdentifier: AnyEndpoint] = [:]
    
    
    required init(_ app: Apodini.Application) {
        self.app = app
        // NOTE: if this precondition fails while running tests, chances are you have to call `RHIInterfaceExporter.resetSingleton` in your -tearDown method
        precondition(Self.shared == nil, "-[\(Self.self) \(#function)] cannot be called multiple times")
        Self.shared = self
    }
    
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        endpointsById[endpoint.identifier] = endpoint
    }
    
    
    func finishedExporting(_ webService: WebServiceModel) {
        // This is where we will expose the remote-invocation endpoint
//        app.vapor.app.post(["__apodini", "invoke"]) { request -> String in
//            String(reflecting: request)
//        }
    }
    
    
    func getEndpoint<H: IdentifiableHandler>(withIdentifier identifier: H.HandlerIdentifier, ofType _: H.Type) -> Endpoint<H>? {
        endpointsById[identifier] as? Endpoint<H>
    }
    
    
    func retrieveParameter<Type: Codable>(_ endpointParameter: EndpointParameter<Type>, for request: ExporterRequest) throws -> Type?? {
        guard let value: Any = request.getValueOfCollectedParameter(for: endpointParameter) else {
            return Optional<Type?>.none // this should be a "top-level" nil value (ie `.none` instead of `.some(.none)`)
        }
        
        if endpointParameter.nilIsValidValue {
            if let value: Type? = dynamicCast(value, to: Type?.self) {
                return .some(value)
            }
        } else {
            if let value = value as? Type {
                return .some(.some(value))
            }
        }
        throw makeApodiniError("Unable to cast parameter value (of type '\(type(of: value))' to expected type '\(Type.self)'")
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
        let openApiDefinitionData = try JSONEncoder().encode(self.app.storage.get(OpenAPIDefStorageKey.self)!)
        print("OPENAPI@RHIIE", openApiDefinitionData)
        let webServiceStructure = WebServiceStructure(
            interfaceExporterId: .init("unused_remove"),
            endpoints: endpointsById.values.map { endpoint -> ExportedEndpoint in
                return ExportedEndpoint(
                    handlerIdRawValue: endpoint.identifier.rawValue,
                    httpMethod: endpoint.operation.httpMethod.string,
                    absolutePath: endpoint.absolutePath.asPathString(parameterEncoding: .id),
                    userInfo: [:]
                )
            },
            deploymentConfig: deploymentConfig,
            openApiDefinition: openApiDefinitionData
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(webServiceStructure)
        print("writing encoded webServiceStructure to \(outputUrl)")
        try data.write(to: outputUrl)
        print("write.success")
    }
}
