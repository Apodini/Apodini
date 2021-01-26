//
//  DeploymentProviderRuntimeSupport.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import Vapor
import NIO
@_exported import ApodiniDeployBuildSupport
import AssociatedTypeRequirementsVisitor


//@_silgen_name("LKGetRuntimeSupportType")
//func LKGetRuntimeSupportType() -> DeploymentProviderRuntimeSupport.Type {
//    fatalError()
//}


public protocol AnyEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}


extension JSONEncoder: AnyEncoder {}


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



public enum RemoteHandlerInvocationRequestResponse<Response: Decodable> {
    // url should be just scheme+hostname+port (but no path)
    case invokeDefault(url: URL)
    case result(EventLoopFuture<Response>)
}


public protocol DeploymentProviderRuntimeSupport: class {
    static var deploymentProviderId: DeploymentProviderID { get }
    
    init(deployedSystemStructure: DeployedSystemStructure) throws
    
    func configure(_ app: Vapor.Application) throws
    
    
    /// This function is called when a handler uses the remote handler invocation API to invoke another
    /// handler and the remote handler invocation manager has determined that the invocation's target handler is not in the current node.
    /// The deployment provider is given the option to manually implement and realise the remote invocation.
    /// It can also re-delegate this responsibility back to the caller.
    func handleRemoteHandlerInvocation<Response: Decodable>( // TODO rename requestRemoteHandlerInvocation?
        withId handlerId: String,
        inTargetNode targetNode: DeployedSystemConfiguration.Node,
        responseType: Response.Type,
        parameters: [HandlerInvocationParameter]
    ) throws -> RemoteHandlerInvocationRequestResponse<Response>
}


extension DeploymentProviderRuntimeSupport {
    public var deploymentProviderId: DeploymentProviderID {
        Self.deploymentProviderId
    }
}
