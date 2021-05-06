//
//  KnowledgeSource.swift
//  
//
//  Created by Max Obermeier on 03.05.21.
//

import Foundation
@_implementationOnly import AssociatedTypeRequirementsVisitor

// MARK: KnowledgeSource

public protocol KnowledgeSource {
    init<B: Blackboard>(_ blackboard: B) throws
}

public indirect enum KnowledgeError: Error, CustomDebugStringConvertible {
    case unsatisfiableDependency(String, String?)
    case either([KnowledgeError])
    
    public var debugDescription: String {
        switch self {
        case let .unsatisfiableDependency(dependency, requiredBoard):
            var message = "'\(dependency)' was initialized as a regular 'KnowledgeSource'."
            if let required = requiredBoard {
                message += "You can only access '\(dependency)' from a '\(required)'."
            }
            return  message
        case let .either(errors):
            return "Trying to initialize a 'KnowledgeSource' failed. Either of the following errors must be resolved: \(errors)"
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

/// A `KnowledgeSource` that lives on a global `Blackboard`. It provides access to a list of local `Blackboard`s
/// available to a certain `TruthAnchor`.
public struct Blackboards: KnowledgeSource {
    
    // default collection of available Blackboards for unrestricted TruthAnchors
    private var boards: [Blackboard] = []
    
    // we store the available Blackboards for each restricted TruthAnchor separately
    private var restricted: [ObjectIdentifier:[Blackboard]] = [:]
    
    public init<B>(_ blackboard: B) throws where B : Blackboard {
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

extension Application: KnowledgeSource {
    public convenience init<B>(_ blackboard: B) throws where B : Blackboard {
        throw KnowledgeError.unsatisfiableDependency("Application", "GlobalBlackboard")
    }
}

public struct EndpointSource<H: Handler>: KnowledgeSource {
    public let handler: H
    public let context: Context
    
    internal init(handler: H, context: Context) {
        self.handler = handler
        self.context = context
    }
    
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        throw KnowledgeError.unsatisfiableDependency("EndpointSource", "LocalBlackboard")
    }
}

public struct AnyEndpointSource: KnowledgeSource {
    public let handler: Any
    public let handlerType: Any.Type
    public let context: Context
    
    internal init<H: Handler>(handler: H, context: Context) {
        self.handler = handler
        self.handlerType = H.self
        self.context = context
    }
    
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        throw KnowledgeError.unsatisfiableDependency("EndpointSource", "LocalBlackboard")
    }
}

public protocol HandlerBasedKnowledgeSource: KnowledgeSource {
    init<H: Handler>(from handler: H) throws
}

private protocol AnyEndpointSourceVisitor: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = AnyEndpointSourceVisitor
    associatedtype Input = Handler
    associatedtype Output
    
    func callAsFunction<T: Handler>(_ value: T) -> Output
}

extension HandlerBasedKnowledgeSource {
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        let anyEndpointSource = blackboard[AnyEndpointSource.self]
        
        guard let result = Visitor(type: Self.self)(anyEndpointSource.handler) else {
            fatalError("AssociatedTypeRequirementsVisitor didn't find a 'Handler' in 'AnyEndpointSource.handler'")
        }
        
        self = (try result.get()) as! Self
    }
}

private struct Visitor: AnyEndpointSourceVisitor {
    typealias Output = Result<HandlerBasedKnowledgeSource, Error>
    
    let type: HandlerBasedKnowledgeSource.Type
    
    func callAsFunction<H>(_ value: H) -> Output where H : Handler {
        Result.init(catching: {
            try type.init(from: value)
        })
    }
}

extension Visitor {
    private struct _TestHandler: Handler {
        func handle() throws -> Int {
            0
        }
    }
    
    @inline(never)
    @_optimize(none)
    func _test() {
        _ = self(_TestHandler()) as Output
    }
}
