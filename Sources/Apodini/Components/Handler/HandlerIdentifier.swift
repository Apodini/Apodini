//
//  HandlerIdentifier.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-16.
//


import Foundation


/// An `AnyHandlerIdentifier` object identifies a `Handler` regardless of its concrete type.
open class AnyHandlerIdentifier: Codable, RawRepresentable, Hashable, Equatable, CustomStringConvertible, KnowledgeSource {
    public let rawValue: String
    
    public required init<B>(_ blackboard: B) throws where B: Blackboard {
        let dslSpecifiedIdentifier = blackboard[DSLSpecifiedIdentifier.self].value
        let handlerSpecifiedIdentifier = blackboard[ExplicitlySpecifiedIdentifier.self].value
        
        switch (dslSpecifiedIdentifier, handlerSpecifiedIdentifier) {
        case (.some(let identifier), .none):
            self.rawValue = identifier.rawValue
        case (.none, .some(let identifier)):
            self.rawValue = identifier.rawValue
        case let (.some(ident1), .some(ident2)):
            if ident1 == ident2 {
                self.rawValue = ident1.rawValue
            } else {
                fatalError("""
                    Handler '\(blackboard[HandlerName.self].name)' has multiple explicitly specified identifiers ('\(ident1)' and '\(ident2)').
                    A handler may only have one explicitly specified identifier.
                    This is caused by using both the 'IdentifiableHandler.handlerId' property as well as the '.identified(by:)' modifier.
                    """
                )
            }
        case (.none, .none):
            let handlerIndexPath = blackboard[HandlerIndexPath.self]
            self.rawValue = handlerIndexPath.rawValue
        }
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
    
    init<H>(from handler: H) throws where H: Handler {
        self.value = handler.getExplicitlySpecifiedIdentifier()
    }
}

struct HandlerName: HandlerKnowledgeSource {
    let name: String
    
    init<H>(from handler: H) throws where H: Handler {
        self.name = "\(handler)"
    }
}
