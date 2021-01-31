//
//  HandlerIdentifier.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-16.
//


import Foundation


/// An `AnyHandlerIdentifier` object identifies a `Handler` regardless of its concrete type.
open class AnyHandlerIdentifier: RawRepresentable, Hashable, Equatable, CustomStringConvertible {
    public let rawValue: String
    
    public required init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public convenience init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    public init<H: IdentifiableHandler>(_: H.Type) {
        self.rawValue = String(describing: H.self)
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
}
