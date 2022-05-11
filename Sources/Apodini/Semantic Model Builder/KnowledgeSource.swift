//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import ApodiniContext

// MARK: KnowledgeSource

/// A `KnowledgeSource` can be anything that can be initialized from a `SharedRepository`, i.e.
/// from other `KnowledgeSource`s. `KnowledgeSource`s are used to provide `InterfaceExporter`s
/// with information on a `.local` endpoint, or the `.global` structure of the web service.
public protocol KnowledgeSource {
    /// The `LocationPreference` used to determine the place of initialization on a `SharedRepository`.
    static var preference: LocationPreference { get }
    /// Initializes the `KnowledgeSource` based on other `KnowledgeSource`s
    /// available on the `sharedRepository`.
    init<B: SharedRepository>(_ sharedRepository: B) throws
}

extension KnowledgeSource {
    /// If not explicitly declared otherwise, all `KnowledgeSource`s are stored locally.
    public static var preference: LocationPreference {
        .local
    }
}

/// Defines the scope of the `KnowledgeSource`.
public enum LocationPreference {
    /// only shared on the endpoint
    case local
    /// shared across the whole application
    case global
}

public enum KnowledgeError: Error, CustomDebugStringConvertible {
    /// An error thrown if a `KnowledgeSource` is requested from the wrong `SharedRepository`, i.e. one that
    /// cannot provide all `KnowledgeSource`s required to initialize the former.
    case unsatisfiableDependency(String, String?)
    /// An error thrown if  a `KnowledgeSource`'s initializer is called, but there is already an instance of
    /// that type present on the `SharedRepository`. This can be used to signalize to the `SharedRepository`, that
    /// creation of the instance was delegated from the original initializer to some other `KnowledgeSource`.
    case instancePresent
    /// An error thrown if a `KnowledgeSource`'s initializer failed with `instancePresent`, but there was
    /// no instance present.
    case initializationFailed
    
    public var debugDescription: String {
        switch self {
        case let .unsatisfiableDependency(dependency, requiredSharedRepository):
            var message = "'\(dependency)' was initialized as a regular 'KnowledgeSource'."
            if let required = requiredSharedRepository {
                message += " You can only access '\(dependency)' from a '\(required)'."
            }
            return  message
        case .instancePresent:
            return "The 'KnowledgeSource' aborted initilaization, because an instance of the same type was already present."
        case .initializationFailed:
            return """
                Initialization of the 'KnowledgeSource' failed without known error.
                There might be an issue with the 'KnowledgeSource'´s delegation logic.
            """
        }
    }
}

// MARK: TruthAnchor

/// A `TruthAnchor` is a type that `KnowledgeSources`s can refer to for establishing a sense of identity.
/// E.g. a `Relationship<RESTInterfaceExporter>` and a
/// `Relationship<GraphQLInterfaceExporter>` could collect different content. However,
/// the OpenAPI exporter would want to export the exact same information as the REST exporter. Thus,
/// the OpenAPI exporter would use `Relationship<RESTInterfaceExporter>`, too.
/// For that to work both `RESTInterfaceExporter` and `GraphQLInterfaceExporter` must conform
/// to `TruthAnchor`.
/// - Note: This is not particularly helpful yet, since we always expose the **whole** service definition to all
/// exporters. However, one could envision a `.hide(from exporter: TruthAnchor.Type)` modifier on
/// `Component`s, where this feature becomes crucial.
public protocol TruthAnchor { }

// MARK: Base KnowledgeSources
// Below are KnowledgeSources that need support by special SharedRepository implementations. They
// are the foundation for all other KnowledgeSource-Implementations.

/// A `.global` `KnowledgeSource` that provides access to the `Application`
/// - Note: This `KnowledgeSource` can only be accessed from `GlobalSharedRepository`
extension Application: KnowledgeSource {
    public static let preference: LocationPreference = .global
    
    public convenience init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        throw KnowledgeError.unsatisfiableDependency("Application", "GlobalSharedRepository")
    }
}

/// A `KnowledgeSource` providing access to the `Handler` and `Context` related to the `.local` `SharedRepository`.
/// - Note: This `KnowledgeSource` can only be accessed from `LocalSharedRepository`
public struct EndpointSource<H: Handler>: KnowledgeSource {
    public let handler: H
    public let context: Context
    
    internal init(handler: H, context: Context) {
        self.handler = handler
        self.context = context
    }
    
    public init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        throw KnowledgeError.unsatisfiableDependency("EndpointSource", "LocalSharedRepository")
    }
}

/// An untyped version of the generic `EndpointSource`
/// - Note: This `KnowledgeSource` can only be accessed from `LocalSharedRepository`
public struct AnyEndpointSource: KnowledgeSource {
    public let handler: Any
    public let handlerType: Any.Type
    public let context: Context
    
    private let initializer: HandlerKnowledgeSourceInitializer
    
    internal init<H: Handler>(source: EndpointSource<H>) {
        self.context = source.context
        self.initializer = source
        self.handler = source.handler
        self.handlerType = H.self
    }
    
    public init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        throw KnowledgeError.unsatisfiableDependency("AnyEndpointSource", "LocalSharedRepository")
    }
}

private protocol HandlerKnowledgeSourceInitializer {
    func create<S: HandlerKnowledgeSource, B: SharedRepository>(_ type: S.Type, using sharedRepository: B) throws -> S
}

extension EndpointSource: HandlerKnowledgeSourceInitializer {
    func create<S, B>(_ type: S.Type = S.self, using sharedRepository: B) throws -> S where S: HandlerKnowledgeSource, B: SharedRepository {
        try type.init(from: self.handler, sharedRepository)
    }
}

extension AnyEndpointSource: HandlerKnowledgeSourceInitializer {
    func create<S, B>(_ type: S.Type = S.self, using sharedRepository: B) throws -> S where S: HandlerKnowledgeSource, B: SharedRepository {
        try initializer.create(type, using: sharedRepository)
    }
}

/// A `KnowledgeSource` that lives on a `.global` `SharedRepository`. It provides access to a list of local `SharedRepository`s
/// available to a certain `TruthAnchor`.
///  - Note: This `KnowledgeSource` is only accessible on `GlobalSharedRepository`
public struct SharedRepositorys: KnowledgeSource {
    public static let preference: LocationPreference = .global
    
    // default collection of available SharedRepositorys for unrestricted TruthAnchors
    private var sharedRepositorys: [SharedRepository] = []
    
    // we store the available SharedRepositorys for each restricted TruthAnchor separately
    private var restricted: [ObjectIdentifier: [SharedRepository]] = [:]
    
    public init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        throw KnowledgeError.unsatisfiableDependency("SharedRepositorys", "GlobalSharedRepository")
    }
    
    internal init() { }
    
    public subscript<A>(for anchor: A.Type) -> [SharedRepository] where A: TruthAnchor {
        restricted[ObjectIdentifier(anchor)] ?? sharedRepositorys
    }
    
    mutating func addSharedRepository(_ sharedRepository: SharedRepository, hiddenFor restrictions: [TruthAnchor.Type] = []) {
        // we handle restrictions first
        for knownRestriction in self.restricted.keys {
            if !restrictions.contains(where: { newRestriction in ObjectIdentifier(newRestriction) == knownRestriction }) {
                // the sharedRepository we are adding is not hidden for the `knownRestriction`
                self.restricted[knownRestriction]?.append(sharedRepository)
            }
        }
        for newRestriction in restrictions {
            if self.restricted[ObjectIdentifier(newRestriction)] == nil {
                // we don't know of any other sharedRepositorys that are hidden from this `newRestriction`,
                // thus we create a new entry with all the default `self.sharedRepositorys` (which don't
                // include the new `sharedRepository` yet)
                self.restricted[ObjectIdentifier(newRestriction)] = self.sharedRepositorys
            }
        }
        // finally the new sharedRepository is added to the default collection of sharedRepositorys
        sharedRepositorys.append(sharedRepository)
    }
}
