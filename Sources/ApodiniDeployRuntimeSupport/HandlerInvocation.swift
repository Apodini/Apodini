//
//  HandlerInvocation.swift
//
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import Apodini
import ApodiniDeployBuildSupport
import Vapor
@_implementationOnly import AssociatedTypeRequirementsVisitor


public struct HandlerInvocation<Handler: InvocableHandler> {
    public let handlerId: Handler.HandlerIdentifier
    public let targetNode: DeployedSystemStructure.Node
    public let parameters: [HandlerInvocationParameter]
    
    public init(handlerId: Handler.HandlerIdentifier, targetNode: DeployedSystemStructure.Node, parameters: [HandlerInvocationParameter]) {
        self.handlerId = handlerId
        self.targetNode = targetNode
        self.parameters = parameters
    }
}




public protocol AnyEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension JSONEncoder: AnyEncoder {}




// TODO move this into HandlerInvocation?
public struct HandlerInvocationParameter {
    public enum RESTParameterType { // We can't import Apodini in here so we have to redefine this instead :/
        case query
        case path
        case body
    }
    
    // TODO somehow fix this to apodini's endpoint parameter propertytype constraint
    public typealias Value = Codable
    
    public let stableIdentity: String
    public let name: String // name as set in the @Parameter property wrapper
    public let value: Value
    public let restParameterType: RESTParameterType
//    let
    
    // TODO we probably need to fix the Encodable to Apodini's thing (ie the EndpointParameter.PropertyTypeConstraint)
    public init(stableIdentity: String, name: String, value: Value, restParameterType: RESTParameterType) {
        self.stableIdentity = stableIdentity
        self.name = name
        self.value = value
        self.restParameterType = restParameterType
    }
    
    public func encodeValue(using encoder: AnyEncoder) throws -> Data {
        switch AnyEncodableEncodeUsingEncoderATRVisitor(encoder: encoder)(value) {
        case nil:
            throw NSError(domain: "wtf", code: 0, userInfo: nil) // TODO?
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
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to ART-visit value"])
        case .some(.none):
            // success
            content = box.value
        case .some(.some(let error)):
            // the encoding process failed
            throw error
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
