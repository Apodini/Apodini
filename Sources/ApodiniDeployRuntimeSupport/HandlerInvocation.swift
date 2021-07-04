//
//  HandlerInvocation.swift
//
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import Apodini
import ApodiniUtils
import ApodiniDeployBuildSupport
@_implementationOnly import AssociatedTypeRequirementsVisitor


public struct ApodiniDeployRuntimeSupportError: Swift.Error, LocalizedError, CustomStringConvertible {
    let deploymentProviderId: DeploymentProviderID?
    let message: String
    
    public init(deploymentProviderId: DeploymentProviderID? = nil, message: String) {
        self.deploymentProviderId = deploymentProviderId
        self.message = message
    }
    
    public var description: String {
        var desc = ""
        if let deploymentProviderId = deploymentProviderId {
            desc = "[\(deploymentProviderId.rawValue)] "
        }
        desc += message
        return desc
    }
    
    public var errorDescription: String? {
        description
    }
}


/// An invocation of a handler encapsulated into an object.
public struct HandlerInvocation<Handler: InvocableHandler> {
    /// The identifier of the handler which is the invocation's target
    public let handlerId: Handler.HandlerIdentifier
    /// The node within the deployed system exporting this handler
    public let targetNode: DeployedSystem.Node
    /// The parameters collected for the invocation
    public let parameters: [Parameter]
    
    /// Creates a `HandlerInvocation` object for the specifid handlerId, targetNode and parameters
    public init(handlerId: Handler.HandlerIdentifier, targetNode: DeployedSystem.Node, parameters: [Parameter]) {
        self.handlerId = handlerId
        self.targetNode = targetNode
        self.parameters = parameters
        precondition(
            targetNode.exportedEndpoints.contains { $0.handlerId == handlerId },
            "HandlerInvocation targetNode does not contain the invocation's handlerId"
        )
    }
}


extension HandlerInvocation {
    /// Utility type for storing a parameter passed to a `HandlerInvocation`.
    /// This type stores all necessary information about the parameter, and allows identifying the parameter within its defining `Handler`.
    public struct Parameter {
        /// The type constraint for supported values.
        /// - Note: This should ideally somehow be fixed to the constraint Apodini defines for an `EndpointParameter`'s type (i.e. `Codable`).
        public typealias Value = Codable
        
        /// A string which can be used to reference this parameter (relative to its defining Handler) in a stable way,
        /// i.e. across multiple compilations and executions of the web service, as long as the parameter definition wasn't somehow modified.
        public let stableIdentity: String
        
        /// The name of the parameter, as set in the `@Parameter` property wrapper.
        public let name: String
        
        /// The value specified for this parameter.
        /// Note that this is stored as a `Codable` object, which in itself is pretty useless (because of ATR limitations),
        /// but you can use the `encodeValue` functions to encode the parameter's value into something more useful.
        public let value: Value
        
        
        /// Create a new Parameter for a specific invocation
        public init(stableIdentity: String, name: String, value: Value) {
            self.stableIdentity = stableIdentity
            self.name = name
            self.value = value
        }
        
        /// Encode the value to a `Data` object, using the specified encoder.
        public func encodeValue(using encoder: AnyEncoder) throws -> Data {
            switch AnyEncodableEncodeUsingEncoderATRVisitor(encoder: encoder)(value) {
            case nil:
                throw ApodiniDeployRuntimeSupportError(message: "Value is not encodable")
            case .success(let data):
                return data
            case .failure(let error):
                throw error
            }
        }
    }
}


// MARK: Utilities

private protocol AnyEncodableATRVisitorBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = AnyEncodableATRVisitorBase
    associatedtype Input = Encodable
    associatedtype Output

    func callAsFunction<T: Encodable>(_ value: T) -> Output
}

extension AnyEncodableATRVisitorBase {
    @inline(never)
    @_optimize(none)
    fileprivate func _test() {
        _ = self(12)
    }
}

private struct AnyEncodableEncodeUsingEncoderATRVisitor: AnyEncodableATRVisitorBase {
    let encoder: AnyEncoder
    func callAsFunction<T: Encodable>(_ value: T) -> Result<Data, Error> {
        .init(catching: { try encoder.encode(value) })
    }
}
