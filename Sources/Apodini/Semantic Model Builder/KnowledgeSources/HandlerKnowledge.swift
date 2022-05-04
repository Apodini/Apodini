//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import TypeInformationMetadata

/// `HandlerDescription` describes a `Handler`'s type-name.
public struct HandlerDescription: HandlerKnowledgeSource, RawRepresentable, CustomStringConvertible {
    public let rawValue: String

    public var description: String {
        rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init<H, B>(from handler: H, _ sharedRepository: B) throws where H: Handler, B: SharedRepository {
        self.init(rawValue: String(describing: H.self))
    }
}

/// `HandlerDescription` describes the full type-name of a `Handler`.
public struct HandlerReflectiveName: HandlerKnowledgeSource, RawRepresentable, CustomStringConvertible {
    public let rawValue: String

    public var description: String {
        rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init<H, B>(from handler: H, _ sharedRepository: B) throws where H: Handler, B: SharedRepository {
        self.init(rawValue: String(reflecting: H.self))
    }
}

public struct HandleReturnType: HandlerKnowledgeSource {
    public let type: Encodable.Type
    
    public init<H, B>(from handler: H, _ sharedRepository: B) throws where H: Handler, B: SharedRepository {
        self.type = H.Response.Content.self
    }
}


public struct HandleReturnTypeRootContext: ContextKeyKnowledgeSource, ContextKeyRetrievable {
    public typealias Key = RootContextOfReturnTypeContextKey

    public let context: Context

    public init(from value: Context) throws {
        self.context = value
    }

    public func get<C: ContextKey>(valueFor contextKey: C.Type) -> C.Value {
        context.get(valueFor: contextKey)
    }

    public func get<C: OptionalContextKey>(valueFor contextKey: C.Type) -> C.Value? {
        context.get(valueFor: contextKey)
    }
}

public struct RootContextOfReturnTypeContextKey: ContextKey {
    public typealias Value = Context
    public static var defaultValue = Context()
}

extension Operation: OptionalContextKeyKnowledgeSource {
    public typealias Key = OperationHandlerMetadata.Key
    
    public init(from value: Key.Value?) {
        self = value ?? .read
    }
}

/// A collection of ``AnyEndpointParameter`` that can be directly obtained from a local ``SharedRepository``.
public typealias EndpointParameters = [AnyEndpointParameter]

extension EndpointParameters: HandlerKnowledgeSource, KnowledgeSource {
    public init<H, B>(from handler: H, _ sharedRepository: B) throws where H: Handler, B: SharedRepository {
        self = handler.buildParametersModel()
    }
}

public extension AnyEndpoint {
    /// Provides the ``EndpointParameters`` that correspond to the ``Parameter``s defined on the ``Handler`` of this ``Endpoint``.
    var parameters: EndpointParameters { self[EndpointParameters.self] }
}

extension HandlerIndexPath: ContextKeyKnowledgeSource {
    typealias Key = ContextKey
    
    init(from value: HandlerIndexPath) {
        self = value
    }
}
