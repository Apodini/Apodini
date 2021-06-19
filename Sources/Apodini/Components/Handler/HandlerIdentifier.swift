//
//  HandlerIdentifier.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-16.
//


import Foundation

private struct AllAnyHandlerIdentifiersAnchor: TruthAnchor {}

/// A `KnowledgeSource` that initializes and holds all `AnyHandlerIdenfier`, by also asserting the uniqueness of them.
private struct AllAnyHandlerIdentifiers: KnowledgeSource {
    static var preference: LocationPreference { .global }
    
    /// All registered `AnyHandlerIdentifer`'s of the web service
    var anyHandlerIdentifiers: Set<AnyHandlerIdentifier>
    
    /// `KnowledgeSource` initializer
    init<B>(_ blackboard: B) throws where B: Blackboard {
        var anyHandlerIdentifiers: Set<AnyHandlerIdentifier> = []
        
        for blackboard in blackboard[Blackboards.self][for: AllAnyHandlerIdentifiersAnchor.self] {
            let dslSpecifiedIdentifier = blackboard[DSLSpecifiedIdentifier.self].value
            let handlerSpecifiedIdentifier = blackboard[ExplicitlySpecifiedIdentifier.self].value
            
            let rawValue: String
            
            switch (dslSpecifiedIdentifier, handlerSpecifiedIdentifier) {
            case (.some(let identifier), .none):
                rawValue = identifier.rawValue
            case (.none, .some(let identifier)):
                rawValue = identifier.rawValue
            case let (.some(ident1), .some(ident2)):
                if ident1 == ident2 {
                    rawValue = ident1.rawValue
                } else {
                    preconditionFailure("""
                        Handler '\(blackboard[HandlerName.self].name)' has multiple explicitly specified identifiers ('\(ident1)' and '\(ident2)').
                        A handler may only have one explicitly specified identifier.
                        This is caused by using both the 'IdentifiableHandler.handlerId' property as well as the '.identified(by:)' modifier.
                        """
                    )
                }
            case (.none, .none):
                let handlerIndexPath = blackboard[HandlerIndexPath.self]
                rawValue = handlerIndexPath.rawValue
            }
            
            let anyHandlerIdentifier = AnyHandlerIdentifier(rawValue)
            let storage = anyHandlerIdentifiers.count
            
            anyHandlerIdentifiers.insert(anyHandlerIdentifier)
            
            Swift.assert(anyHandlerIdentifiers.count > storage, "Encountered a duplicated handler identifier: '\(rawValue)'. The explicitly specified identifiers must be unique")
            blackboard[AnyHandlerIdentifier.self] = anyHandlerIdentifier
        }
        
        self.anyHandlerIdentifiers = anyHandlerIdentifiers
    }
}

/// An `AnyHandlerIdentifier` object identifies a `Handler` regardless of its concrete type.
open class AnyHandlerIdentifier: Codable, RawRepresentable, Hashable, CustomStringConvertible, KnowledgeSource {
    public let rawValue: String
    
    public required init<B>(_ blackboard: B) throws where B: Blackboard {
        _ = blackboard[AllAnyHandlerIdentifiers.self]
        throw KnowledgeError.instancePresent
    }
    
    public required init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public convenience init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    public init<H: IdentifiableHandler>(_: H.Type) {
        self.rawValue = String(describing: H.self)
    }
    
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    public var description: String {
        "\(Self.self)(\"\(rawValue)\")"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
    
    public static func == (lhs: AnyHandlerIdentifier, rhs: AnyHandlerIdentifier) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}


/// A `Handler` identifier which is scoped to a specific handler type.
/// This is the primary way components should be identified and referenced.
open class ScopedHandlerIdentifier<H: IdentifiableHandler>: AnyHandlerIdentifier {
    public required init(rawValue: String) {
        super.init(rawValue: "\(H.self).\(rawValue)")
    }
    
    @available(*, unavailable, message: "'init(IdentifiableHandler.Type)' cannot be used with type-scoped handler identifiers")
    override public init<H: IdentifiableHandler>(_: H.Type) {
        fatalError("Not supported. Use one of the rawValue initializers.")
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public required init<B>(_ blackboard: B) throws where B: Blackboard {
        try super.init(blackboard)
    }
}

struct DSLSpecifiedIdentifier: OptionalContextKeyKnowledgeSource {
    typealias Key = ExplicitHandlerIdentifierContextKey
    
    let value: AnyHandlerIdentifier?
    
    init(from value: AnyHandlerIdentifier?) throws {
        self.value = value
    }
}

struct ExplicitlySpecifiedIdentifier: HandlerKnowledgeSource {
    let value: AnyHandlerIdentifier?
    
    init<H, B>(from handler: H, _ blackboard: B) throws where H: Handler, B: Blackboard {
        self.value = handler.getExplicitlySpecifiedIdentifier()
    }
}

struct HandlerName: HandlerKnowledgeSource {
    let name: String
    
    init<H, B>(from handler: H, _ blackboard: B) throws where H: Handler, B: Blackboard {
        self.name = "\(handler)"
    }
}
