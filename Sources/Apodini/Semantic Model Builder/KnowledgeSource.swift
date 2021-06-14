//
//  KnowledgeSource.swift
//  
//
//  Created by Max Obermeier on 03.05.21.
//

import Foundation

// MARK: KnowledgeSource

/// A `KnowledgeSource` can be anything that can be initialized from a `Blackboard`, i.e.
/// from other `KnowledgeSource`s. `KnowledgeSource`s are used to provide `InterfaceExporter`s
/// with information on a `.local` endpoint, or the `.global` structure of the web service.
public protocol KnowledgeSource {
    /// The `LocationPreference` used to determine the place of initialization on a `Blackboard`.
    static var preference: LocationPreference { get }
    /// Initializes the `KnowledgeSource` based on other `KnowledgeSource`s
    /// available on the `blackboard`.
    init<B: Blackboard>(_ blackboard: B) throws
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
    /// An error thrown if a `KnowledgeSource` is requested from the wrong `Blackboard`, i.e. one that
    /// cannot provide all `KnowledgeSource`s required to initilaize the former.
    case unsatisfiableDependency(String, String?)
    /// An error thrown if  a `KnowledgeSource`'s initilaizer is called, but there is already an instance of
    /// that type present on the `Blackboard`. This can be used to signalize to the `Blackboard`, that
    /// creation of the instance was delegated from the original initializer to some other `KnowledgeSource`.
    case instancePresent
    /// An error thrown if a `KnowledgeSource`'s initializer failed with `instancePresent`, but there was
    /// no instance present.
    case initializationFailed
    
    public var debugDescription: String {
        switch self {
        case let .unsatisfiableDependency(dependency, requiredBoard):
            var message = "'\(dependency)' was initialized as a regular 'KnowledgeSource'."
            if let required = requiredBoard {
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
/// to `TrustAnchor`.
/// - Note: This is not particularely helpful yet, since we always expose the **whole** service definition to all
/// exporters. However, one could envision a `.hide(from exporter: TruthAnchor.Type)` modifier on
/// `Component`s, where this feature becomes crucial.
public protocol TruthAnchor { }

// MARK: Base KnowledgeSources
// Below are KnowledgeSources that need support by special Blackboard implementations. They
// are the foundation for all other KnowledgeSource-Implementations.

/// A `.global` `KnowledgeSource` that provides access to the `Application`
/// - Note: This `KnowledgeSource` can only be accessed from `GlobalBlackboard`
extension Application: KnowledgeSource {
    public static let preference: LocationPreference = .global
    
    public convenience init<B>(_ blackboard: B) throws where B: Blackboard {
        throw KnowledgeError.unsatisfiableDependency("Application", "GlobalBlackboard")
    }
}

/// A `KnowledgeSource` providing access to the `Handler` and `Context` related to the `.local` `Blackboard`.
/// - Note: This `KnowledgeSource` can only be accessed from `LocalBlackboard`
public struct EndpointSource<H: Handler>: KnowledgeSource {
    public let handler: H
    public let context: Context
    
    internal init(handler: H, context: Context) {
        self.handler = handler
        self.context = context
    }
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        throw KnowledgeError.unsatisfiableDependency("EndpointSource", "LocalBlackboard")
    }
}

/// An untyped version of the generic `EndpointSource`
/// - Note: This `KnowledgeSource` can only be accessed from `LocalBlackboard`
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
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        throw KnowledgeError.unsatisfiableDependency("EndpointSource", "LocalBlackboard")
    }
}

private protocol HandlerKnowledgeSourceInitializer {
    func create<S: HandlerKnowledgeSource, B: Blackboard>(_ type: S.Type, using blackboard: B) throws -> S
}

extension EndpointSource: HandlerKnowledgeSourceInitializer {
    func create<S, B>(_ type: S.Type = S.self, using blackboard: B) throws -> S where S: HandlerKnowledgeSource, B: Blackboard {
        try type.init(from: self.handler, blackboard)
    }
}

extension AnyEndpointSource: HandlerKnowledgeSourceInitializer {
    func create<S, B>(_ type: S.Type = S.self, using blackboard: B) throws -> S where S: HandlerKnowledgeSource, B: Blackboard {
        try initializer.create(type, using: blackboard)
    }
}

/// A `KnowledgeSource` that lives on a `.global` `Blackboard`. It provides access to a list of local `Blackboard`s
/// available to a certain `TruthAnchor`.
///  - Note: This `KnowledgeSource` is only accessible on `GlobalBlackboard`
public struct Blackboards: KnowledgeSource {
    public static let preference: LocationPreference = .global
    
    // default collection of available Blackboards for unrestricted TruthAnchors
    private var boards: [Blackboard] = []
    
    // we store the available Blackboards for each restricted TruthAnchor separately
    private var restricted: [ObjectIdentifier: [Blackboard]] = [:]
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        throw KnowledgeError.unsatisfiableDependency("Blackboards", "GlobalBlackboard")
    }
    
    internal init() { }
    
    public subscript<A>(for anchor: A.Type) -> [Blackboard] where A: TruthAnchor {
        restricted[ObjectIdentifier(anchor)] ?? boards
    }
    
    mutating func addBoard(_ board: Blackboard, hiddenFor restrictions: [TruthAnchor.Type] = []) {
        // we handle restrictions first
        for knownRestriction in self.restricted.keys {
            if !restrictions.contains(where: { newRestriction in ObjectIdentifier(newRestriction) == knownRestriction }) {
                // the board we are adding is not hidden for the `knownRestriction`
                self.restricted[knownRestriction]?.append(board)
            }
        }
        for newRestriction in restrictions {
            if self.restricted[ObjectIdentifier(newRestriction)] == nil {
                // we don't know of any other boards that are hidden from this `newRestriction`,
                // thus we create a new entry with all the default `self.boards` (which don't
                // include the new `board` yet)
                self.restricted[ObjectIdentifier(newRestriction)] = self.boards
            }
        }
        // finally the new board is added to the default collection of boards
        boards.append(board)
    }
}
