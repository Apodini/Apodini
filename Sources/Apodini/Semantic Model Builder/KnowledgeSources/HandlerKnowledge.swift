//
//  HandlerKnowledge.swift
//  
//
//  Created by Max Obermeier on 09.05.21.
//

import Foundation


public typealias HandlerDescription = String

extension HandlerDescription: HandlerBasedKnowledgeSource {
    public init<H>(from handler: H) throws where H : Handler {
        self = String(describing: H.self)
    }
}

public struct HandleReturnType: HandlerBasedKnowledgeSource {
    public let type: Encodable.Type
    
    public init<H>(from handler: H) throws where H : Handler {
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

typealias EndpointParameters = [AnyEndpointParameter]

extension EndpointParameters: HandlerBasedKnowledgeSource, KnowledgeSource {
    public init<H>(from handler: H) throws where H : Handler {
        self = handler.buildParametersModel()
    }
}

extension HandlerIndexPath: ContextKeyKnowledgeSource {
    typealias Key = ContextKey
    
    init(from value: HandlerIndexPath) {
        self = value
    }
}
