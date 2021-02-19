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
import Vapor
@_implementationOnly import AssociatedTypeRequirementsVisitor


struct ApodiniDeployRuntimeSupportError: Swift.Error {
    let message: String
}




public struct HandlerInvocation<Handler: InvocableHandler> {
    public let handlerId: Handler.HandlerIdentifier
    public let targetNode: DeployedSystemStructure.Node
    public let parameters: [Parameter]
    
    public init(handlerId: Handler.HandlerIdentifier, targetNode: DeployedSystemStructure.Node, parameters: [Parameter]) {
        self.handlerId = handlerId
        self.targetNode = targetNode
        self.parameters = parameters
    }
}



extension HandlerInvocation {
    public struct Parameter {
        // TODO somehow fix this to apodini's endpoint parameter propertytype constraint
        public typealias Value = Codable
        
        public let stableIdentity: String
        public let name: String // name as set in the @Parameter property wrapper
        public let value: Value
        
        
        public init(stableIdentity: String, name: String, value: Value) {
            self.stableIdentity = stableIdentity
            self.name = name
            self.value = value
        }
        
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
        
        
        public func encodeValue(into content: inout Vapor.ContentContainer, using encoder: Vapor.ContentEncoder) throws {
            let box = Box(content)
            switch AnyEncodableEncodeIntoVaporContentATRVisitor(boxedContentContainer: box, encoder: encoder)(value) {
            case .none:
                throw ApodiniDeployRuntimeSupportError(message: "Value is not encodable")
            case .some(.none):
                // success
                content = box.value
            case .some(.some(let error)):
                // the encoding process failed
                throw error
            }
        }
    }

}


private protocol AnyEncodableATRVisitorBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = AnyEncodableATRVisitorBase
    associatedtype Input = Encodable
    associatedtype Output

    func callAsFunction<T: Encodable>(_ value: T) -> Output
}

extension AnyEncodableATRVisitorBase {
    @inline(never) @_optimize(none)
    func _test() {
        _ = self(12)
    }
}

private struct AnyEncodableEncodeUsingEncoderATRVisitor: AnyEncodableATRVisitorBase {
    let encoder: AnyEncoder
    func callAsFunction<T: Encodable>(_ value: T) -> Result<Data, Error> {
        .init(catching: { try encoder.encode(value) })
    }
}


private struct AnyEncodableEncodeIntoVaporContentATRVisitor: AnyEncodableATRVisitorBase {
    let boxedContentContainer: Box<Vapor.ContentContainer>
    let encoder: Vapor.ContentEncoder
    
    func callAsFunction<T: Encodable>(_ value: T) -> Error? {
        do {
            try boxedContentContainer.value.encode(value, using: encoder)
            return nil
        } catch {
            return error
        }
    }
}
