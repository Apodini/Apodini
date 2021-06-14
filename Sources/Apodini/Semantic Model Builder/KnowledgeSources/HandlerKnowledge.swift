//
//  HandlerKnowledge.swift
//  
//
//  Created by Max Obermeier on 09.05.21.
//

import Foundation

/// `HandlerDescription` describes a `Handler`'s type-name.
public typealias HandlerDescription = String

extension HandlerDescription: HandlerKnowledgeSource {
    public init<H, B>(from handler: H, _ blackboard: B) throws where H: Handler, B: Blackboard {
        self = String(describing: H.self)
    }
}

public struct HandleReturnType: HandlerKnowledgeSource {
    public let type: Encodable.Type
    
    public init<H, B>(from handler: H, _ blackboard: B) throws where H: Handler, B: Blackboard {
        self.type = H.Response.Content.self
    }
}

extension ServiceType: ContextKeyKnowledgeSource {
    public typealias Key = ServiceTypeContextKey
    
    public init(from value: Key.Value) throws {
        self = value
    }
}

extension Operation: OptionalContextKeyKnowledgeSource {
    public typealias Key = OperationContextKey
    
    public init(from value: Key.Value?) {
        self = value ?? .read
    }
}

public typealias EndpointParameters = [AnyEndpointParameter]

extension EndpointParameters: HandlerKnowledgeSource, KnowledgeSource {
    public init<H, B>(from handler: H, _ blackboard: B) throws where H: Handler, B: Blackboard {
        self = handler.buildParametersModel()
    }
}

public extension Endpoint {
    var parameters: EndpointParameters { self[EndpointParameters.self] }
}

extension HandlerIndexPath: ContextKeyKnowledgeSource {
    typealias Key = ContextKey
    
    init(from value: HandlerIndexPath) {
        self = value
    }
}
