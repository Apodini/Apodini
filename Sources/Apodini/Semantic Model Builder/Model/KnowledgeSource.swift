//
//  KnowledgeSource.swift
//  
//
//  Created by Max Obermeier on 03.05.21.
//

import Foundation

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


 // TODO: Context, Handler, Application KnowledgeSources as basis, which are always added by the SemanticModelBuilder

// MARK: Basic KnowledgeSources

public struct Blackboards: KnowledgeSource {
    
    // default collection of available Blackboards for unrestricted TruthAnchors
    private var boards: [Blackboard] = []
    
    // we store the available Blackboards for each restricted TruthAnchor separately
    private var restricted: [ObjectIdentifier:[Blackboard]] = [:]
    
    public init<B>(_ blackboard: B) throws where B : Blackboard { }
    
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
